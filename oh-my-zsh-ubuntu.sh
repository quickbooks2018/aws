#!/bin/bash

# Update the package lists
echo "Updating package lists..."
sudo apt-get update -qq

# Check if ZSH and Git are already installed, if not, install them
if ! command -v zsh &> /dev/null; then
    echo "ZSH not found, installing..."
    sudo apt-get install -y zsh
fi

if ! command -v git &> /dev/null; then
    echo "Git not found, installing..."
    sudo apt-get install -y git
fi

# Check if Oh-My-Zsh is already installed, if not, install it
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh-My-Zsh not found, installing..."
    # Backup existing .zshrc file if it exists
    [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Set ZSH as your default shell if it's not already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting ZSH as default shell..."
    sudo chsh -s "$(which zsh)" $USER
fi
