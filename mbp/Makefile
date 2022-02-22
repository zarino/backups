export BACKUPS_MBP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# `make` (called without any arguments) will run this
# target, because it is the first target in the Makefile
default: bin/backup-wrapper launchd/uk.co.zarino.backups.plist

bin/backup-wrapper: src/backup-wrapper.c
	mkdir -p bin
	gcc -Wall -o $@ $< 

launchd/uk.co.zarino.backups.plist: src/launchd-backup.template
	mkdir -p launchd
	envsubst < $< > $@

clean:
	rm -rf bin launchd

install-launch-agent:
	ln -sfn $(BACKUPS_MBP_DIR)/launchd/uk.co.zarino.backups.plist $(HOME)/Library/LaunchAgents/uk.co.zarino.backups.plist
	launchctl load $(HOME)/Library/LaunchAgents/uk.co.zarino.backups.plist

uninstall-launch-agent:
	launchctl unload $(HOME)/Library/LaunchAgents/uk.co.zarino.backups.plist
	rm -rf $(HOME)/Library/LaunchAgents/uk.co.zarino.backups.plist
