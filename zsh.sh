#!/bin/bash

# Update the system
sudo apt-get update -y

# Install Zsh
sudo apt-get install -y zsh

# Set Zsh as your default shell
chsh -s $(which zsh)

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
