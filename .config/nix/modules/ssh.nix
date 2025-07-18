{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    
    # Common SSH configurations
    matchBlocks = {
      # GitHub
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
      };
      
      # GitLab
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
      };
      
      # Example server configuration
      # Uncomment and customize as needed
      # "myserver" = {
      #   hostname = "example.com";
      #   user = "myuser";
      #   port = 22;
      #   identitiesOnly = true;
      # };
    };
    
    # Security settings
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
    
    # Cross-platform 1Password SSH agent integration and security settings
    extraConfig = ''
      AddKeysToAgent yes
      ${if pkgs.stdenv.isDarwin then ''
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '' else ''
        IdentityAgent ~/.1password/agent.sock
      ''}
      
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