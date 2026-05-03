{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include OrbStack SSH config
    includes = [ "~/.orbstack/ssh/config" ];

    # Common SSH configurations
    matchBlocks = {
      # Default settings for all hosts
      "*" = {
        forwardAgent = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
        addKeysToAgent = "no";
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };

      # GitHub
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = false;
      };

      # GitLab (commented out as in original)
      # "gitlab.com" = {
      #   hostname = "gitlab.com";
      #   user = "git";
      #   preferredAuthentications = "publickey";
      #   identityFile = "~/.ssh/dev";
      # };

      # Raspberry Pi
      "machine0" = {
        hostname = "rpi.local";
        user = "machine";
      };

      # Tailscale devices - shared settings
      "vps oci-vps mbp-work" = {
        identitiesOnly = true;
      };

      # VPS server
      "vps" = {
        # hostname = "vps.whatmay.be";
        # identityFile = "~/.ssh/id_ed25519";
        user = "jda";
      };

      "oci-vps" = {
        hostname = "oci-vps";
        user = "jda";
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
