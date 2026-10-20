# Build AirSane, which shares SANE scanners on the LAN via eSCL/AirScan
FROM debian:trixie-slim AS airsane-build

ARG AIRSANE_VERSION=v0.4.15

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    make \
    g++ \
    ca-certificates \
    libsane-dev \
    libjpeg-dev \
    libpng-dev \
    libavahi-client-dev \
    libusb-1.0-0-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "$AIRSANE_VERSION" https://github.com/SimulPiscator/AirSane.git /src \
    && cmake -S /src -B /build \
    && cmake --build /build -j"$(nproc)"

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install CUPS, HPLIP, SANE, and runtime deps
RUN apt-get update && apt-get install -y \
    cups \
    cups-client \
    cups-filters \
    hplip \
    hplip-data \
    libsane-hpaio \
    sane-utils \
    libjpeg62-turbo \
    libpng16-16t64 \
    libavahi-client3 \
    libusb-1.0-0 \
    avahi-daemon \
    dbus \
    usbutils \
    ca-certificates \
    && apt-get purge -y sane-airscan \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# AirSane binary and its default config
COPY --from=airsane-build /build/airsaned /usr/local/bin/airsaned
COPY --from=airsane-build /src/etc/ /etc/airsane/

# Only load the hpaio SANE backend (from dll.d/hplip). Network backends such as
# escl/airscan (purged above) would discover AirSane's own announcement and
# export the scanner twice.
RUN : > /etc/sane.d/dll.conf

# Admin user for the web interface; password is set at startup from CUPS_ADMIN_PASSWORD
RUN useradd -r -M -G lpadmin -s /usr/sbin/nologin cupsadmin

# /etc/cups is a volume, so keep the config outside it and install it on every start
COPY cupsd.conf /usr/share/cupsd/cupsd.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Runtime directories
RUN mkdir -p /run/cups /run/dbus

# 631: CUPS, 8090: AirSane
EXPOSE 631 8090

ENTRYPOINT ["/entrypoint.sh"]
