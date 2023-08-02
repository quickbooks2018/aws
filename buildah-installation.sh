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

# Buildah inside a container
docker run --name python --privileged -id python:slim

# Buildah to build an image from this Dockerfile:

buildah bud -t myflaskapp:latest .

In this command:

bud is short for build-using-dockerfile.
-t myflaskapp gives the image a tag (in this case, "myflaskapp").
. tells Buildah to look for the Dockerfile in the current directory.
