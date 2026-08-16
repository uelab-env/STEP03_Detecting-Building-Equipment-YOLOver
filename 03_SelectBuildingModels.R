
library(data.table)
library(stringr)





sampling_buildings <- function(dir, tar_year, tar_b, MODE){
  
  
  usage_code <- c("01_Office","02_Hotel","03_Hospital","04_Retail", "05_School", "06_Restaurant", "07_Datacenter", "08_Logistics", "09_Amusement")
  usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")
  
  
  
  ff <- sprintf("%s/00_ALL_TotalFloorArea_%s.csv", dir, tar_year)
  TFA_5sectors <- fread(ff, data.table = F)
  rownames(TFA_5sectors) <- TFA_5sectors[, 1]
  TFA_5sectors <- TFA_5sectors[, c(2:ncol(TFA_5sectors))]
  TFA_5sectors <- subset(TFA_5sectors, TFA_5sectors$Area == region)
  
  ff <- sprintf("%s/00_ALL_RDLA_%s.csv", dir, tar_year)
  TFA_RDLA <- fread(ff, data.table = F)
  rownames(TFA_RDLA) <- TFA_RDLA[, 1]
  TFA_RDLA <- TFA_RDLA[, c(2:ncol(TFA_RDLA))]
  
  TFA_RDLA <- subset(TFA_RDLA, TFA_RDLA$Area == region)
  TFA_RDLA$Schedule_Sampling <- 0
  
  TFA <- rbind(TFA_5sectors, TFA_RDLA)
  
  ncol_b <- which(colnames(tar_b) == "Building")
  ncol_tar <- which(colnames(TFA) == "Building")
  n_b <- usage_code[factor(TFA$Building, levels = usage_code2)]
  n_cl <- TFA$Cluster
  
  ncol_TFA_from <- which(colnames(tar_b) == "TFA")
  ncol_TFA_to <- which(names(TFA) == "TFA")
  ncol_regionB <- which(names(tar_b) == "RegionBuilding")
  ncol_plant <- which(colnames(tar_b) == "PlantYOLO")
  
  
  TFA_out <- apply(tar_b, 1, function(zz){
    # print(zz[ncol_regionB])
    
    yy <- subset(TFA, n_b == zz[ncol_b] & n_cl == zz[ncol_b + 1])

    # 候補が0件の場合、一旦「用途」のみで全件抽出しておく
    if(nrow(yy) == 0){
      yy <- subset(TFA, n_b == zz[ncol_b])
    }
    
    # -------------------------------------------------------------
    # --- 追加: plant_YOLOの値に応じた条件付きサンプリング母集団の形成 ---
    # -------------------------------------------------------------
    if("PlantYOLO" %in% names(zz)) {
      yolo <- zz["PlantYOLO"]
      allowed_plants <- NULL
      
      if(!is.na(yolo) && yolo != "NA" && yolo != "") {
        if(yolo == "CT"){
          allowed_plants <- c("ABCH", "TB", "AB", "COM", "COM+TESICE")
        } else if(yolo == "ACC"){
          allowed_plants <- c("AHP", "AHP+TESICE")
        } else if(yolo %in% c("PAC", "MUL")){
          allowed_plants <- c("EHP", "GHP")
        }
      }
      
      # TFAデータベース側の空調システム列名が "Plant" であると仮定して絞り込みます。
      # （※実際のデータベースで列名が異なる場合は "Plant" の部分を修正してください）
      if(!is.null(allowed_plants) && "Plant" %in% colnames(yy)) {
        yy_filtered <- subset(yy, Plant %in% allowed_plants)
        
        # 絞り込んだ結果、該当するモデルが存在する場合のみ母集団を上書きする
        if(nrow(yy_filtered) > 0){
          yy <- yy_filtered
        }
      }
    }
    # -------------------------------------------------------------
    
    # 絞り込み等を経てそれでも候補が0件の場合は、エラー回避のため最初の1件を採用
    if(nrow(yy) == 0){
      yy <- subset(TFA, n_b == zz[ncol_b])[1,]
    }
    
    if(MODE == "Single"){
      rr <- runif(1)
      cumsum_TFA <- cumsum(yy$TFA)
      cumsum_TFA <- cumsum_TFA / cumsum_TFA[length(cumsum_TFA)]
      kk <- min(which(cumsum_TFA >= rr))
      if(length(kk) == 0){
        out <- as.character(yy[1, ])
      }else{
        out <- as.character(yy[kk, ])
      }
      out[ncol_TFA_to] <- zz[ncol_TFA_from]
      out <- c(out, zz[ncol_regionB], zz[ncol_plant])
      
    }else{
      
      prob <- as.numeric(yy$TFA) / sum(as.numeric(yy$TFA))
      
      n_size <- ifelse(nrow(yy) > 50, 50, nrow(yy))
      kk <- sample(c(1:length(prob)), size = n_size, replace = F, prob = prob)
      
      if(length(kk) == 0){
        out <- as.character(c(yy[1, ], zz[ncol_regionB], zz[ncol_plant]))
        out[ncol_TFA_to] <- zz[ncol_TFA_from]
      }else{
        out <- cbind(
          yy[kk, ],
          rep(zz[ncol_regionB], length(kk)),
          rep(zz[ncol_plant], length(kk))
        )
        out[, ncol_TFA_to] <-  rep(zz[ncol_TFA_from], length(kk))
        out <- as.character(t(out))
      }
      
    }
    
    # print(length(out)/17)    
    out
  })

  TFA_out <- t(matrix(unlist(TFA_out), nrow = ncol(TFA)+2))

  TFA_out <- data.frame(TFA_out)
  names(TFA_out) <- c(names(TFA), "RegionBuilding", "PlantYOLO")

  # TFA_out$Remarks <- sprintf("%s_%s", formatC(as.integer(tar_b$X), width = 2, flag = "0"), 
  #                            tar_b$BuildingName)
  
  TFA_out
}








