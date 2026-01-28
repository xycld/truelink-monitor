{
  description = "TrueLink Monitor - Real WiFi physical layer monitor for KDE Plasma 6";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        truelink-monitor = pkgs.stdenv.mkDerivation rec {
          pname = "plasma6-applet-truelink-monitor";
          version = "1.1.11";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            pkg-config
            kdePackages.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            # Qt6
            kdePackages.qtbase
            kdePackages.qtdeclarative

            # KDE Frameworks 6
            kdePackages.ki18n
            kdePackages.networkmanager-qt
            kdePackages.libplasma
            kdePackages.kirigami

            # Plasma
            kdePackages.plasma-workspace

            # System
            libnl
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DBUILD_TESTING=OFF"
          ];

          meta = with pkgs.lib; {
            description = "Real WiFi physical layer monitor for KDE Plasma 6 - shows RSSI dBm, PHY Rate, MCS, MIMO";
            homepage = "https://github.com/xycld/truelink-monitor";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };
      in
      {
        packages = {
          default = truelink-monitor;
          truelink-monitor = truelink-monitor;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ truelink-monitor ];
          packages = with pkgs; [
            git
          ];
        };
      }
    ) // {
      overlays.default = final: prev: {
        plasma6-applet-truelink-monitor = self.packages.${prev.system}.truelink-monitor;
      };
    };
}
