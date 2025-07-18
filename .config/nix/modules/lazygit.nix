{ config, pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          activeBorderColor = ["#81A1C1" "bold"];
          inactiveBorderColor = ["#4C566A"];
          optionsTextColor = ["#81A1C1"];
          selectedLineBgColor = ["#3B4252"];
          selectedRangeBgColor = ["#3B4252"];
          cherryPickedCommitBgColor = ["#A3BE8C"];
          cherryPickedCommitFgColor = ["#2E3440"];
          unstagedChangesColor = ["#EBCB8B"];
          defaultFgColor = ["#E5E9F0"];
        };
        scrollHeight = 2;
        scrollPastBottom = true;
        sidePanelWidth = 0.3333;
        expandFocusedSidePanel = false;
        mainPanelSplitMode = "flexible";
        enlargedSideViewLocation = "left";
        language = "auto";
        timeFormat = "02 Jan 06 15:04 MST";
        shortTimeFormat = "15:04";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
        commit = {
          signOff = false;
        };
        merging = {
          manualCommit = false;
          args = "";
        };
        log = {
          order = "topo-order";
          showGraph = "when-maximised";
        };
        skipHookPrefix = "WIP";
        autoFetch = true;
        autoRefresh = true;
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
        allBranchesLogCmd = "git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium";
        overrideGpg = false;
        disableForcePushing = false;
        parseEmoji = false;
      };
      update = {
        method = "prompt";
        days = 14;
      };
      reporting = "undetermined";
      confirmOnQuit = false;
      quitOnTopLevelReturn = false;
      keybinding = {
        universal = {
          quit = "q";
          quit-alt1 = "<c-c>";
          return = "<esc>";
          quitWithoutChangingDirectory = "Q";
          togglePanel = "<tab>";
          prevItem = "<up>";
          nextItem = "<down>";
          prevItem-alt = "k";
          nextItem-alt = "j";
          prevPage = ",";
          nextPage = ".";
          gotoTop = "<";
          gotoBottom = ">";
          prevBlock = "<left>";
          nextBlock = "<right>";
          prevBlock-alt = "h";
          nextBlock-alt = "l";
          jumpToBlock = ["1" "2" "3" "4" "5"];
          nextMatch = "n";
          prevMatch = "N";
          optionMenu = "x";
          optionMenu-alt1 = "?";
          select = "<space>";
          goInto = "<enter>";
          openRecentRepos = "<c-r>";
          confirm = "<enter>";
          remove = "d";
          new = "n";
          edit = "e";
          openFile = "o";
          scrollUpMain = "<pgup>";
          scrollDownMain = "<pgdown>";
          scrollUpMain-alt1 = "K";
          scrollDownMain-alt1 = "J";
          scrollUpMain-alt2 = "<c-u>";
          scrollDownMain-alt2 = "<c-d>";
          executeCustomCommand = ":";
          createRebaseOptionsMenu = "m";
          pushFiles = "P";
          pullFiles = "p";
          refresh = "R";
          createPatchOptionsMenu = "<c-p>";
          nextTab = "]";
          prevTab = "[";
          nextScreenMode = "+";
          prevScreenMode = "_";
          undo = "z";
          redo = "<c-z>";
          filteringMenu = "<c-s>";
          diffingMenu = "W";
          diffingMenu-alt = "<c-e>";
          copyToClipboard = "<c-o>";
          submitEditorText = "<enter>";
          appendNewline = "<a-enter>";
          extrasMenu = "@";
          toggleWhitespaceInDiffView = "<c-w>";
          increaseContextInDiffView = "}";
          decreaseContextInDiffView = "{";
        };
      };
      os = {
        editPreset = "nvim";
      };
      disableStartupPopups = false;
      customCommands = [];
      services = {};
      notARepository = "prompt";
      promptToReturnFromSubprocess = true;
    };
  };
}