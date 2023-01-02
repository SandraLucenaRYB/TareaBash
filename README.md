# TareaBash

Authors: Ana Xin Corrales Angulo, Sandra Lucena Rybicka y Pablo Sousa Sánchez.

For contact, please send an email to anacorang@alum.us.es, sandraluce7@gmail.com and pabsousan@alum.us.es

In this work we created an automatized pipeline to avoid making mistakes while working with numerous samples. 

We used chipipe package for ChIP-seq data analysis, it is widely used for different organisms, in the test example Arabidopsis thaliana. This package is designed to be run under a Unix environment.

The package contains one main script called chipipe.sh which redirects to 3 other auxiliary scripts: sample_proc, peak_call and chipipe.R.  They will be described in this README. 
For the program to run correctly, it needs an extensive series of parameters for its executions, which have to be asigned in a single .txt file. That is why the path’s file must be rigorously indicated every time the script is run.

To execute the BASH command you need two arguments, the chiptube.sh file and the params file, e.g:
bash chiptube.sh params_chiptube.txt

The params file should contain the following parameters:

1. installation_directory:  the directory you have installed the package in; e.g. /home/bag3/packages
2. working_directory: the directory where you want to locate your analysis; e.g. /home/bag3/chip_analysis
3. experiment_name: the name you desire for the folders and the results of your analysis; e.g. prr5_test
4. number_replicas: the number of replicas you have for your chip-input samples; e.g. 2.
5. path_genome: the path required to access to the genome of the organism you are experiment with; /home/bag3/bag_psi/chip_analysis/genome.fa
6. path_annotation: the path to access the annotations for the organism’s genome your experimenting with; e.g. /home/bag3/bag_psi/chip_analysis/annotation.gtf
7. path_sample_chip_i: (with i being a natural number) the path needed to access the ChIP-seq data of the sample no.i you have processed; e.g. /home/bag3/bag_psi/chip_analysis/sample_chip_1.fq.gz. (If you have paired end files, you must write both paths in the same row, separated by space).
8. path_sample_input_i (with i being a natural number) the path where the input data relating to the sample no.i is located; e.g. /home/bag3/bag_psi/chip_analysis/sample_input_1.fq.gz. (If you have paired end files, you must write both paths in the same row, separated by space).
9. universe_chromosomes: the ID(s) of the chromosome(s) of your organism you want to use as your genetic universe for GO and KEGG terms enrichment. If using more than one, it needs to be separated by commas without spaces; e.g. 2,3. In case you want to use all the available chromosomes, write "all".
10. type_of_peak: this specifies the shape of the peaks you are looking for. For narrow peaks, the value must be 1 (for TF binding analysis) and 2 for broad peaks (used for histone modification).
11. single_or_paired:  When you have a single end read, it needs to be 1 in this parameter. For pair end reads, you must write 2.
12. tss_upstream:  the upstream number of bases for defining the TSS region.
13. tss_downstream:  the downstream number of bases for defining the TSS region. This number must be positive as it is later considered in the code; e.g. A TSS region analysis of 1000 bases upstream and downstream (-1000,1000) should be set by writing 1000 in both tss_upstream and tss_downstream parameters.

These parameters should be directed correctly in case you want to reproduce our work in your repository. 

Now, a detailed summary of the steps followed by each script will be described: 

chipipe.sh:
1. Load parameters
2. Workspace generation
3. Index creation as reference
4. Sample processing
5. Redirection to sample_proc auxiliary script

sample_proc:
1. Load parameters
2. Sample quality control (fastqc)
3. Mapping to reference genome (bowtie2)
4. Type file conversion and sorting from sam to bam (samtools)
5. Redirection to peak_call second auxiliary script
6. Starting peak calling (macs2)

peak_call:
1. Load parameters
2. Intersection of the results of the replicas (bedtools)
3. Motif search (HOMER)
4. Redirection to R script or data analysis and visualization

chipipe.R: 
1. Load parameters
2. Promoter region definition
3. Peak distribution along the genome calculation
4. Peak annotation depending on the DNA regions they bind to
5. Storage of peaks that bind to correct regions
6. Creation of a list containing the genes affected by the TF or histone modification (regulome creation)
7. Motif enrichment (GO and KEGG terms)

More information:

HOMER parameters can be changed according to the user’s preferences. For more information, check out HOMER's website: http://homer.ucsd.edu/homer/motif/ 

chipipe defines the regulome differently for narrow and broad peaks. It works different for narrow peaks, where it analyzes the genes in which TF binds the promoter, while for broad peaks, it uses genes in which the modification binds to other regions apart from the promoter, such as introns, exons and UTRs. This analysis however, can be customized in the R script.

If using chipipe package with other organisms that are not Arabidopsis thaliana, you must modify the txdb file and the GO and KEGG terms enrichment in the R script.

As for the output, chipipe creates a directory with the name established in the experiment_name parameter containing the following subdirectories and files:

genome: contains the reference genome used for the analysis and its index.
annotation: contains the reference annotation used for the analysis.
samples: contains one directory for each replica, which are then divided in three more subdirectories: chip, input and replica_results. The chip and input directories contain its corresponding sorted bam files and its fastqc quality analysis. The replica_results directory contains the peaks files generated by macs2 for the replica. It should be noted that if only one replica is used, the narrowPeak or broadPeak file is moved to the results file and cannot be found in this directory.
results: contains all the results for the analysis: 
  1. Merged peaks files of the replicas. 
  2. motifs detected by HOMER. 
  3. Rplots.pdf for the ChIp-seq analysis, containing covplot, plotAnnopie and plotDistToTSS. 
  4. regulome.txt file which contains the list of genes predicted to be affected by the TF binding or histone modification. 
  5. GO terms enrichment analysis represented in tables and plots in tsv format. 6. Another tsv file for GO terms  and KEGG pathway enrichment. Pathways are also shown   as a png file while the xml file is located in kegg_images directory. 
  If errors appear in one of the replicas (as indicated in the fastqc output or the bowtie2 alignment stats), just erase the proper merged files and use bedtools
  to intersect the previous merged file with the peak files of the rest of the replicas and execute the R script.
