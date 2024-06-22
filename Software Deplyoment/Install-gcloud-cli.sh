#!/bin/zsh
##########################################################################################
# Created by: Logan Holliday
# Date: 29.09.2023
# 
# Description: Installs the latest gcloud cli version automatically and silent
#	
# Details:
#   - Create download URL link
#   - Installs downloaded file automatically
#
#
################################################################################################# 
 
currentUser=$(stat -f "%Su" /dev/console)
arch=$(uname -m) #Check the CPU type
installVersion="$4" #Parameter for current version to install set in the Jamf Pro Policy example 449.0.0-darwin

# Function to check if gcloud is installed
is_gcloud_installed() {
    if command -v gcloud &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if gcloud is already installed
if is_gcloud_installed; then
    echo "Google Cloud SDK (gcloud) is already installed."
else
    echo "Google Cloud SDK (gcloud) is not installed. Installing..."
    install_gcloud
fi

# Function to install gcloud silently
install_gcloud(){

#Function to check if Intel or Apple Silicon and run proper install.
if [ "$arch" == "x86_64" ]; then
    # Download gcloud SDK installer for macOS
    (cd /usr/local/ && curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$installVersion-x86_64.tar.gz")

    # Extract the archive
    tar -zxvf /usr/local/google-cloud-cli-$installVersion-arm.tar.gz -C "/Users/$currentUser/"

    # Change Google folder permissions
    chown -R $currentUser:staff /Users/$currentUser/google-cloud-sdk
    chown -R $currentUser:staff /Users/$currentUser/.config/gcloud/

    # Run the installation script
    sudo -u $currentUser bash "/Users/$currentUser/google-cloud-sdk/install.sh" --quiet

    # Clean up downloaded files
    rm /usr/local/google-cloud-cli-$installVersion-arm.tar.gz
elif [ "$arch" == "arm64" ]; then
    # Download gcloud SDK installer for macOS
    (cd /usr/local/ && curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$installVersion-arm.tar.gz")

    # Extract the archive
    tar -zxvf /usr/local/google-cloud-cli-$installVersion-arm.tar.gz -C "/Users/$currentUser/"

    # Change Google folder permissions
    chown -R $currentUser:staff /Users/$currentUser/google-cloud-sdk
    chown -R $currentUser:staff /Users/$currentUser/.config/gcloud/

    # Run the installation script
    sudo -u $currentUser bash "/Users/$currentUser/google-cloud-sdk/install.sh" --quiet

    # Clean up downloaded files
    rm /usr/local/google-cloud-cli-$installVersion-arm.tar.gz
else
    echo "Unknown CPU architecture: $arch"
fi
}

