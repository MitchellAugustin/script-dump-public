echo "# script-dump-public" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:MitchellAugustin/script-dump-public.git
git push -u origin main
