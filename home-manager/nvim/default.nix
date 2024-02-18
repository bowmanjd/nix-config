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
    nodePackages_latest.bash-language-server
    nodePackages_latest.poor-mans-t-sql-formatter-cli
    nodePackages_latest.prettier
    nodePackages_latest.pyright
    prettierd
    quick-lint-js
    stylelint
    stylua
    vscode-langservers-extracted
    yaml-language-server
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    plugins = with pkgs.vimPlugins; [
      csv-vim
      direnv-vim
      catppuccin-nvim
      lualine-nvim
      indent-blankline-nvim
      cmp-buffer
      cmp_luasnip
      cmp-nvim-lsp
      gitsigns-nvim
      lspkind-nvim
      luasnip
      none-ls-nvim
      nvim-cmp
      nvim-lightbulb
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      nvim-web-devicons
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      #mini-nvim
    ];
    extraLuaConfig = builtins.readFile ./nvim.lua;
  };
}
