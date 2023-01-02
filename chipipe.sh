#!/bin/bash

if [ $# -ne 1 ]
then
	echo "Number of arguments is: $#"
	echo "Usage chipipe.sh <params.file>"
	exit
fi


PARAMS=$1


INSDIR=$(grep installation $PARAMS | awk '{print($2)}')
echo "Installation directory: $INSDIR"

WD=$(grep working $PARAMS | awk '{print($2)}')
echo "Working directory: $WD"

EXP=$(grep experiment $PARAMS | awk '{print($2)}')
echo "Experiment name: $EXP"

NUMREPLICAS=$(grep number_replicas $PARAMS | awk '{print($2)}')
echo "Number of replica: $NUMREPLICAS"

GENOME=$(grep genome $PARAMS | awk '{print($2)}')
echo "Genome path: $GENOME"

ANNOTATION=$(grep annotation $PARAMS | awk '{print($2)}')
echo "Genome path: $ANNOTATION"

CHR=$(grep chromosomes $PARAMS | awk '{print($2)}')
echo "Universe of chromosomes: $CHR"

PEAK=$(grep peak $PARAMS | awk '{print($2)}')
echo "Peak type: $PEAK"

SINGLE=$(grep single $PARAMS | awk '{print($2)}')
echo "Single or paired: $SINGLE"

TSSUP=$(grep upstream $PARAMS | awk '{print($2)}')
echo "TSS upstream region: $TSSUP"

TSSDOWN=$(grep downstream $PARAMS | awk '{print($2)}')
echo "TSS downstream region: $TSSDOWN"

# We perform an array to diferenciate the chip samples from the input.
CHIPS=()
INPUTS=()
i=0

if [ $SINGLE -eq 1 ]
then
	while [ $i -lt $NUMREPLICAS ]
	do
		j=$(($i + 1))
		CHIPS[$i]=$(grep path_sample_chip_$j $PARAMS | awk '{print($2)}')
		INPUTS[$i]=$(grep path_sample_input_$j $PARAMS | awk '{print($2)}')
		((i++))
	done

elif [ $SINGLE -eq 2 ]
then
	while [ $i -lt $NUMREPLICAS ]
	do
		j=$(($i + 1))
		k=$(($i * 2))
		l=$(($k + 1))
        	CHIPS[$k]=$(grep path_sample_chip_$j: $PARAMS | awk '{print($2)}')
        	CHIPS[$l]=$(grep path_sample_chip_$j: $PARAMS | awk '{print($3)}')
        	INPUTS[$k]=$(grep path_sample_input_$j: $PARAMS | awk '{print($2)}')
        	INPUTS[$l]=$(grep path_sample_input_$j: $PARAMS | awk '{print($3)}')
        	((i++))
	done
else
	echo "No allowed input for single/paired reads determination"
fi


echo "Samples ="
echo "${CHIPS[@]}"
echo "${INPUTS[@]}"


# Generating work space

echo "====================="
echo "GENERATING WORK SPACE"
echo "====================="

cd $WD
mkdir $EXP
cd $EXP
mkdir genome annotation results samples scripts

cp $GENOME genome/genome.fa
cp $ANNOTATION annotation/annotation.gtf
cd samples

if [ $SINGLE -eq 1 ]
then
	i=1
	while [ $i -le $NUMREPLICAS ]
	do
		mkdir replica_$i
		cd replica_$i
		mkdir chip input replica_results
		j=$(($i-1))
		cp ${CHIPS[$j]} chip/sample_chip_$i.fq.gz
		cp ${INPUTS[$j]} input/sample_input_$i.fq.gz
		cd ..
		((i++))
	done

elif [ $SINGLE -eq 2 ]
then
	i=1
	while [ $i -le $NUMREPLICAS ]
	do
  		mkdir replica_$i
  		cd replica_$i
      		mkdir chip input replica_results
      		cd chip
      		j=$(($i - 1))
      		k=$(($j * 2))
      		l=$(($k + 1))
      		cp ${CHIPS[$k]} sample_chip_${i}_1.fq.gz
      		cp ${CHIPS[$l]} sample_chip_${i}_2.fq.gz
      		cd ..
      		cd input
      		cp ${INPUTS[$k]} sample_input_${i}_1.fq.gz
      		cp ${INPUTS[$l]} sample_input_${i}_2.fq.gz
      		cd ../..
      		((i++))
  	done
else
  	echo "No allowed input for single/paired reads determination"
fi



echo "================="
echo "Step 1 completed:"
echo "Workplace created"
echo "================="


echo "=============="
echo "Creating index"
echo "=============="

cd ../genome

bowtie2-build genome.fa index
echo "Files size:" du -h *

echo "=========================="
echo "Starting sample processing"
echo "=========================="

cd ../results

i=1
while [ $i -le $NUMREPLICAS ]
do
	sbatch --job-name=proc_$i --output=out_$i --error=err_$i $INSDIR/sample_proc $WD $i $PEAK $NUMREPLICAS $INSDIR $EXP $CHR $TSSUP $TSSDOWN $GENOME
	((i++))
done
