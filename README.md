# cupsd
A custom cupsd docker image for my own setup

CUPS + HPLIP print server for a USB printer (HP Deskjet 3052A), shared on the LAN
with mDNS/AirPrint discovery via avahi running inside the container. The
printer's scanner is shared via [AirSane](https://github.com/SimulPiscator/AirSane)
(eSCL/AirScan), so it shows up automatically in GNOME Document Scanner and other
sane-airscan clients.

## Setup

```sh
cp .env.example .env    # set CUPS_ADMIN_PASSWORD
docker compose up -d --build
```

The container uses host networking, so the web interface is at
`http://<server-ip>:631`. Log in as `cupsadmin` with the password from `.env`.

## Adding the printer

```sh
docker exec cupsd lpinfo -v                     # find the printer URI (usb://HP/... or hp:/usb/...)
docker exec cupsd lpinfo -m | grep -i 3050a     # find the driver
docker exec cupsd lpadmin -p Deskjet3052A -E \
  -v '<uri>' \
  -m drv:///hpcups.drv/hp-deskjet_3050a_j611_series.ppd \
  -o printer-is-shared=true
```

Check discovery from another machine with `avahi-browse -rt _ipp._tcp`.

## Scanning

No setup is needed; AirSane picks up the scanner on start. Check it with:

```sh
docker exec cupsd scanimage -L        # should list an hpaio:/usb/... device
avahi-browse -rt _uscan._tcp          # from another machine
```

AirSane's status page is at `http://<server-ip>:8090` (LAN addresses only, see
`/etc/airsane/access.conf`).

## Notes

- `cupsd.conf` from this repo is installed on every container start, so server
  settings changed through the web interface are reset on restart. Edit
  `cupsd.conf` and rebuild instead. Printers (`printers.conf`, PPDs) live in the
  `cups-config` volume and are kept.
- If the `hp:/usb/...` URI fails with a permission error, use the `usb://` URI
  with the same hpcups driver, or install `hplip` on the host for its udev rules.
  `lsusb` is available in the container for debugging.
- If the printer was off when the container started, or the scanner disappears
  after power-cycling it, restart the container: without udev in the container,
  AirSane may miss USB hotplug events.
- Printing and scanning at the same time is not possible; HPLIP handles one job
  on the device at a time.
- If another mDNS responder runs on the host, avahi logs a warning about it;
  discovery normally still works.
