{
    description = "NixOS module for rEFInd boot loader";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    outputs = { self, nixpkgs }: {
        nixosModules.refind = import ./refind.nix;
    }
}