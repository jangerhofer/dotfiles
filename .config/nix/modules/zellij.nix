{
  config,
  pkgs,
  pkgsUnstable ? pkgs,
  ...
}:

let
  zellijPackage = pkgsUnstable.zellij;
  renumberTabs = pkgs.writeShellScriptBin "zellij-renumber-tabs" ''
    set -eu

    tabs_json="$("${zellijPackage}/bin/zellij" action list-tabs --json 2>/dev/null || true)"
    if [ -z "$tabs_json" ]; then
      exit 0
    fi

    printf '%s' "$tabs_json" \
      | "${pkgs.jq}/bin/jq" -r '.[] | select(.name | test("^Tab #[0-9]+$")) | [.tab_id, (.position + 1), .name] | @tsv' \
      | while IFS="$(printf '\t')" read -r tab_id tab_number current_name; do
          desired_name="Tab #$tab_number"
          if [ "$current_name" != "$desired_name" ]; then
            "${zellijPackage}/bin/zellij" action rename-tab --tab-id "$tab_id" "$desired_name" >/dev/null 2>&1 || true
          fi
        done
  '';
  closeTabAndRenumber = pkgs.writeShellScriptBin "zellij-close-tab-renumber" ''
    set -eu

    tab_info="$("${zellijPackage}/bin/zellij" action current-tab-info --json 2>/dev/null || true)"
    tab_id="$(printf '%s' "$tab_info" | "${pkgs.jq}/bin/jq" -r '.tab_id // empty' 2>/dev/null || true)"

    nohup "${pkgs.runtimeShell}" -c 'sleep 0.2; exec "$1"' sh "${renumberTabs}/bin/zellij-renumber-tabs" >/dev/null 2>&1 &

    if [ -n "$tab_id" ]; then
      "${zellijPackage}/bin/zellij" action close-tab --tab-id "$tab_id" >/dev/null 2>&1 \
        || "${zellijPackage}/bin/zellij" action close-tab >/dev/null 2>&1 \
        || true
    else
      "${zellijPackage}/bin/zellij" action close-tab >/dev/null 2>&1 || true
    fi
  '';
in
{
  programs.zellij = {
    enable = true;
    package = zellijPackage;
    settings = {
      theme = "nord";
      keybinds = {
        unbind = [
          "Alt Left"
          "Alt Right"
          "Alt Up"
          "Alt Down"
        ];
        tab = {
          bind = {
            _args = [ "x" ];
            Run = {
              _args = [ "${closeTabAndRenumber}/bin/zellij-close-tab-renumber" ];
              close_on_exit = true;
              floating = true;
              borderless = true;
              x = "0";
              y = "0";
              width = "1";
              height = "1";
            };
          };
        };
      };
    };
  };

  home.packages = [
    renumberTabs
    closeTabAndRenumber
  ];

  xdg.configFile."zellij/config.kdl".force = true;
}
