Rebuilding all installed packages on your machine

1. ./initial-deps.sh (install initial dependencies)
2. Install desired workload and all its dependencies
3. ./build-deps.sh (Install build deps for everything installed on your system, recursively)
4. Build custom GCC and install (MUST COME AFTER 3 OR APT RESOLVER WILL BREAK)
5. ./download-sources.sh (download sources for all installed packages)
6. ./build.sh (rebuild everything)
