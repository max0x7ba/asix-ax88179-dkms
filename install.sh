#!/usr/bin/env bash
#
#  ASIX AX88179 DKMS driver installation program
#  Copyright (C) 2024 by Florian LAUNAY
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

set -euo pipefail # Terminate on errors.

readonly pkgname="asix-ax88179"
readonly archiveurl="https://www.asix.com.tw/en/support/download/file/2150"
readonly drvname="ax_usb_nic"

error() {
  local cR="\e[91m" cD="\e[0m"
  printf "${cR}Error:${cD} %s\n" "$1" >&2
  exit 1
}

# An existing tarball can be specified as the last argument. E.g.:
#   cd ~/src/asix-ax88179-dkms/ && sudo ./install.sh ~/Downloads/ASIX_USB_NIC_Linux_Driver_Source_v4.1.0.tar.bz2
#   cd ~/src/asix-ax88179-dkms/ && sudo ./install.sh -u ~/Downloads/ASIX_USB_NIC_Linux_Driver_Source_v4.1.0.tar.bz2
#   cd ~/src/asix-ax88179-dkms-max0x7ba/ && sudo ./install.sh ~/Downloads/ASIX_USB_NIC_Linux_Driver_Source_v4.1.0.tar.bz2
readonly argv=("$0" "$@")
readonly last_arg="${argv[-1]}"
[[ "$last_arg" != *.tar.bz2 ]] || readonly tarball="$last_arg"

if [[ -v tarball ]]; then
  [[ -s "$tarball" && "$tarball" =~ ([^/]+_v([^.]+\.[^.]+\.[^.]+)\.tar\.bz2)$ ]] || error "Invalid value: $tarball"
  readonly pkgver="${BASH_REMATCH[2]}"
  readonly archivename="${BASH_REMATCH[1]}"
else
  readonly pkgver="$(git describe --tags 2> /dev/null || error 'No tag found')"
  readonly archivename="ASIX_USB_NIC_Linux_Driver_Source_v${pkgver}"
fi
[[ "$pkgver" ]] || error "Invalid value: pkgver=$pkgver"

readonly srcdir="/usr/src/${pkgname}-${pkgver}"
readonly log="/var/lib/dkms/${pkgname}/${pkgver}/build/make.log"

usage() {
  cat <<EOF
Usage: $0 [options] [<path-to-source-tarball>]

Options:
  -h  Display usage and exit
  -u  Uninstall

Example:
  to install: $0
  to install from a tarball: $0 <path-to-source-tarball>
  to uninstall: $0 -u

EOF
}

build() {
  untar || error "Download error"

  echo "Configuring DKMS..."
  install -D -m 644 dkms.conf "${srcdir}/dkms.conf"
  sed -i "s/#PKGNAME#/${pkgname}/" "${srcdir}/dkms.conf"
  sed -i "s/#PKGVER#/${pkgver}/" "${srcdir}/dkms.conf"
  sed -i "s/#DRVNAME#/${drvname}/" "${srcdir}/dkms.conf"
  echo -e "Done\n"

  echo "Building with DKMS..."
  if dkms install -m "${pkgname}" -v "${pkgver}"; then
    echo -e "Done\n"

    echo "Configuring driver..."
    install -D -m 644 udev.rules "/etc/udev/rules.d/90-${pkgname}.rules"
    install -D -m 644 modprobe-blacklist.conf "/etc/modprobe.d/${pkgname}.conf"
    modprobe -r ax88179_178a
    udevadm control --reload-rules && udevadm trigger
    echo "Done"
  else
    cat "$log" || :
    error "Build error"
  fi
}

uninstall() {
  set +e # Ignore errors here.

  local status="$(dkms status ${pkgname})"
  [[ "$status" ]] || error "Driver ${pkgname} is not installed!"

  echo "Uninstalling driver ${pkgname} version ${pkgver}..."
  modprobe -r "${drvname}"
  dkms remove -m "${pkgname}" -v "${pkgver}"
  rm -rf "${srcdir}"
  rm -f "/etc/udev/rules.d/90-${pkgname}.rules"
  rm -f "/etc/modprobe.d/${pkgname}.conf"
  modprobe ax88179_178a
  udevadm control --reload-rules && udevadm trigger
  echo "Done"
}

untar() {
  mkdir -p "${srcdir}"
  local -r tar_cmd=(tar -x -C "${srcdir}" --no-same-owner --transform "s/${archivename}/./g")
  if [[ -v tarball ]]; then
    echo "Unpacking source tarball $tarball ..."
    "${tar_cmd[@]}" -f "$tarball"
  else
    echo "Downloading and unpacking source tarball from $archiveurl ..."
    wget -q --show-progress -O - "${archiveurl}" | "${tar_cmd[@]}" -j
  fi
}

while getopts 'hu' opt; do
  case "${opt}" in
    h) usage; exit 0;;
    u) uninstall; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

build

# vim: set sw=2 sts=2 et :
