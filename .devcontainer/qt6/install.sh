#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/qt6.md
# Maintainer: The VS Code and Codespaces Teams

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

# User options
VERSION=${VERSION:-"6.8.0"}
HOST=${HOST:-"linux"}
TARGET=${TARGET:-"desktop"}
ARCH=${ARCH:-"linux_gcc_64"}
INSTALL_DIR="${INSTALLDIR:-"/opt"}/Qt"
USERNAME="${USERNAME:-"${_REMOTE_USER}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# Support modules
if [ ${#MODULES[@]} -gt 0 ]
then
    QT_MODULES=$(echo ${MODULES[*]} | tr ',' ' ')
    QT_MODULES_FLAG="-m"
    echo "(*) Modules: ${QT_MODULES}"
fi

# Runs apt-get update if needed.
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]
    then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not.
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1
    then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Update shell config (if enabled).
updaterc() {
    if [ "${UPDATE_RC}" = "true" ]
    then
        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]
        then
            echo "Updating /etc/bash.bashrc..."
            echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]
        then
            echo "Updating /etc/zsh/zshrc..."
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

fetch_and_install_web_qpa() {
    if [ "$#" -ne 1 ]
    then
        echo "Usage: fetch_and_install_web_qpa <qt-version>"
        return 2
    fi

    architecture="$(uname -m)"
    if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ]
    then
        echo "(!) Architecture $architecture unsupported"
        return 1
    fi

    local requested_version="$1"
    local install_dir="/opt/qtwebplugin"
    local release_json
    local asset_name
    local asset_url

    # Qt versions are expected to look like "6.8", "6.9", "6.10", etc.
    if [[ ! "$requested_version" =~ ^6\.[0-9]+$ ]]
    then
        echo "Invalid Qt version: '$requested_version'"
        echo "Expected a version such as 6.8 or 6.10"
        return 2
    fi

    # Get the latest release.
    release_json="$(curl --fail --silent --show-error --location --header 'Accept: application/vnd.github+json' "https://api.github.com/repos/Symbitic/qtwebplugin/releases/latest")"
    if [ $? -ne 0 ]
    then
        echo "Failed to retrieve the latest qtwebplugin release."
        return 1
    fi

    # First try to find an exact Qt-version match.
    asset_name="$(
        jq -r --arg version "$requested_version" '
            .assets[]
            | select(.name | test("^libqweb-" + ($version | gsub("\\."; "\\.")) + "\\.so$"))
            | .name
        ' <<< "$release_json" | head -n1
    )"

    # If there is no exact match, select the highest available Qt 6 version.
    if [ -z "$asset_name" ]
    then
        asset_name="$(
            jq -r '
                [
                    .assets[]
                    | select(.name | test("^libqweb-6\\.[0-9]+\\.so$"))
                    | .name
                ]
                | sort_by(
                    capture("^libqweb-(?<major>[0-9]+)\\.(?<minor>[0-9]+)\\.so$")
                    | (.major | tonumber) * 1000 + (.minor | tonumber)
                )
                | last
            ' <<< "$release_json"
        )"
    fi

    if [ -z "$asset_name" ] || [ "$asset_name" = "null" ]
    then
        echo "No compatible libqweb platform plugin was found in the latest release."
        return 1
    fi

    asset_url="$(
        jq -r --arg name "$asset_name" '
            .assets[]
            | select(.name == $name)
            | .browser_download_url
        ' <<< "$release_json"
    )"

    if [ -z "$asset_url" ] || [ "$asset_url" = "null" ]
    then
        echo "Could not determine download URL for $asset_name." >&2
        return 1
    fi

    mkdir -p "$install_dir"

    curl --fail --silent --show-error --location "$asset_url" -o "${install_dir}/libqweb.so.tmp"
    if [ $? -ne 0 ]
    then
        rm -f "${install_dir}/libqweb.so.tmp"
        echo "Failed to download $asset_name"
        return 1
    fi

    install -m 0755 "${install_dir}/libqweb.so.tmp" "${install_dir}/libqweb.so"
    if [ $? -ne 0 ]
    then
        rm -f "${install_dir}/libqweb.so.tmp"
        echo "Failed to install libqweb.so"
        return 1
    fi

    rm -f "${install_dir}/libqweb.so.tmp"

    echo "Installed ${install_dir}/libqweb.so"
}

echo "(*) Installing Qt6..."

export DEBIAN_FRONTEND=noninteractive
export QT_ROOT_DIR=${INSTALL_DIR}/${VERSION}/${ARCH/${HOST}_}
export QT_PLUGIN_PATH=${QT_ROOT_DIR}/plugins
export QML2_IMPORT_PATH=${QT_ROOT_DIR}/qml
export PATH=${QT_ROOT_DIR}/bin:${PATH}

if [ -z "${LD_LIBRARY_PATH}" ]
then
  export LD_LIBRARY_PATH="${QT_ROOT_DIR}/lib"
else
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${QT_ROOT_DIR}/lib"
fi

if [ "$(id -u)" -ne 0 ]
then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ -z "${USERNAME}" ]
then
    echo -e 'Feature script must be executed by a tool that implements the dev container specification. See https://containers.dev/ for more information.'
    exit 1
fi

# Install dependencies
check_packages curl ca-certificates gnupg2 dirmngr unzip build-essential cmake clang-format \
    libgl1-mesa-dev libgstreamer-gl1.0-0 libpulse-dev libxcb-glx0 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-shm0 \
    libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xinerama0 libxcb1 libxkbcommon-dev \
    libxkbcommon-x11-0 libxcb-xkb-dev libxcb-cursor0 python3 python3-pip pipx ninja-build \
    libfontconfig1 libfreetype6 libvulkan-dev jq

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Setup pipx
pipx ensurepath
if (( $? > 0 ))
then
    echo "'pipx ensurepath' failed"
    exit 1
fi

# Ensure pipx binaries are in PATH
export PATH=${PATH}:/root/.local/bin

# Install aqtinstall
pipx install aqtinstall
if (( $? > 0 ))
then
    echo "Failed to install aqtinstall"
    exit 1
fi

# Install
echo "(*) Installing Qt6..."
echo aqt install-qt ${HOST} ${TARGET} ${VERSION} ${ARCH} --outputdir "${INSTALL_DIR}" ${QT_MODULES_FLAG} ${QT_MODULES}
aqt install-qt ${HOST} ${TARGET} ${VERSION} ${ARCH} --outputdir "${INSTALL_DIR}" ${QT_MODULES_FLAG} ${QT_MODULES}
if (( $? > 0 ))
then
    echo "Failed to install Qt"
    exit 1
fi

# Add Qt directories into bash/zsh config files (unless disabled)
updaterc "$(cat << EOF
export QT_ROOT_DIR="${QT_ROOT_DIR}"
export QT_PLUGIN_PATH="\${QT_ROOT_DIR}/plugins"
export QML2_IMPORT_PATH="\${QT_ROOT_DIR}/qml"

if [[ "\${PATH}" != *"\${QT_ROOT_DIR}/bin"* ]]
then
    export PATH="\${QT_ROOT_DIR}/bin:\${PATH}"
fi

if [[ -z "\${LD_LIBRARY_PATH}" ]]
then
  export LD_LIBRARY_PATH="\${QT_ROOT_DIR}/lib"
else
  export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH}:\${QT_ROOT_DIR}/lib"
fi

EOF
)"

echo "(*) Installing Qt Web QPA plugin..."
fetch_and_install_web_qpa ${VERSION}

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"