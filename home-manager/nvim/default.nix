{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    biome
    csharpier
    delve
    dockerfile-language-server-nodejs
    emmet-language-server
    eslint_d
    fzf
    gopls
    hadolint
    markdownlint-cli
    lldb
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
    tflint
    vale
    vim
    vimgolf
    vscode-langservers-extracted
    vscode-extensions.ms-vscode.cpptools
    vscode-extensions.vadimcn.vscode-lldb
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
      ChatGPT-nvim
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
      conform-nvim
      copilot-cmp
      copilot-lua
      csv-vim
      diffview-nvim
      direnv-vim
      friendly-snippets
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
      telescope-fzf-native-nvim
      telescope-nvim
      toggleterm-nvim
      trouble-nvim
      typescript-tools-nvim
      vim-dadbod
      vim-dadbod-completion
      vim-dadbod-ui
      which-key-nvim
      #mini-nvim
    ];
    extraLuaConfig =
      ''
        pluginPath = "${pkgs.vimUtils.packDir config.programs.neovim.finalPackage.passthru.packpathDirs}/pack/myNeovimPackages/start"
        omnisharpCmd = { "dotnet", "${pkgs.omnisharp-roslyn.outPath}/lib/omnisharp-roslyn/OmniSharp.dll" }
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
