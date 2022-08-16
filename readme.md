# Introduction
This pipeline detects and visualises phenotype-associated genome rearrangement events in bacterial genomes that are mediated by homologous recombination between repetitive elements (such as IS elements). 

# Installation
genome_rearrangement can be installed using the `git clone` command
```
git clone https://github.com/DorothyTamYiLing/genome_rearrangement.git
```
# Usage

## For detecting genome rearrangement in genomes
```
bash main.sh <kmers> <genomes> <phenotype> <output> <size of kmers> <flanking seqeunces minimum length> <size of IS elements>

```

Arguments:

**kmers** : multifasta file of significant phenotype-associated kmers from the GWAS output 

**genomes** : multifasta fie of genomes set (without IS replacement)

**phenotype** : phenotype file with path (file format: sample names in 1st column, binary phenotype in 2nd column; no header, tab-delimited) 

**output** : directory being created where the output files are generated 

**size of kmers** : length (bp) of significant kmers (all kmers have to be the output of one GWAS hence are of the same size) 

**flanking seqeunces minimum length** :  Minimum length (bp) of flanking sequences (both side) for the kmer to be blasted with the genomes; default: 30bp 

**size of IS elements** : size of the IS element that are replaced by shorter placeholder sequence (i.e. Maximum distance (bp) between the upstream and downstream flanks in the genome for a kmer to be defined as intact kmer)  

Example:

```
bash main.sh allsig_kmer_withN.fasta 111_yearGWAS_genlist.fasta.gz  path/to/your/phenotypes.tsv path/to/your/output 200 30 2500
```

## For plotting flanks of selected kmer (visualising genome rearrangements that are captured by selected kmer)
```
Rscript plot_flk_kmer_prop.R --kmer <kmer ID> --phen <phenotype> --coor <myflk_behave_pheno.txt> --genome.size <genome size> --outdir <output directory> --flk.dist <flanking seqeunces minimum length>

```

Arguments:

**kmer ID** : ID of chosen kmer for plotting IS-flanking sequences

**phenotype** : phenotype file with path (file format: sample names in 1st column, binary phenotype in 2nd column; no header, tab-delimited)

**myflk_behave_pheno.txt** : myflk_behave_pheno.txt file from the output of main.sh

**genome size** : size of the genome (in thousands)

**output directory** : directory path where the plot will be generated (need to be created from before)

**flanking seqeunces minimum length** : size of the IS element that are replaced by shorter placeholder sequence (i.e. Maximum distance (bp) between the upstream and downstream flanks in the genome for a kmer to be defined as intact kmer) (same as "size of IS elements" in main.sh)

Example:

```
Rscript plot_flk_kmer_prop.R --kmer kmer93 --phen path/to/your/phenotypes.tsv \
--coor path/to/your/myflk_behave_pheno.txt \
--genome.size 4000 --outdir path/to/your/output --flk.dist 2500
```
 
# Pre-requisite

## Replacement of IS elements in genome set

Before using this pipeline, the repetitive elements that are speculated to have mediated the rearrangement events, such as IS element, must be replaced by a short placeholder sequence (e.g. Nx15) in the genome set. This can be done using the script "iSreplace_2col.py" provided in this repository.
```
python3 iSreplace_2col.py --input <genome fasta> --coor <coordinates of IS> --out <path of output>
```
Arguments:

**genome fasta** : fasta file of the genome (single genome) for IS replacement, gzipped

**coordinates of IS** : genome coordinates of the IS element to be replaced (file format: start coordinate in 1st column, end coordinate in 2nd column; no header, tab-delimited)

**path of output** : output directory of the IS replaced genome, not gzipped since fsm-lite does not accept gzipped fasta

Example:
```
python3 iSreplace_2col.py --input path/to/your/J234_rename.fna.gz --coor path/to/your/J234_mergedIS.coor_2col.txt --out path/to/your/output/file
```

## Kmer-based GWAS

