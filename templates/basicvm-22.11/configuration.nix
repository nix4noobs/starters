{ inputs, ... }:
{ pkgs, ... }: {
  # variable pertaining to package defaults.
  # generally, never CHANGE after initial setup.
  # @ initial setup, set it to match the release you're tracking (e.g. nixos-22.11 => 22.11)
  system.stateVersion = "22.11";

  nix = {
    # enable new CLI and flake support
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # allow logging into `root` without a password
  users.users.root.initialHashedPassword = "";

  # install user `nixusr`
  users.users.nixusr = {
    isNormalUser = true;
    home = "/home/nixusr";
    description = "nixusr user";
    extraGroups = [ "wheel" ];
    uid = 1000;
    # `mkpasswd -m sha-512` | default: nix4noobs
    hashedPassword =
      "$6$bIj/yHEKrsB4GIg9$SW2OHgWTvoC5AVlENwhWkBY7tF6SSG8z6cT/bSEuyw2Jy7U2qui1isCQjeDd.ti94FI..DyKExk/FCR0FpyEO/";
    openssh.authorizedKeys.keys = [ "ssh-rsa ..." ];
  };

  # configure OpenSSH service
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # extra software to install
  environment.systemPackages = [
    pkgs.fortune
    # inputs.<flake ref>.packages.${pkgs.system}.<pkg>
  ];
}
