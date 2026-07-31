import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
from pathlib import Path
import re

# ─── パス設定 ───────────────────────────────────────────────
DATA_DIR = Path("/home/un_ishimura/03_SIP_gyomu/02b_G_Regional_BuildingList/01_TFA_Proportion")
OUT_DIR  = Path("/home/un_ishimura/03_SIP_gyomu/02b_G_Regional_BuildingList")

# ─── 対象地域・CLラベル ────────────────────────────────────
REGIONS   = ["Sapporo", "Sendai", "Tokyo", "Nigata", "Nagoya",
             "Osaka", "Hiroshima", "Matsuyama", "Fukuoka", "Naha"]
CL_COLS   = ["V3","V4","V5","V6","V7","V8","V9","V10","V11"]
CL_LABELS = ["CL1","CL2","CL3","CL4","CL5","CL6","CL7","CL8","CL9"]

# ─── 地域ごとのカラーマップ（同系色） ───────────────────────
# 10地域にそれぞれ異なるカラーファミリを割り当て
CMAPS = {
    "Sapporo"  : "Blues",
    "Sendai"   : "Greens",
    "Tokyo"    : "Reds",
    "Nigata"   : "Purples",
    "Nagoya"   : "Oranges",
    "Osaka"    : "GnBu",
    "Hiroshima": "RdPu",
    "Matsuyama": "YlGn",
    "Fukuoka"  : "BuPu",
    "Naha"     : "YlOrBr",
}

# ─── データ読み込み ────────────────────────────────────────
files = sorted(DATA_DIR.glob("01_Region_Segment_Year*.csv"))
records = {}  # {(region, year): [CL1..CL9]}
years_set = set()

for f in files:
    m = re.search(r'Year(\d{4})', f.name)
    if not m:
        continue
    year = int(m.group(1))
    years_set.add(year)

    df = pd.read_csv(f, index_col=0, dtype=str)
    office_df = df[df["V1"] == "Office"]

    for region in REGIONS:
        row = office_df[office_df["V2"] == region]
        if row.empty:
            continue
        vals = []
        for col in CL_COLS:
            try:
                v = float(row[col].values[0])
            except (ValueError, TypeError, KeyError):
                v = 0.0
            vals.append(max(v, 0.0))
        records[(region, year)] = vals

years = sorted(years_set)
n_years = len(years)

# ─── プロット ──────────────────────────────────────────────
fig, axes = plt.subplots(2, 5, figsize=(26, 11), sharex=True)
fig.suptitle("Office Total Floor Area by Region and CL Class",
             fontsize=15, fontweight="bold", y=1.01)

for idx, region in enumerate(REGIONS):
    ax = axes[idx // 5, idx % 5]

    # 年×CLのデータ行列を構築
    matrix = np.array([
        records.get((region, y), [0.0] * 9)
        for y in years
    ])  # shape: (n_years, 9)

    # 同系色：colormap の 0.25~0.95 の範囲から9色
    cmap   = cm.get_cmap(CMAPS[region])
    colors = [cmap(0.25 + 0.70 * i / 8) for i in range(9)]

    # 積み上げ面グラフ
    ax.stackplot(years, matrix.T,
                 labels=CL_LABELS,
                 colors=colors,
                 alpha=0.92)

    ax.set_title(region, fontsize=12, fontweight="bold")
    ax.set_xlim(min(years), max(years))
    ax.set_ylim(bottom=0)

    # Y軸を百万m²単位で表示
    ax.yaxis.set_major_formatter(
        plt.FuncFormatter(lambda x, _: f"{x/1e6:.0f}M")
    )
    ax.tick_params(axis="x", rotation=45, labelsize=14)
    ax.tick_params(axis="y", labelsize=14)
    ax.set_ylabel("", fontsize=16)

    # 凡例は左上のサブプロットのみ表示
    if idx == 0:
        ax.legend(loc="upper left", fontsize=7,
                  ncol=1, framealpha=0.7, title="CLクラス", title_fontsize=16)

# X軸ラベルは下段のみ
for ax in axes[1]:
    ax.set_xlabel("", fontsize=9)

plt.tight_layout()

out_png = OUT_DIR / "office_tfa_by_region_cl.png"
out_svg = OUT_DIR / "office_tfa_by_region_cl.svg"
fig.savefig(out_png, dpi=150, bbox_inches="tight")
fig.savefig(out_svg, bbox_inches="tight")
print(f"Saved:\n  {out_png}\n  {out_svg}")
plt.show()

# ─── 全地域合算の積み上げ面グラフ ─────────────────────────
fig2, ax2 = plt.subplots(figsize=(14, 7))
fig2.suptitle("Office Total Floor Area – All Regions Combined (Stacked)",
              fontsize=14, fontweight="bold")

# 積み上げ順：Sapporo→Naha の順に、各地域のCL1~CL9を重ねる
stack_data   = []   # 各バンドの時系列 (n_years,)
stack_colors = []   # 各バンドの色
stack_labels = []   # 凡例ラベル

for region in REGIONS:
    cmap   = cm.get_cmap(CMAPS[region])
    colors = [cmap(0.25 + 0.70 * i / 8) for i in range(9)]
    for cl_idx, cl_label in enumerate(CL_LABELS):
        series = np.array([
            records.get((region, y), [0.0] * 9)[cl_idx]
            for y in years
        ])
        stack_data.append(series)
        stack_colors.append(colors[cl_idx])
        stack_labels.append(f"{region} {cl_label}")

ax2.stackplot(years, stack_data,
              labels=stack_labels,
              colors=stack_colors,
              alpha=0.88)

ax2.set_xlim(min(years), max(years))
ax2.set_ylim(bottom=0)
ax2.set_xlabel("", fontsize=11)
ax2.set_ylabel("", fontsize=11)
ax2.yaxis.set_major_formatter(
    plt.FuncFormatter(lambda x, _: f"{x/1e6:.0f}M")
)
ax2.tick_params(axis="x", rotation=45, labelsize=14)
ax2.tick_params(axis="y", labelsize=14)

# 凡例：地域代表色を1エントリにまとめて表示（90個は多すぎるため地域単位で）
from matplotlib.patches import Patch
legend_handles = []
for region in REGIONS:
    cmap = cm.get_cmap(CMAPS[region])
    rep_color = cmap(0.60)   # 代表色（中間値）
    legend_handles.append(Patch(facecolor=rep_color, label=region))

ax2.legend(handles=legend_handles,
           loc="upper left", fontsize=12,
           ncol=2, framealpha=0.8, title="Region", title_fontsize=16)

plt.tight_layout()

out_comb_png = OUT_DIR / "office_tfa_combined.png"
out_comb_svg = OUT_DIR / "office_tfa_combined.svg"
fig2.savefig(out_comb_png, dpi=150, bbox_inches="tight")
fig2.savefig(out_comb_svg, bbox_inches="tight")
print(f"Saved:\n  {out_comb_png}\n  {out_comb_svg}")
plt.show()
