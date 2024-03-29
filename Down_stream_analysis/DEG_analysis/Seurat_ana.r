library(Seurat)
library(dplyr)
library(Matrix)
library(cowplot)
library(patchwork)
library(RaceID)
library(openxlsx)
#####################
##load data in to R
####################
con1.data <- Read10X(data.dir = "~/Desktop/single_cell_analysis/633818_22-REX/outs/filtered_feature_bc_matrix")
con2.data <- Read10X(data.dir = "~/Desktop/single_cell_analysis/633818_23-REX/outs/filtered_feature_bc_matrix")
con3.data <- Read10X(data.dir = "~/Desktop/single_cell_analysis/633818_24-REX/outs/filtered_feature_bc_matrix")
con<-cbind(con1.data,con2.data,con3.data)
ctrl.names <- paste("CTRL_",c(1:378), sep = "")
colnames(con) <- ctrl.names
######make seurat object 
#ctrl<- CreateSeuratObject(counts = con,  project = "ctrl")

#####
treat1.data <- Read10X(data.dir = "~/Desktop/single_cell_analysis/633818_25-REX/outs/filtered_feature_bc_matrix")
treat2.data <- Read10X(data.dir = "~/Desktop/single_cell_analysis/633818_26-REX/outs/filtered_feature_bc_matrix")
treat3.data <- Read10X(data.dir = "~/Desktop/single_cell_analysis/633818_27-REX/outs/filtered_feature_bc_matrix")
########
trt<-cbind(treat1.data,treat2.data,treat3.data)
trt.names <- paste("TRT_",c(1:495), sep = "")
colnames(trt) <- trt.names
##combine the data 
final<-cbind(con,trt)
#####remove mt genes
idx<-grep("mt-", rownames(final))
final<-final[-idx,]
####creat seurat object
final<- CreateSeuratObject(counts = final,  project = "t-cell")
#########################
######Qc test
########################

#final[["percent.mt"]] <- PercentageFeatureSet(final, pattern = "^mt-")
#VlnPlot(final, features = c("nFeature_RNA", "nCount_RNA", "percent.mt"), ncol = 3)
#plot1 <- FeatureScatter(final, feature1 = "nCount_RNA", feature2 = "percent.mt")
plot2 <- FeatureScatter(final, feature1 = "nCount_RNA", feature2 = "nFeature_RNA")
plot1 + plot2
dev.copy2pdf(file="violin_plot.pdf")

#final <- subset(final, subset = nFeature_RNA > 200 & nFeature_RNA < 2500 & percent.mt < 5)
#final <- subset(final, subset = nFeature_RNA>500)

########################################################################
###########keep those cell whose transcript count >500
########################################################################

final <- subset(final, subset = nCount_RNA>500)


#########################
######norm data##########
########################

final <- NormalizeData(final, normalization.method = "LogNormalize", scale.factor = 10000)
####find top 10 variable gene
final <- FindVariableFeatures(final, selection.method = "vst", nfeatures = 2000)
# Identify the 10 most highly variable genes
top10 <- head(VariableFeatures(final), 10)
pdf(file="Most_Variable_gene.pdf",width = 15,height = 10)
# plot variable features with and without labels
plot1 <- VariableFeaturePlot(final)
plot2 <- LabelPoints(plot = plot1, points = top10, repel = TRUE)
plot1 + plot2
dev.off()

#####
#############
all.genes <- rownames(final)
final<- ScaleData(final, features = all.genes)

#final<- ScaleData(final, vars.to.regress = "percent.mt")
#final<- ScaleData(final)

###############################################
#run PCAPerform linear dimensional reduction###
############################################
final <- RunPCA(final, features = VariableFeatures(object = final))

########################################################
##Examine and visualize PCA results a few different ways
########################################################

print(final[["pca"]], dims = 1:5, nfeatures = 5)
VizDimLoadings(final, dims = 1:2, reduction = "pca")
dev.copy2pdf(file="pc_1_pc2_gene.pdf")

DimPlot(final, reduction = "pca")
dev.copy2pdf(file="pca_plot.pdf")

DimHeatmap(final, dims = c(1:2), cells = 500, balanced = TRUE)
dev.copy2pdf(file="pca_1_DimHeatmap.pdf")

#final <- FindNeighbors(final, dims = 1:10)
#final <- FindClusters(final, resolution = 0.5)
#####################################################
### t-SNE and Clustering#############################
#####################################################

final <- FindNeighbors(object = final, reduction = "pca", dims = 1:20)
final <- FindClusters(final, resolution = 0.5)
final <- RunTSNE(object = final, dims.use = 1:10, do.fast = TRUE)
TSNEPlot(object = final,group.by='orig.ident')
dev.copy2pdf(file="TSNEPlot.pdf")
TSNEPlot(object = final)
dev.copy2pdf(file="TSNEPlot_with_clusternumber.pdf")

#final<- RunUMAP(object = final, reduction = "pca", dims = 1:20)
final<- RunUMAP(final, dims = 1:10)
DimPlot(final, reduction = "umap",group.by='orig.ident')
dev.copy2pdf(file="cluster.pdf")

DimPlot(final, reduction = "umap")
dev.copy2pdf(file="cluster_umap.pdf")

##########################################################################
##Finding differentially expressed features (cluster biomarkers)
##########################################################################

