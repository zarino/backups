# zarino/backups

Automated restic backups, to Backblaze B2, from my Mac and Pop_OS PC.

## Pop_OS

### Installing

Install restic 0.9.2 or higher: (0.9.2 supports non-master Backblaze keys.)

    sudo apt-get install restic
    restic version

Check out this repo at `/home/zarino/backups`:

    cd /home/zarino
    git clone https://github.com/zarino/backups.git
    cd backups

Copy `pop/example-env.conf` and fill in the required variables:

    cp pop/example-env.conf pop/env.conf
    nano pop/env.conf

If the remote restic repo at `$RESTIC_REPOSITORY` hasn’t been created yet, you can run the `init.sh` script to create it: (This command will fail if the repo has already been initialised, which is fine.)

    pop/init.sh

Install the systemd units and timers:

    mkdir -p /home/zarino/.config/systemd/user
    ln -s {/home/zarino/backups/pop/systemd,/home/zarino/.config/systemd/user}/restic-backup.service
    ln -s {/home/zarino/backups/pop/systemd,/home/zarino/.config/systemd/user}/restic-backup.timer
    ln -s {/home/zarino/backups/pop/systemd,/home/zarino/.config/systemd/user}/restic-maintain.service
    ln -s {/home/zarino/backups/pop/systemd,/home/zarino/.config/systemd/user}/restic-maintain.timer

Enable the systemd timers:

    systemctl --user daemon-reload
    systemctl --user enable restic-backup.timer restic-maintain.timer

And test out the systemd timers by starting them off, and watching the status:

    systemctl --user start restic-backup.timer restic-maintain.timer
    watch -n 1 systemctl --user list-timers --all

### Updating

    cd /home/zarino/backups
    git pull
    systemctl --user daemon-reload

### Checking on status

To check the status of the systemd timers:

    systemctl --user list-timers --all

To check the status of a systemd unit:

    systemctl --user status restic-backup
    systemctl --user status restic-maintain

To read the log for a systemd unit:

    journalctl --user -u restic-backup.service -f
    journalctl --user -u restic-maintain.service -f

To check the state of the restic repo:

    pop/restic.sh snapshots
