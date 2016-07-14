## Usage
```bash
docker run --name=ampache -d -v /path/to/your/music:/media:ro -p 80:80 ampache/ampache
```

## Installation
- MySQL Administrative Username: root # leave alone
- MySQL Administrative Password:      # (blank) leave alone
- Check "Create Database User"
- Ampache Database Username: ampache
- Ampache Database User Password: ampache # or whatever you want, but remember it on the next page
- next page fill out MySQL Username / Password
- Click the "Write" buttons from BOTTOM to TOP
- Do this because it is the last one that needs the username and password and they get blanked out on every click

## Other Features
 - gd for php (this was missing from main branch)
 - ampache defaults (install.lib.php)
 - avconv for transcoding

## Volumes
These are all optional.
 - /etc/mysql -- mysql config
 - /var/lib/mysql -- mysql database
 - /media -- music, videos, etc.
 - /var/www/config -- ampache config
 - /var/www/themes -- ampache themes