sampling_DHW <- function(TFA_out, tar_year){
  
  
  usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")
  
  no_b <- as.integer(TFA_out$NoBuilding)
  
  no_b <- cbind(as.integer(factor(TFA_out$Building, levels = usage_code2)), no_b)
  
  
  
  dir <- "01_TFA_Proportion"
  ff <- sprintf("%s/00_DHW_TotalFloorArea_%s.csv", dir, tar_year)
  print(ff)
  
  candidates <- read.csv(ff, stringsAsFactors = F, fileEncoding = "shift-jis", row.names = 1)

  no_b_DHW <- apply(no_b, 1, function(aa){
    
    if(aa[1] > 5){
      out <- 0
    }else{
      nn <- which(aa[2] == candidates$NoBuilding)
      if(length(nn) == 0){
        out <- 0
      }else{
        out <- nn[1]
      }
    }
    out
  })
  
  no_reg <- subset(TFA_out$RegionBuilding, no_b_DHW > 0)
  no_b_out <- subset(c(1:length(no_b_DHW)), no_b_DHW > 0)
  no_b_DHW <- subset(no_b_DHW, no_b_DHW > 0)
  
  selected_scenario <- candidates[no_b_DHW, ]
  rownames(selected_scenario) <- no_b_out
  selected_scenario$RegionBuilding <- no_reg
  selected_scenario$PlantYOLO <- TFA_out$PlantYOLO[no_b_out]
  
  selected_scenario
}