Then, a kmer-based GWAS is performed on the IS-replaced genome set (created as described above) searching for kmers that are associated with the phenotype of interested. K-mer based GWAS can be performed using pyseer. K-mers can be generated using fsm-lite. (See the tutorial section for detailed instructions)

From the output of pyseer, the kmers that are significantly associated with the phenotype and contain the short placeholder sequence are converted into a multi-fasta file, which is then used as one of the inputs of this pipeline (i.e. argument "kmers" of the main.sh script) for detecting potential genome rearrangement events that are associated with the phenotype of interest. (See the tutorial section for detailed instructions)
 
# Tutorial using examples input files from /example
 
This tutorial is based on a k-mer based GWAS using 111 American _Bordetella pertussis_ genomes as described in Weigand _et al_. 2019), with an aim of identifying genome rearrangement events that are associated with different year periods (between periods 2007-2010 and 2011-2013). 44 isolates are from year period 2007-2010 (phenotype 0) and 67 are from year period 2011-2013 (phenotype 1).

First, the gzipped multifasta file containing the 111 genomes being used in the GWAS (i.e. 111_yearGWAS_genlist.fasta.gz) is splitted into individual genome fasta.gz file, using the script "split_fastagz.py"
```
python3 split_fastagz.py -i 111_yearGWAS_genlist.fasta.gz
```

Then, the genome rearrangement-mediated IS elements of interest (i.e. IS481) in each of these genomes will be replaced by shorter placeholder sequences N x 15, using the script replaceIS.py. The script can be run for each genome using a loop.
```
for i in *.fasta.gz
do
myname=${i/.fasta.gz}
python3 iSreplace_2col.py --input ${i} --coor ${myname}_mergedIS.coor_2col.txt --out <path of output>
done
```
 
Generating kmers using fsm-lite
```
#generating input.list file
for f in /home/ubuntu/Dorothy/B.pertussis_573genomes_NCBI/Weigand_USA_genome/*.fna; do id=$(basename "$f" .fna); echo $id $f; done > 129_chromstrucGWAS_norepl_input.list

#running fsm-lite
fsm-lite -l ${mypath}/111_yearGWAS_ISrepl_input.list -v -t tmp -s 6 -S 105 -m 200 -M 200 | gzip - > ${mypath}/k200_maf0.05_output.txt.gz 
```

#Running fixed model kmer-based GWAS in pyseer
```
pyseer --phenotypes /home/ubuntu/Dorothy/USAgenomes_GWAS/111_yearGWAS/phenotypes.tsv \
--kmers /home/ubuntu/Dorothy/fsm-lite/USA_Weigand_170genomes/111_yearGWAS_ISrepl/k200_maf0.05_output.txt.gz \
--distances /home/ubuntu/Dorothy/USAgenomes_GWAS/111_yearGWAS/mash.tsv \
--print-samples \
--output-patterns kmer_patterns.txt \
--max-dimensions 8 --min-af 0.05 --max-af 0.95 > 111yearGWAS_ISrepl_fix

#mash.tsv is the distance matrix generating using mash as described in pyseer tutorial (can be found in /)
```

#calculate the significance threshold 
```
/home/ubuntu/Dorothy/pyseer-master/scripts/count_patterns.py kmer_patterns.txt > count_pattern.txt
```

#Finding how many significant kmers based on the Bonferroni significance threshold
```
awk '{ if ($4 <= 3.11E-04) { print } }' chromstruc_clus1clus2_GWAS_nopopctrl > sig_k.txt
```

#removing the kmer with warning flags 
```
sed '/bad-chisq\|high-bse/d' sig_k.txt > sig_k_pass.txt
```

#converting the significant kmers from pyseer output into multifasta file



Reference: Weigand, M.R., Williams, M.M., Peng, Y., Kania, D., Pawloski, L.C., Tondella, M.L. and CDC Pertussis Working Group, 2019. Genomic survey of Bordetella pertussis diversity, United States, 2000–2013. Emerging infectious diseases, 25(4), p.780.


 

