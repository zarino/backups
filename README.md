# zarino/backups

Automated restic backups, to Backblaze B2, from my Mac and Pop_OS PC.

## macOS

### Installing

Install restic 0.9.2 or higher: (0.9.2 supports non-master Backblaze keys.)

    brew install restic
    restic version

Check out this repo somewhere (eg: `/Users/zarinozappia/backups`) and then go into the `mbp` directory:

    cd /Users/zarinozappia
    git clone https://github.com/zarino/backups.git
    cd backups/mbp

Copy `example-env.conf` and fill in the required variables:

    cp example-env.conf env.conf
    nano env.conf

Since the backup script doesn’t have access to your default shell environment, it won’t know where to find the `restic` command. This is why the `env.conf` file contains a `RESTIC_BINARY` setting. You’ll want to set this to the output of `which restic` in your default shell.

Run the `init` script to create the remote restic repository:

    script/init

(If this works, you’ll see a message like `created restic repository [blah] at [blah]`. If it fails with `Fatal: create repository at [blah] failed: config already exists` don’t panic – that just means the remote repository has already been created, you’ll all set!)

Compile the launchd launch agent and backup-wrapper binary, using `make`:

    make

Grant Full Disk Access permissions to the `bin/backup-wrapper` binary, via `System Preferences > Security & Privacy > Privacy > Full Disk Access`.

Install and load the compiled launch agent:

    make install-launch-agent

Your first backup will begin immediately (and will take a very, very long time).

### Updating

    cd <whatever>/backups/mbp
    git pull
    make
    make install-launch-agent

If the `bin/backup-wrapper` binary has been updated, you will need to re-grant it Full Disk Access permissions, via `System Preferences > Security & Privacy > Privacy > Full Disk Access`.

### Checking on status

The launch agent directs script output and errors to files in `~/Library/Logs/uk.co.zarino.backups/`. A copy of all script output is _also_ saved into a new file per day, in the `mbp/logs` directory.

The process ID of current backups/maintenances, and the timestamp after which the next backup/maintenance will be performed, are stored in the `mbp/cache` directory. Removing the timestamp files from this directory will force a backup/maintenance to run the next time the launch agent runs.

You can see when a backup/maintenance will next happen with the `script/next` shortcut:

    mbp/script/next

You can see information about the launch agent with the hilariously user-unfriendly command:

    launchctl print gui/$(id -u)/uk.co.zarino.backups

To check the state of the restic repo, use the restic wrapper script, eg:

    mbp/script/restic snapshots
    mbp/script/restic stats

### Manually starting a backup

Backup and maintenance runs at most every 300 seconds, as long as the computer is connected to a power source.

If you want to run it manually, you can:

    launchctl kickstart gui/$(id -u)/uk.co.zarino.backups

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

If the remote restic repo at `$RESTIC_REPOSITORY` hasn’t been created yet, you can run the `init` script to create it: (This command will fail if the repo has already been initialised, which is fine.)

    pop/script/init

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

    pop/script/restic snapshots

## Restoring files from backup

Assuming you have suitable `env.conf` files in place, you can use both the `mbp/script/restic` and `pop/script/restic` command wrappers to access either of the remote repositories, from any device.

To view snapshots:

    pop/script/restic snapshots

To restore an entire directory tree (or indeed, multiple directories) into place, you can use `restore`. For example, this command restores the latest version of two directories into which Cities Skylines content is saved:

    pop/script/restic restore latest --target / --include '/home/zarino/.local/share/Colossal Order' --include '/home/zarino/.local/share/Paradox Interactive'

To pluck a single file or directory (as a .tar) from the backup, you can use `dump`. For example, this command, run from my Mac, pulled the latest copy of my Pop_OS PC’s bash history, into a text file on my Desktop:

    pop/script/restic dump latest '/home/zarino/.bash_history' > ~/Desktop/bash_history.txt

## Troubleshooting

If a restic command ever fails with an exception like:

> unable to create lock in backend: repository is already locked by PID…

And you’re sure there are no restic processes running, then you can clear the orphaned lock file with:

    script/restic unlock