make_scenario_for_all_candidates <- function(area, region, year, tar_b){
 
  ff <- "10_Setting/00_SegmentCategory.csv"
  SegmentSetting <- read.csv(ff, stringsAsFactors = F, fill = TRUE, fileEncoding = "shift-jis")
  usage_code <- c("01_Office","02_Hotel","03_Hospital","04_Retail", "05_School", "06_Restaurant", "07_Datacenter", "08_Logistics", "09_Amusement")
  usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")
  
  fname <- "./10_Setting/01_TFA_Archetype.csv"
  archetypes <- read.csv(fname, stringsAsFactors = F, fill = TRUE, fileEncoding = "shift-jis")
  
  
  
  MODE <- "Multiple"
  MODE <- "Single"
  
  tar_years <- c(year, 2030, 2050)
  dir <- "01_TFA_Proportion"
  out_dir <- "02_SelectedBuildingModels"
  
  
  for(year in tar_years){
  
    tar_year <- sprintf("Year%s", year)
    print(tar_year)

    print("sampling_buildings")  
    TFA_out <- sampling_buildings(dir, tar_year, tar_b, MODE)
    # print(head(TFA_out))
    
    # TFA_out <- read.csv(ff, stringsAsFactors = F, row.names = 1, fileEncoding = "shift-jis")
    
    print("sampling_DHW")  
    TFA_DHW <- sampling_DHW(TFA_out, tar_year)
    
    region_b <- TFA_out$RegionBuilding
    check_b <- TFA_DHW$RegionBuilding
    
    # print(head(TFA_DHW))

    nn_tar <- sapply(check_b, function(aa){
      kk <- which(region_b == aa)
      
      # if(length(kk) != 1){
      #   print(sprintf("[%s][%s]",aa,kk))
      # }
      kk[1]
    })
    
    # print(class(nn_tar))
    
    print("Output")  
    TFA_out$Schedule_Sampling <- sample(c(1:400), nrow(TFA_out), replace = TRUE, prob = NULL)
    # print("Output1")  
    TFA_DHW$Schedule_Sampling <- TFA_out$Schedule_Sampling[nn_tar]
    # print("Output2")  
    TFA_DHW$TFA <- TFA_out$TFA[nn_tar]
    
    # 従来フォーマット（他プログラムの input として使用）
    ff <- sprintf("%s/00_%s_Buildings_%s.csv", out_dir, area, tar_year)
    print(ff)
    write.csv(TFA_out, ff, fileEncoding = "UTF-8")

    # 属性付きフォーマット（ID, 住所コード, building_usage, building_usage_detailed を先頭に追加）
    meta_cols <- c("ID", "住所コード", "大字名", "字丁目名", "建物名", "building_usage", "building_usage_detailed", "地域冷暖房計画区域", "is_target", "エリア")
    if(all(meta_cols %in% names(tar_b))) {
      meta <- tar_b[, c("RegionBuilding", meta_cols)]
      idx  <- match(TFA_out$RegionBuilding, meta$RegionBuilding)
      TFA_out_enriched <- cbind(meta[idx, meta_cols, drop = FALSE], TFA_out)
      rownames(TFA_out_enriched) <- NULL

      # 指定カラムを先頭に配置
      front_cols <- c("RegionBuilding", "エリア", "大字名", "字丁目名", "建物名", "地域冷暖房計画区域", "is_target", "building_usage", "building_usage_detailed", "PlantYOLO")
      TFA_out_enriched <- TFA_out_enriched[, c(front_cols, setdiff(names(TFA_out_enriched), front_cols))]

      ff <- sprintf("%s/00_%s_Buildings_%s_withAddress.csv", out_dir, area, tar_year)
      print(ff)
      write.csv(TFA_out_enriched, ff, fileEncoding = "UTF-8")
    }

    ff <- sprintf("%s/00_%sDHW_Buildings_%s.csv", out_dir, area, tar_year)
    print(ff)
    write.csv(TFA_DHW, ff, fileEncoding = "UTF-8")
    
  }

}


# 
# MODE <- 1
# area <- "ChibaSosa"
# area <- "TokyoTama"
# area <- "TokyoChuo"
# 
# 
# area <- "NagasakiNagasaki"
# region <- "Fukuoka"
# 
# area <- "FukuokaIizuka"
# area <- "FukuokaKama"
# region <- "Fukuoka"


ff <- "10_Setting/00_SegmentCategory.csv"
SegmentSetting <- read.csv(ff, stringsAsFactors = F, fill = TRUE, fileEncoding = "shift-jis")
usage_code <- c("01_Office","02_Hotel","03_Hospital","04_Retail", "05_School", "06_Restaurant", "07_Datacenter", "08_Logistics", "09_Amusement")
usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")

