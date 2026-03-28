{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, dpkg
, openssl
, xdg-utils
, ffmpeg
, libtorrent-rasterbar
, gst_all_1
, qt6
, makeWrapper
, pipewire
}:

stdenv.mkDerivation rec {
  pname = "freedownloadmanager";
  version = "6.33.2.6656";

  src = fetchurl {
    url = "http://debrepo.freedownloadmanager.org/pool/main/f/freedownloadmanager/freedownloadmanager_6.33.2.6656_amd64.deb";
    sha256 = "sha256-n1Y6h9xXeqU6LO6h66qlnT9wsjFYqToaAPJ8sTYL9Gg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    openssl
    ffmpeg
    libtorrent-rasterbar
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    qt6.qtbase
    qt6.qtwayland
    pipewire
  ];

  # autoPatchelfHook will handle finding deps; tell it where to look
  autoPatchelfIgnoreMissingDeps = true;

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    # Install opt directory (main application)
    mkdir -p $out/opt/${pname}
    cp -r opt/${pname}/. $out/opt/${pname}/

    # Install shared data (desktop entry, icons, etc.)
    mkdir -p $out/share
    cp -r usr/share/. $out/share/

    # Fix desktop entry: icon name
    substituteInPlace $out/share/applications/freedownloadmanager.desktop \
      --replace "/opt/freedownloadmanager/icon.png" "freedownloadmanager" \
      --replace "/opt/freedownloadmanager/fdm" "$out/bin/fdm"

    # Add StartupWMClass to desktop entry
    sed -i '/^Exec=/a StartupWMClass=fdm' \
      $out/share/applications/freedownloadmanager.desktop

    # Install icon
    mkdir -p $out/share/icons/hicolor/256x256/apps
    ln -s $out/opt/${pname}/icon.png \
      $out/share/icons/hicolor/256x256/apps/${pname}.png

    # Wrapper script for the binary
    mkdir -p $out/bin
    makeWrapper $out/opt/${pname}/fdm $out/bin/fdm \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        openssl
        ffmpeg
        libtorrent-rasterbar
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        pipewire
      ]}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Powerful modern download accelerator and organizer";
    homepage = "https://www.freedownloadmanager.org/";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
