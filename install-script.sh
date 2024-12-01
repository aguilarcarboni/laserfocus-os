#!/bin/bash

# Exit on error and ensure errors in pipelines are caught
set -e
set -o pipefail

# Check if the script is being run as root
echo -e "\nChecking if you are root..."
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
echo -e "You are root. Proceeding with installation...\n"

# Set the root password, username, and hostname
read -sp "Enter the password for root: " root_password
read -p "Enter the username you want to create: " username
read -sp "Enter the password for ${username}: " user_password
read -p "Enter the host name: " hostname
echo -e "\n"

# Set the time zone
echo -e "\nTo set the time zone, you will use /sbin/tzselect."
echo "This command will guide you through selecting your region and city."
echo "Running /sbin/tzselect..."
timezone=$(/sbin/tzselect)
echo -e "\nSetting the time zone..."
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
echo "Time zone set."

# Ask for swap to file
read -p "Do you want to create a swap file? (Y/n): " swap
if [[ -z "${swap}" || "${swap}" =~ ^[Yy]$ ]]; then
    read -p "Enter the size of the swap file in GB: " swap_size
fi

# Set swap file if wanted
if [[ -z "${swap}" || "${swap}" =~ ^[Yy]$ ]]; then
    echo -e "\nCreating swap file..."
    mkswap -U clear --size ${swap_size}G --file /swapfile
    swapon /swapfile
    echo -e '/swapfile none swap defaults 0 0\n' >> /etc/fstab
    echo "Swap file created."
else
    echo -e "Skipping swap file creation.\n"
fi

# Set accounts
echo -e "\nSetting up accounts..."
echo "root:${root_password}" | chpasswd
useradd -mG wheel "${username}"
echo "${username}:${user_password}" | chpasswd
echo "Accounts set."

# Pacman configuration
echo -e "\nConfiguring pacman..."
sed -i '/#Color/s/^#//' /etc/pacman.conf
sed -i '/#ParallelDownloads/s/^#//' /etc/pacman.conf
if ! grep -q '^ILoveCandy' /etc/pacman.conf; then
    sed -i '/\[options\]/a ILoveCandy' /etc/pacman.conf
fi
pacman -Syy
echo "Pacman configured."

# Enable sudo
echo -e "\nEnabling sudo..."
pacman -S --noconfirm --needed sudo
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers
echo "Sudo enabled."

# Hardware packages installation
pacman -S --noconfirm --needed intel-ucode mesa

# Set the locale
echo -e "\nSetting english UTF-8 locale..."
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "Locale set."

# Grub installation
echo -e "\nInstalling GRUB..."
pacman -S --noconfirm --needed grub efibootmgr os-prober
grub-install --verbose --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
echo "GRUB installed."
echo -e "\nGenerating GRUB configuration..."
sed -i '$ s/^#//' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB configuration generated."

# Network configuration
echo -e "\nConfiguring network..."
echo ${hostname} >/etc/hostname
echo "127.0.0.1 localhost
::1       localhost
127.0.1.1 ${hostname}.localhost ${hostname}" | tee /etc/hosts >/dev/null
pacman -S --noconfirm --needed networkmanager
systemctl enable NetworkManager.service
echo "Network configured."

# Audio configuration
echo -e "\nConfiguring audio..."
pacman -S --noconfirm --needed alsa-firmware pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber
echo "Audio configured."

# Bluetooth configuration
echo -e "\nConfiguring Bluetooth..."
pacman -S --noconfirm --needed bluez bluez-utils blueman
systemctl enable bluetooth.service
echo "Bluetooth configured."

# Install usefull packages
echo -e "\nInstalling usfull packages..."
pacman -S --needed --noconfirm base-devel fastfetch
echo -e "Packages installed.\n"

# Install KDE Plasma
echo -e "\nInstalling KDE Plasma..."
pacman -S --noconfirm --needed plasma-meta

# Run Fastfetch
fastfetch

echo -e "\nInstallation complete."
