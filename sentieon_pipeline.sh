#!/bin/sh
# *******************************************
# Script to perform DNA seq variant calling
# using a single sample with fastq files
# *******************************************

# ******************************************
# sbatch settings:
# added ~30-50% extra RAM and time (min 1 hr)
# decided based on:
#  - 20x WGS ~50GB fq.gz (x2)
#  - hg38 with alt-contigs from Broad
# ******************************************


while getopts r:1:2:o:l:i:s:g: flag
do
    case "${flag}" in
        r) ref_dir=${OPTARG};;
        1) fastq_1=${OPTARG};;
        2) fastq_2=${OPTARG};;
        o) data_dir=${OPTARG};;
        l) license=${OPTARG};;
        i) install_dir=${OPTARG};;
        s) sample=${OPTARG};;
        g) group=${OPTARG};;
    esac
done

platform="ILLUMINA" 

echo "ref_dir: $ref_dir";
echo "fastq_1: $fastq_1";
echo "fastq_2: $fastq_2";
echo "data_dir: $data_dir";
echo "license: $license";
echo "install_dir: $install_dir";
echo "sample: $sample";
echo "group: $group";
echo "platform: $platform";


# Update with the location of the reference data files
fasta=$ref_dir/Homo_sapiens_assembly38.fasta
known_1000G_indels=$ref_dir/Homo_sapiens_assembly38.known_indels.vcf.gz 
dbsnp=$ref_dir/Homo_sapiens_assembly38.dbsnp138.vcf
known_Mills_indels=$ref_dir/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

# Set SENTIEON_LICENSE if it is not set in the environment
# export SENTIEON_LICENSE=10.1.1.1:8990
# on O2: this will change to export SENTIEON_LICENSE=LICSRVR_HOST:LICSRVR_PORT
export SENTIEON_LICENSE=$license

# Update with the location of the Sentieon software package
# on O2: this path to change to Sentieon bin directory
SENTIEON_INSTALL_DIR=$install_dir

# Update with the location of temporary fast storage and uncomment
#SENTIEON_TMPDIR=/tmp

# It is important to assign meaningful names in actual cases.
# It is particularly important to assign different read group names.

# Other settings
nt=16 #number of threads to use in computation

# ******************************************
# 0. Setup
# ******************************************
workdir=$data_dir/result
mkdir -p $workdir
cd $workdir

#Sentieon proprietary compression
bam_option="--bam_compression 1"

# ******************************************
# 1. Mapping reads with BWA-MEM, sorting
# ******************************************
#The results of this call are dependent on the number of threads used. To have number of threads independent results, add chunk size option -K 10000000 

# speed up memory allocation malloc in bwa
export LD_PRELOAD=$SENTIEON_INSTALL_DIR/lib/libjemalloc.so
export MALLOC_CONF=lg_dirty_mult:-1

#@1,0,map,,sbatch -p short -c 10 -n 1 -t 0-11:59 --mem 30G
( $SENTIEON_INSTALL_DIR/bin/sentieon bwa mem -M -R "@RG\tID:$group\tSM:$sample\tPL:$platform" -t $nt -K 10000000 $fasta $fastq_1 $fastq_2 || echo -n 'error' ) | $SENTIEON_INSTALL_DIR/bin/sentieon util sort $bam_option -r $fasta -o sorted.bam -t $nt --sam2bam -i -

# ******************************************
# 2. Metrics
# ******************************************

#@2,1,metrics,,sbatch -p short -c 4 -n 1 -t 0-02:00 --mem 4G
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i sorted.bam --algo MeanQualityByCycle mq_metrics.txt --algo QualDistribution qd_metrics.txt --algo GCBias --summary gc_summary.txt gc_metrics.txt --algo AlignmentStat --adapter_seq '' aln_metrics.txt --algo InsertSizeMetricAlgo is_metrics.txt && \
$SENTIEON_INSTALL_DIR/bin/sentieon plot GCBias -o gc-report.pdf gc_metrics.txt && \
$SENTIEON_INSTALL_DIR/bin/sentieon plot QualDistribution -o qd-report.pdf qd_metrics.txt && \
$SENTIEON_INSTALL_DIR/bin/sentieon plot MeanQualityByCycle -o mq-report.pdf mq_metrics.txt && \
$SENTIEON_INSTALL_DIR/bin/sentieon plot InsertSizeMetricAlgo -o is-report.pdf is_metrics.txt

# ******************************************
# 3. Remove Duplicate Reads
# To mark duplicate reads only without removing them, remove "--rmdup" in the second command
# ******************************************
#@3,2,dedup,,sbatch -p short -c 6 -n 1 -t 0-04:00 --mem 4G
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i sorted.bam --algo LocusCollector --fun score_info score.txt && \
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i sorted.bam --algo Dedup --rmdup --score_info score.txt --metrics dedup_metrics.txt $bam_option deduped.bam 

# ******************************************
# 4. Indel realigner
# This step is optional for haplotyper-based
# caller like HC, but necessary for any
# pile-up based caller. If you want to use
# this step, you need to update the rest of
# the commands to use realigned.bam instead
# of deduped.bam
# ******************************************
#$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam --algo Realigner -k $known_Mills_indels -k $known_1000G_indels $bam_option realigned.bam

# ******************************************
# 5. Base recalibration
# ******************************************

# Perform recalibration (line 1)
# Perform post-calibration check (lines 2,3,4 - optional)
#@4,3,recal,,sbatch -p short -c 6 -n 1 -t 0-06:00 --mem 4G
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_indels recal_data.table && \
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam -q recal_data.table --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_indels recal_data.table.post && \
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt --algo QualCal --plot --before recal_data.table --after recal_data.table.post recal.csv && \
$SENTIEON_INSTALL_DIR/bin/sentieon plot QualCal -o recal_plots.pdf recal.csv

# ******************************************
# 5b. ReadWriter to output recalibrated bam
# This stage is optional as variant callers
# can perform the recalibration on the fly
# using the before recalibration bam plus
# the recalibration table
# ******************************************
#$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam -q recal_data.table --algo ReadWriter recaled.bam


# ******************************************
# 6. HC Variant caller
# Note: Sentieon default setting matches versions before GATK 3.7.
# Starting GATK v3.7, the default settings have been updated multiple times. 
# Below shows commands to match GATK v3.7 - 4.1
# Please change according to your desired behavior.
# ******************************************

# Matching GATK 3.7, 3.8, 4.0
#@5,4,call,,sbatch -p short -c 8 -n 1 -t 0-11:59 --mem 4G
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam -q recal_data.table --algo Haplotyper -d $dbsnp --emit_conf=10 --call_conf=10 output-hc.vcf.gz

# Matching GATK 4.1
#$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam -q recal_data.table --algo Haplotyper -d $dbsnp --genotype_model multinomial --emit_conf 30 --call_conf 30 output-hc.vcf.gz
