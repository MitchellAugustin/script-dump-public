#!/bin/bash

# General Sysbench benchmarks
echo "Automated Multicloud Analysis Framework - Results" >> /output/report.txt
echo "Sysbench CPU Performance" >> /output/report.txt
sysbench cpu run | awk '/events per second/ || /execution time/' >> /output/report.txt 2>&1
echo "FileIO: Write operations (sequential access):" >> /output/report.txt
sysbench fileio prepare && sysbench --file-test-mode=seqrewr fileio run | awk '/writes\/s/ || /fsyncs\/s/ || /written, MiB\/s/ || /File operations/ || /Throughput/' >> /output/report.txt 2>&1 
echo -e "\n" >> /output/report.txt
echo "FileIO: Read operations (sequential access):" >> /output/report.txt
sysbench fileio prepare && sysbench --file-test-mode=seqrd fileio run | awk '/reads\/s/ || /read, MiB\/s/ || /File operations/ || /Throughput/' >> /output/report.txt 2>&1
echo -e "\n" >> /output/report.txt
echo "FileIO: Write operations (asynchronous access):" >> /output/report.txt
sysbench fileio prepare && sysbench --file-io-mode=async --file-test-mode=seqrewr fileio run | awk '/writes\/s/ || /fsyncs\/s/ || /written, MiB\/s/ || /File operations/ || /Throughput/' >> /output/report.txt 2>&1
echo -e "\n" >> /output/report.txt
echo "FileIO: Read operations (asynchronous access):" >> /output/report.txt
sysbench fileio prepare && sysbench --file-io-mode=async --file-test-mode=seqrd fileio run  | awk '/reads\/s/ || /read, MiB\/s/ || /File operations/ || /Throughput/' >> /output/report.txt 2>&1
echo -e "\n" >> /output/report.txt
echo "FileIO: Write operations (Memory-mapped I/O):" >> /output/report.txt
sysbench fileio prepare && sysbench --file-io-mode=mmap --file-test-mode=seqrewr fileio run | awk '/writes\/s/ || /fsyncs\/s/ || /written, MiB\/s/ || /File operations/ || /Throughput/' >> /output/report.txt 2>&1
echo -e "\n" >> /output/report.txt
echo "FileIO: Read operations (Memory-mapped I/O):" >> /output/report.txt
sysbench fileio prepare && sysbench --file-io-mode=mmap --file-test-mode=seqrd fileio run  | awk '/reads\/s/ || /read, MiB\/s/ || /File operations/ || /Throughput/' >> /output/report.txt 2>&1
echo -e "\n" >> /output/report.txt
echo "Memory: Sequential write test:" >> /output/report.txt
sysbench memory run | awk '/Total operations/ || /MiB transferred/' >> /output/report.txt 2>&1 # Sequential memory write test
echo -e "\n" >> /output/report.txt
echo "Memory: Random write test:" >> /output/report.txt
sysbench --memory-access-mode=rnd memory run  | awk '/Total operations/ || /MiB transferred/' >> /output/report.txt 2>&1 # Random memory write test
echo -e "\n" >> /output/report.txt
echo "Memory: Sequential read test:" >> /output/report.txt
sysbench --memory-oper=read memory run  | awk '/Total operations/ || /MiB transferred/' >> /output/report.txt  2>&1 # Sequential memory access test
echo -e "\n" >> /output/report.txt
echo "Memory: Random read test:" >> /output/report.txt
sysbench --memory-oper=read --memory-access-mode=rnd memory run | awk '/Total operations/ || /MiB transferred/' >> /output/report.txt 2>&1 # Random memory access test
#The threads/mutex ones aren't really things people will care about, so I'm not including them in the top-level report.
sysbench threads run > /output/threads_out.txt 2>&1  
sysbench mutex run > /output/mutex_out.txt 2>&1
sysbench mutex run > /output/mutex_out.txt 2>&1 

# RAM/Storage with FIO
TEST_DIR=/mnt/disks/mnt_dir/fiotest
mkdir -p $TEST_DIR
echo -e "\n" >> /output/report.txt

# (1) Write Throughput
echo Starting_FIO_Write_Throughput_Test...
echo "FIO Write Throughput/Bandwidth test:" >> /output/report.txt
fio --name=write_throughput --directory=$TEST_DIR --numjobs=4 \
--size=1G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio \
--direct=1 --verify=0 --bs=1M --iodepth=64 --rw=write \
--group_reporting=1 --iodepth_batch_submit=64 \
--iodepth_batch_complete_max=64 | awk '$1 ~ /^bw/' >> /output/report.txt 2>&1
echo Finished_FIO_Write_Throughput_Test...
echo -e "\n" >> /output/report.txt

# (2) Write Input/Ouput Operations Per Second (IOPS)
echo Starting_FIO_Write_IOPS_Test...
echo "FIO Write IOPS test:" >> /output/report.txt
fio --name=write_iops --directory=$TEST_DIR --size=1G \
--time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 \
--verify=0 --bs=4K --iodepth=256 --rw=randwrite --group_reporting=1  \
--iodepth_batch_submit=256 --iodepth_batch_complete_max=256 | awk '$1 ~ /^iops/' >> /output/report.txt 2>&1
echo Finished_FIO_Write_IOPS_Test...
echo -e "\n" >> /output/report.txt

# (3) Read Throughput
echo Starting_FIO_Read_Throughput_Test...
echo "FIO Read Throughput/Bandwidth test:" >> /output/report.txt
fio --name=read_throughput --directory=$TEST_DIR --numjobs=4 \
--size=1G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio \
--direct=1 --verify=0 --bs=1M --iodepth=64 --rw=read \
--group_reporting=1 \
--iodepth_batch_submit=64 --iodepth_batch_complete_max=64 | awk '$1 ~ /^bw/' >> /output/report.txt 2>&1
echo Finished_FIO_Read_Throughput_Test...
echo -e "\n" >> /output/report.txt

# (4) Read IOPS
echo Starting_FIO_Read_IOPS_Test...
echo "FIO Read IOPS test:" >> /output/report.txt
fio --name=read_iops --directory=$TEST_DIR --size=1G \
--time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 \
--verify=0 --bs=4K --iodepth=256 --rw=randread --group_reporting=1 \
--iodepth_batch_submit=256  --iodepth_batch_complete_max=256 | awk '$1 ~ /^iops/' >> /output/report.txt 2>&1
echo Finished_FIO_Read_IOPS_Test...
echo -e "\n" >> /output/report.txt

# cleanup
rm $TEST_DIR/write* $TEST_DIR/read*
echo -e "\n" >> /output/report.txt
