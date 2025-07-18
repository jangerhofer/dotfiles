{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud provider CLIs
    google-cloud-sdk # Google Cloud SDK
    azure-cli       # Azure CLI
    
    # Infrastructure as Code
    terraform       # Infrastructure provisioning
    terragrunt      # Terraform wrapper
    packer          # Image building
    
    # Container orchestration
    kubectx        # Kubernetes context switcher
    
    # Monitoring and observability
    prometheus      # Metrics monitoring
    grafana-cli     # Grafana CLI
    
    # Service mesh and networking
    istioctl        # Istio service mesh CLI
    linkerd         # Linkerd service mesh CLI
    
    # CI/CD and deployment
    flyctl          # Fly.io CLI
    argocd          # Argo CD CLI
    
    # Development and debugging
    dive            # Docker image analyzer
    stern           # Kubernetes log tailing
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
    AWS_PAGER = "";  # Disable pager for AWS CLI
    
    # Kubernetes
    KUBECTL_EXTERNAL_DIFF = "delta";
    
    # Terraform
    TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
  };
}