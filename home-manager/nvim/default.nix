{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    dockerfile-language-server-nodejs
    dprint
    eslint_d
    fzf
    gopls
    nodePackages.bash-language-server
    nodePackages.poor-mans-t-sql-formatter-cli
    nodePackages.prettier
    pyright
    prettierd
    quick-lint-js
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
      cloak-nvim
      conform-nvim
      csv-vim
      direnv-vim
      catppuccin-nvim
      lualine-nvim
      indent-blankline-nvim
      cmp-buffer
      cmp_luasnip
      cmp-nvim-lsp
      copilot-lua
      copilot-cmp
      diffview-nvim
      gitsigns-nvim
      lazy-nvim
      lspkind-nvim
      luasnip
      markdown-preview-nvim
      mason-nvim
      mason-lspconfig-nvim
      nvim-cmp
      nvim-lightbulb
      nvim-lint
      nvim-lspconfig
      nvim-notify
      nvim-treesitter.withAllGrammars
      nvim-web-devicons
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      trouble-nvim
      typescript-tools-nvim
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      #mini-nvim
    ];
    extraLuaConfig = builtins.readFile ./nvim.lua;
  };
}
