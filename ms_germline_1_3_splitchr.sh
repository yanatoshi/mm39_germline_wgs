#!/bin/bash
#$ -cwd
#$ -q all.q@@calchosts
#$ -t 68-69
#$ -o /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
#$ -e /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
set -euo pipefail
fc_id=E100024103
id=${fc_id}_L01_${SGE_TASK_ID}
bcftools_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/bcftools_latest.sif
gatk_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/gatk_latest.sif
workingdir=/mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/working_dir
germline_gatkdir=${workingdir}/${id}/germline_gatk_dir
chrname=$(cat /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/hg38/split_chr/chr_name.txt)

for chr in $chrname; do
singularity exec --nv -B /mnt:/mnt --userns ${bcftools_sif} \
 bcftools view -r chr${chr} ${germline_gatkdir}/${id}.germline_output.g.vcf.gz -Oz \
         -o ${germline_gatkdir}/${id}.chr${chr}.germline_output.g.vcf.gz

singularity exec --nv -B /mnt:/mnt --userns ${gatk_sif} \
    gatk IndexFeatureFile \
        -I ${germline_gatkdir}/${id}.chr${chr}.germline_output.g.vcf.gz
done
