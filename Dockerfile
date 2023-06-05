FROM debian:bullseye-slim

ARG DEBIAN_VERSION=bullseye \
    WINE_BRANCH=stable \
    WINE_VERSION=8.0.1 \
    PYTHON_VERSION=3.10.11

ENV WINEPREFIX=/opt/wineprefix \
    WINEARCH=win64 \
    WINEPATH="C:\python;C:\python\Scripts;C:\mingw64\bin;C:\mingw64\x86_64-w64-mingw32\bin;C:\ccache"

RUN \
    # Enable x86 & Update & Upgrade
    dpkg --add-architecture i386 && apt-get update -y && apt-get upgrade -y && \
    # Install required apt packages
    apt-get install -y xvfb cabextract wget unzip && \
    # Add wine repository
    mkdir -pm755 /etc/apt/keyrings && \
    wget -q \
    --output-document=/etc/apt/keyrings/winehq-archive.key \
    https://dl.winehq.org/wine-builds/winehq.key && \
    wget -q \
    --directory-prefix=/etc/apt/sources.list.d/ \
    https://dl.winehq.org/wine-builds/debian/dists/${DEBIAN_VERSION}/winehq-${DEBIAN_VERSION}.sources && \
    apt-get update -y && \
    # Install wine
    apt-get install -y --no-install-recommends \
    winehq-stable=${WINE_VERSION}~${DEBIAN_VERSION}-1 \
    wine-stable=${WINE_VERSION}~${DEBIAN_VERSION}-1 \
    wine-stable-amd64=${WINE_VERSION}~${DEBIAN_VERSION}-1 \
    wine-stable-i386=${WINE_VERSION}~${DEBIAN_VERSION}-1 && \
    # Install winetricks
    wget -q \
    --output-document=/usr/local/bin/winetricks \
    https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks && \
    # Setup dummy display
    { echo '#!/bin/bash'; echo 'rm -f /tmp/.X99-lock && xvfb-run $@'; } > /usr/local/bin/xdummy && \
    chmod +x /usr/local/bin/xdummy && \
    # Setup wine
    mkdir -p ${WINEPREFIX} && \
    wineboot && \
    xdummy winetricks -q win10 arch=64 mfc42 && \
    # Install Python3
    wget -q \
    --output-document=/tmp/python-installer.exe \
    https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.exe && \
    xdummy wine /tmp/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir="C:\python" && \
    # Install MinGW64
    wget -q \
    --output-document=/tmp/mingw64.zip \
    https://github.com/brechtsanders/winlibs_mingw/releases/download/13.1.0posix-16.0.3-11.0.0-msvcrt-r1/winlibs-x86_64-posix-seh-gcc-13.1.0-llvm-16.0.3-mingw-w64msvcrt-11.0.0-r1.zip && \
    unzip -d ${WINEPREFIX}/drive_c/mingw64 /tmp/mingw64.zip && \
    # Install ccache
    wget -q \
    --output-document=/tmp/ccache.zip \
    https://github.com/ccache/ccache/releases/download/v4.8.1/ccache-4.8.1-windows-x86_64.zip && \
    unzip -d /tmp /tmp/ccache.zip && \
    mv $(find /tmp/ccache-*-windows-x86_64 | head -n 1) ${WINEPREFIX}/drive_c/ccache && \
    # Install dependency walker
    DEPENDENCY_WALKER_INSTALL_DIR="${WINEPREFIX}/drive_c/users/root/AppData/Local/Nuitka/Nuitka/Cache/downloads/depends/x86_64" && \
    wget -q \
    --output-document=/tmp/depends.zip \
    https://dependencywalker.com/depends22_x86.zip && \
    mkdir -p "${DEPENDENCY_WALKER_INSTALL_DIR}" && \
    unzip -d "${DEPENDENCY_WALKER_INSTALL_DIR}" /tmp/depends.zip && \
    # Install pip dependencies
    wine python -m pip install nuitka zstandard poetry && \
    # Cleanup
    apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove && \
    rm -rf /tmp/* && \
    wineboot --update

# Build sample code
WORKDIR /sample
RUN echo 'print("Hello, World!")' > ./sample.py && \
    wine python -m nuitka \
    ./sample.py \
    --mingw64 \
    --onefile \
    --standalone \
    --follow-stdlib \
    --follow-imports \
    --static-libpython=no \
    --output-filename=sample.exe \
    --remove-output && \
    wine ./sample.exe && \
    rm -rf /sample

WORKDIR ${WINEPREFIX}/drive_c/users/root
