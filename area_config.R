# ============================================================
# area_config.R
# 対象エリアの設定ファイル
#
# 03_SelectBuildingModels.R の実行前に、下記の値を対象エリアに
# 合わせて書き換えてください。03_SelectBuildingModels.R は本ファイルを
# source() して設定を読み込みます。
# ============================================================

# 対象地域名
# 00_BuildingList/ に配置した建物リストCSVファイル名（拡張子を除く）と
# 一致させてください。
# 例）00_BuildingList/TokyoChuo.csv を使う場合は "TokyoChuo"
area <- "TokyoChuo"

# 地方名
# 01_TFA_Proportion/ 内の延床面積データベースの Area 列の値と一致させてください。
region <- "Tokyo"

# 基準年（この年を起点に 2030, 2050 のシナリオが自動生成されます）
year <- 2022

# 建物リストCSVファイルの文字コード
fileEncoding <- "UTF-8"
# fileEncoding <- "shift-jis"

# 建物リストCSVファイルのカラム名設定
# 対象エリアのCSVファイルでカラム名が異なる場合はここを変更してください。
colname_TFA <- "floor_area"                                   # 延床面積
colname_building_segment <- "building_usage"                  # 建物用途
colname_building_subsegment <- "building_usage_detailed_sim"  # 詳細用途分類
colname_is_target <- "is_target"                              # 対象建物フラグ（TRUE/FALSE）
