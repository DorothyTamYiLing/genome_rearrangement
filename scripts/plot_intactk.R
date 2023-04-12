library("optparse")

option_list = list(
  make_option("--input", type="character", default=NULL,
              help="kmer to plot", metavar="character"),
  make_option("--gen_size", type="character", default=NULL,
              help="kmer to plot", metavar="character"),
  make_option("--outdir", type="character", default=NULL,
              help="kmer to plot", metavar="character"),
  make_option("--outname", type="character", default=NULL,
              help="kmer to plot", metavar="character"),
  make_option("--intkrd", type="character", default=NULL,
              help="kmer to plot", metavar="character")
) 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser); 

#install.packages("ggplot2")
library("ggplot2")
#install.packages("ggforce")
library("ggforce")
#install.packages("ggpubr")
library("ggpubr")
library("plyr")

myx<-read.delim(opt$input,header=T,sep="\t")
#mytable<-mytable[-1,]


#sort the kmer rows
myx<-myx[order(myx$fwdk_0gen_med),]

myx$fwdk_0gen_med_round<-round_any(myx$fwdk_0gen_med, as.numeric(as.character(opt$intkrd)))    

#remove rows that are duplicated in myx$fwdk_0gen_med
mykeeprow<-c()
mycoorlist<-unique(myx$fwdk_0gen_med_round)
for (i in 1:length(mycoorlist)){
  mykeeprow<-c(mykeeprow,which(myx$fwdk_0gen_med_round==mycoorlist[i])[1])
}
myx_unqiue<-myx[mykeeprow,]
#indexing the kmers for colour gradients
myx_unqiue$mycol_index<-1:nrow(myx_unqiue)

colnames(myx_unqiue)

#if need specify again which kmer to plot here
#myx_unqiue<-myx_unqiue[which(myx_unqiue$kmer%in%c("kmer205","kmer3606")),]

#output the kmers for plot
write.table(myx_unqiue,file=paste(opt$outdir,"/",opt$outname,"_kmer4plot.txt",sep=""),quote=F,col.names=T,row.names=F,sep="\t")

mysize<-as.numeric(as.character(opt$gen_size))*1000


png(paste(opt$outdir,"/",opt$outname,".png",sep=""))

p  <- ggplot(data = myx_unqiue) + 
  geom_link(aes(x = fwdk_0gen_med, y = 0, xend = fwdk_0gen_med+15, yend = 0, color=mycol_index),arrow = grid::arrow(length = grid::unit(myx_unqiue$fwdk_0gen_prop, 'cm')))+
  geom_link(aes(x = revk_1gen_med, y = 1, xend = revk_1gen_med-15, yend = 1, color=mycol_index),arrow = grid::arrow(length = grid::unit(myx_unqiue$revk_1gen_prop, 'cm')))+
  geom_link(aes(x = fwdk_1gen_med, y = 0.9, xend = fwdk_1gen_med+15, yend = 0.9, color=mycol_index),arrow = grid::arrow(length = grid::unit(myx_unqiue$fwdk_1gen_prop, 'cm')))+
  geom_link(aes(x = revk_0gen_med, y = 0.1, xend = revk_0gen_med-15, yend = 0.1, color=mycol_index),arrow = grid::arrow(length = grid::unit(myx_unqiue$revk_0gen_prop, 'cm')))+
  scale_colour_gradientn(name = "mycol_index", 
                         colours=c("darkred","orange","red","blue","chartreuse3"))+
  scale_x_continuous(limits = c(1, mysize),breaks = seq(1, mysize, by = 100000))+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
p
dev.off()