cluster1.markers <- FindMarkers(final, ident.1 = 0, min.pct = 0.25)
head(cluster1.markers, n = 5)

cluster2.markers <- FindMarkers(final, ident.1 = 1, min.pct = 0.25)
head(cluster2.markers, n = 5)

cluster3.markers <- FindMarkers(final, ident.1 = 2, min.pct = 0.25)
head(cluster3.markers, n = 5)

cluster4.markers <- FindMarkers(final, ident.1 = 3, min.pct = 0.25)
head(cluster4.markers, n = 5)

cluster5.markers <- FindMarkers(final, ident.1 = 4, min.pct = 0.25)
head(cluster5.markers, n = 5)

cluster6.markers <- FindMarkers(final, ident.1 = 5, min.pct = 0.25)
head(cluster5.markers, n = 5)

#cluster7.markers <- FindMarkers(final, ident.1 = 6, min.pct = 0.25)
#head(cluster5.markers, n = 5)
#cluster8.markers <- FindMarkers(final, ident.1 = 7, min.pct = 0.25)
#head(cluster5.markers, n = 5)

all.markers <- FindAllMarkers(final, only.pos = TRUE, min.pct = 0.25, logfc.threshold = 1)
a<-all.markers %>% group_by(cluster) %>% top_n(n = 30, wt = avg_logFC)
write.xlsx(data.frame(all.markers),"all_cluster_marker.xls",rownames=T)

####################################################################
###generates an expression heatmap for given cells and features.
####################################################################

final <- ScaleData(object = final, verbose = FALSE)
top10 <- all.markers %>% group_by(cluster) %>% top_n(n = 10, wt = avg_logFC)
DoHeatmap(final, features = top10$gene) + NoLegend()
dev.copy2pdf(file="all_maker_of_cluster.pdf",width = 15,height = 10)

#DoHeatmap(object = final,
#         features = top10$gene,
#        disp.min = -1,
#       disp.max = 1) + scale_fill_gradientn(colors = colorRampPalette(c("#0200ad",
#                                                                       "#fbfcbd",
#                                                                       "#ff0000"))(256))
#ggplot2::ggsave(filename = "feature.pdf", plot = plot)

################################################
####top2 plot for all cluster ##################
###############################################

top2=all.markers%>% group_by(cluster) %>% top_n(2,avg_logFC)

pdf(file="top2gene_violinplot.pdf",width = 10,height = 10)
VlnPlot(final, features = top2$gene)
####
dev.off()

#dev.copy2pdf(file="top2gene_violinplot.pdf")

#################################################
#######Single cell heatmap of feature expression
#################################################
DoHeatmap(subset(final, downsample = 100), features = top2$gene, size = 3)
dev.copy2pdf(file="top2gene_heatmap.pdf")
##############################################################################################
######RidgePlot#############################
##############################################################################################
pdf(file="top2gene_rigid_plot.pdf",width = 15,height = 10)
RidgePlot(final, features = top2$gene[1:10], ncol = 2)
dev.off()
##############################################################################################
# Feature plot - visualize feature expression in low-dimensional space####
##############################################################################################
pdf(file="top2gene_umpa_plot.pdf",width = 15,height = 10)
FeaturePlot(final, features = top2$gene)
dev.off()

####################################################
# Dot plots - the size of the dot corresponds to the percentage of cells expressing the feature
# in each cluster. The color represents the average expression level
##########################################################################
pdf(file="top2gene_dot_plot.pdf",width = 15,height = 10)
DotPlot(final, features = top2$gene) + RotatedAxis()
dev.off()

##################################################################
######anotate the cell type 
##################################################################

FeaturePlot(object = final, features = top2$gene, min.cutoff = "q9")

#####top2$gene
#[1] "Thrsp"  "Car4"   "Igkc"   "Plac8"  "Cldn5"  "Cdkn1a" "C1qb"   "Lyz2"   "Ms4a1"  "Il4i1"  "Lrg1"  
#[12] "Ackr1"  "Trbc2"  "Satb1"

#[1] "Timp4"  "Car3"   "Trbc2"  "Satb1"  "C1qc"   "C1qb"   "Ms4a1"  "Ly6d"   "Igkc"   "Ighg2b" "Timp3" 
#[12] "Enpp2" 

final <- RenameIdents(object = final, `0` = "Endothelial cell", 
                                `1` = "Tcell", 
                                `2` = "Macrophages", 
                                `3` = "Luminal cell", 
                                `4` = "B cells",
                                `5` = "Macrophages/MICell")
                              
pdf(file="pca_ploe_with_cell_tyow.pdf",width = 10,height = 10)
DimPlot(final, reduction = "pca")
dev.off()

pdf(file="label_ucna_plot.pdf",width = 10,height = 10)
DimPlot(object = final, label = TRUE)
dev.off()

pdf(file="label_tsne_plot.pdf",width = 10,height = 10)
TSNEPlot(object = final)
dev.off()



##########################################################################
##some other plot
##################################################################
final <- JackStraw(final, num.replicate = 100)
final <- ScoreJackStraw(final, dims = 1:20)
JackStrawPlot(final, dims = 1:15)
dev.copy2pdf(file="JackStra_plot.pdf")
ElbowPlot(final)
dev.copy2pdf(file="elbow_plot.pdf")