fname <- "./10_Setting/01_TFA_Archetype.csv"
archetypes <- read.csv(fname, stringsAsFactors = F, fill = TRUE, fileEncoding = "shift-jis")



MODE <- 2

# 対象エリア・地方名・基準年・カラム名等の設定は area_config.R で行う
source("area_config.R")

ff <- sprintf("00_BuildingList/%s.csv", area)
# Use fread for better BOM handling
Buildings <- as.data.frame(fread(ff, encoding = "UTF-8", check.names = FALSE))
rownames(Buildings) <- Buildings[[1]]
Buildings <- Buildings[, -1]

Buildings$Region <- region

# 「大字名」を基にエリア1〜4を分類
area1_names <- c("日本橋本石町", "日本橋横山町", "日本橋浜町", "日本橋箱崎町", "日本橋茅場町",
                  "日本橋蛎殻町", "日本橋馬喰町", "日本橋人形町", "日本橋兜町", "日本橋堀留町",
                  "日本橋大伝馬町", "日本橋室町", "日本橋富沢町", "日本橋小伝馬町", "日本橋小網町",
                  "日本橋小舟町", "日本橋本町", "日本橋中洲", "日本橋久松町", "八丁堀", "新川", "東日本橋")
area2_names <- c("京橋", "八重洲", "日本橋")
area3_names <- c("銀座", "銀座西")
area4_names <- c("佃", "入船", "明石町", "晴海", "月島", "勝どき", "新富", "湊", "築地", "豊海町", "浜離宮庭園")

Buildings$エリア <- NA
Buildings$エリア[Buildings[["大字名"]] %in% area1_names] <- 1
Buildings$エリア[Buildings[["大字名"]] %in% area2_names] <- 2
Buildings$エリア[Buildings[["大字名"]] %in% area3_names] <- 3
Buildings$エリア[Buildings[["大字名"]] %in% area4_names] <- 4

dir <- "02_SelectedBuildingModels"
if(!dir.exists(dir)){
  dir.create(dir)
}

