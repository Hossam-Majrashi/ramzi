# resources/linux

Launcher-icon integration assets and packaging metadata for the Linux build
of Ramzi itself (NOT the icons Ramzi exports for users).

| File | Used by |
| ---- | ------- |
| `com.hossam.ramzi.png` | App icon installed to `hicolor/256x256/apps/` by `build_linux.sh` (deb/rpm/Arch/AppImage/tarball) and by the Flatpak manifest. |
| `com.hossam.ramzi.desktop` | Desktop entry installed by `build_linux.sh` packages. |
| `com.hossam.ramzi.metainfo.xml` | AppStream metadata installed by `build_linux.sh` packages. |

The Flatpak package has its own self-contained copies under `/flatpak/`
(required by `flatpak-builder`), per PROJECT_NOTES.md.
