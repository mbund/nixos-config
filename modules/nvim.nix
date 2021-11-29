{ pkgs, inputs, ... }: {
  home-manager.users.mbund.programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      # file tree
      nvim-web-devicons
      nvim-tree-lua

      # languages
      vim-nix

      # rice
      nvim-treesitter
      bufferline-nvim
      galaxyline-nvim
      nvim-colorizer-lua
      pears-nvim

      # lsp and completion
      nvim-lspconfig
      nvim-compe

      # misc
      telescope-nvim
      indent-blankline-nvim
    ];
  };
}