if(MODE == 1){
  colnames(Buildings)[1] <- "BuildingName"
  tar_b <- data.frame(BuildingName = Buildings$BuildingName,
                      Area = Buildings$Region,
                      Building = Buildings$Building,
                      Cluster = Buildings$Segment,
                      TFA = Buildings$colname_TFA,
                      RegionBuilding = rownames(Buildings))
  
  
}else{
  
  Buildings$RegionBuilding <- sprintf("B%s", formatC(c(1:nrow(Buildings)), width = 5, flag = "0"))
  
  # ターゲットの建物のみを抽出
  print(paste("Buildings shape before subset:", nrow(Buildings), "rows,", ncol(Buildings), "cols"))
  print(paste("Checking column:", colname_is_target))
  print(paste("Column exists:", colname_is_target %in% colnames(Buildings)))
  
  if(!colname_is_target %in% colnames(Buildings)) {
    print(paste("WARNING: Column", colname_is_target, "not found. Available columns:"))
    print(colnames(Buildings))
    # Fallback: assume all records are targets
    Buildings$is_target <- TRUE
  }
  
  Buildings[colname_is_target] <- as.logical(Buildings[[colname_is_target]])
  print(paste("is_target values - TRUE:", sum(Buildings[[colname_is_target]], na.rm=TRUE), "FALSE:", sum(!Buildings[[colname_is_target]], na.rm=TRUE)))
  Buildings <- subset(Buildings, Buildings[[colname_is_target]])
  print(paste("Buildings shape after subset:", nrow(Buildings), "rows"))
  
  buildings <- data.frame(
    Region = Buildings$Region,
    RegionBuilding = Buildings$RegionBuilding,
    # Cat_PointData = Buildings[[colname_Cat_PointData]],
    Segment = Buildings[[colname_building_segment]],
    SubSegment = Buildings[[colname_building_subsegment]],
    TFA = Buildings[[colname_TFA]]
  )
  print(paste("buildings shape:", nrow(buildings), "rows,", ncol(buildings), "cols"))

  
  buildings$SegBESM <- usage_code[as.integer(factor(buildings$Segment, levels = SegmentSetting$Usage))]
  
  
  ncol_TFA <- which(colnames(buildings) == "TFA")
  ncol_SubSeg <- which(colnames(buildings) == "SubSegment")
  
  ncol_SegBSEM <- which(colnames(buildings) == "SegBESM")
  
  mat_seg <- matrix(nrow = nrow(buildings), ncol = 3, NA)
  colnames(mat_seg) <- c("Building", "Cluster", "Zoning")
  print(paste("mat_seg initial shape:", nrow(mat_seg), "rows,", ncol(mat_seg), "cols"))
  
  
  # 事務所、宿泊、医療
  for(kk in c(1:3)){
    nn <- which(buildings$SegBESM == usage_code[kk])
    if(length(nn) > 0) {
      out <- t(apply(buildings[nn, c(ncol_SegBSEM, ncol_TFA)], 1, function(aa){
        tar <- subset(archetypes, archetypes$Building == as.character(aa[1]))
        bb <- subset(tar, as.numeric(aa[2]) >= tar$MinTFA)
        if(nrow(bb) > 0) {
          as.character(bb[nrow(bb), c(1:3)])
        } else {
          c(NA, NA, NA)
        }
      }))
      
      # Ensure out is a matrix (not a vector if only one row)
      if(!is.matrix(out)) {
        out <- matrix(out, nrow = 1)
      }
      
      for(ii in c(1:3)){
        mat_seg[nn, ii] <- out[, ii]
      }
    }
  }
  
  for(kk in c(4:9)){
    nn <- which(buildings$SegBESM == usage_code[kk])
    
    if(length(nn) == 0){
      next
    }
    out <- t(apply(buildings[nn, c(ncol_SegBSEM, ncol_SubSeg, ncol_TFA)], 1, function(aa){
      mm <- which(archetypes$Building == as.character(aa[1]) & archetypes$Cluster == as.character(aa[2]))
      if(length(mm) > 0) {
        as.character(archetypes[mm, c(1:3)])
      } else {
        c(NA, NA, NA)
      }
    }))
    
    # Ensure out is a matrix (not a vector if only one row)
    if(!is.matrix(out)) {
      out <- matrix(out, nrow = 1)
    }
    
    for(ii in c(1:3)){
      mat_seg[nn, ii] <- out[, ii]
    }
  }  
  
  print(paste("Before tar_b: Buildings=", nrow(Buildings), "rows, mat_seg=", nrow(mat_seg), "rows"))
  print(paste("Columns to use: RegionBuilding=", length(Buildings$RegionBuilding), ", Region=", length(Buildings$Region)))
  print(paste("              floor_area=", length(Buildings$floor_area)))
  
  tar_b <- data.frame(BuildingName = Buildings$RegionBuilding,
                      Area = Buildings$Region,
                      Building = mat_seg[,1],
                      Cluster = mat_seg[,2],
                      TFA = Buildings$floor_area,
                      RegionBuilding = Buildings$RegionBuilding,
                      PlantYOLO = if("plant" %in% colnames(Buildings)) Buildings$plant else NA)

  tar_b$ID                    <- rownames(Buildings)
  tar_b[["住所コード"]]          <- Buildings[["住所コード"]]
  tar_b[["大字名"]]              <- Buildings[["大字名"]]
  tar_b[["字丁目名"]]            <- Buildings[["字丁目名"]]
  tar_b[["建物名"]]              <- Buildings[["建物名"]]
  tar_b[["building_usage"]]    <- Buildings[["building_usage"]]
  tar_b[["building_usage_detailed"]] <- Buildings[["building_usage_detailed"]]
  tar_b[["地域冷暖房計画区域"]]       <- Buildings[["地域冷暖房計画区域"]]
  tar_b[["is_target"]]         <- Buildings[[colname_is_target]]
  tar_b[["エリア"]]              <- Buildings[["エリア"]]
}

make_scenario_for_all_candidates(area, region, year, tar_b)

