{
  stdenv,
  lib,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  libsoup_3,
  glib,
  gnome,
  gssdp-tools,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  buildPackages,
  gobject-introspection,
  gi-docgen,
  vala,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gssdp";
  version = "1.6.4";

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals withIntrospection [ "devdoc" ];

  src = fetchurl {
    url = "mirror://gnome/sources/gssdp/${lib.versions.majorMinor finalAttrs.version}/gssdp-${finalAttrs.version}.tar.xz";
    hash = "sha256-/5f9+39WHT5oE7T2ohRSWefC7/Q8wOY/P9Ax0LYmYDI=";
  };

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    glib
  ] ++ lib.optionals withIntrospection [
    gobject-introspection
    gi-docgen
    vala
  ];

  buildInputs = [
    libsoup_3
  ];

  propagatedBuildInputs = [
    glib
  ];

  mesonFlags = [
    (lib.mesonBool "gtk_doc" withIntrospection)
    "-Dsniffer=false"
    # This packages only has manpages for gssdp-device-sniffer, which we disabled above.
    "-Dmanpages=false"
    (lib.mesonBool "introspection" withIntrospection)
    (lib.mesonBool "vapi" withIntrospection)
  ];

  # On Darwin: Failed to bind socket, Operation not permitted
  doCheck = !stdenv.hostPlatform.isDarwin;

  postFixup = ''
    # Move developer documentation to devdoc output.
    if [ "${lib.boolToString withIntrospection}" == "true" ]; then
      # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
      find -L "$out/share/doc" -type f -regex '.*\.devhelp2?' -print0 \
        | while IFS= read -r -d ''' file; do
          moveToOutput "$(dirname "''${file/"$out/"/}")" "$devdoc"
      done
    fi
  '';

  passthru = {
    updateScript = gnome.updateScript {
      attrPath = "gssdp_1_6";
      packageName = "gssdp";
    };

    tests = {
      inherit gssdp-tools;
    };
  };

  meta = {
    description = "GObject-based API for handling resource discovery and announcement over SSDP";
    homepage = "http://www.gupnp.org/";
    license = lib.licenses.lgpl2Plus;
    teams = [ lib.teams.gnome ];
    platforms = lib.platforms.all;
  };
})
