#!/bin/bash

packages=(
	dbus-x11
	dconf-editor	
	vim 
	gimp 
	inkscape
	blender
)
# special installation functions
dl_vscode() {
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
	sudo dnf install code
}

dl_hyper() {
	curl https://github-production-release-asset-2e65be.s3.amazonaws.com/62367558/e3dd3a80-7299-11e9-899b-216abd868f6d?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20200821%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20200821T020211Z&X-Amz-Expires=300&X-Amz-Signature=dcdbbd4ec3e3b4eaaee43e516cefff7ab83d88d5aba57ce0e085dfaebac1b00e&X-Amz-SignedHeaders=host&actor_id=5242114&repo_id=62367558&response-content-disposition=attachment%3B%20filename%3Dhyper-3.0.2.x86_64.rpm&response-content-type=application%2Foctet-stream > hyper.rpm
	rpm -i hyper.rpm
	rm hyper.rpm
}

if [ -f /etc/redhat-release ]; then
	
	echo -e "\e[34;1mOS Detected: $(cat /etc/redhat-release)\e[0m" 

	# update packages
	dnf update

	# install packages
	dnf install -y ${packages[*]}

	# VS Code function
	dl_vscode

	# Hyper Terminal
	dl_hyper

	# set time format to syncrhonized and AM / PM
	timedatectl set-ntp yes
	dbus-launch gsettings set org.gnome.desktop.interface clock-format '12h' 
fi



