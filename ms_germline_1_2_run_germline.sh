#!/bin/bash
#$ -cwd
#$ -q all.q@gpu001.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu002.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu003.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu004.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu005.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu006.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu007.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu008.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu009.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu010.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu011.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu012.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu013.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu014.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu015.rare.genetics.riem.nagoya-u.ac.jp,all.q@gpu016.rare.genetics.riem.nagoya-u.ac.jp
#$ -t 68-69
#$ -o /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
#$ -e /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
set -euo pipefail
fc_id=E100024103
id=${fc_id}_L01_${SGE_TASK_ID}
workingdir=/mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/working_dir
germline_gatkdir=${workingdir}/${id}/germline_gatk_dir
parabricks_sif="/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/clara-parabricks_4.3.1-1.sif"
ref_fasta=/mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/gatk/Mus_musculus.GRCm39.dna.primary_assembly.fa

singularity exec --nv -B /mnt:/mnt --userns ${parabricks_sif} \
    pbrun germline \
    --ref ${ref_fasta} \
    --in-fq ${germline_gatkdir}/${id}_R1.fastq.gz ${germline_gatkdir}/${id}_R2.fastq.gz "@RG\tID:${id}\tPU:${id}\tSM:${id}\tPL:illumina\tLB:${id}" \
    --tmp-dir ${germline_gatkdir} \
    --num-cpu-threads-per-stage 16 \
    --bwa-cpu-thread-pool 16 \
    --gpusort \
    --gpuwrite \
    --keep-tmp \
    --knownSites /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/gatk/mgp_REL2021_snps.vcf.gz \
    --knownSites /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/gatk/mgp_REL2021_indels.vcf.gz \
    --gvcf \
    --out-duplicate-metrics ${germline_gatkdir}/${id}.germline_output_dup.bam.metrix.txt \
    --out-bam ${germline_gatkdir}/${id}.germline_output_dup.bam \
    --out-recal-file ${germline_gatkdir}/${id}.germline_recaltab.txt \
    --htvc-bam-output ${germline_gatkdir}/${id}.germline_htvc.bam \
    --out-variants ${germline_gatkdir}/${id}.germline_output.g.vcf.gz
