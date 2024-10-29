{pkgs, ...}: {
  home.packages = with pkgs; [
    biome
    dockerfile-language-server-nodejs
    emmet-language-server
    eslint_d
    fzf
    gopls
    nodePackages.bash-language-server
    nodePackages.poor-mans-t-sql-formatter-cli
    nodePackages.prettier
    pyright
    prettierd
    quick-lint-js
    ruff
    stylelint
    stylua
    vim
    vimgolf
    vscode-langservers-extracted
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
      indent-blankline-nvim
      lazy-nvim
      lspkind-nvim
      lualine-nvim
      luasnip
      markdown-preview-nvim
      mason-lspconfig-nvim
      mason-nvim
      nvim-cmp
      nvim-lightbulb
      nvim-lint
      nvim-lspconfig
      nvim-notify
      nvim-treesitter.withAllGrammars
      nvim-web-devicons
      plenary-nvim
      telescope-fzf-native-nvim
      telescope-nvim
      trouble-nvim
      typescript-tools-nvim
      vim-dadbod
      vim-dadbod-completion
      vim-dadbod-ui
      #mini-nvim
    ];
    extraLuaConfig = builtins.readFile ./nvim.lua;
  };


  xdg.configFile."words" = {
    enable = true;
    source = ./words;
    target = "look/words";
  };
}
