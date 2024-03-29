
full-install: first-config install-yay install-packages personal-configuration
	sudo reboot

first-config: configure-git update-fast-mirrors
	sudo sed -i 's/^# %wheel ALL=(ALL)/%wheel ALL=(ALL)/' /etc/sudoers ;\
	sudo pacman -S archlinux-keyring --noconfirm; \
	sudo pacman -Sy

update-fast-mirrors:
	sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist

install-keyboard:
	cd $(HOME) ;\
	wget https://raw.githubusercontent.com/raelgc/win_us_intl/master/.XCompose ;\
	echo "export GTK_IM_MODULE=uim \nexport QT_IM_MODULE=uim\nexport QT_IM_MODULE=uim \nuim-xim & \nexport XMODIFIERS=@im=uim " > .xprofile

configure-git:
	git config --global user.name "ErikBPF" ;\
	git config --global user.email "erikbogado@gmail.com"

install-yay:
	cd $(HOME)/.config ;\
	git clone https://aur.archlinux.org/yay-git.git ;\
	cd yay-git ;\
	makepkg -si --noconfirm ;\
	cd $(HOME)

install-packages: install-pacman-packages install-yay-packages install-python-packages

install-pacman-packages:
	yes | yay -S iptables-nft
	sudo pacman --noconfirm --needed -Syu - < packages-list/packages-list-pacman.txt

install-yay-packages:
	yay --noconfirm --needed -Sy - < packages-list/packages-list-aur.txt

install-python-packages:
	pip install -r packages-list/packages-list-python.txt

disable-services:
	sudo systemctl disable systemd-networkd.service ;\
	sudo systemctl stop systemd-networkd.service 

enable-services:
	sudo usermod -s /bin/fish $(USER) ;\
	sudo pkgfile --update ;\
	setxkbmap -layout us -variant intl ;\
	sudo usermod -a -G docker $(USER) ;\
	sudo usermod -a -G audio $(USER) ;\
	sudo usermod -a -G video $(USER) ;\
	sudo usermod -a -G libvirt $(USER) ;\
	sudo systemctl enable cups.service ;\
	sudo systemctl enable wpa_supplicant.service ;\
	sudo systemctl enable NetworkManager.service ;\
	sudo systemctl enable bluetooth.service; \
	sudo systemctl enable docker ;\
	sudo systemctl enable lightdm ;\
	sudo systemctl enable bluetooth ;\
	sudo systemctl enable libvirtd ;\
	sudo systemctl enable sshd ;\
	sudo systemctl --user enable ssh-agent.service ;\
	sudo echo "SSH_ASKPASS=/usr/bin/gnome-ssh-askpass3" >> /etc/environment ;\
	sudo sed -i '/unix_sock_group/s/^#//g' /etc/libvirt/libvirtd.conf ;\
    sudo sed -i '/unix_sock_rw_perms/s/^#//g' /etc/libvirt/libvirtd.conf ;\
    sudo virsh net-autostart default ;\
	xdg-user-dirs-update ;\
	yay --editmenu --nodiffmenu --save
	

personal-configuration: disable-services enable-services install-keyboard configure-apps

configure-apps:
	#gnome
	#rm $(HOME)/.config/dconf/user ;\
	#ln -s $(PWD)/config-files/gnome/user $(HOME)/.config/dconf/user ;\
	#find the command
	sudo rm /usr/share/doc/find-the-command/ftc.fish  ;\
	sudo ln -s $(PWD)/config-files/fish/ftc.fish /usr/share/doc/find-the-command/ftc.fish ;\
	#fish
	rm $(HOME)/.config/fish/config.fish ;\
	mkdir $(HOME)/.config/fish ;\
	ln -s $(PWD)/config-files/fish/config.fish $(HOME)/.config/fish/config.fish ;\
	rm $(HOME)/.config/fish/fish_variables  ;\
	ln -s $(PWD)/config-files/fish/fish_variables $(HOME)/.config/fish/fish_variables ;\
	#flameshot
	rm $(HOME)/.config/flameshot/flameshot.ini  ;\
	mkdir $(HOME)/.config/flameshot ;\
	ln -s $(PWD)/config-files/flameshot/flameshot.ini $(HOME)/.config/flameshot/flameshot.ini
	#kitty
	rm -rf $(HOME)/.config/kitty/kitty.conf  ;\
	mkdir $(HOME)/.config/kitty ;\
	ln -s $(PWD)/config-files/kitty/kitty.conf $(HOME)/.config/kitty/kitty.conf
	rm $(HOME)/.config/kitty/dracula.conf  ;\
	ln -s $(PWD)/config-files/kitty/dracula.conf $(HOME)/.config/kitty/dracula.conf
	rm $(HOME)/.config/kitty/diff.conf  ;\
	ln -s $(PWD)/config-files/kitty/diff.conf $(HOME)/.config/kitty/diff.conf
	# btop
	rm -rf $(HOME)/.config/btop  ;\
	ln -s $(PWD)/config-files/btop $(HOME)/.config/
	#qtile
	rm -rf $(HOME)/.config/qtile  ;\
	mkdir $(HOME)/.config/qtile ;\
	ln -s $(PWD)/config-files/qtile/autostart.sh $(HOME)/.config/qtile/autostart.sh
	ln -s $(PWD)/config-files/qtile/config.py $(HOME)/.config/qtile/config.py
	#dunst
	rm -rf $(HOME)/.config/dunst  ;\
	mkdir $(HOME)/.config/dunst ;\
	ln -s $(PWD)/config-files/dunst/dunstrc $(HOME)/.config/dunst/dunstrc
	#rofi
	rm -rf $(HOME)/.config/rofi  ;\
	ln -s $(PWD)/config-files/rofi $(HOME)/.config/
	#bin files
	rm -rf $(HOME)/.local/bin/statusbar  ;\
	mkdir $(HOME)/.local/bin ;\
	ln -s $(PWD)/config-files/bin/statusbar $(HOME)/.local/bin/statusbar
	# lightdm
	rm $(HOME)/.xsession ;\
	chmod 744 $(PWD)/config-files/lightdm/.xsession ;\
	ln -s $(PWD)/config-files/lightdm/.xsession $(HOME)/.xsession ;\
	sudo cp $(PWD)/config-files/lightdm/slick-greeter.conf /etc/lightdm/slick-greeter.conf
	sudo sed -i 's/^#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf								
	sudo sed -i 's/^#!\/bin\/sh/#!\/bin\/bash/' /etc/lightdm/Xsession
	# BetterLockscreen
	rm -f $(HOME)/.config/betterlockscreenrc ;\
	ln -s $(PWD)/config-files/betterlockscreen/betterlockscreenrc $(HOME)/.config/betterlockscreenrc
	# Wallpaper
	rm -rf $(HOME)/.config/wallpapers  ;\
	ln -s $(PWD)/config-files/wallpapers $(HOME)/.config/wallpapers
	sudo rm -rf /usr/share/wallpapers
	sudo mkdir -p /usr/share/wallpapers
	sudo cp $(PWD)/config-files/wallpapers/wallpaper.png /usr/share/wallpapers/wallpaper.png
	# GTK
	rm -rf $(HOME)/.config/gtk-3.0/settings.ini  ;\
	mkdir $(HOME)/.config/gtk-3.0 ;\
	ln -s $(PWD)/config-files/gtk-3.0/settings.ini $(HOME)/.config/gtk-3.0/settings.ini
