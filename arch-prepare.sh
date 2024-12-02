// Esto es el programa para hacer las particiones
// Ocupas una para el boot de 500 megas y el resto para root
cfdisk /dev/sda

// formatear las particiones
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

// montar las particiones
mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot

// instalar arch
pacstrap -K /mnt linux linux-firmware base git

// generar las filesystem tabs
genfstab -U /mnt >> /mnt/etc/fstab

// cambiar el root al sistema nuevo
arch-chroot /mnt

// descargar el script y ejecutarlo
cd /root
git clone https://github.com/aguilarcarboni/laserfocus-os
cd /
sh /root/laserfocus-os/install-script.sh

// cuando termina sales y reinicias
exit
reboot
