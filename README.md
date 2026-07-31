# Regional Building Energy Model Selector / 地域建物エネルギーモデル選択ツール

---

## 日本語

### 概要
本プロジェクトは、地域の建物リストから、エネルギーシミュレーション用の建物モデルを選択・サンプリングするツールです。建物の用途、延床面積、クラスター、空調システムなどの属性に基づいて、複数年度のシナリオを作成します。

### 前提条件
- R（バージョン 4.0 以上推奨）
- RStudio（推奨、必須ではない）

### 実行環境
- Windows11のUbuntu 24.04.3 LTS

### 環境構築

#### 1. Rのインストール
Ubuntu/Debianの場合：
```bash
sudo apt update
sudo apt install r-base r-base-dev
```

#### 2. 必要なRパッケージのインストール
Rコンソールまたはスクリプト内で以下を実行：
```r
install.packages("data.table")
install.packages("stringr")
```

### ディレクトリ構成
```
.
├── 00_BuildingList/          # 入力：地域別の建物リストCSVファイル
├── 01_TFA_Proportion/        # 入力：延床面積データベース（年度別）
├── 02_SelectedBuildingModels/# 出力：選択された建物モデル
├── 10_Setting/               # 設定ファイル（用途分類、アーキタイプなど）
├── 03_SelectBuildingModels.R # メインスクリプト
└── README.md
```

### 使用方法

#### 1. 建物リストの準備
`00_BuildingList/` ディレクトリに、対象地域の建物リストCSVファイルを配置してください。

必須カラム：
- `ID`: 建物ID
- `floor_area`: 延床面積
- `building_usage`: 建物用途
- `building_usage_detailed_sim`: 詳細用途分類
- `is_target`: 対象建物フラグ（TRUE/FALSE）
- `plant`: 空調システムタイプ（オプション）

#### 2. スクリプトの実行

**ステップ1**: Rを起動
```bash
R
```

**ステップ2**: 作業ディレクトリを設定
```r
setwd("/path/to/02b_G_Regional_BuildingList")
```

**ステップ3**: メインスクリプトを実行
```r
source("03_SelectBuildingModels.R")
```

#### 3. パラメータの設定
スクリプト内の以下のパラメータを編集してください：

```r
area <- "TokyoChuo"           # 対象地域名
region <- "Tokyo"             # 地方名
year <- 2022                  # 基準年
fileEncoding <- "UTF-8"       # ファイルエンコーディング

# カラム名の設定
colname_TFA <- "floor_area"
colname_building_segment <- "building_usage"
colname_building_subsegment <- "building_usage_detailed_sim"
colname_is_target <- "is_target"
```

### 出力ファイル

実行後、`02_SelectedBuildingModels/` ディレクトリに以下のファイルが生成されます：

- `00_[地域名]_Buildings_Year[年度].csv`: 選択された建物モデルリスト
- `00_[地域名]_Buildings_Year[年度]_withAddress.csv`: 住所情報付き建物モデルリスト
- `00_[地域名]DHW_Buildings_Year[年度].csv`: 給湯システム選択結果

複数年度（例：2022, 2030, 2050）のシナリオが自動的に作成されます。

### トラブルシューティング

#### エンコーディングエラーが発生する場合
```r
fileEncoding <- "shift-jis"  # または "UTF-8"
```

#### パッケージが見つからない場合
```r
# 各パッケージを個別にインストール
install.packages("data.table", dependencies = TRUE)
install.packages("stringr", dependencies = TRUE)
```

#### メモリ不足エラーの場合
Rのメモリ制限を増やす：
```r
# Linuxの場合
memory.limit(size = NA)
```

### 建物用途分類
本ツールでサポートされる建物用途：
1. Office（オフィス）
2. Hotel（宿泊施設）
3. Hospital（病院）
4. Retail（小売）
5. School（学校）
6. Restaurant（飲食店）
7. Datacenter（データセンター）
8. Logistics（物流施設）
9. Amusement（娯楽施設）

---

## English

### Overview
This project is a tool for selecting and sampling building energy models from regional building lists for energy simulation purposes. It creates multi-year scenarios based on building attributes such as usage, total floor area, cluster, and HVAC systems.

### Prerequisites
- R (version 4.0 or higher recommended)
- RStudio (recommended but not required)

### Setup
#### execution environment
- Windows11のUbuntu 24.04.3 LTS

#### 1. Install R
For Ubuntu/Debian:
```bash
sudo apt update
sudo apt install r-base r-base-dev
```

#### 2. Install Required R Packages
Execute in R console or within a script:
```r
install.packages("data.table")
install.packages("stringr")
```

### Directory Structure
```
.
├── 00_BuildingList/          # Input: Regional building list CSV files
├── 01_TFA_Proportion/        # Input: Total floor area database (by year)
├── 02_SelectedBuildingModels/# Output: Selected building models
├── 10_Setting/               # Configuration files (usage categories, archetypes)
├── 03_SelectBuildingModels.R # Main script
└── README.md
```

### Usage

#### 1. Prepare Building List
Place your regional building list CSV file in the `00_BuildingList/` directory.

Required columns:
- `ID`: Building ID
- `floor_area`: Total floor area
- `building_usage`: Building usage category
- `building_usage_detailed_sim`: Detailed usage classification
- `is_target`: Target building flag (TRUE/FALSE)
- `plant`: HVAC system type (optional)

#### 2. Execute Script

**Step 1**: Launch R
```bash
R
```

**Step 2**: Set working directory
```r
setwd("/path/to/02b_G_Regional_BuildingList")
```

**Step 3**: Run main script
```r
source("03_SelectBuildingModels.R")
```

#### 3. Configure Parameters
Edit the following parameters in the script:

```r
area <- "TokyoChuo"           # Target area name
region <- "Tokyo"             # Region name
year <- 2022                  # Base year
fileEncoding <- "UTF-8"       # File encoding

# Column name configuration
colname_TFA <- "floor_area"
colname_building_segment <- "building_usage"
colname_building_subsegment <- "building_usage_detailed_sim"
colname_is_target <- "is_target"
```

### Output Files

After execution, the following files will be generated in `02_SelectedBuildingModels/`:

- `00_[AreaName]_Buildings_Year[Year].csv`: Selected building model list
- `00_[AreaName]_Buildings_Year[Year]_withAddress.csv`: Building model list with address information
- `00_[AreaName]DHW_Buildings_Year[Year].csv`: Domestic hot water system selection results

Multi-year scenarios (e.g., 2022, 2030, 2050) are automatically created.

### Troubleshooting

#### Encoding Errors
```r
fileEncoding <- "shift-jis"  # or "UTF-8"
```

#### Package Not Found
```r
# Install each package individually
install.packages("data.table", dependencies = TRUE)
install.packages("stringr", dependencies = TRUE)
```

#### Out of Memory Error
Increase R memory limit:
```r
# For Linux
memory.limit(size = NA)
```

### Building Usage Categories
Supported building usage types:
1. Office
2. Hotel
3. Hospital
4. Retail
5. School
6. Restaurant
7. Datacenter
8. Logistics
9. Amusement

---

## License
This project is intended for research purposes. Please contact the laboratory for usage permissions.

## Contact
For questions or issues, please contact the research laboratory managing this repository.
