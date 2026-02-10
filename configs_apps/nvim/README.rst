Neovim Configuration
====================

Personal neovim configuration with LSP support for Python, TypeScript, Rust, and more.

Features
--------

- LSP integration: Pyright, Ruff, TypeScript, Rust Analyzer, Stylelint
- Autocompletion via nvim-cmp
- Linting via nvim-lint (eslint_d for JS/TS)
- Formatting via Prettier (JS/TS/CSS/etc.)
- Telescope for fuzzy finding
- Gruvbox colorscheme with transparency support

Installation
------------

Clone this repository into ``~/configs_apps``:

.. code-block:: bash

    cd ~/configs_apps
    git clone git@github.com:bouillon/nvim.git

Run the init script to set up symlinks and git worktree:

.. code-block:: bash

    cd nvim
    ./init.sh

This will:

1. Configure git worktree to track files in your home directory
2. Copy/link ``.config/nvim`` to ``~/.config/nvim``
3. Copy/link ``.local`` files if present

Dependencies
------------

Install these tools for full functionality:

- `neovim <https://neovim.io/>`_ (0.10+)
- `vim-plug <https://github.com/junegunn/vim-plug>`_
- `ruff <https://github.com/astral-sh/ruff>`_ (Python linter/formatter)
- `pyright <https://github.com/microsoft/pyright>`_ (Python LSP)
- `typescript-language-server <https://github.com/typescript-language-server/typescript-language-server>`_
- `eslint_d <https://github.com/mantoni/eslint_d.js>`_
- `prettier <https://prettier.io/>`_
- `rust-analyzer <https://rust-analyzer.github.io/>`_ (for Rust)

After installation, run ``:PlugInstall`` in neovim to install plugins.
