git clone https://github.com/CloudCompile/fastvm
cd fastvm
pip install textual
sleep 2
python3 installer.py
docker build -t fastvm . --no-cache
cd ..

sudo apt update
sudo apt install -y jq

mkdir Save
cp -r fastvm/root/config/* Save

json_file="fastvm/options.json"
if jq ".enablekvm" "$json_file" | grep -q true; then
    docker run -d --name=FastVM -e PUID=1000 -e PGID=1000 --device=/dev/kvm --security-opt seccomp=unconfined -e TZ=Etc/UTC -e SUBFOLDER=/ -e TITLE=FastVM -p 3000:3000 --shm-size="2gb" -v $(pwd)/Save:/config --restart unless-stopped fastvm
else
    docker run -d --name=FastVM -e PUID=1000 -e PGID=1000 --security-opt seccomp=unconfined -e TZ=Etc/UTC -e SUBFOLDER=/ -e TITLE=FastVM -p 3000:3000 --shm-size="2gb" -v $(pwd)/Save:/config --restart unless-stopped fastvm
fi
clear
echo "FASTVM WAS INSTALLED SUCCESSFULLY! Check Port Tab"
