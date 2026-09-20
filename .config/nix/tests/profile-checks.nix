# Pass this function to `nix eval ...#homeConfigurations --apply`.
profiles:
builtins.mapAttrs (
  name: profile:
  let
    inherit (profile.pkgs) lib;
    config = profile.config;
    git = config.programs.git.iniContent;
    isDarwin = profile.pkgs.stdenv.isDarwin;
    isVps = name == "vps-aarch64";
    commitSigning = git.commit.gpgSign or false;
    tagSigning = git.tag.gpgSign or false;
    annotatedTagSigning = git.tag.forceSignAnnotated or false;
    signingKey = git.user.signingKey or null;
    signingFormat = git.gpg.format or null;
    signingProgram = git.gpg.ssh.program or null;
    expectedKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUy3gdzKIGR7Euq21r4O8hScZBj4wg9hJp9gXcOB00n";
    expectedSigner =
      if isDarwin then
        "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
      else
        "${profile.pkgs.openssh}/bin/ssh-keygen";
  in
  assert lib.assertMsg
    (
      if isVps then
        !commitSigning && !tagSigning && !annotatedTagSigning
      else
        commitSigning && tagSigning && annotatedTagSigning
    )
    "${name}: automatic commit and tag signing must remain enabled for workstations and disabled for the VPS";
  assert lib.assertMsg
    (
      if isVps then
        signingKey == null && signingProgram == null
      else
        signingFormat == "ssh" && signingKey == expectedKey && signingProgram == expectedSigner
    )
    "${name}: preserve the SSH signing key and platform-specific signer, with no signer configured on the VPS";
  assert lib.assertMsg
    (lib.hasInfix "#homeConfigurations.${name}.activationPackage" config.programs.nushell.extraConfig)
    "${name}: hm must rebuild the same named profile selected by bootstrap";
  {
    system = profile.pkgs.stdenv.hostPlatform.system;
    username = config.home.username;
    inherit signingProgram;
  }
) profiles
