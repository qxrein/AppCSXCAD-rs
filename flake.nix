{
  description = "AppCSXCAD rewritten in Rust using wgpu and gpui";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        devDependencies = with pkgs; [
          vulkan-headers
          vulkan-loader
          vulkan-tools
          vulkan-validation-layers
          
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXinerama
          xorg.libXi
          xorg.libXxf86vm

          wayland
          wayland-protocols

          alsa-lib
          pulseaudio
          
          pkg-config
          cmake

          clang
          llvmPackages.libclang

          gdb
          lldb

          rustfmt
          clippy
        ];

        runtimeDependencies = with pkgs; [
          vulkan-loader
          vulkan-tools

          alsa-lib
          pulseaudio

          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXinerama
          xorg.libXi
          xorg.libXxf86vm
          
          wayland
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = devDependencies;
          
          nativeBuildInputs = [ rustToolchain ];

          shellHook = ''
            export RUST_SRC_PATH="${rustToolchain}/lib/rustlib/src/rust/library"
            export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
            export PKG_CONFIG_PATH="${pkgs.vulkan-headers}/lib/pkgconfig:$PKG_CONFIG_PATH"
            
            # Set up Vulkan environment
            export VULKAN_SDK="${pkgs.vulkan-headers}"
            export VK_LAYER_PATH="${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d"
            
            # Set up X11 environment
            export XDG_DATA_DIRS="${pkgs.xorg.libX11}/share:$XDG_DATA_DIRS"
            
            echo "AppCSXCAD Rust development environment loaded!"
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
          '';
        };

        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "appcsxcad-rs";
          version = "0.1.0";
          
          src = ./.;
          
          cargoLock.lockFile = ./Cargo.lock;
          
          buildInputs = runtimeDependencies;
          
          nativeBuildInputs = with pkgs; [
            pkg-config
            cmake
            rustToolchain
          ];

          buildPhase = ''
            runHook preBuild
            cargo build --release
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp target/release/appcsxcad-rs $out/bin/
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "AppCSXCAD rewritten in Rust using wgpu and gpui";
            homepage = "https://github.com/yourusername/AppCSXCAD-rs";
            license = licenses.mit;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };

        apps = {
          run = {
            type = "app";
            program = toString (pkgs.writeShellScript "run-appcsxcad" ''
              cargo run
            '');
          };

          build = {
            type = "app";
            program = toString (pkgs.writeShellScript "build-appcsxcad" ''
              cargo build --release
            '');
          };

          test = {
            type = "app";
            program = toString (pkgs.writeShellScript "test-appcsxcad" ''
              cargo test
            '');
          };

          fmt = {
            type = "app";
            program = toString (pkgs.writeShellScript "fmt-appcsxcad" ''
              cargo fmt
            '');
          };

          clippy = {
            type = "app";
            program = toString (pkgs.writeShellScript "clippy-appcsxcad" ''
              cargo clippy
            '');
          };
        };
      }
    );
} 