#!/bin/bash

packages=(
	vim 
	gimp 
	inkscape
	blender
)

if [ -f /etc/redhat-release ]; then
	
	echo -e "\e[34;1mOS Detected: $(cat /etc/redhat-release)\e[0m" 
	dnf install -y ${packages[*]}

fi
