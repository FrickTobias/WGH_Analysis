#!/bin/bash

#
# Initials
#

processors=1
mailing=false
remove=false

#
# Argument parsing
#

while getopts "m:hp" OPTION
do
    case ${OPTION} in

        p)
            processors=${OPTARG}
            ;;
        m)
            email=${OPTARG}
            mailing=true
            ;;
        h)
            echo ''
	    echo 'This script runs the trimming parts of the WGH pipeline. Input are two WGH read files and output is written to a directory containing four sets of compressed fastq files. The final files are the ".trimmed.fq" files.'
	    echo ""
	    echo 'Useage: bash WGH_read_processing.sh <r1.fq> <r2.fq> <output_dir>'
	    echo ''
	    echo "Positional arguments (required)"
	    echo "  <r1.fq>         Read one in .fastq format. Also handles gzip files (.fastq.gz)"
	    echo "  <mapped.bam>    Mapped bamfile which is to be tagged with clustering information"
	    echo "  <output_dir>    Output directory for clusterng files."
	    echo ""
	    echo "Optional arguments"
	    echo "  -h  help (this output)"
	    echo "  -m  mails the supplied email when analysis is finished"
	    echo "  -p  processors for threading, not implemented yet"
	    echo "  -r  removes files generated during analysis instead of just compressing them"
	    echo ''
	    exit 0
	    ;;
    esac
done

#
# Positonal redundancy for option useage
#

ARG1=${@:$OPTIND:1}
ARG2=${@:$OPTIND+1:1}
ARG3=${@:$OPTIND+2:1}

#
# Mailing option
#

if $mailing
then
    if [[ $email == *"@"* ]]
    then
        echo 'Mailing '$email' when finished.'
    else
        echo 'FORMAT ERROR: -m '
        echo ''
        echo 'Please supply email on format john.doe@domain.org'
        echo '(got "'$email'" instead)'
        exit 0
    fi
fi

#
# Error handling
#

if [ -z "$ARG1" ] || [ -z "$ARG2" ] || [ -z "$ARG3" ]
then
    echo ""
    echo "ARGUMENT ERROR"
    echo "Did not find all three positional arguments, see -h for more information."
    echo "(got r1:"$ARG1", mapped:"$ARG2" and output_dir:"$ARG3" instead)"
    echo ""
    exit 0
fi

#
# Fetching paths to external programs (from paths.txt)
#

# PATH to WGH_Analysis folder
wgh_path=$(dirname "$0")

# Loading PATH:s to software
#   - reference:            $bowtie2_reference
#   - Picard tools:         $picard_path
#   - fragScaff:            $fragScafff_path
. $wgh_path'/paths.txt'

r1_with_header=$ARG1
bam=$ARG2
output=$ARG3

#pigz -d $r1

#echo 'Starting bc extraction '$(date) | mail -s 'wgh' tobias.frick@scilifelab.se

python3 $wgh_path'/python scripts/cdhit_prep.py' $r1_with_header $output -r 3 -f 0

for file in $output/*.fa;
do
    cd-hit-454 -i $file -o $file'.clustered' -T 0 -c 0.9 -gap 100 -g 1 -n 3 -M 0;
done;

#pigz $r1

cat $output/*.clstr > $output/NNN.clstr

python3 $wgh_path'/python scripts/tag_bam.py' $bam $output/NNN.clstr $bam'.tag.bam'

rm $bam'.tag.bam.tmp.bam'

if $mailing
then
    echo 'Barcodes clustered and bamfile tagged '$(date) | mail -s $bam $email
fi