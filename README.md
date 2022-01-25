
## Introduction 

In the analysis of high-throughput big genomic sequencing data, it is required to write custom scripts to form the glue between tools or to perform specific analysis tasks. All Squeegeeing data are big size in nature, handling and pre/processing these data required high computing processing power. Generally, most of the tasks are carried out in the computer cluster. Various processing steps are required in order to get the final matrix form of the data for further downstream analysis. The easiest way to install this software is via [Bioconda](https://bioconda.github.io/).

The sequence analysis pipeline involves the below steps.

1. Quality assessment of sequencing data
2. Mapping reads onto a reference genome
3. Quantification and normalization
4. Downstream analysis (Statistic and Machine learning approach)
5. Report and Visualization

Multiple scripting languages are required for complete the genomics sequence analysis, for bioinformatic/sequence analysis Bash and R/biconductor language is reported here and Matlab for mathematical modeling.


## Quality assement of sequencing data 

Most sequencer machines generate a QC report as a part of their analysis pipeline, however, the focal point of the problems generated by the sequencer itself. Different bioinformatics tool aims to provide the information or spot the problem which originates either in the sequencer or in the starting experimental library material. A widely used tool is FastQC. It is performed by a series module and generates an HTML output evaluating pass/ fail results. The different analysis modules namely Basic Statistics, Per Base Sequence Quality, Per Sequence Quality Scores, Per Base Sequence Content, Per Base GC Content, Per Sequence GC Content, Per Base N Content, Sequence Length Distribution, Duplicate Sequences, Overrepresented Sequences, Overrepresented Kmers. Command-line can be used as (fastqc .fastq.gz*) for generating reports. More details of the module can be found [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).


#### Adapter Remove 

Illumina adapter and other technical sequences are performed by TruSeq2 and TruSeq3 (as used by HiSeq and MiSeq machines)
for both single-end and paired-end modes. Depending on specific issues which may occur in library preparation, other sequences may work better for a given data set. Therefore, generating some quality metrics for raw sequence data is necessary. Different tool used widely such as  [Cutadapt](https://cutadapt.readthedocs.io/), [Trimmomatic](https://github.com/usadellab/Trimmomatic), [Flexbar](https://github.com/seqan/flexbar). Below bash script for Flexbar for trimming raw data. 

````
#!/bin/bash
#PBS -N trim_data
##PBS -j oe
#PBS -m e
#PBS-l mem=100G
#PBS -l walltime=50:13:59
#PBS -l nodes=1:ppn=8   
#PBS -e ./trim_data_$PBS_JOBID.err       
#PBS -o ./trim_data_$PBS_JOBID.out
#PBS -V
#echo $PBS_JOBNAME
#echo $PBS_JOBID
name=$1
data=~/raw_data
trim_data=~/raw_data
flexbar -r ${data}/${name}_1.fq -p ${data}/${name}_2.fq -t ${trim_data}/$(name) - 10 -z BZ2 -m 30 -u 0 -q 28 -a ${data}/Adapter.fa -f sanger

````

## Mapping reads onto a reference genome 

The initial process of sequencing analysis is (Alignment) which involved mapping the reads to the reference genome. This gives the precise location in the genome of each base pair in each sequencing read comes from. Further, mapped reads can be used to identify genetic variation and the genotypes of individuals at different locations in the genome (Variant calling ->Variant Annotation ->Visualization) using [bcftools](https://samtools.github.io/bcftools/bcftools.html), [VEP](https://www.ensembl.org/info/docs/tools/vep/index.htm),[IGV] (https://software.broadinstitute.org/software/igv/). This pipeline is typically used in whole-genome sequence analysis. Additionally, if the data are chip-sequencing the mapped read is used to identify the read distribution profile (Peak calling -> Peak annotation ->Peak visualization).
Different tools are used for the analysis such as [MACS2](https://samtools.github.io/bcftools/), [HOMER](http://homer.ucsd.edu/homer/ngs/peaks.html), [Bedtools](https://bedtools.readthedocs.io/en/latest/), [samtools](http://samtools.sourceforge.net/), [bamtools](https://github.com/pezmaster31/bamtools).
For RNA sequencing, mapped reads are further quantified as counted per gene. Gene-level count datasets for downstream analysis such as exploratory data analysis (EDA) for quality assessment and to explore the relationship between samples, differential gene expression analysis, and visualization of the results. Various software tools are used for alignment to reference the genome. Few names are outlined here, [hisat2](http://ccb.jhu.edu/software/hisat2/), [BWA](http://bio-bwa.sourceforge.net/bwa.shtml), [Bowtie](http://bowtie-bio.sourceforge.net/index.shtml), [subread](http://subread.sourceforge.net/), [STAR](https://github.com/alexdobin/STAR). Below script used for STAR alignment, the upper part of the script is used for indexing the reference genome, later part of the script is used for mapping the raw data. 

#### Align to Reference Genome

```
#!/bin/bash
#PBS -N Star_alignment
##PBS -j oe
#PBS -m e
#PBS-l mem=100G
#PBS -l walltime=50:13:59
#PBS -l nodes=1:ppn=8   
#PBS -e ./Star_alignment_$PBS_JOBID.err       
#PBS -o ./Star_alignment_$PBS_JOBID.out
#PBS -V
#echo $PBS_JOBNAME
#echo $PBS_JOBID
name=$1
ref_genome=~/genome_fold
data=~/raw_data
out=~/alignment
# Script to generate the genome index
STAR --runThreadN 8 \
--runMode genomeGenerate \
--genomeDir ${ref_genome} \
--genomeFastaFiles ${ref_genome} reference.fa \
--sjdbGTFfile ${ref_genome} reference.gtf \
--genomeSAindexNbases 6
--sjdbOverhang 99
# After genome indices generated,read alignment can be perfomed
STAR --runThreadN 8 --genomeDir ${ref_genome} --sjdbGTFfile ${ref_genome}/reference.gtf \
--readFilesCommand zcat \
--readFilesIn ${data}/${name}_1.fastq.gz ${data}/${name}_2.fastq.gz \
--outSAMtype BAM SortedByCoordinate \
--outSAMunmapped Within \
--outSAMattributes Standard 
--outFileNamePrefix ${out}/${name} \
--quantMode ${name}_GeneCounts

```

## Quantification and normalization

Alignments mapped read is counted using [Cufflinks](http://cole-trapnell-lab.github.io/cufflinks/), [eXpress](https://pachterlab.github.io/eXpress/overview.html), [HTSeq](https://htseq.readthedocs.io/en) using both the Intersection-Strict and the Union approaches, [RSEM](https://github.com/deweylab/RSEM), [featureCounts](http://subread.sourceforge.net/featureCounts.html) and [Stringtie](https://ccb.jhu.edu/software/stringtie/). There are some methods do not consider the classical alignment process and carry out alignment, counting and normalization in one single step such as [Kallisto](https://pachterlab.github.io/kallisto/), [Sailfish](https://www.cs.cmu.edu/~ckingsf/software/sailfish/), [Salmon](https://combine-lab.github.io/salmon/getting_started/)
Further, gene expression values are represented using the normalization techniques provided by each algorithm in R/Bioconductor: Transcripts per Million (TPM), Fragments per Kilobase of Mapped reads (FPKM), Trimmed Mean of M values (TMM from edgeR), Relative Log Expression (RLE from DESeq2). 

```
#!/bin/bash
#PBS -N htseq
##PBS -j oe
#PBS -m e
##PBS -l file=100GB
#PBS-l mem=100G
#PBS -l walltime=50:13:59
#PBS -l nodes=1:ppn=8   
#PBS -e ./htseq_$PBS_JOBID.err           # stderr file
#PBS -o ./htseq_$PBS_JOBID.out
#PBS -V
#echo $PBS_JOBNAME
#echo $PBS_JOBID
name=$1
gtf=~/genome
out=~/alignment
data=~/count
htseq-count -f bam \
-r pos \
--type=exon --idattr=gene_id \
--stranded=reverse \
--mode=intersection-nonempty \
${input}/${name}_accepted_hits.bam \
${gtf}/Reference.gtf >${output}/${name}.htseq_count.txt
```

## Down stream analysis (Statistic and Machine learning approach)

A primary objective of many gene expression experiments is to detect transcripts showing differential expression across various conditions.
Downstream analyses with RNA-Seq data include testing for differential expression between samples condition, cluster analysis of selected genes and samples, detecting condition gene-specific expression, GO, signaling pathway analysis (functional enrichment analysis and Network Construction), Dimensional reduction approach for data visualization, identifying novel genes and exons and novel splice junctions, ability to detect gene fusion events.
The below code demonstrates some of the key aspects of RNA sequence downstream analysis.

```
##############################################################################
Load require Library,or installed.packages('name of the pkg')
#############################################################################

library(DESeq2)
library(biomaRt)
library(gage)
library(gageData)
library(org.Mm.eg.db)
library(reshape2)
library(dplyr)

###############################################################################
Load the meta file, meta file contain tab separated sample infomration 
################################################################################

setwd("~/Desktop/Data")
meta<-read.delim("meta_data.txt",header=T,sep="\t")
meta<-read.delim("meta.txt",header = T,sep="\t")
sampleTable <- data.frame(sampleName = meta$sampleNames, fileName = meta$sampleFiles, condition = meta$sampleCondition)
DESeq2Table <- DESeqDataSetFromHTSeqCount(sampleTable = sampleTable,directory = ".",design = ~ condition)


####################################################################################
Data visulation by PCA plot
####################################################################################

DESeq2::plotPCA(vsd, intgroup=c("condition"),ntop=1000)
dev.copy2pdf(file='PCA_plot.pdf')
ddsHTSeq <- DESeq(DESeq2Table)
##Comparison conditions between two sample group  
res <- results(ddsHTSeq, contrast=c("condition", "Sample1", "Sample2"))
##Select significant Diffrential regulated gene
resSig <- subset(res, padj < 0.01)

########################################################################################################################
Annotate Ensembl id to gene symbol,gene biotype and entrezgene by biomart here mouse name taken as an example"
########################################################################################################################

resSig$ensembl <- sapply(strsplit(rownames(resSig), split="\\+" ), "[", 1 )
ensembl = useMart( "ensembl", dataset = "mmusculus_gene_ensembl")
genemap <- getBM( attributes = c("ensembl_gene_id","mgi_symbol","entrezgene","gene_biotype"),filters = "ensembl_gene_id",values = resSig$ensembl,mart = ensembl)
idx <- match(resSig$ensembl, genemap$ensembl_gene_id)
resSig$name <- genemap$mgi_symbol[idx]
resSig$gene <- genemap$entrezgene[idx]
resSig$gene_biotype <- genemap$gene_biotype[idx]
resSig$symbol <- genemap$name_1006[idx]

############################################################################################
Remove noncoding genes from the data
###############################################################################################

idx<-grep("protein_coding", resSig$gene_biotype, fixed = TRUE)
resSig<-resSig[idx,]
resOrdered <- resSig[order(-resSig$log2FoldChange ),]
write.xlsx(data.frame(resOrdered), "DEG_list.xlsx",asTable = TRUE,row.names=T)

#########################################################################################################
GO pathways analysis using GAGE Here all gene expression used unlike only DE gene, here data normalized 
########################################################################################################

GeneCounts <- counts(DESeq2Table)
cnts<-GeneCounts
sel.rn=rowSums(cnts) != 0
cnts=cnts[sel.rn,]
dim(cnts)
libsizes=colSums(cnts)
size.factor=libsizes/exp(mean(log(libsizes)))#cnts.norm=t(t(cnts)/size.factor)
range(cnts.norm)
cnts.norm=log2(cnts.norm+1)
range(cnts.norm)

#####################################################################################################################################
Make a GO term list from "org.Mm.eg.db" a mouse annotation package from bioconductor but you can also download "Misgdatabase"
or any other sourcse of the data base can be useed such as KEGG, reactome, consesuspathDB etc.
#######################################################################################################################################

mygo <- as.list(org.Mm.egGO2EG)
mygo <- (mygo[!is.na(mygo)])
t <- mget(names(mygo),GOTERM)
names(mygo) <- as.character(lapply(t,Term))

########################################################################################################################
Obtain Significance pathways using gage, gage uses t-test between two condition and listed up and down Go/pathway
#########################################################################################################################
gos <- gage(mymat,gsets = mygo,ref=ref,samp=samp,compare ="paired")
gene_set<-sigGeneSet(gos,cutoff=0.001)
up<-(gene_set$greater)
write.csv(up,file="go_upregulated.csv")
down<-(gene_set$less)
write.csv(down,file="go_downregulated.csv")

########################################################################################################################
only with differentially regulated gene based on fold change 
########################################################################################################################
foldchanges = resSig$log2FoldChange
names(foldchanges) = resSig$ensembl
keggres = gage(foldchanges, gsets=mygo, same.dir=TRUE)
lapply(keggres, head)

```

## Single cell sequencing analysis pipeline

Single-cell transcriptomics determines the gene expression level of individual cells by simultaneously measuring the messenger RNA (mRNA) concentration of hundreds to thousands of genes. It allows the studying of new biological questions in which cell-specific changes in transcriptome are important, e.g. heterogeneity of cell responses, cell type identification, inference of gene regulatory networks across the cells. There are also commercial platforms available for single-cell sequencing, 10X Genomics chromium platform widely used in the present day.
Most computational analysis methods from bulk RNA-seq can be used for the analysis of single-cell sequencing. In most cases, computational analysis requires adaptation of the existing methods or the development of new ones.
Here, analysis code is demonstrated for the 10x genomics chromium platform. The analysis pipeline typically starts as bulk RNA.  
[Cell Ranger](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/tutorial_in) software used for the single-cell pre-processing analysis. It integrates several tools and reported the count matrix as an output. 

##### Alignemnt and gene count

```
#!/bin/bash
#PBS -N cell_ranger
#PBS -j oe 
##PBS -l file=32GB
#PBS-l mem=100G
#PBS -l walltime=50:13:59
#PBS -l nodes=1:ppn=8	
#PBS -o ./cell_ranger_$PBS_JOBID.out
#PBS -e ./cell_ranger_$PBS_JOBID.err
echo $PBS_JOBID
echo $PBS_JOBNAME
cd $PBS_O_WORKDIR

#echo "=========================================================="
#echo "Starting on : $(date)"
#echo "Running on node : $(hostname)"
#echo "Current directory : $(pwd)"
#echo "Current job ID : $JOB_ID"
#echo "Current job name : $JOB_NAME"
#echo "Task index number : $SGE_TASK_ID"
#echo "=========================================================="

genome=~/genome/Ref_genome
data=~/single_cell/fastqs
name=$1

##### Downlaod the Refernce genome from ensembl(example mouse) and fileter all gene only keep protein biotype before mapping the sequnce data
wget ftp://ftp.ensembl.org/pub/release-93/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz
gunzip Mus_musculus.GRCm38.dna.primary_assembly.fa.gz

wget ftp://ftp.ensembl.org/pub/release-93/gtf/mus_musculus/Mus_musculus.GRCm38.93.gtf.gz
gunzip Mus_musculus.GRCm38.93.gtf.gz

gn=~/genome/10x_genome
cellranger mkgtf ${gn}/Refernce.gtf Reference.filtered.gtf \
--attribute=gene_biotype:protein_coding \
--attribute=gene_biotype:lincRNA \
--attribute=gene_biotype:antisense \
--attribute=gene_biotype:IG_LV_gene \
--attribute=gene_biotype:IG_V_gene \
--attribute=gene_biotype:IG_V_pseudogene \
--attribute=gene_biotype:IG_D_gene \
--attribute=gene_biotype:IG_J_gene \
--attribute=gene_biotype:IG_J_pseudogene \
--attribute=gene_biotype:IG_C_gene \
--attribute=gene_biotype:IG_C_pseudogene \
--attribute=gene_biotype:TR_V_gene \
--attribute=gene_biotype:TR_V_pseudogene \
--attribute=gene_biotype:TR_D_gene \
--attribute=gene_biotype:TR_J_gene \
--attribute=gene_biotype:TR_J_pseudogene \
--attribute=gene_biotype:TR_C_gene

#########Genome indexing 
cellranger mkref --genome=mm10 \
--fasta=${gn}/Refernce.fa \
--genes=${gn}/Refernce.gtf \
--ref-version=3.0.0

################# Gene count  
cellranger count --chemistry=SC3Pv3 \
--id=${name}-REX --project=P180721 \
--transcriptome=${gn} \
--fastqs=${data} \
--sample=${name} \
--localcores=7 \
--expect-cells=500
--localmem=128

##############
library(Seurat)
library(dplyr)
library(Matrix)
library(cowplot)
library(patchwork)
library(RaceID)
library(openxlsx)
###################################################################
Load data in to R
####################################################################
BM <- CreateSeuratObject(counts =BM_data, project = "BoneMetastasis", min.cells =3,min.features = 200)
###################################################################
Filter specific cell marker 
###################################################################
BM<-subset( BM, subset = PECAM1>0.5)
BM <-SCTransform(BM)
############################################################
top10 <- head(VariableFeatures(BM), 10)
plot1 <- VariableFeaturePlot(BM)
plot2 <- LabelPoints(plot = plot1, points = top10, repel = TRUE)
plot1 + plot2
dev.copy2pdf(file="variable_plot.pdf")

##########################################################################
Run PCA 
##################################################################
BM <- JackStraw(BM, num.replicate = 100)
JackStrawPlot(BM, dims = 1:50)
dev.copy2pdf(file="JackStra_plot.pdf")
ElbowPlot(BM)
dev.copy2pdf(file="elbow_plot.pdf")

BM  <- RunPCA(BM , features = VariableFeatures(object = BM ))
BM  <- RunUMAP(BM , dims = 1:25, verbose = F)
BM <- FindNeighbors(BM , dims = 1:25, verbose = F)
BM<- FindClusters(BM, resolution = 0.4)


#############################################################################################################
FIND MARKER GENES list and theier count matrix
#############################################################################################################
all.markers <- FindAllMarkers(BM, only.pos = TRUE, min.pct = 0.25, logfc.threshold =0.5,return.thresh = 0.01)
write.xlsx(data.frame(all.markers),"all_cluster_marker_gene.xls",rownames=T)
write.table(as.matrix(GetAssayData(object = BM, slot = "counts")), 'counts.csv', sep = ',', row.names = T, col.names = T, quote = F)

################################################################################################################
PLOT GENE OF INTEREST 
################################################################################################################
features = c( "PECAM1",FLT4")
FeaturePlot(BM, features = features,ncol = 2)
dev.copy2pdf(file="feature_plot.pdf")

VlnPlot(BM,features = features,ncol = 2)
dev.copy2pdf(file="VINPOT.pdf")

DimPlot(BM, reduction = "umap",label = T)
dev.copy2pdf(file="umap.pdf")

pdf(file="gene_umap.pdf",width = 12,height = 6)
p1<-FeaturePlot(object = BM, features,ncol = 2)
p2<-DimPlot(BM, label = T)
CombinePlots(plots = list(p1, p2))
dev.off()
##############################################################################################
Anotate the cell type based on the top marker gene plot them 
#################################################################################
BM <- RenameIdents(object = BM, `0` = "Endothelial cell", 
                                `1` = "Tcell", 
                                `2` = "Macrophages", 
                                `3` = "Luminal cell", 
                                `4` = "B cells",
                                `5` = "Macrophages/MICell")
                              
pdf(file="pca_plot_with_cell_type.pdf",width = 10,height = 10)
DimPlot(BM , reduction = "pca")
dev.off()

pdf(file="label_umap_plot.pdf",width = 10,height = 10)
DimPlot(object = BM , label = TRUE)
dev.off()

pdf(file="label_tsne_plot.pdf",width = 10,height = 10)
TSNEPlot(object = BM)
dev.off()


###########################################################################################
GO/ PATHWAYS ANALYSIS OF SPECIFIC CLUSTER
###########################################################################################

clut<-all.markers[which(all.markers$cluster == "6"),]
all.gen <- subset(clut, p_val_adj< 0.001)
all.gen$geneid <- as.character(mget(rownames(all.gen),org.Hs.egSYMBOL2EG,ifnotfound=NA))
mygo <- as.list(org.Hs.egGO2EG)
mygo <- (mygo[!is.na(mygo)])
t <- mget(names(mygo),GOTERM)
names(mygo) <- as.character(lapply(t,Term))
deseq2.fc=all.gen$avg_log2FC
names(deseq2.fc)=all.gen$geneid
gos <- gage(deseq2.fc,gsets = mygo,ref = NULL, samp = NULL)
gene_set<-sigGeneSet(gos,cutoff=0.01)
up_path<-(gene_set$greater)
down_path<-(gene_set$less)

#############################################################################################
Kegg pathways analysis 
##############################################################################################
kg.hsa=kegg.gsets("hsa")
kg.hsa<-kegg.gsets(species = "hsa", id.type = "entrez")
kegg.gs=kg.hsa$kg.sets[kg.hsa$sigmet.idx]
kegg.gs=kg.hsa$kg.sets
gos <- gage(deseq2.fc,gsets=kegg.gs,ref = NULL, samp = NULL)
up<-(gene_set$greater)
write.csv(up,file="go_upregulated.csv")
down<-(gene_set$less)
write.csv(down,file="go_downregulated.csv")

```

## Mathematical modeling of biological process

Cellular processes such as cell migration and cell differentiation, cell cycle
are complex processes that are controlled through the time-sequential regulation of protein signaling and gene regulation. Various positive and negative feedback of the signaling pathways controls these cellular processes.
To study and understand these cellular processes a mathematical modeling approach is required. Boolean networks as models of biological pathways allow capturing the qualitative signaling behavior. Model construction for signalling networks begins with a wiring diagram that shows the interactions between the system components. Next, transfer model into Boolean logic network. later, predictive logical model simulation results verified by experiment.Modeling simulations code demonstrates the signaling pathways that are responsible for the [cell migration](https://pubmed.ncbi.nlm.nih.gov/22962472/) upon hepatocyte growth factor (HGF) simulation in primary human keratinocytes cells. 

### Booelan modelling of signaling pathway

##### Model defination file 
```
targets,factors
HGF,HGF
MET,HGF
PTEN,PTEN
PAI1,PAI1
AKAP12,AKAP12
SHC,MET | EGFR | FAK
GRB2,SHC
SOS,GRB2
RAS,SOS
RAF,RAS & PKC & PAK3
MEK,RAF | MEKK1
ERK,MEK
RSK,ERK
CREB,RSK
cMYC,ERK
EGR1,ERK
ELK1,ERK
ETS,ERK | JNK
STAT3,ERK
PTGS2,ATF2 | (cFOS & cJUN)
IL8,P38 | ERK
PAK1,CDC42RAC1
PAK2,CDC42RAC1
PAK3,CDC42RAC1
cFOS,ERK
cJUN,JNK & P38
RAP1,C3G
C3G,CRKL
PLCg,MET | EGFR
IP3,PLCg
DAG,PLCg
Ca,IP3
UPA,UPAR
MMP,Plasmin
ECM,MMP
Integrin,ECM
CRKL,GRB2
HBEGF,P38 | ERK
EGFR,HBEGF
CTGF,P38 | ERK
ATF2,P38 & JNK
Plasmin,PAI1 & UPA
FAK,Integrin & !PTEN
DOCK1,CRKL
AKT,!PTEN & PI3K
CDC42RAC1,RAS & AKT & DOCK1
MLK3,CDC42RAC1
UPAR,AP1
AP1,cJUN & cFOS
CCL20,ERK
PKC,DAG & Ca & !AKAP12
MKK3,MLK3
MKK4,MLK3 | MEKK1 | MEKK4
MKK6,MLK3
P38,(MKK3 & MKK6) | PAK1
JNK,(MEKK7 & MKK4) | PAK2
PI3K,MET | EGFR & FAK
MEKK7,MEKK1
MEKK1,CDC42RAC1
MEKK4,CDC42RAC1
CDK2,!CDKN1A  | !CDKN2A
CDKN1A,STAT3
CDKN2A,ELK1  | ETS
CyclinD,ELK1 | ATF2
Proliferation,CDK2 & CyclinD
CELL_MIGRATION,CTGF & PTGS2 & CCL20 & IL8
```
##### Model Simulation

```
library("BoolNet")
install.packages("colorRamps",dependencies=TRUE)
install.packages("pheatmap",dependencies=TRUE)
library(colorRamps)
library(pheatmap)
net<-loadNetwork("EGFR_new.txt")

mycol <- matlab.like2(13)
mycol[1] <- "#FFFFFF"
myoder<-c(1:5,8,9,10,11,12,13,14,15,16,7,51,6,52,53,55,17:22,24:27,29,31,33,39,32,23,30,34:38,64,40,41,42:50,58:62,66,57,28,65,56,54,63)
mycols <- c(rep(1,2),rep(2,12),rep(3,2),rep(4,4),rep(5,14),rep(6,3),rep(7,8),rep(8,9),rep(9,6),rep(10,3),rep(11,3))
n<-fixGenes(net,"HGF",1)

# HGR_stimulation-on_1hr
path1<-getPathToAttractor(n,c(1,0,rep(0,6),0,0,rep(0,28),0,rep(0,27)))
dummy1 = c(rep(1,nrow(path1)))
path1_wi_dummy <- cbind(path1, dummy1)
out_path1<-path1_wi_dummy[,myoder]
pheatmap(t(out_path1)*mycols,cluster_cols=F,cluster_rows=F,cellwidth=8,color=mycol)
#dev.copy2eps(file="HGR_stimulation-on_1hr.eps")

# PAI1_stimulation-on_3hr
net<-path1[nrow(path1),]
net$PAI1<-1
path2<-getPathToAttractor(n,as.numeric(net))
dummy2 = c(rep(1,nrow(path2)))
path2_wi_dummy <- cbind(path2, dummy2)
out_path2<-path2_wi_dummy[,myoder]
pheatmap(t(out_path2)*mycols,cluster_cols=F,cluster_rows=F,cellwidth=8,color=mycol)
#dev.copy2eps(file="PAI1_stimulation-on_3hr.eps")

# MET_inhibition-steady_state (this is where the path to attractor varies significantly)
net1<-path2[nrow(path2),]
net1$MET<-0
path3<-getPathToAttractor(n,as.numeric(net1))
dummy3 = c(rep(1,nrow(path3)))
path3_wi_dummy <- cbind(path3, dummy3)
out_path3<-path3_wi_dummy[,myoder]
pheatmap(t(out_path3)*mycols,cluster_cols=F,cluster_rows=F,cellwidth=8,color=mycol)
#dev.copy2eps(file="MET_inhibition-steady_state-on-5hr.eps")
# EGFR_inhibition-steady_state (this also is where the path to attractor varies significantly, probably because of its dependence on the previous steady state)
net2<-path3[nrow(path3),]
net2$EGFR<-0
path4<-getPathToAttractor(n,as.numeric(net2))
dummy4 = c(rep(1,nrow(path4)))
path4_wi_dummy <- cbind(path4, dummy4)
out_path4<-path4_wi_dummy[,myoder]
pheatmap(t(out_path4)*mycols,cluster_cols=F,cluster_rows=F,cellwidth=8,color=mycol)

#### PAI1_inhibition-steady_state (this also is where the path to attractor varies significantly, probably because of its dependence on the previous steady state)

net3<-path3[nrow(path3),]
net3$PAI1<-0
path5<-getPathToAttractor(n,as.numeric(net3))
dummy5 = c(rep(1,nrow(path5)))
path4_wi_dummy <- cbind(path5, dummy5)
out_path5<-path5_wi_dummy[,myoder]
pheatmap(t(out_path5)*mycols,cluster_cols=F,cluster_rows=F,cellwidth=8,color=mycol)

```

#### ODE model 
Fundamental cell processes (growth, division, motility, etc.) are driven by intracellular and intercellular communication. Modeling is particularly useful in analyzing information flow through cell signaling networks in response to a stimulus. These functions arise from the underlying biochemical reactions and require quantitative modeling. Modeling of these networks and pathways allows us to explore the signaling pathways for emergent properties. One of the key features of cell signaling networks is the nonlinearity arising from the presence of regulatory negative/positive loops and branches in the signaling network. Model construction for signaling networks begins with a wiring diagram that shows the interactions between the system components followed by translating to a system of differential equations. The next step in model construction is the estimation of the kinetic parameters and initial concentrations. Kinetic parameters for some biochemical reactions can be found in the literature, otherwise, these kinetic parameters are estimated from experimental data. Here, an example of a Mathematical model and how to estimate parameters are demonstrated in MatLab. The model (NGF-> ERK->DUSP6)  where NGF is stimulated in PC12 cells and that subsequently activates ERK pathways and ERK active DUSP6 and DUSP6 inhibit ERK activity. This model was transcribed to a simple ODE form. The cost function is used to estimate parameters using lsqnonlin function from MatLab. Estimation of parameters is a key aspect of a dynamic model and finding trustworthy parameters is key for the prediction of the model. Software packages like [pyABC](https://pyabc.readthedocs.io/en/latest/), [Data2Dynamics](https://github.com/Data2Dynamics/d2d),and [PEtab](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1008646) are dedicated for parameter estimation in dynamic system. 

##### ODE model 
```
function dydt = amit(t,y,params) % Solve the kinetics examp
dydt=zeros(size(y));
% parameters -reaction rate constant k1=0.1; k2=0.56; k3=1; k4=6;
% parameter rate constant k5=0.3; k6=0.6; k7=0.45; k8=0.9; k9=1;k10=0.69;k11=0.89;kd1=0.76;kd2=0.56;
%k1=0.309612038315457;
%k2=11.0210796878263;
%k3=0.758439956454315;
%k4=0.07839782952251  ;
%k5=0.988;
%kd2=0.0584442759638285;
%kd1= 0.0923602319622291;
params(1)=k1;
params(2)=k2;
params(3)=k3;
params(4)=k4;
params(5)=k5;
params(6)=kd1;
params(7)=kd2;
NGF=50;
ERK =y(1);                                            
pERK =y(2);                                            
DUSP6 = y(3);                                         
mRNADUSP6=y(4);
% evalute the rhs expression 
dydt(1) = -k1*ERK*NGF + k2*pERK*DUSP6;
dydt(2) = k1*ERK*NGF-k2*pERK*DUSP6;
dydt(3) = k3*mRNADUSP6-kd1*DUSP6;
dydt(4) = k4+k5*pERK-kd2*mRNADUSP6;

%[t,y] = ode45('amit',[0 50],[10 0 0 0]);
%plot(t,y);
%legend('ERK','pERK','DUSP6','mRNADUSP6');
%y(:,2) %to find the data of sepcific variabale 
%plot(t,y(:,2)) single plot of one variable.
%subplot
%plot(t,y(:,2))
%subplot(2,2,2)
%plot(t,y(:,3))
%% subplot issue 
%subplot(2,2,1);plot(t,y(:,1));legend('ERK');subplot(2,2,2);plot(t,y(:,2));legend('pERK');
%subplot(2,2,3);plot(t,y(:,3));
%legend('DUSP6');subplot(2,2,4);plot(t,y(:,4));legend('mRNADUSP6');subplot(2,2,1);plot(t,y(:,1));legend('ERK'); 
%subplot(2,2,2); plot(t,y(:,2));legend('pERK'); subplot(2,2,3);plot(t,y(:,3));legend('DUSP6');subplot(2,2,4); plot(t,y(:,4));
```
##### Cost function
```
function F=cost(k)
data1=[0.1 1 2 3 4 5 6 7 8 10 12 24 48];
data2=[3.710850787 
9.838755552 
6.926178303 
3.002167839 
5.304734841 
9.419238552 
0.403079263 
2.184241053 
011.359823295 
11.208385545 
0.100043796 
0.214691004 
-0.00221013];% pERK
%data3=[0.1, 0.5 1 3 5 8 24 48];
%data4=[0.139641867 0.078210527 0.046907391 0.04671645 0.046262227 0.044421201 0.035776173 0.017303024]; %pAKT
data5=[0 1 2 3 4 5 6 7 8 10 12 24 48];
data6=[ 0 0.8 3.22 5.67 5.65 5.31 4.83 4.64 4.66 4.27 3.94 3.79 4.15];% mrnaDUSP6
data7=[2 4 6 8 10 12 24 48];
data8=[-0.15920227 0.158085114 0.305665902 0.780491888 0.365455901 0.567850031 0.110412225 0.487074831];%dusp6 protein 
	
%%%%erk 
model=@amit;
y0=[1 0 0 0];
tmax=50;
options=odeset('MaxStep',tmax*0.1);
[t,y]=ode45(model,[0.1 1 2 3 4 5 6 7 8 10 12 24 48],y0,options,k);
Y1=(y(:,2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model=@amit;
y0=[1 0 0 0];
tmax=50;
options=odeset('MaxStep',tmax*0.1);
[t,y]=ode45(model,[2 4 6 8 10 12 24 48],y0,options,k);
Y2=(y(:,3));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model=@amit;
y0=[1 0 0 0];
tmax=50;
options=odeset('MaxStep',tmax*0.1);
[t,y]=ode45(model,[0 1 2 3 4 5 6 7 8 10 12 24 48],y0,options,k);
Y3=(y(:,4));%mrnaDUSP6
x1=Y1-data2;%erk
x2=Y2'-data8; %dusp6
x3=Y3'-data6; %mrnadusp6
F=[x1;x2';x3'];
subplot(2,1,1);
      plot(data1,data2,'red',data1,Y1,'black')
      title('pERK')
  
subplot(2,1,2);
      plot(data7,data8,'red',data3,Y2,'black')
      title('DUSP6')
      
subplot(2,3,2);
      plot(data5,data6,'red',data5,Y3,'black')
      title('mRNADUSP6')
return
```
##### Parameter estimation

```
function x=estimate()
k0=[1.2736 0.1000 0.1000 0.1106 8.7757 0.3736 3.2675];
options=optimset('LevenbergMarquardt','on','LargeScale','on','TolX',10^(-12),'MaxFunEvals',10^12,'MaxIter',10^4,'Display','on','TolFun',10^(-12));
[x,resnorm,residual,exitflag,output]=lsqnonlin(@cost,k0,[0.01 0.01 0.01 0.01 0.01 0.01 0.01],[20 20 20 20 20 20 20],options)
%Jacobian = full(Jacobian); 
%varp = resnorm*inv(Jacobian'*Jacobian)/length(50);
    				%stdp = sqrt(diag(varp));
					%AIC=log(residual /50)+2*23;
					
return

%% calculate the covariance of parameter estimators
%pcov = s*inv(j'*j) ; %covariance of parameters
%psigma=sqrt(diag(pcov))'; % standard deviationparameters
%pcor = pcov ./ [psigma'*psigma]; % correlationmatrix
%alfa=0.025; % significance level
%tcr=tinv((1-alfa),dof); % critical t-dist value at alfa
%p95 =[pmin-psigma*tcr; pmin+psigma*tcr]; %+-95%confidence intervals

```









