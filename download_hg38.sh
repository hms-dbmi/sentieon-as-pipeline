#!/bin/bash
wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dict \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.amb \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.ann \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.bwt \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.pac \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.sa \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.fai \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.alt \
&& wget https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz \
&& wget https://storage.googleapis.com/genomics-public-data/references/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz.tbi \
&& wget https://storage.googleapis.com/genomics-public-data/references/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
&& wget https://storage.googleapis.com/genomics-public-data/references/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi \
&& wget https://storage.googleapis.com/genomics-public-data/references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf \
&& wget https://storage.googleapis.com/genomics-public-data/references/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf.idx 