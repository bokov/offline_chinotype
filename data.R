#' ---
#' title: "Read in Data"
#' author:
#' - "Alex F. Bokov^[UT Health, Department of Epidemiology and Biostatistics]"
#' date: "09/14/2018"
#' ---
#'
#+ message=F,echo=F
# init ----
debug <- 0;
.projpackages <- c('dplyr');
if(debug>0) source('scripts/global.R') else {
  .junk<-capture.output(source('scripts/global.R',echo=F))};
#.currentscript <- parent.frame(2)$ofile;
.currentscript <- current_scriptname('data.R');
#' Saving original file-list so we don't keep exporting functions and
#' environment variables to other scripts
.origfiles <- ls();
#+ echo=FALSE,message=FALSE
# read data ----
#' generic read function which auto-guesses file formats:
message('About to autoread');

rawdata <- sapply(inputdata,try_import,simplify=FALSE);
# rename columns
if(!file.exists(file.path(.workdir,'varmap.csv'))){
  map0 <- sapply(rawdata,makevarmap,simplify=FALSE) %>% c(.id='table') %>%
    do.call(bind_rows,.);
  write.csv(map0,file.path(.workdir,'varmap.csv'),row.names = FALSE);
} else {
  map0 <- try_import(file.path(.workdir,'varmap.csv'));
}

# chi_pconcepts
n_total <- length(unique(rawdata$dat01$PATIENT_NUM));
pconcepts <- data.table(rawdata$dat01)[,.(REF=.N
                                          ,PREFIX=gsub(':.*$','',CONCEPT_CD))
                                       ,by='CONCEPT_CD'] %>%
  setkey(PREFIX,CONCEPT_CD);

# save out ----
#' ## Save all the processed data to an rdata file
#'
suppressWarnings(save(file=file.path(.workdir
                                      ,paste0(basename(.currentscript)
                                              ,'.rdata'))
                       ,list=setdiff(ls(),.origfiles)));
#+ echo=F,eval=F
c()
