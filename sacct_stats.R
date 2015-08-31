# We need data.table package
# To install
# install.packages(data.table)

require(data.table)

args <- commandArgs(trailingOnly = TRUE)
print(args[0])
filename <- args[1] 

# Load some helper functions
source('./helpers.R')

# Read the input file containing raw data
dt=fread(filename,header=T,sep="|")

# Clean up the batch lines
dt <- dt[-which(dt$User == ""), ]

# Convert the elapsed times (run time and time limit) into seconds
dt$Timelimit=as.numeric(unlist(lapply(dt$Timelimit,getelapsed)))
dt$Elapsed=as.numeric(unlist(lapply(dt$Elapsed,getelapsed)))

# Convert timestamps to POSIXct format
dt$Submit=as.POSIXct(strptime(dt$Submit,"%Y-%m-%dT%H:%M:%S"))
dt$Start=as.POSIXct(strptime(dt$Start,"%Y-%m-%dT%H:%M:%S"))
dt$End=as.POSIXct(strptime(dt$End,"%Y-%m-%dT%H:%M:%S"))

# Some helper tables to speed things up (I hope)
dt$Year=year(dt$Start)
dt$Month=month(dt$Start)

# Calculate the queuing time for each job
dt$QueueTime=as.numeric(dt$Start - dt$Submit)

# Calculate the total time (core seconds) for each job
dt$TotalTime=dt$Elapsed * dt$AllocCPUS

# Calculate the accuracy of timelimit estimation for each job
dt$TimelimitAccuracy = dt$Elapsed / dt$Timelimit

# Convert the formatted byte values to standard bytes

dt$MaxVMSize=convb(dt$MaxVMSize)
dt$MaxRSS=convb(dt$MaxRSS)
dt$MaxDiskRead=convb(dt$MaxDiskRead)
dt$MaxDiskWrite=convb(dt$MaxDiskWrite)


# User -based statistics as CSV

setkey(dt,User)
df2 <- dt[, list(count=.N, AllocCPUS_min=min(AllocCPUS), AllocCPUS_mean=mean(AllocCPUS), AllocCPUS_stddev=sd(AllocCPUS), AllocCPUS_max=max(AllocCPUS),
                     QueueTime_min=min(QueueTime), QueueTime_mean=mean(QueueTime), QueueTime_stddev=sd(QueueTime), QueueTime_max=max(QueueTime),
                     Elapsed_min=min(Elapsed),Elapsed_mean=mean(Elapsed), Elapsed_stddev=sd(Elapsed), Elapsed_max=max(Elapsed),
                     TimelimitAccuracy_min=min(TimelimitAccuracy),TimelimitAccuracy_mean=mean(TimelimitAccuracy), TimelimitAccuracy_stddev=sd(TimelimitAccuracy), TimelimitAccuracy_max=max(TimelimitAccuracy)
                     ),by=list(User)]
write.csv(dt2,file=paste(filename,"_stats_per_user.csv",sep=""))

setkey(dt,Month,Year)

# Monthly statistics as CSV

dt3 <- dt[, list(count=.N, AllocCPUS_min=min(AllocCPUS), AllocCPUS_mean=mean(AllocCPUS), AllocCPUS_stddev=sd(AllocCPUS), AllocCPUS_max=max(AllocCPUS),
                            QueueTime_min=min(QueueTime), QueueTime_mean=mean(QueueTime), QueueTime_stddev=sd(QueueTime), QueueTime_max=max(QueueTime),
                            Elapsed_min=min(Elapsed),Elapsed_mean=mean(Elapsed), Elapsed_stddev=sd(Elapsed), Elapsed_max=max(Elapsed),
                            TimelimitAccuracy_min=min(TimelimitAccuracy,na.rm=TRUE),TimelimitAccuracy_mean=mean(TimelimitAccuracy,na.rm=TRUE), TimelimitAccuracy_stddev=sd(TimelimitAccuracy,na.rm=TRUE), TimelimitAccuracy_max=max(TimelimitAccuracy,na.rm=TRUE)
                            ),by=list(Year,Month)]
write.csv(dt3,file=paste(filename,"_stats_per_month.csv",sep=""))

# Some random things that I've commented out for now

#save.image("Tables.RData")

# Plot runtime vs allocated CPUs
#plot(dt$RunTime,dt$AllocCPUS)

# Cumulative core counts
#CoreCounts <- table(dt$AllocCPUS)
#CumulativeCoreCounts <- cumsum(CoreCounts)

# Cumulative total time (core seconds)
#TotalTimes <- table(df$TotalTime)
#CumTotalTimes <- cumsum(TotalTimes)
#plot(as.numeric(names(CumTotalTimes),CumTotalTimes))

# Plot job size distribution
#plot(as.numeric(names(CumulativeCoreCounts)),CumulativeCoreCounts,
#      main="Job size distribution",
#      xlab="Core count",
#      ylab="Job count")

