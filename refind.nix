{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.boot.loader.myrefind;

  efi = config.boot.loader.efi;

  refindBuilder = pkgs.replaceVarsWith {
    src = ./refind-builder.py;

    isExecutable = true;

    
    replacements = {
      inherit (pkgs) python3;
      inherit (pkgs) refind efibootmgr coreutils gnugrep gnused gawk util-linux gptfdisk findutils;

      inherit (efi) efiSysMountPoint canTouchEfiVariables;

      nixosVersion = config.system.nixos.version;
      kernelVersion = config.boot.kernelPackages.kernel.version;

      nix = config.nix.package.out;

      timeout = if config.boot.loader.timeout != null then config.boot.loader.timeout else "";

      extraConfig = cfg.extraConfig;

      maxEntries = cfg.maxGenerations;

      extraIcons = if cfg.extraIcons != null then cfg.extraIcons else "";

      themes = if cfg.themes != null then cfg.themes else "[]";
    };

  };

in {

  options.boot.loader.myrefind = {
    enable = mkOption {
      default = false;
      type = types.bool;
      description = "Whether to enable the refind EFI boot manager";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration text appended to refind.conf";
    };

    maxGenerations = mkOption {
      type = types.int;
      default = 100;
      description = "Maximum number of generations in submenu. This is to avoid problems with refind or possible size problems with the config";
    };

    extraIcons = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "A directory containing icons to be copied to 'extra-icons'";
    };
    
    themes = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "A list of theme paths to copy";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ refind gptfdisk findutils ];
    assertions = [
      {
        assertion = (config.boot.kernelPackages.kernel.features or { efiBootStub = true; }) ? efiBootStub;

        message = "This kernel does not support the EFI boot stub";
      }
    ];

    boot.loader.grub.enable = mkDefault false;

    # boot.loader.supportsInitrdSecrets = false; # TODO what does this do ?

    system = {
      build.installBootLoader = refindBuilder;

      boot.loader.id = "refind";

      requiredKernelConfig = with config.lib.kernelConfig; [
        (isYes "EFI_STUB")
      ];
    };
  };

}
