#!/bin/sh
set -e

# Install the image's cupsd.conf over the copy in the /etc/cups volume
install -m 640 -o root -g lp /usr/share/cupsd/cupsd.conf /etc/cups/cupsd.conf

# Set the web interface admin password
if [ -n "$CUPS_ADMIN_PASSWORD" ]; then
    echo "cupsadmin:$CUPS_ADMIN_PASSWORD" | chpasswd
fi

# Remove pid files left over from a previous run of this container
rm -f /run/dbus/pid /run/avahi-daemon/pid

# Start dbus and avahi for printer discovery on the LAN
dbus-uuidgen --ensure
dbus-daemon --system
avahi-daemon --daemonize --no-chroot

# Share the scanner via AirSane, restarting it if it exits. Runs as root
# because there is no udev in the container to grant the saned user USB access.
(
    while :; do
        airsaned --hotplug=true --local-scanners-only=true
        echo "airsaned exited, restarting in 5s" >&2
        sleep 5
    done
) &

# Keep CUPS in the foreground as PID 1 so it receives stop signals
exec cupsd -f
