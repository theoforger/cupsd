FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install CUPS, HPLIP, and runtime deps
RUN apt-get update && apt-get install -y \
    cups \
    cups-client \
    cups-filters \
    hplip \
    hplip-data \
    avahi-daemon \
    dbus \
    usbutils \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Admin user for the web interface; password is set at startup from CUPS_ADMIN_PASSWORD
RUN useradd -r -M -G lpadmin -s /usr/sbin/nologin cupsadmin

# /etc/cups is a volume, so keep the config outside it and install it on every start
COPY cupsd.conf /usr/share/cupsd/cupsd.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Runtime directories
RUN mkdir -p /run/cups /run/dbus

EXPOSE 631

ENTRYPOINT ["/entrypoint.sh"]
