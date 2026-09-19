{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include OrbStack SSH config
    includes = [ "~/.orbstack/ssh/config" ];

    # Common SSH configurations
    settings = {
      # Default settings for all hosts
      "*" = {
        ForwardAgent = false;
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        Compression = true;
        AddKeysToAgent = "no";
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      # GitHub
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentitiesOnly = false;
      };

      # GitLab (commented out as in original)
      # "gitlab.com" = {
      #   HostName = "gitlab.com";
      #   User = "git";
      #   PreferredAuthentications = "publickey";
      #   IdentityFile = "~/.ssh/dev";
      # };

      # Raspberry Pi
      "machine0" = {
        HostName = "rpi.local";
        User = "machine";
      };

      # Tailscale devices - shared settings
      "vps oci-vps mbp-work" = {
        IdentitiesOnly = true;
      };

      # VPS server
      "vps" = {
        # HostName = "vps.whatmay.be";
        # IdentityFile = "~/.ssh/id_ed25519";
        User = "jda";
      };

      "oci-vps" = {
        HostName = "oci-vps";
        User = "jda";
      };
    };

    # Cross-platform SSH agent and security settings
    extraConfig = ''
      # Global SSH settings
      AddKeysToAgent yes
      ${
        if pkgs.stdenv.isDarwin then
          ''
            UseKeychain yes
            IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          ''
        else
          ''
            IdentityAgent ~/.1password/agent.sock
          ''
      }

      # Security settings
      UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts2
      StrictHostKeyChecking ask
    '';
  };

  # Ensure SSH directory exists with correct permissions
  home.file.".ssh/.keep" = {
    text = "";
    onChange = ''
      chmod 700 ~/.ssh
    '';
  };
}
