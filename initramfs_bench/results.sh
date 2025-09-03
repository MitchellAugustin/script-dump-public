for f in /var/lib/initramfs-test/results/*; do
    [ -f "$f" ] || continue
    echo "===== $f ====="
    cat "$f" | grep kernel | grep Startup
    echo
done

