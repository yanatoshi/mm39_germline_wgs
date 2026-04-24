#!/bin/bash
#$ -cwd
#$ -q all.q@@calchosts
#$ -o /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
#$ -e /mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/log
set -euo pipefail
fc_id=E100024103
sample_name=${fc_id}_L01
workingdir=/mnt/scratch3/yanagiwasa/dry_yanagisawa/project/nicer/working_dir
combinefiles=${workingdir}/ms_germline_gatk_dir_combinefiles_${fc_id}
picard_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/picard_latest.sif
bcftools_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/bcftools_latest.sif
gatk_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/gatk_latest.sif
vep_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/vep.sif
ref_fasta=/mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/gatk/Mus_musculus.GRCm39.dna.primary_assembly.fa

chrnames=$(cat /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/hg38/split_chr/ms_chr_name.txt)
inputs=""

for chr in $chrnames; do
    inputs="${inputs} INPUT=${combinefiles}/${sample_name}_chr${chr}all.pass.vcf.gz"
done

singularity exec --nv -B /mnt:/mnt --userns ${picard_sif} \
java -jar /opt/picard/picard.jar MergeVcfs \
       ${inputs} \
       OUTPUT=${combinefiles}/${sample_name}_chrmergedall.pass.vcf.gz

singularity exec --nv -B /mnt:/mnt --userns ${bcftools_sif} \
bcftools view -f PASS ${combinefiles}/${sample_name}_chrmergedall.pass.vcf.gz -Oz -o ${combinefiles}/${sample_name}_chrmergedall.passfilterd.vcf.gz

singularity exec --nv -B /mnt:/mnt --userns ${gatk_sif} \
    gatk IndexFeatureFile \
        -I ${combinefiles}/${sample_name}_chrmergedall.passfilterd.vcf.gz

for sample in $(singularity exec --nv -B /mnt:/mnt --userns ${bcftools_sif} bcftools query -l ${combinefiles}/${sample_name}_chrmergedall.passfilterd.vcf.gz); do 

singularity exec --nv -B /mnt:/mnt --userns ${bcftools_sif} \
bcftools view -s "$sample" ${combinefiles}/${sample_name}_chrmergedall.passfilterd.vcf.gz -Ou | \
singularity exec --nv -B /mnt:/mnt --userns ${bcftools_sif} \
bcftools view -i 'GT="alt"' -Oz -o ${workingdir}/${sample}/germline_gatk_dir/${sample}_chrmergedall.passfilterd.vcf.gz

singularity exec --nv -B /mnt:/mnt --userns ${gatk_sif} \
    gatk IndexFeatureFile \
        -I ${workingdir}/${sample}/germline_gatk_dir/${sample}_chrmergedall.passfilterd.vcf.gz

singularity exec --nv -B /mnt:/mnt --userns ${vep_sif} \
vep \
        -i ${workingdir}/${sample}/germline_gatk_dir/${sample}_chrmergedall.passfilterd.vcf.gz \
        -o ${workingdir}/${sample}/germline_gatk_dir/${sample}_vep_annotated.txt \
        --stats_file ${workingdir}/${sample}/germline_gatk_dir/${sample}_variant_effect_output.txt_summary.html \
        --fasta ${ref_fasta} \
        --dir_cache /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/vep/cache \
        --dir_plugins /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/vep/plugins \
        --species mus_musculus \
        --assembly GRCm39 \
        --cache \
        --offline \
        --refseq \
        --use_given_ref \
        --format vcf \
        --force_overwrite \
        --variant_class \
        --regulatory \
        --individual ${sample} \
        --allele_number \
        --show_ref_allele \
        --uploaded_allele \
        --total_length \
        --hgvs \
        --hgvsg \
        --hgvsg_use_accession \
        --transcript_version \
        --gene_version \
        --protein \
        --canonical \
        --biotype \
        --domains \
        --xref_refseq \
        --exclude_predicted \
        --pick_allele \
        --sift b \
        --tab \
        --plugin NMD \
        --plugin Blosum62 \
        --plugin Downstream \
        --plugin SpliceRegion \
        --plugin TSSDistance,both_direction=1
        #--gene_phenotype \ 
        #--check_existing \ 
        #--pubmed \ 
        #--var_synonyms \ 
        #--symbol \
        #--plugin Paralogues \
done
