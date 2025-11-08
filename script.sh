#!/bin/bash

# The main point of this file is to bootstrap us up to the point of syncing and installing through chezmoi
# compatible with debian, arch, fedora, macOS, WSL

set -e

# initialize a basic data structure to store some of the most crucial details about the system
#
# basic_system_details[gpu]
# basic_system_details[os]
# basic_system_details[pkg_mgr]
# basic_system_details[https_requester] - (curl, wget, and whatever powershell uses teehee)
#
declare -A basic_system_details


# foundational #
################

# figure out whether we need to install drivers, get  wsl, or get an https requester

## detect  os & package manager
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if command -v apt >/dev/null; then
    basic_system_details[os]="debian"
    basic_system_details[pkg_mgr]="apt"
  elif command -v dnf >/dev/null; then
    basic_system_details[os]="fedora"
    basic_system_details[pkg_mgr]="dnf"
  elif command -v pacman >/dev/null; then
    basic_system_details[os]="arch"
    basic_system_details[pkg_mgr]="pacman"
  else
    echo "❌ Unknown Linux package manager"
    exit 1
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  basic_system_details[os]="macos"
  basic_system_details[pkg_mgr]="brew"
elif grep -qi microsoft /proc/version; then
  basic_system_details[os]="wsl"
  basic_system_details[pkg_mgr]="apt"
else
  echo "❌ Unsupported OS"
  exit 1
fi


echo "🌐 Installing curl and wget..."
case "${basic_system_details[pkg_mgr]}" in
  apt)
    sudo apt update
    sudo apt install -y curl wget
    ;;
  dnf)
    sudo dnf install -y curl wget
    ;;
  pacman)
    sudo pacman -Sy --noconfirm curl wget
    ;;
  brew)
    brew install curl wget
    ;;
esac

# Set curl as the standard HTTPS tool for scripting
basic_system_details[https_requester]="curl"


# detect gpu
if lspci | grep -qi nvidia; then
  basic_system_details[gpu]="nvidia"
  case ${basic_system_details[os]} in
    debian)
      apt install -y nvidia-driver
      ;;
    arch)
      pacman -S --noconfirm nvidia
      ;;
    redhat)
      dnf install -y akmod-nvidia
      ;;
  esac
elif lspci | grep -qi amd; then
  basic_system_details[gpu]="amd"
  case ${basic_system_details[os]} in
    debian)
      sudo apt install -y mesa-utils mesa-vulkan-drivers
      ;;
    arch)
      sudo pacman -S --noconfirm mesa mesa-utils vulkan-radeon
      ;;
    redhat)
      sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers
      ;;
  esac
elif [[ "$OSTYPE" == "darwin"* ]]; then
  basic_system_details[gpu]="macos-managed"
  echo "🖥 macOS handles GPU drivers automatically."
else
  basic_system_details[gpu]="intel/unknown"
fi

# Optionally: install GPU driver (placeholder)
# echo "TODO: Install driver for ${basic_system_details[gpu]}"

## detect whether we need to install ssh/git
for pkg in git ssh; do
  if ! command -v $pkg >/dev/null; then
    echo "📦 Installing $pkg..."
    case "${basic_system_details[pkg_mgr]}" in
      apt) sudo apt install -y $pkg ;;
      dnf) sudo dnf install -y $pkg ;;
      pacman) sudo pacman -Sy --noconfirm $pkg ;;
      brew) brew install $pkg ;;
    esac
  fi
done

# install GitHub CLI
if ! command -v gh >/dev/null; then
  echo "📦 Installing GitHub CLI..."
  case ${basic_system_details[os]} in
    debian)
      apt install -y gh
      ;;
    arch)
      pacman -S --noconfirm github-cli
      ;;
    redhat)
      dnf install -y gh
      ;;
    macos)
      brew install gh
      ;;
  esac
fi

# Prompt user to authenticate
if ! gh auth status &>/dev/null; then
  echo "Starting GitHub authentication..."
  gh auth login --git-protocol ssh --hostname github.com
fi

echo "✅ System Setup Summary:"
for key in "${!basic_system_details[@]}"; do
  echo "  - $key: ${basic_system_details[$key]}"
done

# essentials #
##############

# install chezmoi
echo "📦 Installing chezmoi..."
#bash -c "$(${basic_system_details[https_requester]} -fsSL https://get.chezmoi.io)"
sh -c "$(${basic_system_details[https_requester]} -fsSL get.chezmoi.io)"

# Move chezmoi binary to a proper location
if [[ -f "bin/chezmoi" ]]; then
  if command -v sudo &>/dev/null; then
    echo "🔧 Moving chezmoi to /usr/local/bin using sudo..."
    sudo mv bin/chezmoi /usr/local/bin/chezmoi
    rmdir bin
  else
    echo "🔧 Moving chezmoi to ~/.local/bin (no sudo available)..."
    mkdir -p "$HOME/.local/bin"
    mv bin/chezmoi "$HOME/.local/bin/chezmoi"
    rmdir bin
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  fi
else
  echo "❌ chezmoi binary not found in ./bin — install may have failed."
  exit 1
fi

# simply run git clone ~/.local/share/chezmoi
chezmoi init git@github.com:K-JAX/dotfiles.git

echo "Applying chezmoi config..."
