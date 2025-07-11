{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    biome
    csharpier
    delve
    djlint
    dockerfile-language-server-nodejs
    emmet-language-server
    eslint_d
    fzf
    golangci-lint
    # golangci-lint-langserver
    gopls
    hadolint
    libxml2
    #lldb
    luajitPackages.tiktoken_core
    luajitPackages.jsregexp
    # luajitPackages.luarocks
    # lua51Packages.luarocks
    lynx
    markdownlint-cli
    #netcoredbg
    nodePackages.bash-language-server
    nodePackages.poor-mans-t-sql-formatter-cli
    nodePackages.prettier
    nodePackages.jsonlint
    omnisharp-roslyn
    pyright
    prettierd
    quick-lint-js
    ruff
    stylelint
    stylua
    superhtml
    tflint
    typescript-language-server
    vale
    vim
    vimgolf
    vscode-langservers-extracted
    vscode-extensions.ms-vscode.cpptools
    #vscode-extensions.vadimcn.vscode-lldb
    yaml-language-server
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = false;
    vimAlias = false;
    vimdiffAlias = false;
    withNodeJs = true;
    withPython3 = true;
    plugins = with pkgs.vimPlugins; [
      avante-nvim
      ChatGPT-nvim
      CopilotChat-nvim
      catppuccin-nvim
      cloak-nvim
      cmp-buffer
      cmp-emoji
      cmp-look
      cmp-nvim-lsp
      cmp-path
      cmp-rg
      cmp-treesitter
      cmp-tmux
      cmp_luasnip
      codecompanion-nvim
      comment-nvim
      conform-nvim
      copilot-cmp
      copilot-lua
      csv-vim
      diffview-nvim
      direnv-vim
      dressing-nvim
      friendly-snippets
      fzf-lua
      gitsigns-nvim
      guess-indent-nvim
      indent-blankline-nvim
      lazy-nvim
      lspkind-nvim
      lualine-nvim
      luasnip
      markdown-preview-nvim
      mason-lspconfig-nvim
      mason-nvim
      mason-nvim-dap-nvim
      mini-pick
      mini-surround
      mini-comment
      omnisharp-extended-lsp-nvim
      neo-tree-nvim
      neogit
      nui-nvim
      nvim-cmp
      nvim-dap
      nvim-dap-ui
      nvim-dap-lldb
      nvim-lightbulb
      nvim-lint
      nvim-lspconfig
      nvim-notify
      nvim-treesitter.withAllGrammars
      nvim-web-devicons
      oil-nvim
      plenary-nvim
      render-markdown-nvim
      telescope-fzf-native-nvim
      telescope-nvim
      toggleterm-nvim
      trouble-nvim
      typescript-tools-nvim
      vim-dadbod
      vim-dadbod-completion
      vim-dadbod-ui
      which-key-nvim
      zellij-nav-nvim
      #mini-nvim
    ];
    extraLuaConfig = let
      grammarsPath = pkgs.symlinkJoin {
        name = "nvim-treesitter-grammars";
        paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
      };
    in
      ''
        pluginPath = "${pkgs.vimUtils.packDir config.programs.neovim.finalPackage.passthru.packpathDirs}/pack/myNeovimPackages/start"
        omnisharpCmd = { "dotnet", "${pkgs.omnisharp-roslyn.outPath}/lib/omnisharp-roslyn/OmniSharp.dll" }
        treesitterPath = "${pkgs.vimPlugins.nvim-treesitter}"
        treesitterGrammars = "${grammarsPath}"
        jsregexpPath = "${pkgs.luajitPackages.jsregexp}/lib/lua/5.1/jsregexp/?.so;"
        tiktokenCorePath = "${pkgs.luajitPackages.tiktoken_core}/lib/lua/5.1/?.so;"
        luarocksPath = "${pkgs.luajitPackages.luarocks}"
      ''
      + builtins.readFile ./nvim.lua;
  };

  xdg.configFile."nvim/lua" = {
    recursive = true;
    source = ./lua;
  };

  xdg.configFile."words" = {
    enable = true;
    source = ./words;
    target = "look/words";
  };
}
