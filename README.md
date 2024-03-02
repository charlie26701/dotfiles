<p align="center"><image width="900" height="60" src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=30&color=3c8893&pause=1000&random=false&width=900&lines=WELCOME TO SOWNTEE'S DOTFILES ARCH AWESOMEWM 🌸">

> **NOTE**: Perfect with Resolution 2560x1600(16:10) 2K

<br>

<details><summary>Install Arch Linux</summary><blockquote>

### Make you have Internet

    iwctl

### Time sync (Vietnam) and set keyboard

    loadkeys i386/qwerty/us.map.gz

    timedatectl set-ntp true
    timedatectl set-timezone Asia/Ho_Chi_Minh

### Reflector and Keyring

    pacman -Sy reflector archlinux-keyring

    reflector -c Vietnam -c Singapore -c Japan -c India -a 12 --sort rate --save /etc/pacman.d/mirrorlist

### Disk

    cfdisk /dev/nvme0n1

    mkswap /dev/nvme0n1p6
    swapon /dev/nvme0n1p6

    mkfs.ext4 /dev/nvme0n1p5

    mount /dev/nvme0n1p5 /mnt

    mkdir /mnt/efi
    mount /dev/nvme0n1p1 /mnt/efi

### Install basic package

    pacstrap /mnt base base-devel linux linux-firmware linux-headers neovim

### Switch to /mnt

    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt

### Set time and Languaue

    ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
    hwclock --systohc

    nvim /etc/locale.gen
    Uncomment: en_US.UTF-8 UTF-8
    locale-gen
    echo LANG=en_US.UTF-8 > /etc/locale.conf

### Set hostname

    echo arch > /etc/hostname

    nvim /etc/hosts
    127.0.0.1[TAB]localhost
    ::1[TAB][TAB]localhost
    127.0.1.1[TAB]arch.localdomain[TAB]arch

### User add or password

    passwd

    useradd -m sowntee
    passwd sowntee
    usermod -aG wheel,audio,video,optical,storage,power sowntee

    EDITOR=nvim visudo
    Add: sowntee ALL=(ALL) ALL
    sowntee ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl reboot, /usr/bin/systemctl poweroff, /usr/sbin/rfkill unblock all, /usr/sbin/rfkill block all
    Uncomment: %wheel ALL=(ALL) ALL

### Grub and OsProber and Wifi

	sudo pacman -S netctl networkmanager ifplugd dhcpcd dialog wpa_supplicant wireless_tools
	sudo systemctl enable NetworkManager dhcpcd.service

    sudo pacman -S grub os-prober efibootmgr ntfs-3g mtools dosfstools
    sudo nvim /etc/default/grub
    Uncomment: GRUB_DISABLE_OS_PROBER=false

    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

### Exit and Reboot

    exit
    reboot

###### If GRUB not found Windows (For Dual Boot)

    sudo os-prober
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
    grub-mkconfig -o /boot/grub/grub.cfg

</blockquote></details>
