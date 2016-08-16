#
# Simple SLURM queue time statistics
# Olli-Pekka Lehto / CSC - IT Center for Science Ltd. 
# 
# ------
# Step 1:
# Create the accounting file, run:
# sacct --format Submit,Start,Partition,User  -s BF,CA,CD,F,NF,PR,TO -P -a -S (startdate) -X > queue_stats
#
# Where (startdate) is the start timestamp
# Feel free to use other sacct parameters (like -E as well) 
# -------
# Step 2:
# The script needs the data.table package
# To install it, do install.packages(data.table)
# -------
# Step 3
# Run this script and give the input file as a parameter. For example: 
# Rscript --vanilla sacct_stats_queue_dist.R queue_stats 
# After the run you should have queue_stats.out in your directory

require(data.table)

args <- commandArgs(trailingOnly = TRUE)
filename <- args[1] 

# Load some helper functions
source('./helpers.R')

# Read the input file containing raw data
dt=fread(filename,header=T,sep="|")

# Clean up the batch lines
dt <- dt[-which(dt$User == ""), ]

# Convert timestamps to POSIXct format
dt$Submit=as.POSIXct(strptime(dt$Submit,"%Y-%m-%dT%H:%M:%S"))
dt$Start=as.POSIXct(strptime(dt$Start,"%Y-%m-%dT%H:%M:%S"))

# Some helper tables to speed things up (I hope)
dt$Year=year(dt$Start)
dt$Month=month(dt$Start)

# Calculate the queuing time for each job
dt$QueueTime=as.numeric(dt$Start - dt$Submit)

out=dt[,list("<1min"=sum(QueueTime<60)/.N,"<15min"=sum(QueueTime %in% 60:900 )/.N,"<1h"=sum(QueueTime %in% 900:3600)/.N,"<5h"=sum(QueueTime %in% 3600:18000 )/.N,"Longer"=sum(QueueTime>18000)/.N),by=Partition]

write.csv(out,paste(filename,"_out.csv",sep=""),row.names=FALSE, na="")
