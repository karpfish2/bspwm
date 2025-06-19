#!/bin/bash

set -e

echo "[1/5] Установка основных пакетов..."
sudo pacman -Syu --noconfirm \
  bspwm sxhkd xorg-server xorg-xinit xorg-xrandr xclip xdotool \
  polybar picom nitrogen rofi \
  pipewire pipewire-pulse wireplumber pavucontrol \
  setxkbmap \
  ttf-jetbrains-mono-nerd ttf-font-awesome ttf-dejavu \
  acpi acpi_call lm_sensors brightnessctl networkmanager scrot \
  dunst lxappearance qt5ct qt6ct

echo "[2/5] Включение NetworkManager и PipeWire..."
sudo systemctl enable NetworkManager
sudo systemctl enable --now pipewire pipewire-pulse wireplumber

echo "[3/5] Настройка sensors..."
yes | sudo sensors-detect

echo "[4/5] Разворачивание конфигов..."

mkdir -p ~/.config/{bspwm,sxhkd,polybar/scripts,picom}
mkdir -p ~/.local/bin

# BSPWM конфиг
cat > ~/.config/bspwm/bspwmrc << 'EOF'
#!/bin/bash
pgrep -x sxhkd > /dev/null || sxhkd &
pgrep -x picom > /dev/null || picom &
pgrep -x nitrogen > /dev/null || nitrogen --restore &
pgrep -x polybar > /dev/null || polybar main &

TERMINAL="kitty"
FILEMANAGER="thunar"
BROWSER="firefox"
MENU="rofi -show drun"

xrandr --output eDP-1 --mode 1920x1080 --rate 60

bspc monitor -d 1 2 3 4 5 6 7 8 9 10
bspc config border_width         1
bspc config window_gap           8
bspc config split_ratio          0.52
bspc config borderless_monocle   true
bspc config gapless_monocle      true
bspc config focus_follows_pointer true

bspc config normal_border_color "#8b7355aa"
bspc config active_border_color "#ffd700"
EOF

chmod +x ~/.config/bspwm/bspwmrc

# SXHKD конфиг
cat > ~/.config/sxhkd/sxhkdrc << 'EOF'
super + Return
    kitty

super + F
    xfce4-terminal

super + E
    thunar

super + B
    firefox

super + R
    rofi -show drun

super + M
    pkill -KILL -u $USER

super + Q
    bspc node -c

super + {1-9,0}
    bspc desktop -f {1-9,10}

super + shift + {1-9,0}
    bspc node -d {1-9,10}

super + {Left,Down,Up,Right}
    bspc node -f {west,south,north,east}

super + alt + {Left,Down,Up,Right}
    bspc node -v {-20 0, 0 20, 0 -20, 20 0}

super + ctrl + {Left,Down,Up,Right}
    bspc node -z {left -20 0, bottom 0 20, top 0 -20, right 20 0}

super + V
    bspc node -t floating

super + P
    bspc node -p split

super + J
    bspc node -s biggest.window.local

XF86AudioRaiseVolume
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+

XF86AudioLowerVolume
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

XF86AudioMute
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

super + shift + Up
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+

super + shift + Down
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

super + shift + m
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

XF86MonBrightnessUp
    brightnessctl set +5%

XF86MonBrightnessDown
    brightnessctl set 5%-

Print
    scrot -e 'xclip -selection clipboard -t image/png -i $f'

super + button4
    bspc desktop -f next.local

super + button5
    bspc desktop -f prev.local

super + button1
    bspc node -t floating; bspc pointer -g move

super + button3
    bspc node -t floating; bspc pointer -g resize
EOF

# Polybar конфиг
cat > ~/.config/polybar/config.ini << 'EOF'
[bar/main]
width = 100%
height = 28
fixed-center = true
background = #222
foreground = #fff
padding-left = 10
padding-right = 10
module-margin = 2

font-0 = JetBrainsMono Nerd Font:size=11;2

modules-left = bspwm
modules-center = window
modules-right = xkeyboard pulseaudio cpu memory temperature battery network date

[module/bspwm]
type = internal/bspwm

[module/window]
type = custom/script
exec = ~/.config/polybar/scripts/window-title.sh
interval = 1

[module/xkeyboard]
type = internal/xkeyboard
format = "⌨ %layout%"
layout = us ru

[module/pulseaudio]
type = internal/pulseaudio
format-volume = <ramp-volume> <label-volume>
label-muted =  muted
label-volume = %percentage%%
ramp-volume-0 = 
ramp-volume-1 = 
ramp-volume-2 = 
click-left = pavucontrol

[module/cpu]
type = internal/cpu
format =  <total>%

[module/memory]
type = internal/memory
format =  <used>%

[module/temperature]
type = internal/temperature
format = <ramp> <temperature>°C
warn-temperature = 80
ramp-0 = 
ramp-1 = 
ramp-2 = 

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
format-charging =  <percentage>%
format-discharging = <ramp> <percentage>%
format-full =  <percentage>%
ramp-0 = 
ramp-1 = 
ramp-2 = 
ramp-3 = 
ramp-4 = 

[module/network]
type = internal/network
interface = auto
interval = 3
format-connected =  <signal>%
format-disconnected = ⚠

[module/date]
type = internal/date
interval = 5
format =  %Y-%m-%d %H:%M
EOF

# Скрипт window title
cat > ~/.config/polybar/scripts/window-title.sh << 'EOF'
#!/bin/bash
xprop -id $(xdotool getactivewindow) WM_NAME | cut -d '"' -f 2 | cut -c1-35
EOF

chmod +x ~/.config/polybar/scripts/window-title.sh

# Picom базовый конфиг
cat > ~/.config/picom/picom.conf << 'EOF'
backend = "glx";
vsync = true;
shadow = true;
shadow-radius = 7;
shadow-offset-x = -7;
shadow-offset-y = -7;
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
opacity-rule = [
  "100:class_g = 'rofi'",
];
blur:
{
  method = "gaussian";
  size = 10;
  deviation = 5.0;
};
EOF

# .xinitrc
cat > ~/.xinitrc << 'EOF'
#!/bin/bash
setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle"
exec bspwm
EOF

chmod +x ~/.xinitrc

echo "[5/5] Готово! Теперь можешь запускать X с помощью: startx"
