# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'
mainApp = function(input){
  library(pacman)
  pacman::p_load(data.table,parallel)
  # read.data
  data. = WCMC.Fansly::MetaboAnalystFormat(input,row_start = 3)
  e = data.$e
  f = data.$f
  p = data.$p


  e = as.matrix(e)

  e = e[,order(p[[3]])]
  p = p[order(p[[3]]),]

  multicore = T
  if(multicore){
    cl = makeCluster(min(detectCores(),20))
  }else{
    cl = makeCluster(1)
  }


  group=colnames(p)[2]
  PairedTtest = parSapply(cl,1:nrow(e),function(j,e,p,group){
    t.test(e[j,]~p[[group]],paired = T)$p.value
  },e,p,group)
  PairedTtest.FDR=p.adjust(PairedTtest,'fdr')

  medians = by(t(e),p[[2]],function(x){
    sapply(x,median,na.rm=T)
  })
  FC = medians[[1]]/medians[[2]]

  result = data.table(f,PairedTtest,PairedTtest.FDR,FC)
  rownames(result) = 1:nrow(result)
  if(class(f)=="character"){
    colnames(result) = c(colnames_f_1,c('p value', 'adjusted p value',paste0("FC: ",names(medians)[1],"/",names(medians)[2])))
  }else{
    colnames(result) = c(colnames(f),c('p value', 'adjusted p value',paste0("FC: ",names(medians)[1],"/",names(medians)[2])))
  }

  fwrite(data.table(result),"PairedTtest.csv")
  fwrite(data.table(result),"PairedTtest.txt",sep = "\t")


  stopCluster(cl)

  return(result)


}
