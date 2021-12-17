
full-install: first-config disable-services install-package-managers install-pacman-packages install-yay-packages enable-services install-keyboard
	sudo reboot

pos-reboot: install-snap-packages

first-config: configure-git update-fast-mirrors
	sudo pacman -S archlinux-keyring --noconfirm

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

install-snap:
	cd $(HOME)/Documents ;\
	git clone https://aur.archlinux.org/snapd.git ;\
	cd snapd ;\
	makepkg -si --noconfirm ;\
	sudo systemctl enable --now snapd.socket;\
	sudo ln -s /var/lib/snapd/snap /snap ;\
	cd $(HOME)

install-package-managers: install-yay install-snap

install-pacman-packages:
	sudo pacman --noconfirm --needed -Syu - < packages-list/packages-list-pacman.txt

install-yay-packages:
	yay --noconfirm --needed -Sy - < packages-list/packages-list-aur.txt

install-snap-packages:
	sudo snap install nordpass

disable-services:
	sudo systemctl disable systemd-networkd.service ;\
	sudo systemctl stop systemd-networkd.service 

enable-services:
	chsh -s /bin/fish ;\
	sudo pkgfile --update ;\
	sudo systemctl enable cups.service ;\
	sudo systemctl start cups.service ;\
	sudo usermod -a -G docker $(USER) ;\
	sudo systemctl start docker ;\
	sudo systemctl enable docker

configure-apps:
	#gnome
	rm $(HOME)/.config/dconf/user ;\
	ln -s $(PWD)/config-files/gnome/user $(HOME)/.config/dconf/user ;\
	#find the command
	sudo rm /usr/share/doc/find-the-command/ftc.fish  ;\
	sudo ln -s $(PWD)/config-files/fish/ftc.fish /usr/share/doc/find-the-command/ftc.fish ;\
	#fish
	rm $(HOME)/.config/fish/config.fish ;\
	ln -s $(PWD)/config-files/fish/config.fish $(HOME)/.config/fish/config.fish ;\
	rm $(HOME)/.config/fish/fish_variables  ;\
	ln -s $(PWD)/config-files/fish/fish_variables $(HOME)/.config/fish/fish_variables ;\
	#flameshot
	rm $(HOME)/.config/flameshot/flameshot.ini  ;\
	ln -s $(PWD)/config-files/flameshot/flameshot.ini $(HOME)/.config/flameshot/flameshot.ini
	#kitty
	rm $(HOME)/.config/kitty/kitty.conf  ;\
	ln -s $(PWD)/config-files/kitty/kitty.conf $(HOME)/.config/kitty/kitty.conf
	rm $(HOME)/.config/kitty/dracula.conf  ;\
	ln -s $(PWD)/config-files/kitty/dracula.conf $(HOME)/.config/kitty/dracula.conf
	rm $(HOME)/.config/kitty/diff.conf  ;\
	ln -s $(PWD)/config-files/kitty/diff.conf $(HOME)/.config/kitty/diff.conf