# Pipeline and output files description

## Step1:

`filtering_kmer_and_blast.sh` (called by `main.sh`)

script functions:
1. filters sig. kmers for blasting by keeping only the kmers that contain flanking sequences (both side) of at least `$flnk_len` bp in size
2. blasts the filtered kmers with the genomes

output files: 
1. myout.txt (blast output file)
2. kmer_flanktooshort_4rm.txt (list of kmers that are removed due to having at least one flank being too short, i.e. <`$flnk_len`)
3. kmer_flanktooshort_flkcoor.txt (flank start and end coordinates of the kmers being removed)
4. kmer_forblast.fasta (multifasta file of kmer that have passed the filter and for blasting with genomes)



`extract_flank_coor.py` (called by `filtering_kmer_and_blast.sh`)

script functions:
1. gets the flank start and end coordinates of the sig. kmers

output files: 
1. flank_coor.txt; format: `kmerX_{end coordinate of the upstream flank}_{start coordinate of the downstream flank}_kmer size`


## Step2:

`make_flank_summary.R` (called by `main.sh`)

script functions:
1. filtering kmers based on blast hit information. Kmer passing the filter should have blast hits that fulfill the following criteria:

Criteria 1: both flanks should be found in all genomes (there should be 2 blast hits per kmer, one for each flank)

Criteria 2: Both flanks should be fully aligned with the genomes (the flank start and end coordinates in the blast hit should be consistent 
with those in flank_coor.txt)

Criteria 3: there should be no SNPs nor gaps (the values in the "mismatch" and "gap" columns should be 0 for all blast hit)

Criteria 4: Each flank should only show one unique blast hit per genome

2. for those kmers that have passed the filter, determine:

-`StartL` (genomic coordinate of the start of upstream flank)

-`EndL` (genomic coordinate of the end of upstream flank)

-`StartR` (genomic coordinate of the start of downstream flank)

-`EndR` (genomic coordinate of the end of downstream flank)

