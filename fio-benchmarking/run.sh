docker run -v std_benchmark_output:/output standard_benchmark:v1
echo "Output file location:"
docker volume inspect std_benchmark_output
