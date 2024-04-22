# Builds source packages for all subdirectories of pwd (Assumes all subdirectories have valid debian/ build info)
for dir in */; do
	cd $dir; debuild -S -sa; cd ..
done
