
full-install: first-config install-package-managers install-pacman-packages install-yay-packages enable-services install-keyboard install-dev-tools
	sudo reboot

pos-reboot: install-snap-packages

first-config: configure-git
	sudo pacman -S archlinux-keyring --nocofirm

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
	sudo snap install nordpass teams

enable-services:
	sudo systemctl enable cups.service ;\
	sudo systemctl start cups.service ;\
	sudo usermod -a -G docker $(USER) ;\
	sudo usermod -aG docker $(USER) ;\
	sudo systemctl start docker ;\
	sudo systemctl enable docker

install-kubectl:
	cd $(HOME) ;\
	curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" ;\
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

install-minikube:
	cd $(HOME) ;\
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 ;\
	sudo install minikube-linux-amd64 /usr/local/bin/minikube

install-helm:
	cd $(HOME) ;\
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 ;\
	chmod 700 get_helm.sh ;\
	./get_helm.sh

install-dev-tools: install-kubectl install-minikube install-helm