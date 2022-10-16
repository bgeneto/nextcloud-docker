# nextcloud-docker

Nextcloud docker containers primarily used for cpu/system benchmarking.

We use a ramdisk (tmpfs) storage folder for file uploading in order to avoid disk bottlenecks. 

So before using the `start.sh` script issue the following:


```bash
sudo mkdir /mnt/storage
sudo mount -t tmpfs -o size=4G tmpfs /mnt/storage
sudo mv .env.tmp .env
sudo ./start.sh
```

You can build an optimized PHP docker image (with -O3 and -march=native) by running the script `build-docker-opt-images.sh` 
and setting the flag `USE_OPT_IMG=1` in the `.env` file. 
