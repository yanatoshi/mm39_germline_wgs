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
sample_ids=$(cat /mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/hg38/sample_number/sample_number.txt)
chr=X
gatk_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/gatk_latest.sif
picard_sif=/mnt/scratch3/yanagiwasa/dry_yanagisawa/singularity/picard_latest.sif
ref_fasta=/mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/gatk/Mus_musculus.GRCm39.dna.primary_assembly.fa
ref_dict=/mnt/scratch3/yanagiwasa/dry_yanagisawa/reference/mm39/gatk/Mus_musculus.GRCm39.dna.primary_assembly.dict
vcf_inputs=""

for id in $sample_ids; do
    vcf_inputs="${vcf_inputs} -V ${workingdir}/${sample_name}_${id}/germline_gatk_dir/${sample_name}_${id}.chr${chr}.germline_output.g.vcf.gz"
done

singularity exec -B /mnt:/mnt --userns ${gatk_sif} \
gatk --java-options -Xmx16g \
        CombineGVCFs \
        -R ${ref_fasta} \
        ${vcf_inputs} \
        --sequence-dictionary ${ref_dict} \
        --tmp-dir ${combinefiles} \
        -L ${chr} \
        -O ${combinefiles}/${sample_name}_chr${chr}combined.g.vcf.gz

singularity exec -B /mnt:/mnt --userns ${gatk_sif} \
gatk --java-options -Xmx16g \
        GenotypeGVCFs \
        -R ${ref_fasta} \
        -V ${combinefiles}/${sample_name}_chr${chr}combined.g.vcf.gz \
        --sequence-dictionary ${ref_dict} \
        --tmp-dir ${combinefiles} \
        -L ${chr} \
        -O ${combinefiles}/${sample_name}_chr${chr}genotyped.vcf.gz

singularity exec -B /mnt:/mnt --userns ${gatk_sif} \
gatk --java-options -Xmx16g \
        SelectVariants \
        -R ${ref_fasta} \
        -V ${combinefiles}/${sample_name}_chr${chr}genotyped.vcf.gz \
        --select-type-to-include SNP \
        -O ${combinefiles}/${sample_name}_chr${chr}snv.raw.vcf.gz
singularity exec -B /mnt:/mnt --userns ${gatk_sif} \
gatk --java-options -Xmx16g \
        SelectVariants \
        -R ${ref_fasta} \
        -V ${combinefiles}/${sample_name}_chr${chr}genotyped.vcf.gz \
        --select-type-to-include INDEL \
        -O ${combinefiles}/${sample_name}_chr${chr}indel.raw.vcf.gz

singularity exec -B /mnt:/mnt --userns ${gatk_sif} \
gatk --java-options -Xmx16g \
        VariantFiltration \
        -R ${ref_fasta} \
        -V ${combinefiles}/${sample_name}_chr${chr}snv.raw.vcf.gz \
        -O ${combinefiles}/${sample_name}_chr${chr}snv.pass.vcf.gz \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "FS > 60.0" --filter-name "FS60" \
        -filter "MQ < 40.0" --filter-name "MQ40" \
        -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
        -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8"
singularity exec -B /mnt:/mnt --userns ${gatk_sif} \
gatk --java-options -Xmx16g \
        VariantFiltration  \
        -R ${ref_fasta} \
        -V ${combinefiles}/${sample_name}_chr${chr}indel.raw.vcf.gz \
        -O ${combinefiles}/${sample_name}_chr${chr}indel.pass.vcf.gz \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "FS > 200.0" --filter-name "FS200" \
        -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20"

singularity exec --nv -B /mnt:/mnt --userns ${picard_sif} \
java -jar /opt/picard/picard.jar MergeVcfs \
       INPUT=${combinefiles}/${sample_name}_chr${chr}snv.pass.vcf.gz \
       INPUT=${combinefiles}/${sample_name}_chr${chr}indel.pass.vcf.gz \
       OUTPUT=${combinefiles}/${sample_name}_chr${chr}all.pass.vcf.gz
