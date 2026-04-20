
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
  ncol_sourceName <- which(colnames(tar_b) == "SourceBuildingName")
  
  
  TFA_out <- apply(tar_b, 1, function(zz){
    # print(zz[ncol_regionB])
    
    yy <- subset(TFA, n_b == zz[ncol_b] & n_cl == zz[ncol_b + 1])
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
      out <- c(out, zz[ncol_regionB], zz[ncol_sourceName])
      
    }else{
      
      prob <- as.numeric(yy$TFA) / sum(as.numeric(yy$TFA))
      
      n_size <- ifelse(nrow(yy) > 50, 50, nrow(yy))
      kk <- sample(c(1:length(prob)), size = n_size, replace = F, prob = prob)
      
      if(length(kk) == 0){
        out <- as.character(c(yy[1, ], zz[ncol_regionB], zz[ncol_sourceName]))
        out[ncol_TFA_to] <- zz[ncol_TFA_from]
      }else{
        out <- cbind(yy[kk, ], rep(zz[ncol_regionB], length(kk)), rep(zz[ncol_sourceName], length(kk)))
        out[, ncol_TFA_to] <-  rep(zz[ncol_TFA_from], length(kk))
        out <- as.character(t(out))
      }
      
    }
    
    # print(length(out)/17)    
    out
  })

  TFA_out <- t(matrix(unlist(TFA_out), nrow = ncol(TFA)+2))

  TFA_out <- data.frame(TFA_out)
  names(TFA_out) <- c(names(TFA), "RegionBuilding", "SourceBuildingName")

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
  selected_scenario$SourceBuildingName <- TFA_out$SourceBuildingName[no_b_out]
  
  selected_scenario
}



make_scenario_for_all_candidates <- function(area, region, year, tar_b){
 
  ff <- "10_Setting/00_SegmentCategory.csv"
  SegmentSetting <- read.csv(ff, stringsAsFactors = F, fileEncoding = "shift-jis")
  usage_code <- c("01_Office","02_Hotel","03_Hospital","04_Retail", "05_School", "06_Restaurant", "07_Datacenter", "08_Logistics", "09_Amusement")
  usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")
  
  fname <- "./10_Setting/01_TFA_Archetype.csv"
  archetypes <- read.csv(fname, stringsAsFactors = F, fileEncoding = "shift-jis")
  
  
  
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
    
    ff <- sprintf("%s/00_%s_Buildings_%s.csv", out_dir, area, tar_year)
    print(ff)
    write.csv(TFA_out, ff, fileEncoding = "shift-jis")
    
    ff <- sprintf("%s/00_%sDHW_Buildings_%s.csv", out_dir, area, tar_year)
    print(ff)
    write.csv(TFA_DHW, ff, fileEncoding = "shift-jis")
    
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
SegmentSetting <- read.csv(ff, stringsAsFactors = F, fileEncoding = "shift-jis")
usage_code <- c("01_Office","02_Hotel","03_Hospital","04_Retail", "05_School", "06_Restaurant", "07_Datacenter", "08_Logistics", "09_Amusement")
usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")

fname <- "./10_Setting/01_TFA_Archetype.csv"
archetypes <- read.csv(fname, stringsAsFactors = F, fileEncoding = "shift-jis")



MODE <- 2
area <- "TokyoChuo"
region <- "Tokyo"
year <- 2022
fileEncoding <- "UTF-8"
# fileEncoding <- "shift-jis"

colname_TFA <- "floor_area"
colname_building_segment <- "building_usage"
colname_building_subsegment <- "building_usage_detailed_sim"
# colname_Cat_PointData <- "building_usage_detailed"
colname_is_target <- "is_target"

ff <- sprintf("00_BuildingList/%s.csv", area)
Buildings <- read.csv(ff, stringsAsFactors = F, fileEncoding = fileEncoding, row.names = 1, check.names = FALSE)
Buildings$SourceBuildingName <- Buildings[["建物名"]]
Buildings$Region <- region

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
  Buildings[colname_is_target] <- as.logical(Buildings[[colname_is_target]])
  Buildings <- subset(Buildings, Buildings[[colname_is_target]])
  
  
  buildings <- data.frame(
    Region = Buildings$Region,
    RegionBuilding = Buildings$RegionBuilding,
    # Cat_PointData = Buildings[[colname_Cat_PointData]],
    Segment = Buildings[[colname_building_segment]],
    SubSegment = Buildings[[colname_building_subsegment]],
    TFA = Buildings[[colname_TFA]]
  )

  
  buildings$SegBESM <- usage_code[as.integer(factor(buildings$Segment, levels = SegmentSetting$Usage))]
  
  
  ncol_TFA <- which(colnames(buildings) == "TFA")
  ncol_SubSeg <- which(colnames(buildings) == "SubSegment")
  
  ncol_SegBSEM <- which(colnames(buildings) == "SegBESM")
  
  mat_seg <- matrix(nrow = nrow(buildings), ncol = 3, NA)
  colnames(mat_seg) <- c("Building", "Cluster", "Zoning")
  
  
  # 事務所、宿泊、医療
  for(kk in c(1:3)){
    nn <- which(buildings$SegBESM == usage_code[kk])
    out <- t(apply(buildings[nn, c(ncol_SegBSEM, ncol_TFA)], 1, function(aa){
      tar <- subset(archetypes, archetypes$Building == as.character(aa[1]))
      bb <- subset(tar, as.numeric(aa[2]) >= tar$MinTFA)
      as.character(bb[nrow(bb), c(1:3)])
    }))
    
    for(ii in c(1:3)){
      mat_seg[nn, ii] <- out[, ii]
    }
  }
  
  for(kk in c(4:9)){
    nn <- which(buildings$SegBESM == usage_code[kk])
    
    if(length(nn) == 0){
      next
    }
    out <- t(apply(buildings[nn, c(ncol_SegBSEM, ncol_SubSeg, ncol_TFA)], 1, function(aa){
      
      mm <- which(archetypes$Building == as.character(aa[1]) & archetypes$Cluster == as.character(aa[2]))
      as.character(archetypes[mm, c(1:3)])
    }))
    
    for(ii in c(1:3)){
      mat_seg[nn, ii] <- out[, ii]
    }
  }  
  
  tar_b <- data.frame(BuildingName = Buildings$RegionBuilding,
                      Area = Buildings$Region,
                      Building = mat_seg[,1],
                      Cluster = mat_seg[,2],
                      TFA = Buildings$floor_area,
                      RegionBuilding = Buildings$RegionBuilding,
                      SourceBuildingName = Buildings$SourceBuildingName)
  
  
}

make_scenario_for_all_candidates(area, region, year, tar_b)

