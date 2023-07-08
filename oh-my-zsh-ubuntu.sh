#!/bin/bash

# Update the package lists
sudo apt-get update

# Install ZSH and Git (if not installed)
sudo apt-get install -y zsh git

# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set ZSH as your default shell
chsh -s $(which zsh)
