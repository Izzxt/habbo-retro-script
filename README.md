# Unofficial Habbo Retro Installation Script

Installing Habbo Retro Script in just a few minutes! <br />

```sh
git clone https://github.com/Izzxt/habbo-retro-script.git
```
```sh
cd habbo-retro-script
```
```sh
./install.sh
```

**TIP** : if you choose to install Cosmic CMS or Nitro only, you have to move the plugins manually.
```
[1] Install CMS
[2] Install Nitro
[3] Install Morningstar Emulator
[4] Install CMS / Nitro / Arcturus Emulator
```
**Cosmic Webkit plugins**
```sh
cd habbo-retro-script/Webkit.jar
```
**Nitro Websockets plugins**
* https://git.krews.org/nitro/ms-websockets/-/releases

**Run emulator**
```sh
# Enable emulator service
sudo systemctl enable arcturus

# Start emulator service
sudo systemctl start arcturus

# Stop emulator service
sudo systemctl stop arcturus

# Check status emulator service
sudo systemctl status arcturus

# Restart emulator service
sudo systemctl restart arcturus

# Check emulator log
sudo tail -f /var/log/emulator.log
```

**Folder location**
```sh
# CMS Folder
cd /var/www/<domain name here>

# Nitro Folder
cd /var/www/<domain name here>

# Emulator Folder
cd /srv/Arcturus
```

# Supported CMS
| CMS                | Supported           |
| -----------------  | ------------------- |
| Cosmic             | :heavy_check_mark:  |
| Instinct Dev       | :x:                 |

# Supported Web Server
| Web Server        | Supported            |
| ----------------- | -------------------- |
| Nginx             | :heavy_check_mark:   |
| Apache2           | :x:                  |

# Supported Operating System
| Operating System  | Version | Supported            |
| ----------------- | ------- | -------------------- |
| Ubuntu            | 22.04   | Not Tested           |
| Ubuntu            | 21.04   | Not Tested           |
| Ubuntu            | 20.04   | :heavy_check_mark:   |

# Credits

### Nitro (Game Engine)
https://git.krews.org/nitro/nitro-react

### Oshawott (for assets)
https://git.krews.org/oshawott/nitro-assets

### Arcturus Emulator
https://git.krews.org/morningstar/Arcturus-Community

### Discord : Izzat#0333
