# This script provides a bootable install of archlinux with Sway.

clear
echo ""
echo "        Make sure you red the install.sh file, set variables to the right value, etc."
echo "           Some passwords will be asked to you during the installation process."
echo "                                        WARNING"
echo "This script is not a full automation script; if you don't understand the script you should'nt use it"
echo ""
read -n 1 -s -r -p "Press any key to start the installation ..."


COMPUTER_NAME="arch"
USERNAME="lizcaps"
USER_PASSWORD=""
INSTALL_DRIVE="sda"
BOOT_SIZE=512
ROOT_SIZE=16
SWAP_SIZE=2
LANGUAGE="en_US.UTF8"
KEYMAP="fr"
COUNTRY_LOCATION="France"
HOME_INSTALL_REPOSITORY="https://github.com/lizcaps/Home.git"
HOME_INSTALL_FOLDER=".env/Home"
INSTALL_REPOSITORY="https://github.com/lizcaps/aii.git"
INSTALL_FOLDER=".env/asi"

loadkeys "$KEYMAP"
timedatectl set-ntp true
# -- Create Partition --
sfdisk /dev/"$INSTALL_DRIVE" -uS <<EOF
,$(($ROOT_SIZE*1024*1024*1024/512))
,$(($SWAP_SIZE*1024*1024*1024/512))
;
EOF
mkfs.ext4 '/dev/'$INSTALL_DRIVE'1'
mkfs.ext4 '/dev/'$INSTALL_DRIVE'3'
mkswap '/dev/'$INSTALL_DRIVE'2'
swapon '/dev/'$INSTALL_DRIVE'2'
mount '/dev/'$INSTALL_DRIVE'1' /mnt
mkdir /mnt/home
mount '/dev/'$INSTALL_DRIVE'3' /mnt/home

# -- Install Base Packages --
# add network
reflector -c "$COUNTRY_LOCATION" -f 12 -l 12 --verbose --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel linux linux-firmware
arch-chroot /mnt pacman --noconfirm -Sy grub \
pulseaudio openssh openvpn acpilight \
vim git htop wget curl noto-fonts man xterm\
xorg-server xorg-xinit  \
i3-gaps i3lock i3status i3blocks dmenu pavucontrol \
atom rxvt-unicode firefox-developer-edition discord \
#zsh zsh-theme-powerlevel9k awesome-terminal-fonts

# -- Generate fstab --
genfstab -U -p /mnt >> /mnt/etc/fstab
#sed -i 's|filesystems keyboard|keyboard encrypt lvm2 filesystems|g' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -p linux

# -- Setup Locales --
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

sed -i "s|#$LANGUAGE|$LANGUAGE|g" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$LANGUAGE" > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
echo "$COMPUTER_NAME" > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
echo "127.0.0.1 $COMPUTER_NAME.localdomain $COMPUTER_NAME" >> /mnt/etc/hosts

# -- Setup nework with NetworkManager --
#arch-chroot /mnt systemctl enable NetworkManager.service
#arch-chroot /mnt systemctl disable dhcpcd.service
#arch-chroot /mnt systemctl enable wpa_supplicant.service
#arch-chroot /mnt systemctl start NetworkManager.service

# -- Grub Install --
#sed -i 's|\([[:blank:]]*\)insmod gfxterm|\1insmod gfxterm\n\1insmod gfxterm_background|g' /mnt/etc/grub.d/00_header
#echo 'GRUB_BACKGROUND="/boot/grub/themes/background.jpg"' >> /mnt/etc/default/grub
#echo 'GRUB_FORCE_HIDDEN_MENU="true"' >> /mnt/etc/default/grub
#arch-chroot /mnt chmod a+x /etc/grub.d/31_hold_shift
arch-chroot /mnt grub-install --target=i386-pc /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# -- Create new user and setup passwords --
arch-chroot /mnt groupadd sudo
echo "%sudo ALL=(ALL) ALL" >> /mnt/etc/sudoers
arch-chroot /mnt useradd -m -G sudo -s /bin/bash $USERNAME
arch-chroot /mnt su $USERNAME -c "cd ~/ && mkdir .env"
arch-chroot /mnt su $USERNAME -c "git clone $INSTALL_REPOSITORY ~/$INSTALL_FOLDER"
arch-chroot /mnt su $USERNAME -c "git clone $HOME_INSTALL_REPOSITORY ~/$HOME_INSTALL_FOLDER"
arch-chroot /mnt passwd -l root
echo "-- $USERNAME --"
arch-chroot /mnt passwd $USERNAME

# -- Configure --
#arch-chroot /mnt cp /home/"$USERNAME"/"$INSTALL_FOLDER"/ressources/grubBackground.jpg /boot/grub/themes/background.jpg

echo "     ------ INSTALLATION DONE ------"
echo "You should check if everything went right."
echo "After that, unmount your /mnt and reboot."
echo "-> unmout -R /mnt"
echo "-> reboot"
