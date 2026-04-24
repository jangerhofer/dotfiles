{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud provider CLIs
    google-cloud-sdk # Google Cloud SDK

    # Infrastructure as Code
    terraform # Infrastructure provisioning
    terragrunt # Terraform wrapper
    packer # Image building

    # Container orchestration
    kubectx # Kubernetes context switcher

    # CI/CD and deployment
    flyctl # Fly.io CLI

    # Development and debugging
    dive # Docker image analyzer
    stern # Kubernetes log tailing
  ];

  # AWS CLI configuration
  programs.awscli = {
    enable = true;
    settings = {
      default = {
        region = "us-east-1";
        output = "json";
      };
    };
  };

  # Set common cloud environment variables
  home.sessionVariables = {
    # AWS
    AWS_PAGER = ""; # Disable pager for AWS CLI

    # Kubernetes
    KUBECTL_EXTERNAL_DIFF = "delta";

    # Terraform
    TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
  };
}
