{
  stdenv,
  lib,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  glib,
  gssdp_1_6,
  libsoup_3,
  libxml2,
  gnome,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  buildPackages,
  gi-docgen,
  gobject-introspection,
  vala,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gupnp";
  version = "1.6.9";

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals withIntrospection [ "devdoc" ];

  src = fetchurl {
    url = "mirror://gnome/sources/gupnp/${lib.versions.majorMinor finalAttrs.version}/gupnp-${finalAttrs.version}.tar.xz";
    hash = "sha256-Lttu42E1WOYvU4c1NoruJxUbfgnU4uLFFgaDPagBhps=";
  };

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ] ++ lib.optionals withIntrospection [
    gobject-introspection
    gi-docgen
    vala
  ];

  propagatedBuildInputs = [
    glib
    gssdp_1_6
    libsoup_3
    libxml2
  ];

  mesonFlags = [
    (lib.mesonBool "gtk_doc" withIntrospection)
    (lib.mesonBool "introspection" withIntrospection)
    (lib.mesonBool "vapi" withIntrospection)
  ];

  # On Darwin: Failed to bind socket, Operation not permitted
  doCheck = !stdenv.hostPlatform.isDarwin;

  postFixup = ''
    # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
    if [ "${lib.boolToString withIntrospection}" == "true" ]; then
      moveToOutput "share/doc" "$devdoc"
    fi
  '';

  passthru = {
    updateScript = gnome.updateScript {
      attrPath = "gupnp_1_6";
      packageName = "gupnp";
    };
  };

  meta = {
    homepage = "http://www.gupnp.org/";
    description = "Implementation of the UPnP specification";
    mainProgram = "gupnp-binding-tool-1.6";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
