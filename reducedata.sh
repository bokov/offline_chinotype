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
