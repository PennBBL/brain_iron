compileData <- function(){
  library(tidyverse)
  setwd("/data/jux/BBL/projects/brain_iron/scripts/PublicationScripts/")
  #Get the demographics and cognitive vars
  ### Demographics
  demographics <- read.csv('/data/jux/BBL/projects/brain_iron/scripts/analysis/n3699_demographics_20181120.csv')
  ### Cognitive measures
  # WRAT (IQ) data
  wrat <- read.csv('/data/jux/BBL/projects/brain_iron/input_data/cnb_wrat_20181213.csv')
  colnames(wrat) = gsub("scan2cnbmonths", "scan2wratmonths", colnames(wrat))
  # Motor
  motor <- read.csv('/data/jux/BBL/projects/brain_iron/input_data/cnb_mpraxis_20181220.csv')
  #Factor scores
  cog_fac <- read.csv('/data/jux/BBL/projects/brain_iron/input_data/CNB_Factor_Scores_GO1-GO2-GO3_NON-AGE-REGRESSED.csv')
  cog_fac <- cog_fac %>% filter(bblid != 110689) # this person is an age outlier
  
  ## Make an ID table
  cnbtable <- read.csv("~/go1_go2_go3_pnc_cnb_zscores_frar_20170202_wdates.csv")
  cnbtable <- cnbtable %>% select(bblid,cnbDatasetid,timepoint,cnbAgeMonths)
  scanmatches <-motor %>% group_by(bblid,datasetid) %>% summarize(scanid=ScanID[which.min(scan2cnbmonths)])
  cnbtable <- left_join(cnbtable,scanmatches,by = c("bblid","cnbDatasetid" ="datasetid"))
  koshtables <- left_join(demographics,scanmatches,by = c("BBLID"="bblid","ScanID"="scanid")) %>% select(BBLID,ScanID,datasetid,ProjectName,ScanAgeMonths)
  # This table will match up all identifying variables
  IDT <- left_join(koshtables,cnbtable,by = c("BBLID" = "bblid","datasetid"="cnbDatasetid")) %>% select(BBLID,ScanID,datasetid,ProjectName,timepoint,ScanAgeMonths,cnbAgeMonths)
  
  # Now assemble behavior and demographic data
  facTable <- full_join(cnbtable,cog_fac,by = c("bblid","timepoint"))
  behTable <- full_join(koshtables,demographics,by = c("BBLID","ScanID","ScanAgeMonths","ProjectName")) %>%
    left_join(facTable,by = c("BBLID" = "bblid","ScanID"="scanid", "datasetid"="cnbDatasetid")) %>%
    left_join(motor,by = c("BBLID"="bblid","ScanID","datasetid")) %>%
    left_join(wrat,by = c("BBLID"="bblid","ScanID"="ScanID","datasetid"))
  
  ### QA data
  qa <- read.csv("/data/jux/BBL/projects/brain_iron/input_data/QA_ALL.csv")
  qa <- qa %>%
    distinct() %>% na.omit()
  qa$GOOD <- as.factor(qa$GOOD)
  protocols <- read.csv('/data/jux/BBL/projects/brain_iron/scripts/echotimes.csv')
  protocols <- protocols %>% distinct()
  
  ## Load t2 files and combine dataframes
  # T2*
  t2 <- read.csv('/data/jux/BBL/projects/brain_iron/results/t2star_ROIs_TEMPLATE.csv');
  t2_sigma <- read.csv('/data/jux/BBL/projects/brain_iron/results/t2star_sigma_ROIs_TEMPLATE.csv');
  t2 <- full_join(t2,t2_sigma,by = c("bblid","scanid"),suffix=c("","_sd")) %>% select_if(~!all(is.na(.)))
    
  # convert T2* (msec) to R2* (1/sec)
  r2 <- t2%>%
    mutate_at(4:ncol(t2),funs(1000/.))
  # change Inf to NA
  is.na(r2) <- sapply(r2, is.infinite)
    
  ##Merge
  dataTable <- r2 %>% group_by(bblid) %>% mutate(visit= as.factor(min_rank(scanid))) %>%
    left_join(protocols,by = c("bblid","scanid")) %>%
    left_join(qa,by = c("bblid"="BBLID","scanid"="SCANID")) %>%
    full_join(behTable, by = c("bblid"="BBLID","scanid"="ScanID"))
 
  dataTable$bblid <- as.factor(dataTable$bblid)
  dataTable <- dataTable %>% distinct() #remove duplicate rows
  dataTable$te1 <- as.factor(dataTable$te1)
  dataTable$sex <- factor(dataTable$SEX,labels = c("male","female"))
  dataTable$oSex <- ordered(dataTable$sex,levels = c("male","female"))
  dataTable$oRace <- ordered(dataTable$RACE)
  dataTable$oRace_bwo <- dataTable$RACE
  dataTable$oRace_bwo[dataTable$RACE>2] = 3
  dataTable$oRace_bwo <- ordered(dataTable$oRace_bwo,levels = c(1,2,3), labels = c("white","black","other"))
  dataTable$timepoint <- ordered(dataTable$timepoint)
  dataTable$age <- dataTable$ScanAgeMonths/12
  dataTable <- dataTable %>% rowwise() %>% mutate(Putamen = mean(c(Left_Putamen,Right_Putamen)),na.rm = T) 
  dataTable <- dataTable %>% rowwise() %>% mutate(Caudate = mean(c(Left_Caudate,Right_Caudate)),na.rm = T) 
  dataTable <- dataTable %>% rowwise() %>% mutate(Pallidum = mean(c(Left_Pallidum,Right_Pallidum)),na.rm = T) 
  dataTable <- dataTable %>% rowwise() %>% mutate(Accumbens_Area = mean(c(Left_Accumbens_Area,Right_Accumbens_Area)),na.rm = T) 

  dataTable <- dataTable %>% rowwise() %>% mutate(Putamen_sd = mean(c(Left_Putamen_sd,Right_Putamen_sd)),na.rm = T) 
  dataTable <- dataTable %>% rowwise() %>% mutate(Caudate_sd = mean(c(Left_Caudate_sd,Right_Caudate_sd)),na.rm = T) 
  dataTable <- dataTable %>% rowwise() %>% mutate(Pallidum_sd = mean(c(Left_Pallidum_sd,Right_Pallidum_sd)),na.rm = T) 
  dataTable <- dataTable %>% rowwise() %>% mutate(Accumbens_Area_sd = mean(c(Left_Accumbens_Area_sd,Right_Accumbens_Area_sd)),na.rm = T) 
  ## save the dataframe
  saveRDS(dataTable, file="brain_iron_data_TEMPLATE.Rda")
}
