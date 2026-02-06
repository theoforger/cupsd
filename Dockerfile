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

# Configure CUPS for remote access
RUN sed -i 's/^Listen .*/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\
  Order allow,deny\
  Allow all/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\
  Order allow,deny\
  Allow all/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\
  Order allow,deny\
  Allow all/' /etc/cups/cupsd.conf

# Runtime directories
RUN mkdir -p /run/cups /run/dbus

EXPOSE 631

# Start dbus, avahi, and keep CUPS in foreground
CMD dbus-daemon --system && \
    avahi-daemon --daemonize --no-chroot && \
    cupsd -f
