# sentieon-as-pipeline
Run sentieon DNA analysis as O2 pipeline

### setup

[Download hg38 files](download_hg38.sh).

### running

set required variables and run as pipeline:

```
ref_dir=/somewhere/hg38
senteion_dir=/somewhere/sentieon
license=$senteion_dir/Harvard_Medical_School_DBMI_eval.lic
installed=$senteion_dir/sentieon-genomics-202010.01
out_dir=/somwhere/1234567
fq1=PID1234567_1.fq.gz
fq2=PID1234567_2.fq.gz

runAsPipeline "sentieon_pipeline.sh -r $ref_dir -1 $out_dir/$fq1 -2 $out_dir/$fq2 -o $out_dir -l $license -i $installed" "sbatch -p short -t 10:0 -n 1" useTmp run
```

### sbatch settings

added ~30-50% extra RAM and time (min 1 hr)

decided based on:
 - 20x WGS ~50GB fq.gz (x2)
 - hg38 with alt-contigs from Broad

### example timings

- map:     04:38
- metrics: 00:12
- dedup:   00:17
- recal:   01:38
- call:    01:41

total ~8hrs for 20x WGS