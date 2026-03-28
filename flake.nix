{
  description = "freedownloadmanager-nixpkg";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }: 
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = { allowUnfree = true; };
      };
    in
    {
      packages.x86_64-linux.freedownloadmanager = 
        pkgs.callPackage ./package.nix { };
    };
}
