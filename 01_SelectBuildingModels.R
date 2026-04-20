
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
  
  
  TFA_out <- apply(tar_b, 1, function(zz){
    print(zz[ncol_regionB])
    
    yy <- subset(TFA, n_b == zz[ncol_b] & n_cl == zz[ncol_b + 1])
    if(nrow(yy) == 0){
      out <- as.character(c(TFA[1, ], zz[1]))
      out[ncol_TFA_to] <- zz[ncol_TFA_from]
    }else{
      
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
        out <- c(out, zz[ncol_regionB])
        
      }else{
        
        prob <- as.numeric(yy$TFA) / sum(as.numeric(yy$TFA))
        
        n_size <- ifelse(nrow(yy) > 50, 50, nrow(yy))
        kk <- sample(c(1:length(prob)), size = n_size, replace = F, prob = prob)
        
        if(length(kk) == 0){
          out <- as.character(c(yy[1, ], zz[ncol_regionB]))
          out[ncol_TFA_to] <- zz[ncol_TFA_from]
        }else{
          out <- cbind(yy[kk, ], rep(zz[ncol_regionB], length(kk)))
          out[, ncol_TFA_to] <-  rep(zz[ncol_TFA_from], length(kk))
          out <- as.character(t(out))
        }
        
      }
    }

    print(length(out)/17)    
    out
  })

  TFA_out <- t(matrix(unlist(TFA_out), nrow = ncol(TFA)+1))

  TFA_out <- data.frame(TFA_out)
  names(TFA_out) <- c(names(TFA), "RegionBuilding")

  # TFA_out$Remarks <- sprintf("%s_%s", formatC(as.integer(tar_b$X), width = 2, flag = "0"), 
  #                            tar_b$BuildingName)
  
  TFA_out
}








sampling_DHW <- function(TFA_out){
  usage_code2 <- c("Office","Hotel","Hospital","Retail", "School", "Restaurant", "Datacenter", "Logistics", "Amusement")
  
  no_b <- as.integer(TFA_out$NoBuilding)
  
  no_b <- cbind(as.integer(factor(TFA_out$Building, levels = usage_code2)), no_b)
  
  
  
  dir <- "01_TFA_Proportion"
  ff <- sprintf("%s/00_DHW_TotalFloorArea_Year%s.csv", dir, year)
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

    TFA_out <- sampling_buildings(dir, tar_year, tar_b, MODE)
    ff <- sprintf("%s/00_%s_Buildings_%s.csv", out_dir, area, tar_year)
    write.csv(TFA_out, ff, fileEncoding = "shift-jis")
    
    # TFA_out <- read.csv(ff, stringsAsFactors = F, row.names = 1, fileEncoding = "shift-jis")
    
    TFA_DHW <- sampling_DHW(TFA_out)
    
    region_b <- as.integer(TFA_out$RegionBuilding)
    check_b <- as.integer(TFA_DHW$RegionBuilding)
    nn_tar <- sapply(check_b, function(aa){
      kk <- which(region_b == aa)
      kk[1]
    })
    
    TFA_out$Schedule_Sampling <- sample(c(1:400), nrow(TFA_out), replace = TRUE, prob = NULL)
    TFA_DHW$Schedule_Sampling <- TFA_out$Schedule_Sampling[nn_tar]
    TFA_DHW$TFA <- TFA_out$TFA[nn_tar]
    
    
    ff <- sprintf("%s/00_%sDHW_Buildings_%s.csv", out_dir, area, tar_year)
    write.csv(TFA_DHW, ff, fileEncoding = "shift-jis")
    
  }

}



area <- "TokyoChuo"
region <- "Tokyo"
fileEncoding <- "shift-jis"
fileEncoding <- "UTF-8"
year <- 2025


ff <- sprintf("00_BuildingList/%s.csv", area)

Buildings <- read.csv(ff, stringsAsFactors = F, fileEncoding = fileEncoding, row.names = 1)
colnames(Buildings)[1] <- "BuildingName"
Buildings$Region <- region



tar_b <- data.frame(BuildingName = Buildings$BuildingName,
                    Area = Buildings$Region,
                    Building = Buildings$Building,
                    Cluster = Buildings$Segment,
                    TFA = Buildings$延床面積...,
                    RegionBuilding = rownames(Buildings))


make_scenario_for_all_candidates(area, region, year, tar_b)

