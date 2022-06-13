#!/usr/bin/env -S bash -e

xdg-user-dirs-update # Updates user directories for XDG Specification

echo >> /etc/profile
echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> /etc/profile
echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> /etc/profile
echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> /etc/profile
echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> /etc/profile
echo 'export GOPATH="$XDG_DATA_HOME/go"' >> /etc/profile
echo 'export CARGO_HOME="$XDG_DATA_HOME/cargo"' >> /etc/profile
echo 'export LESSHISTFILE="$XDG_CONFIG_HOME/less/history"' >> /etc/profile
echo 'export LESSKEY="$XDG_CONFIG_HOME/less/keys"' >> /etc/profile
echo 'export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm"' >> /etc/profile
sed -i -e 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

main_user=$(id -nu 1000)
chown -R 1000:1000 "/home/$main_user/Documents"
sudo -i -u "$main_user" bash << EOF
make -C /home/$main_user/Documents/arch-setup/ full-install
EOF

clear