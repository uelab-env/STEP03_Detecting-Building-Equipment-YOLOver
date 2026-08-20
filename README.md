# Regional Building Energy Model Selector / 地域建物エネルギーモデル選択ツール

---

## 日本語

### 概要
本プロジェクトは、地域の建物リストから、エネルギーシミュレーション用の建物モデルを選択・サンプリングするツールです。建物の用途、延床面積、クラスター、空調システムなどの属性に基づいて、複数年度のシナリオを作成します。

※plot_office_tfa.pyは無視してください  
また01_SelectBuildingModels.Rも実行しません

### 前提条件
- Anaconda（またはMiniconda）
- R（バージョン 4.0 以上推奨、後述のconda仮想環境に同梱）
- RStudio（推奨、必須ではない）

### 実行環境
- Windows11のUbuntu 24.04.3 LTS

### 環境構築
本リポジトリでは、Rおよび必要なパッケージ一式を conda 仮想環境 `r_env` としてまとめて管理しています。個別に `install.packages()` を実行する必要はありません。

#### 1. Anacondaのインストール
未導入の場合は、[Anacondaのインストール手順](https://uelab.growi.cloud/61b187fa2c2460beb28066f9#:~:text=%23-,Anaconda%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%20/%20Installation%20of%20Anaconda,-edit_square)からインストールしてください。

#### 2. 仮想環境 `r_env` の作成
リポジトリのルートディレクトリで以下を実行し、`gyomu_r_env.yaml` から仮想環境を作成します（初回のみ）：
```bash
conda env create -n r_env -f gyomu_r_env.yaml
```
- r_envという名前が既にある仮想環境の名前と被る場合は、任意の名前の仮想環境を設定してください
- というか、このgyomu_r_envには、基礎的なパッケージしか入っていないので、既にお持ちのRの仮想環境でも対応可能だと思います

#### 3. 仮想環境の有効化
スクリプトを実行する際は、必ず事前に仮想環境を有効化してください：
```bash
conda activate r_env
```
以後の手順（R起動、`source()`の実行など）は、この仮想環境を有効化した状態のターミナルで行ってください。作業が終わったら以下で無効化できます：
```bash
conda deactivate
```

#### （参考）仮想環境を使わない場合
`r_env` を使わず、システムのRに直接パッケージを入れて動かすことも可能です。
```bash
sudo apt update
sudo apt install r-base r-base-dev
```
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
├── area_config.R             # 対象エリアの設定ファイル（要編集）
├── 03_SelectBuildingModels.R # メインスクリプト
├── gyomu_r_env.yaml          # conda仮想環境 r_env の定義ファイル
└── README.md
```

### 使用方法

#### 1. 建物リストの準備


##### 航空画像による熱源設備判定を使用しない場合
1. 業務モデルの[STEP01](https://github.com/uelab-env/Building-Usage-Determination_py)の以下のパスの"地名".csvを入力ファイルとする  
```01_Building-Usage-Determination\Building-Usage-Determination_py\"地名"\BuildingUsageDetermination_Chuo\"地名".csv```
2. `00_BuildingList/` ディレクトリに、対象地域の建物リストCSVファイル"地名".csvを配置してください。

##### 航空画像による熱源設備判定を使用する場合
1. 業務モデルの[STEP02](https://github.com/uelab-env/STEP02-Detecting-Building-Plant-byYOLOmodel)の以下のパスの"地名".csvを入力ファイルとする  
```output\"地名".csv```
2. `00_BuildingList/` ディレクトリに、対象地域の建物リストCSVファイル"地名".csvを配置してください。

必須カラム：
- `ID`: 建物ID
- `floor_area`: 延床面積
- `building_usage`: 建物用途
- `building_usage_detailed_sim`: 詳細用途分類
- `is_target`: 対象建物フラグ（TRUE/FALSE）
- `plant`: 空調システムタイプ（オプション）

#### 2. `area_config.R` の設定
対象エリアなどのパラメータは、メインスクリプト（`03_SelectBuildingModels.R`）を直接編集するのではなく、専用の設定ファイル `area_config.R` を編集して指定します。リポジトリ直下の `area_config.R` をエディタで開き、以下の値を対象エリアに合わせて書き換えてください。

```r
area <- "TokyoChuo"           # 対象地域名（00_BuildingList/ に置いたCSVファイル名と一致させる）
region <- "Tokyo"             # 地方名
year <- 2022                  # 基準年
fileEncoding <- "UTF-8"       # ファイルエンコーディング

# カラム名の設定
colname_TFA <- "floor_area"
colname_building_segment <- "building_usage"
colname_building_subsegment <- "building_usage_detailed_sim"
colname_is_target <- "is_target"
```

例えば `00_BuildingList/Yokohama.csv` を対象にする場合は `area <- "Yokohama"` のように書き換えます。`03_SelectBuildingModels.R` の実行時にこのファイルが自動的に読み込まれます。

#### 3. スクリプトの実行

**ステップ1**: （仮想環境を使用する場合）`r_env` を有効化
```bash
conda activate r_env
```

**ステップ2**: ファイルを実行
```bash
Rscript 03_SelectBuildingModels.R
```

01_SelectBuildingModels.Rは無視してください

### 出力ファイル

実行後、`02_SelectedBuildingModels/` ディレクトリに以下のファイルが生成されます：

- `00_[地域名]_Buildings_Year[年度].csv`: 選択された建物モデルリスト
- `00_[地域名]_Buildings_Year[年度]_withAddress.csv`: 住所情報付き建物モデルリスト
- `00_[地域名]DHW_Buildings_Year[年度].csv`: 給湯システム選択結果

複数年度（例：2022, 2030, 2050）のシナリオが自動的に作成されます。

### トラブルシューティング

#### エンコーディングエラーが発生する場合
`area_config.R` の `fileEncoding` を変更してください：
```r
fileEncoding <- "shift-jis"  # または "UTF-8"
```

#### パッケージが見つからない場合
まず `conda activate r_env` で仮想環境を有効化できているか確認してください。仮想環境を使わずシステムのRを使用している場合は、以下で個別にインストールしてください：
```r
install.packages("data.table", dependencies = TRUE)
install.packages("stringr", dependencies = TRUE)
```

#### メモリ不足エラーの場合
Rのメモリ制限を増やす：
```r
# Linuxの場合
memory.limit(size = NA)
```

### 既知の制限事項
`03_SelectBuildingModels.R` 内の「大字名」に基づく `エリア`（1〜4）の分類（`area1_names` 〜 `area4_names`）は、東京都中央区（`TokyoChuo`）を対象に作成されたものであり、他の地域を対象とする場合はこの分類が適用されません（`エリア` 列は `NA` になります）。中央区以外のエリアでこの分類を利用したい場合は、`03_SelectBuildingModels.R` 内の該当箇所を対象エリアの大字名に合わせて修正してください。

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
- Anaconda (or Miniconda)
- R (version 4.0 or higher recommended; bundled in the conda environment described below)
- RStudio (recommended but not required)

### Setup
#### execution environment
- Windows11のUbuntu 24.04.3 LTS

This repository manages R and all required packages together as a conda virtual environment named `r_env`. You do not need to run `install.packages()` individually.

#### 1. Install Anaconda/Miniconda
If not already installed, get it from the [Anaconda website](https://www.anaconda.com/download).

#### 2. Create the `r_env` virtual environment
From the repository root, create the environment from `gyomu_r_env.yaml` (one-time setup):
```bash
conda env create -n r_env -f gyomu_r_env.yaml
```

#### 3. Activate the virtual environment
Always activate the environment before running the script:
```bash
conda activate r_env
```
Perform the remaining steps (launching R, running `source()`, etc.) in a terminal where this environment is active. When you're done, you can deactivate it with:
```bash
conda deactivate
```

#### (Alternative) Without the virtual environment
You can also install R directly on your system instead of using `r_env`:
```bash
sudo apt update
sudo apt install r-base r-base-dev
```
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
├── area_config.R             # Target area configuration file (edit this)
├── 03_SelectBuildingModels.R # Main script
├── gyomu_r_env.yaml          # Definition file for the r_env conda environment
└── README.md
```

### Usage
#### 1. Prepare Building List
## When Not Using Aerial-Image-Based HVAC Equipment Detection

1. Use the following CSV file generated by **[STEP01](https://github.com/uelab-env/Building-Usage-Determination_py)** as the input file:
   ```
   01_Building-Usage-Determination/Building-Usage-Determination_py/<AreaName>/BuildingUsageDetermination_Chuo/<AreaName>.csv
   ```

2. Place the target building list CSV file (`<AreaName>.csv`) in the `00_BuildingList/` directory.

## When Using Aerial-Image-Based HVAC Equipment Detection

1. Use the following CSV file generated by **[STEP02](https://github.com/uelab-env/STEP02-Detecting-Building-Plant-byYOLOmodel)** as the input file:
   ```
   output/<AreaName>.csv
   ```
2. Place the target building list CSV file (`<AreaName>.csv`) in the `00_BuildingList/` directory.

Required columns:
- `ID`: Building ID
- `floor_area`: Total floor area
- `building_usage`: Building usage category
- `building_usage_detailed_sim`: Detailed usage classification
- `is_target`: Target building flag (TRUE/FALSE)
- `plant`: HVAC system type (optional)

#### 2. Configure `area_config.R`
Instead of editing the main script (`03_SelectBuildingModels.R`) directly, target-area parameters are set in a dedicated configuration file, `area_config.R`. Open `area_config.R` at the repository root in an editor and set the following values for your target area:

```r
area <- "TokyoChuo"           # Target area name (must match the CSV filename placed in 00_BuildingList/)
region <- "Tokyo"             # Region name
year <- 2022                  # Base year
fileEncoding <- "UTF-8"       # File encoding

# Column name configuration
colname_TFA <- "floor_area"
colname_building_segment <- "building_usage"
colname_building_subsegment <- "building_usage_detailed_sim"
colname_is_target <- "is_target"
```

For example, to target `00_BuildingList/Yokohama.csv`, set `area <- "Yokohama"`. This file is automatically loaded when `03_SelectBuildingModels.R` runs.

#### 3. Execute Script

**Step 1**: (If using the virtual environment) Activate `r_env`
```bash
conda activate r_env
```

**Step 2**: Run the script
```bash
Rscript 03_SelectBuildingModels.R
```

Please ignore `01_SelectBuildingModels.R`.

### Output Files

After execution, the following files will be generated in `02_SelectedBuildingModels/`:

- `00_[AreaName]_Buildings_Year[Year].csv`: Selected building model list
- `00_[AreaName]_Buildings_Year[Year]_withAddress.csv`: Building model list with address information
- `00_[AreaName]DHW_Buildings_Year[Year].csv`: Domestic hot water system selection results

Multi-year scenarios (e.g., 2022, 2030, 2050) are automatically created.

### Troubleshooting

#### Encoding Errors
Change `fileEncoding` in `area_config.R`:
```r
fileEncoding <- "shift-jis"  # or "UTF-8"
```

#### Package Not Found
First check that the virtual environment is active (`conda activate r_env`). If you're using your system's R without the virtual environment, install the packages individually:
```r
install.packages("data.table", dependencies = TRUE)
install.packages("stringr", dependencies = TRUE)
```

#### Out of Memory Error
Increase R memory limit:
```r
# For Linux
memory.limit(size = NA)
```

### Known Limitations
The `エリア` (Area 1–4) classification based on `大字名` (sub-district name) in `03_SelectBuildingModels.R` (`area1_names` through `area4_names`) was built specifically for Tokyo's Chuo Ward (`TokyoChuo`) and does not apply to other regions (the `エリア` column will be `NA`). If you want to use this classification for an area other than Chuo Ward, edit that section of `03_SelectBuildingModels.R` to match the sub-district names of your target area.

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