3. for those kmers that have passed the filter, determine their flank behaviours in each genome (behaviours could be 
`intact_k` (intact kmer), `mv_away` (flanks move away from each other), `swp_flk` (flanks swap in position),`mv&flp` (one flank has 
move away and flipped) according to the following rules:

To be defined as "intact kmer":

```
(StartL < EndL) & (EndL < StartR) & (StartR < EndR) & ((StartR-EndL) < flkdist)

(EndR < StartR) & (StartR < EndL) & (EndL < StartL) & ((EndL-StartR) < flkdist)
```

To be defined as "mv_away":
```

(StartL < EndL) & (EndL < StartR) & (StartR < EndR) & ((StartR-EndL) > flkdist)

(StartL > EndL) & (EndL > StartR) & (StartR > EndR) & ((EndL-StartR) > flkdist)
```

To be defined as "swp_flk":
```

(StartR < EndR) & (EndR < StartL) & (StartL < EndL)

(EndL < StartL) & (StartL < EndR) & (EndR < StartR)
```

To be defined as "mv&flp":
```

(StartL < EndL) & (EndL < EndR) & (EndR < StartR)

(EndL < StartL) & (StartL < StartR) & (StartR < EndR)

(StartR < EndR) & (EndR < EndL) & (EndL < StartL)

(EndR < StartR) & (StartR < StartL) & (StartL < EndL)
```

Flank behaviours are defined as `undefined_behave` when none of the rules above are fulfilled for that kmer.


4. for each kmer (across all genomes), count the number (and proportion) of case/control genome that in which each type of flank behaviour is found, determine the flank behaviour that is associated with case genomes and control genome respectively, include information of where in the genome  the flank behaviour take place (in form of summary statistics of genome coordinates. Finally, the most possible genome rearrangement event as indicated by each kmer is determined by the following rules:

- Define as `translocation` when case genomes/contrl genomes associated flank behaviour include `mv_away` or `swp_flk`.

- Define as `inversion` when case genomes/contrl genomes associated flank behaviour include `mv&flp`.


output files: 
1. rows_for_process.txt (blast hit of kemrs that pass the filter)
 
2. kmer_with_deletion.txt (blast hit of kmers that do not fulfill criteria 1) <sup> 1 </sup>

3. kmer_with_alignlen_issue.txt (blast hit of kmers that do not fulfill criteria 2) <sup> 1 </sup>

4. kmer_with_SNPgap.txt (blast hit of kmers that do not fulfill criteria 3) <sup> 1 </sup> 
 
5. kmer_with_multi_hits.txt (blast hit of kmers that do not fulfill criteria 4) <sup> 1 </sup>

6. myundefine_k.txt (blast hit of kmers with undefined behaviour in at least one genome) <sup> 1 </sup>

7. myflk_behave_pheno.txt (kmers with `StartL`,`EndL`,`StartR`,`EndR` and flank behaviour in each genome defined, and merged with phenotype information)

8. myall_out.txt, include the following information in columns:

**kmer**: kmer ID

**event_sum**: list of flank behaviours obserevd across genomes for this kmer, seperated by ":"

**flk_behaviour**: count and proportion of case and control genomes for each behaviour; format: `count of case genomes with behaviour/total number of case genomes (proportion): count of control genomes with behaviour/total number of control genomes (proportion)`

**case_assos**: behaviour associated with case genomes

**case_assos_prop**: proportion of case genomes with this behaviour

**ctrl_assos**: behaviour associated with control genomes

**ctrl_assos_prop**: proportion of control genomes with this behaviour

**case_assos_gp_Lflk_sumstat**: for the flank behaviours that is associated with case genomes, the summary statistics <sup> 2 </sup>  of the genome positions of the upstream flanks

**case_assos_gp_Rflk_sumstat**: for the flank behaviours that is associated with case genomes, the summary statistics <sup> 2 </sup>  of the genome positions of the downstream flanks

**ctrl_assos_gp_Lflk_sumstat**: for the flank behaviours that is associated with control genomes, the summary statistics <sup> 2 </sup> of the genome positions of the upstream flanks

**ctrl_assos_gp_Rflk_sumstat**: for the flank behaviours that is associated with control genomes, the summary statistics <sup> 2 </sup>  of the genome positions of the downstream flanks

**case_assos_gp_flkdis_sumstat**: for the flank behaviours that is associated with case genomes, the summary statistics <sup> 2 </sup>  of the distance between the upstream and downstream flanks

**ctrl_assos_gp_flkdis_sumstat**: for the flank behaviours that is associated with control genomes, the summary statistics <sup> 2 </sup>  of the distance between the upstream and downstream flanks

**event**: genome rearrangemnet event

<sup> 1 </sup> files are not produced when there is no content

<sup> 2 </sup>  summary statistics format: `minimum, 1st quantile, median, mean, 3rd quantile, maximum, standard deviation`

## Step3:
`plot_flk_kmer_prop.R`

script functions: 
For specific kmer, visualise the rearrangement event by plotting where the flanks are found in each genome
output file: 
1. kmerX_plot.pdf 
2. case_upstreamflk.txt (information <sup> 3 </sup> for plotting case upstream flank arrows in plot)
3. case_downstreamflk.txt (information <sup> 3 </sup> for plotting case downstream flank arrows in plot)
4. case_intactk.txt (information <sup> 3 </sup> for plotting case intactk arrows in plot)
5. ctrl_upstreamflk.txt (information <sup> 3 </sup> for plotting control upstream flank arrows in plot)
6. ctrl_downstreamflk.txt (information <sup> 3 </sup> for plotting control downstream flank arrows in plot)
7. ctrl_intactk.txt (information <sup> 3 </sup> for plotting control intactk arrows in plot)

<sup> 3 </sup> information includes median start and end coordinates, count and proportion of genomes
