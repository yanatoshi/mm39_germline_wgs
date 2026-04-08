#!/bin/bash
#$ -cwd
#$ -q all.q@@calchosts
#$ -t 68-69
#$ -o /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
#$ -e /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
set -euo pipefail
fc_id=E100024103
id=${fc_id}_L01_${SGE_TASK_ID}
fastq_dir=/mnt/scratch3/yanagiwasa/dry_yanagisawa/fastq/${fc_id}/L01
workingdir=/mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/working_dir
germline_gatkdir=${workingdir}/${id}/germline_gatk_dir
fastqc_sif=/mnt/scratch2/yanagisawa/dry_yanagisawa/singularity/fastqc_latest.sif
fastp_sif=/mnt/scratch2/yanagisawa/dry_yanagisawa/singularity/fastp_latest.sif
mkdir ${workingdir}/${id}
mkdir ${germline_gatkdir}

singularity exec --nv -B /mnt:/mnt --userns ${fastqc_sif} \
    fastqc -o ${germline_gatkdir} --noextract ${fastq_dir}/${id}_1.fq.gz

singularity exec --nv -B /mnt:/mnt --userns ${fastqc_sif} \
    fastqc -o ${germline_gatkdir} --noextract ${fastq_dir}/${id}_2.fq.gz

singularity exec --nv -B /mnt:/mnt --userns ${fastp_sif} \
fastp \
    -i ${fastq_dir}/${id}_1.fq.gz -I ${fastq_dir}/${id}_2.fq.gz \
    --detect_adapter_for_pe \
    -j ${germline_gatkdir}/${id}_fastp.json \
    -h ${germline_gatkdir}/${id}_fastp.html \
    -o ${germline_gatkdir}/${id}_R1.fastq.gz -O ${germline_gatkdir}/${id}_R2.fastq.gz
