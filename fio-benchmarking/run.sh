if [ $# -eq 0 ]
  then
    echo "Usage: $0 <number of iterations>"
    exit
fi

for i in $(seq 1 $1);
do
	docker run -v std_benchmark_output:/output standard_benchmark:v1
	echo "Output file location:"
	docker volume inspect std_benchmark_output
done
