#!/usr/bin/env bash

# This script takes raw i2b2-style table dumps and strips them down to essentials

outdir=${1:-'test'};
indir=${2:-'local'};

[ ! -d "$outdir" ] && mkdir -p "$outdir";

echo "Creating $outdir/obs_pat_cd.tsv";
cut -f 2,3 "$indir/observation_fact.tsv" | (read -r; printf "%s\n" "$REPLY"; sort)  | uniq > "$outdir/obs_pat_cd.tsv";
echo "Creating $outdir/concept_path_cd.tsv";
cut -f 1,2 "$indir/concept_dimension.tsv" | (read -r; printf "%s\n" "$REPLY"; sort)  | uniq | grep -v "^\\[" |sed '/^\r$/d' > "$outdir/concept_path_cd.tsv";
echo "Creating $outdir/concept_cd_name.tsv";
cut -f 2,3 "$indir/concept_dimension.tsv" | (read -r; printf "%s\n" "$REPLY"; sort)  | uniq | grep -v "^\\[" |sed '/^\r$/d' > "$outdir/concept_cd_name.tsv";
echo "Creating $outdir/obsfact_efi_small.tsv";
cut -f 2,5,10 "$indir/obsfact_efi.tsv" > "$outdir/obsfact_efi_small.tsv";
echo "Creating $outdir/heron_terms_diag_meds.tsv";
sed -n "1p;/\\\i2b2\\\\\(Medication\|Epic Diagnosis\|Diagnosis\\)\\\/p" "$indir/heron_terms.tsv"|cut -f 1,3,4,5,6,7,13,14|grep -v Diagnosis > "$outdir/heron_terms_diag_meds.tsv";

# There are FURTHER steps before this stuff is usable by CODEHR...
for ii in $(ls $indir/offline_chi/efi*.tsv|head -n 4);do grep -v "^UHSOrd" $ii | grep -v $'^\r' | grep -v "^[[]" > $(basename $ii); done;
for ii in $(ls efi*.tsv); do head $ii -n 1 > cleaned/$ii; done
for ii in $(ls efi*.tsv); do tail $ii -n +2 | sort >> cleaned/$ii; done

echo "Creating the inpatient encounters in $outdir";
cut -f 2,3,5 $indir/observation_fact.tsv |head -n 1 > $outdir/obsfact_ip.tsv;
cut -f 2,3,5 $indir/observation_fact.tsv |grep "ENC.TYPE:IP" >> obsfact_ip.tsv;
echo "Creating the emergency encounters in $outdir";
cut -f 2,3,5 $indir/observation_fact.tsv |head -n 1 > $outdir/obsfact_ed.tsv;
cut -f 2,3,5 $indir/observation_fact.tsv |grep "ENC.TYPE:ED" >> $outdir/obsfact_ed.tsv;
cut -f 2,3,5 $indir/observation_fact.tsv |head -n 1 > $outdir/obsfact_disc.tsv;
cut -f 2,3,5 $indir/observation_fact.tsv |grep "DischargeStatus" >> $outdir/obsfact_disc.tsv;
