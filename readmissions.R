#' # Minimum Scriport
#'
#' Add the names of packages (enclosed in quotes) you need to this vector
.projpackages <- c('pander','dplyr','readr','survival','survminer');
#' If you want to reuse calculations done by other scripts, add them to `.deps`
#' below after `'dictionary.R'`.
.deps <- c( 'dictionary.R' );
#+ load_deps, echo=FALSE, message=FALSE, warning=FALSE,results='hide'
# Do not edit the next line
.junk<-capture.output(source('./scripts/global.R',chdir=TRUE,echo=FALSE));
#' Edit the next line only if you copy or rename this file (make the new name the
#' argument to `current_scriptname()`)
.currentscript <- current_scriptname('minimum_scriport.R');
#' ### Start
#'
#' Completely overriding `data.R` because lots of custom steps needed
dat0 <- read_tsv('local/reduced/obsfact_efi_small.tsv') %>%
  subset(.,grepl('^[0-9]*0',(.)$PATIENT_NUM)) %>%
  mutate(START_DATE=as.Date(START_DATE)) %>% unique();
dat1ip <- read_tsv('local/reduced/obsfact_ip.tsv') %>%
  mutate(START_DATE=as.Date(START_DATE)) %>% unique;
dat2ed <- read_tsv('local/reduced/obsfact_ed.tsv') %>%
  mutate(START_DATE=as.Date(START_DATE)) %>% unique;
# TODO: also read in local/reduced/obsfact_disc.tsv
pat <- read_tsv('local/patient_dimension.tsv') %>%
  select(PATIENT_NUM,BIRTH_DATE,DEATH_DATE,SEX_CD,LANGUAGE_CD,RACE_CD,HISPANIC
         ,MARITAL_STATUS_CD) %>%
  mutate(BIRTH_DATE=as.Date(BIRTH_DATE),DEATH_DATE=as.Date(DEATH_DATE));

dat3 <- left_join(dat0,dat1ip) %>%
  mutate(IP=!is.na(CONCEPT_CD),CONCEPT_CD=NULL) %>%
  left_join(dat2ed) %>% mutate(ED=!is.na(CONCEPT_CD),CONCEPT_CD=NULL) %>%
  left_join(pat) %>% mutate(enc_age=as.numeric(START_DATE-BIRTH_DATE)) %>%
  group_by(PATIENT_NUM) %>% arrange(START_DATE) %>%
  group_modify(function(xx,yy) {
    # time from previous inpatient encounter
    xx[xx$IP,'REIP'] <- diff(c(-Inf,subset(xx,IP)$START_DATE));
    if(yy$PATIENT_NUM %in% head(.patipna,19)){ print('NA'); browser();}
    if(yy$PATIENT_NUM %in% .patipinf){ print('Inf'); browser();}
    # time from previous ED encounter
    xx[xx$ED,'REED'] <- diff(c(-Inf,subset(xx,ED)$START_DATE));
    # TODO: time from previous inpatient encounter to ED or IP subsequent
    #       ...but not IP subsequent to ED
    # time from first visit
    return(xx);
  });

#' Now we need the time to first 30-day readmission (30 day followup from first
#' hospitalization for all patients who have been hospitalized)
#'
dat4hosp30r30f <- group_modify(dat3,function(xx,yy,window=30){
  # check whether patient has been hospitalized. If not, the following
  # omits them
  if(!any(xx$IP)) return(subset(mutate(xx,startage=0,tt=0,cc=F,deceased=F,efi=0
                                       ,dsc_efi='eFI==0'),F));
  # age at first IP encounter
  startage <- xx$enc_age[match(TRUE,xx$IP)];
  efi <- xx$NVAL_NUM[match(TRUE,xx$IP)];
  dsc_efi <- case_when(efi==0~'eFI==0'
                       ,between(efi,0,0.1)~'0 < eFI <= 0.1'
                       ,between(efi,0.1,0.2)~'0.1 < eFI <= 0.2'
                       ,TRUE~'eFI > 0.2');
  #if(startage == 12527) browser();
  # subsequent encounters within specified window
  followup <- subset(xx,between(enc_age,startage+1,startage+window));
  # if no subsequent encounter, take the index encounter and censor
  if(nrow(followup)==0) out <- mutate(subset(xx,enc_age==startage),IP=F) else {
    # if subsequent encounters, take first one (already marked as event)
    if(any(followup$IP)) out <- followup[match(TRUE,followup$IP),] else {
      # if there is a death date, take that encounter and censor
      if(with(followup,!is.na(DEATH_DATE) && any(DEATH_DATE==START_DATE))){
        out <- subset(followup,DEATH_DATE==START_DATE)} else {
          # if no death date and no IP encounters, take last encounter and censor
          out <- tail(followup,1)};
      };
    };
  out$startage <- startage;
  # 2. make tt variable based on that and START_DATE
  out$tt <- out$enc_age - startage;
  # 5. create cc variable
  out$cc <- out$IP;
  out$deceased <- !is.na(out$DEATH_DATE) && out$DEATH_DATE == out$START_DATE;
  out$efi <- efi;
  out$dsc_efi <- dsc_efi;
  #if(isTRUE(out$REIP=='Inf')) {cat('Inf\n'); browser()}
  #if(is.na(out$REIP)) {cat('NA\n');browser()}
  #if(is.na(out$REIP) && any(is.infinite(xx$REIP))) {cat('NA\n');browser()}
  #if(is.infinite(out$REIP)) {cat('Inf\n'); browser()}
  #if(is.infinite(out$REIP) && nrow(followup) > 0) browser();
  #if(is.na(out$REIP) && nrow(followup) ==0 ) browser()
  return(out);
});

cp30r30f <- coxph(Surv(tt,cc)~efi+startage,data=dat4hosp30r30f,subset=startage>0);
dat4hosp30r30f$lp30r30f <- predict(cp30r30f,type='lp');
dat4hosp30r30f$risk <- qcut(dat4hosp30r30f$lp30r30f,2);
levels(dat4hosp30r30f$risk) <- c('Low','High');
survfit(Surv(tt,cc)~risk,dat4hosp30r30f) %>%
  ggsurvplot(ylim=c(.9,1),conf.int=T,xlab='Days to First Readmission'
             ,ylab='Fraction of Patients Without Readmission');

#' Now the results are saved and available for use by other scriports if you
#' place `r sprintf("\x60'%s'\x60",.currentscript)` among the values in their
#' `.deps` variables.
save(file=paste0(.currentscript,'.rdata'),list=setdiff(ls(),.origfiles));
#' ### Finish
#+ echo=FALSE, results='hide'
c()
