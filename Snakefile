# kate: syntax Python;
rule trim_r1_handle:
    "Trim away E handle on R1 5'. Also removes reads shorter than 85 bp."
    output:
        r1_fastq="{dir}/trimmed-a.1.fastq.gz",
        r2_fastq="{dir}/trimmed-a.2.fastq.gz"
    input:
        r1_fastq="{dir}/reads.1.fastq.gz",
        r2_fastq="{dir}/reads.2.fastq.gz"
    log: "{dir}/trimmed-a.log"
    threads: 20
    shell:
        "cutadapt"
        " -g ^CAGTTGATCATCAGCAGGTAATCTGG"
        " -e 0.2"
        " --discard-untrimmed"
        " -j {threads}"
        " -m 65"
        " -o {output.r1_fastq}"
        " -p {output.r2_fastq}"
        " {input.r1_fastq}"
        " {input.r2_fastq}"
        " > {log}"


rule extract_barcodes:
    output:
        r1_fastq=temp("{dir}/unbarcoded.1.fastq"),
        r2_fastq=temp("{dir}/unbarcoded.2.fastq")
    input:
        r1_fastq="{dir}/trimmed-a.1.fastq.gz",
        r2_fastq="{dir}/trimmed-a.2.fastq.gz"
    log: "{dir}/extractbarcode.log"
    shell:
        # BDHVBDVHBDVHBDVH
        "blr extractbarcode"
        " {input.r1_fastq} {input.r2_fastq}"
        " {output.r1_fastq} {output.r2_fastq}"
        " 2> {log}"


rule compress:
    output: "{dir}/unbarcoded.{nr}.fastq.gz"
    input: "{dir}/unbarcoded.{nr}.fastq"
    shell:
        "pigz < {input} > {output}"

rule:
    """Cut TES from 5' of R1. TES=AGATGTGTATAAGAGACAG. Discard untrimmed."""
    output:
        r1_fastq=temp("{dir}/trimmed-b.1.fastq.gz"),
        r2_fastq=temp("{dir}/trimmed-b.2.fastq.gz")
    input:
        r1_fastq="{dir}/unbarcoded.1.fastq.gz",
        r2_fastq="{dir}/unbarcoded.2.fastq.gz"
    log: "{dir}/trimmed-b.log"
    threads: 20
    shell:
        "cutadapt"
        " -g AGATGTGTATAAGAGACAG"
        " -e 0.2"
        " --discard-untrimmed"
        " -j {threads}"
        " -o {output.r1_fastq}"
        " -p {output.r2_fastq}"
        " {input.r1_fastq}"
        " {input.r2_fastq}"
        " > {log}"


rule:
    "Cut TES' from 3' for R1 and R2. TES'=CTGTCTCTTATACACATCT"
    output:
        r1_fastq="{dir}/trimmed-c.1.fastq.gz",
        r2_fastq="{dir}/trimmed-c.2.fastq.gz"
    input:
        r1_fastq="{dir}/trimmed-b.1.fastq.gz",
        r2_fastq="{dir}/trimmed-b.2.fastq.gz"
    log: "{dir}/trimmed-c.log"
    threads: 20
    shell:
        "cutadapt"
        " -a CTGTCTCTTATACACATCT -A CTGTCTCTTATACACATCT"
        " -j {threads}"
        " -m 25"
        " -e 0.2"
        " -o {output.r1_fastq}"
        " -p {output.r2_fastq}"
        " {input.r1_fastq}"
        " {input.r2_fastq}"
        " > {log}"
