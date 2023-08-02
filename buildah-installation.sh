# https://fabianlee.org/2022/08/02/buildah-installing-buildah-and-podman-on-ubuntu-20-04/

# https://github.com/containers/buildah/blob/main/install.md

# prereq packages
sudo apt-get update
sudo apt-get install -y wget ca-certificates gnupg2

# add repo and signing key
VERSION_ID=$(lsb_release -r | cut -f2)
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel-kubic-libcontainers-stable.list
curl -Ls https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$VERSION_ID/Release.key | sudo apt-key add -
sudo apt-get update

# install buildah
sudo apt install buildah -y
