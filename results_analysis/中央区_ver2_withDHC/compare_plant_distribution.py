"""
YOLO有り・無しの熱源設備推定結果の比較可視化スクリプト

グラフ1: Plant別 総延床面積の比較 (全体・積み上げ棒グラフ)
グラフ2: 大字名×Plant別 総延床面積の比較 (上位10地域)
グラフ3: Cluster×Plant別 割合の比較
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")  # 非インタラクティブ環境向け
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib import rcParams

# 日本語フォント設定（Noto Sans CJK JP を使用）
rcParams["font.family"] = "Noto Sans CJK JP"
rcParams["font.size"]   = 24  # 全テキスト基本サイズ

# ── データ読み込み ──────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

df_noyolo = pd.read_csv(os.path.join(SCRIPT_DIR, "00_TokyoChuo_Buildings_Year2022_ori.csv"),
                        index_col=0)
df_yolo   = pd.read_csv(os.path.join(SCRIPT_DIR, "00_TokyoChuo_Buildings_Year2022_yolo.csv"),
                        index_col=0)

df_yolo["TFA"]   = pd.to_numeric(df_yolo["TFA"],   errors="coerce")
df_noyolo["TFA"] = pd.to_numeric(df_noyolo["TFA"], errors="coerce")

# CSV内の "TESICE" 表記 → グラフ表示用の "蓄熱" 表記に統一
_PLANT_RENAME = {"AHP+TESICE": "AHP+蓄熱", "COM+TESICE": "COM+蓄熱"}
df_yolo["Plant"]   = df_yolo["Plant"].replace(_PLANT_RENAME)
df_noyolo["Plant"] = df_noyolo["Plant"].replace(_PLANT_RENAME)

# 熱源種別の表示順（統一）
PLANT_ORDER = ["EHP", "GHP", "AHP", "AHP+蓄熱", "ABCH", "TB", "AB", "COM", "COM+蓄熱"]

LABEL_YOLO   = "提案モデル"
LABEL_NOYOLO = "従来モデル"

OUT_DIR = SCRIPT_DIR
os.makedirs(OUT_DIR, exist_ok=True)

# ── カラーパレット ──────────────────────────────────────────────────────────────
PLANT_COLORS = {
    "EHP":        "#18ce6a",
    "GHP":        "#0A6D12",
    "AHP":        "#0daeee",
    "AHP+蓄熱": "#3010e6",
    "ABCH":       "#e90e0e",
    "TB":         "#e97508",
    "AB":         "#d81577",
    "COM":        "#ff9da7",
    "COM+蓄熱": "#dd0ac1",
}

# CT/ACC/MULorPAC 区分（graph1 追加バー用）
PLANT_CATEGORY = {
    "CT":       ["ABCH", "TB", "AB", "COM", "COM+蓄熱"],
    "ACC":      ["AHP", "AHP+蓄熱"],
    "MULorPAC": ["EHP", "GHP"],
}
CATEGORY_ORDER  = ["MULorPAC", "ACC", "CT"]   # 積み上げ順（下から）
CATEGORY_COLORS = {
    "CT":       "red",
    "ACC":      "blue",
    "MULorPAC": "green",
}


# ================================================================================
# グラフ1: Plant別 総延床面積 (全体・積み上げ1本 vs 1本 + CT/ACC/MUL区分バー)
# ================================================================================
def plot_graph1():
    def agg_plant(df):
        return (df.groupby("Plant")["TFA"]
                  .sum()
                  .reindex(PLANT_ORDER, fill_value=0)
                  / 1e4)   # 万m²

    def agg_category(plant_series):
        return pd.Series({
            cat: sum(plant_series.get(p, 0) for p in plants)
            for cat, plants in PLANT_CATEGORY.items()
        })

    tfa_yolo   = agg_plant(df_yolo)
    tfa_noyolo = agg_plant(df_noyolo)
    cat_yolo   = agg_category(tfa_yolo)
    cat_noyolo = agg_category(tfa_noyolo)

    # バー位置: [従来-CT/ACC/MUL, 従来-詳細, 提案-CT/ACC/MUL, 提案-詳細]
    width     = 0.9
    inner_gap = width * 1.15   # 同グループ内バー間隔
    group_gap = width * 2.0    # グループ間追加間隔
    x_nc = 0
    x_nd = x_nc + inner_gap
    x_yc = x_nd + group_gap
    x_yd = x_yc + inner_gap

    fig, ax = plt.subplots(figsize=(16, 10))

    def _stacked_plant(x_pos, series, alpha, outlined=False):
        bottom = 0.0
        for plant in PLANT_ORDER:
            val = series.get(plant, 0)
            color = PLANT_COLORS.get(plant, "#aaaaaa")
            ec = "black" if outlined else "white"
            lw = 1.2 if outlined else 0.5
            ax.bar(x_pos, val, width, bottom=bottom, label=plant,
                   color=color, alpha=alpha, edgecolor=ec, linewidth=lw)
            bottom += val

    def _stacked_cat(x_pos, cat_series, alpha, outlined=False):
        bottom = 0.0
        for cat in CATEGORY_ORDER:
            val = cat_series.get(cat, 0)
            color = CATEGORY_COLORS.get(cat, "#aaaaaa")
            ec = "black" if outlined else "white"
            lw = 1.2 if outlined else 0.5
            ax.bar(x_pos, val, width, bottom=bottom, label=f"_cat_{cat}",
                   color=color, alpha=alpha, edgecolor=ec, linewidth=lw)
            bottom += val

    _stacked_cat  (x_nc, cat_noyolo, alpha=0.6)
    _stacked_plant(x_nd, tfa_noyolo, alpha=0.6)
    _stacked_cat  (x_yc, cat_yolo,   alpha=1.0, outlined=True)
    _stacked_plant(x_yd, tfa_yolo,   alpha=1.0, outlined=True)

    ax.set_xticks([x_nc, x_nd, x_yc, x_yd])
    ax.set_xticklabels(
        [f"{LABEL_NOYOLO}\n2.1_STEP5熱源区分", f"{LABEL_NOYOLO}\n2.3の詳細分析",
         f"{LABEL_YOLO}\n2.1_STEP5熱源区分",   f"{LABEL_YOLO}\n2.3の詳細分析"],
        rotation=90, ha="center"
    )
    ax.set_ylabel("総延床面積 (万 m²)")
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v:,.0f}"))
    ax.grid(axis="y", linestyle="--", alpha=0.5)

    # 凡例: 熱源種別（詳細）＋区分（CT/ACC/MULorPAC）を1つの凡例にまとめる
    import matplotlib.patches as mpatches
    from matplotlib.lines import Line2D

    handles, labels = ax.get_legend_handles_labels()
    plant_h, plant_l = [], []
    seen = set()
    for h, l in zip(handles, labels):
        if l in PLANT_COLORS and l not in seen:
            seen.add(l); plant_h.append(h); plant_l.append(l)

    # 区分エントリ
    cat_entries = [(mpatches.Patch(color=CATEGORY_COLORS[cat]), cat) for cat in CATEGORY_ORDER]

    # 区切り用ダミーエントリ（空ラベル＋不可視パッチ）
    sep_h = mpatches.Patch(color="none", linewidth=0)
    sep_l = " "   # 空白1文字（空文字だとmatplotlibが無視する場合あり）

    all_h = (plant_h + [sep_h] +
             [Line2D([0],[0], color="none")] +  # タイトル代わりの空行
             [e[0] for e in cat_entries])
    all_l = (plant_l + [sep_l] + ["─── 熱源区分 ───"] +
             [e[1] for e in cat_entries])

    ax.legend(all_h, all_l, loc="upper left", bbox_to_anchor=(1.02, 1.0),
              borderaxespad=0, fontsize=20, title="熱源種別（詳細）", title_fontsize=20)

    fig.tight_layout(rect=[0, 0, 0.78, 1])

    out = os.path.join(OUT_DIR, "graph1_plant_total_tfa.png")
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"[保存] {out}")


# ================================================================================
# グラフ2: 大字名×Plant別 総延床面積 (上位10地域のみ)
# ================================================================================
def plot_graph2():
    def agg(df):
        pt = (df.groupby(["大字名", "Plant"])["TFA"]
                .sum()
                .unstack(fill_value=0)
                .reindex(columns=PLANT_ORDER, fill_value=0)
                / 1e4)   # 万m²
        # 割合に変換
        total = pt.sum(axis=1)
        pt_pct = pt.div(total.replace(0, 1), axis=0) * 100.0
        return pt_pct

    pt_yolo   = agg(df_yolo)
    pt_noyolo = agg(df_noyolo)

    # 表示する大字名（指定順）
    CHOME_ORDER = ["銀座", "京橋", "日本橋", "八重洲", "日本橋本石町",
                   "日本橋小舟町", "日本橋久松町", "八丁堀", "勝どき", "豊海町"]

    all_chomes = pt_yolo.index.union(pt_noyolo.index)
    pt_yolo   = pt_yolo.reindex(all_chomes, fill_value=0)
    pt_noyolo = pt_noyolo.reindex(all_chomes, fill_value=0)

    # 指定リストに含まれる地域のみ・指定順で抽出
    order = [c for c in CHOME_ORDER if c in all_chomes]
    pt_yolo   = pt_yolo.loc[order]
    pt_noyolo = pt_noyolo.loc[order]

    n_areas = len(order)
    x       = range(n_areas)
    width   = 0.4

    fig, ax = plt.subplots(figsize=(max(20, n_areas * 1.2), 10))

    def stacked_bars(ax, data, x_positions, width, alpha, outlined=False):
        bottoms = [0.0] * len(data)
        for plant in PLANT_ORDER:
            vals = data[plant].values if plant in data.columns else [0] * len(data)
            color = PLANT_COLORS.get(plant, "#aaaaaa")
            ec = "black" if outlined else "white"
            lw = 1.2   if outlined else 0.5
            ax.bar(x_positions, vals, width,
                   bottom=bottoms, label=plant,
                   color=color, alpha=alpha, edgecolor=ec, linewidth=lw)
            bottoms = [b + v for b, v in zip(bottoms, vals)]

    stacked_bars(ax, pt_noyolo, [i - width/2 for i in x], width, alpha=0.6)
    stacked_bars(ax, pt_yolo,   [i + width/2 for i in x], width, alpha=1.0, outlined=True)

    ax.set_xticks(list(x))
    ax.set_xticklabels(order, rotation=90, ha="center")
    ax.set_ylabel("熱源種別の割合 (%)")
    ax.set_ylim(0, 100)
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v:.0f}%"))
    ax.grid(axis="y", linestyle="--", alpha=0.5)

    handles, labels = ax.get_legend_handles_labels()
    seen, unique_h, unique_l = set(), [], []
    for h, l in zip(handles, labels):
        if l not in seen:
            seen.add(l); unique_h.append(h); unique_l.append(l)
    ax.legend(unique_h, unique_l, loc="upper left", bbox_to_anchor=(1.02, 1),
              borderaxespad=0, fontsize=22, title="熱源種別", title_fontsize=22)
    fig.tight_layout(rect=[0, 0, 0.88, 1])

    out = os.path.join(OUT_DIR, "graph2_chome_plant_tfa.png")
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"[保存] {out}")


# ================================================================================
# グラフ3: Cluster×Plant別 割合 (積み上げ棒グラフ・割合表示)
# ================================================================================

# Clusterのマージ定義
CLUSTER_MERGE = {
    "CL6m": "CL6", "CL6b": "CL6",
    "CL7m": "CL7",
    "CL8c": "CL8",
    "CL9c": "CL9",
}

def merge_clusters(df):
    """ClusterカラムをCLUSTER_MERGEに従ってマージした新列を返す"""
    d = df.copy()
    d["Cluster"] = d["Cluster"].replace(CLUSTER_MERGE)
    return d

def _cl_sort_key(name):
    """CL1〜CL9を先頭・番号順、それ以外を後ろにするソートキー"""
    import re
    m = re.match(r'^CL(\d+)$', name)
    if m:
        return (0, int(m.group(1)), name)
    return (1, 0, name)


def _make_stacked_bars(ax, data, x_positions, width, alpha, outlined=False):
    bottoms = [0.0] * len(data)
    for plant in PLANT_ORDER:
        vals = data[plant].values if plant in data.columns else [0.0] * len(data)
        color = PLANT_COLORS.get(plant, "#aaaaaa")
        ec = "black" if outlined else "white"
        lw = 1.2   if outlined else 0.5
        ax.bar(x_positions, vals, width,
               bottom=bottoms, label=plant,
               color=color, alpha=alpha, edgecolor=ec, linewidth=lw)
        bottoms = [b + v for b, v in zip(bottoms, vals)]


def _unique_legend(ax, fontsize=22):
    handles, labels = ax.get_legend_handles_labels()
    seen, unique_h, unique_l = set(), [], []
    for h, l in zip(handles, labels):
        if l not in seen:
            seen.add(l); unique_h.append(h); unique_l.append(l)
    ax.legend(unique_h, unique_l, loc="upper left", bbox_to_anchor=(1.02, 1),
              borderaxespad=0, fontsize=fontsize, title="熱源種別", title_fontsize=fontsize)


def plot_graph3():
    def agg(df):
        d = merge_clusters(df)
        pt = (d.groupby(["Cluster", "Plant"])
               .size()
               .unstack(fill_value=0)
               .reindex(columns=PLANT_ORDER, fill_value=0))
        total = pt.sum(axis=1)
        # 非CLクラスタで建物数10件以下は除外
        is_cl = pt.index.str.startswith("CL")
        keep  = is_cl | (total > 10)
        pt    = pt[keep]
        total = total[keep]
        # 割合に変換
        pt_pct = pt.div(total, axis=0) * 100.0
        return pt_pct, total

    pt_yolo,   total_yolo   = agg(df_yolo)
    pt_noyolo, total_noyolo = agg(df_noyolo)

    # CL1→CL9順、その後その他
    all_clusters = sorted(pt_yolo.index.union(pt_noyolo.index), key=_cl_sort_key)
    pt_yolo      = pt_yolo.reindex(all_clusters,   fill_value=0)
    pt_noyolo    = pt_noyolo.reindex(all_clusters, fill_value=0)
    total_yolo   = total_yolo.reindex(all_clusters, fill_value=0)

    n_cls = len(all_clusters)
    x     = [i * 1.5 for i in range(n_cls)]
    width = 0.6

    fig, ax = plt.subplots(figsize=(max(20, n_cls * 1.5 + 3), 10))

    _make_stacked_bars(ax, pt_noyolo, [xi - width/2 for xi in x], width, alpha=0.6)
    _make_stacked_bars(ax, pt_yolo,   [xi + width/2 for xi in x], width, alpha=1.0, outlined=True)

    # 棒グラフ上にYOLO版の建物数のみ記載
    for idx, cl in enumerate(all_clusters):
        n_yes = int(total_yolo.get(cl, 0))
        ax.text(x[idx] + width/2, 101, f"{n_yes}", ha="center", va="bottom", fontsize=20, clip_on=False)

    ax.set_xticks(x)
    ax.set_xticklabels(all_clusters, rotation=45, ha="right")
    ax.set_ylabel("熱源種別の割合 (%)")
    ax.set_ylim(0, 100)
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v:.0f}%"))
    ax.grid(axis="y", linestyle="--", alpha=0.5)
    _unique_legend(ax)
    fig.tight_layout(rect=[0, 0, 0.88, 1])

    out = os.path.join(OUT_DIR, "graph3_cluster_plant_count.png")
    fig.savefig(out, dpi=150)
    plt.close(fig)
    print(f"[保存] {out}")


# ================================================================================
# グラフ4: Building種別(Office/Hotel/Hospital)×CL別 Plant割合
# ================================================================================

CL_BUILDINGS = ["Office", "Hotel", "Hospital"]
BUILDING_JP  = {"Office": "事務所", "Hotel": "ホテル", "Hospital": "病院"}


def plot_graph4():
    for building in CL_BUILDINGS:
        d_yolo   = merge_clusters(df_yolo[df_yolo["Building"] == building])
        d_noyolo = merge_clusters(df_noyolo[df_noyolo["Building"] == building])

        def agg(d):
            pt = (d.groupby(["Cluster", "Plant"])
                   .size()
                   .unstack(fill_value=0)
                   .reindex(columns=PLANT_ORDER, fill_value=0))
            # CL1〜CL9のみ
            pt = pt[pt.index.str.match(r'^CL\d+$')]
            total = pt.sum(axis=1)
            pt_pct = pt.div(total.replace(0, 1), axis=0) * 100.0
            return pt_pct, total

        pt_yolo,   total_yolo   = agg(d_yolo)
        pt_noyolo, total_noyolo = agg(d_noyolo)

        all_cls = sorted(pt_yolo.index.union(pt_noyolo.index), key=_cl_sort_key)
        pt_yolo   = pt_yolo.reindex(all_cls,   fill_value=0)
        pt_noyolo = pt_noyolo.reindex(all_cls, fill_value=0)
        total_yolo = total_yolo.reindex(all_cls, fill_value=0)

        n_cls = len(all_cls)
        if n_cls == 0:
            continue

        x     = [i * 1.5 for i in range(n_cls)]
        width = 0.6

        fig, ax = plt.subplots(figsize=(max(12, n_cls * 1.8 + 3), 10))

        _make_stacked_bars(ax, pt_noyolo, [xi - width/2 for xi in x], width, alpha=0.6)
        _make_stacked_bars(ax, pt_yolo,   [xi + width/2 for xi in x], width, alpha=1.0, outlined=True)

        for idx, cl in enumerate(all_cls):
            n_yes = int(total_yolo.get(cl, 0))
            ax.text(x[idx], 101, f"{n_yes}棟", ha="center", va="bottom", fontsize=20, clip_on=False)

        ax.set_xticks(x)
        ax.set_xticklabels(all_cls, rotation=90, ha="center")
        ax.set_ylabel("熱源種別の割合 (%)")
        ax.set_ylim(0, 100)
        ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v:.0f}%"))
        ax.grid(axis="y", linestyle="--", alpha=0.5)
        _unique_legend(ax)
        fig.tight_layout(rect=[0, 0, 0.88, 1])

        out = os.path.join(OUT_DIR, f"graph4_{building.lower()}_cluster_plant.png")
        fig.savefig(out, dpi=150)
        plt.close(fig)
        print(f"[保存] {out}")


# ── 実行 ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("グラフ1: Plant別 総延床面積 (全体) を生成中...")
    plot_graph1()

    print("グラフ2: 大字名×Plant別 総延床面積 を生成中...")
    plot_graph2()

    print("グラフ3: Cluster×Plant別 割合 を生成中...")
    plot_graph3()

    print("グラフ4: Building種別(Office/Hotel/Hospital)×CL別 Plant割合 を生成中...")
    plot_graph4()

    print("完了。results_analysis/ フォルダにPNGが出力されました。")
