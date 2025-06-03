# WSL Setup Guide for Lava Project

## Overview
This guide shows how to install and configure Windows Subsystem for Linux (WSL) to build, test, and develop the Lava Swift project in a Linux‐like environment on Windows.

## Prerequisites
- Windows 10 (Build 19041 or later) or Windows 11  
- Administrator privileges to enable optional features  
- Internet access to download packages and Swift toolchain  

## Step 1: Enable WSL and Virtual Machine Platform
Open PowerShell as Administrator and run:  
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart  
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart  
Restart your PC to complete installation.

## Step 2: Install and Configure a Linux Distribution
1. Open Microsoft Store, search for **Ubuntu**, and install (Ubuntu 20.04 LTS recommended).  
2. Launch Ubuntu from the Start menu.  
3. When prompted, create a new UNIX username and password.  
4. Back in PowerShell, set WSL 2 as default:  
    wsl --set-default-version 2  
5. (Optional) Convert an existing distro to WSL 2:  
    wsl --set-version Ubuntu-20.04 2  

## Step 3: Install Swift on WSL
In the Ubuntu shell:  
1. Update packages:  
    sudo apt-get update && sudo apt-get upgrade -y  
2. Install dependencies:  
    sudo apt-get install -y clang libicu-dev libcurl4-openssl-dev libssl-dev git libxml2-dev libsqlite3-dev pkg-config libncurses5-dev libatomic1  
3. Download the latest Swift for Ubuntu from swift.org:
    - Copy the `.tar.gz` URL for Ubuntu 20.04.  
    - In shell:  
        wget <SWIFT_DOWNLOAD_URL>  
4. Extract and install:  
    tar xzf <SWIFT_FILENAME>  
    sudo mv <SWIFT_DIRNAME> /usr/share/swift  
5. Add Swift to your PATH:
    echo 'export PATH=/usr/share/swift/usr/bin:$PATH' >> ~/.bashrc  
    source ~/.bashrc  
6. Verify installation:  
    swift --version  

## Step 4: Build and Test Lava
1. Navigate to your Windows project folder (mounted under `/mnt`):
    cd /mnt/c/Path/To/lava  
2. Build the package:
    swift build  
3. Run tests:
    swift test  

## Step 5: VS Code Remote – WSL Integration (Optional)
1. Install **Remote – WSL** extension in VS Code.  
2. In VS Code, click the green “><” icon and choose **New WSL Window**.  
3. Open the Lava project folder within WSL for seamless Linux tooling and debugging.