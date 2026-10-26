Neovim Configuration
====================

Personal neovim configuration with LSP support for Python, TypeScript, Rust, and more.

Features
--------

LSP Integration
~~~~~~~~~~~~~~~

- **Python**: Pyright (type checking) + Ruff (linting/formatting, uses local ``.venv`` if available)
- **TypeScript/JavaScript**: ts_ls + eslint_d linting + Prettier formatting
- **Rust**: rust-analyzer
- **CSS/SCSS**: Stylelint LSP
- **YAML**: yaml-language-server with custom schema validation (Kubernetes, Rook/Ceph CRDs)
- **Go**: gopls

Editor Features
~~~~~~~~~~~~~~~

- Autocompletion via nvim-cmp (trigger with ``<C-Space>``)
- Snippet support via LuaSnip
- Telescope fuzzy finder (``,f`` for files, ``,g`` for grep)
- Gruvbox colorscheme with transparency
- vim-sneak for quick navigation

Key Bindings
~~~~~~~~~~~~

- ``jk`` - Exit insert mode
- ``gd`` - Go to definition
- ``K`` - Hover documentation
- ``<space>f`` - Format buffer
- ``<space>ca`` - Code actions
- ``<space>rn`` - Rename symbol
- ``[d`` / ``]d`` - Navigate diagnostics
- ``gn`` / ``gp`` - Next/previous buffer
- ``gw`` - Close buffer
- ``H`` / ``L`` - Previous/next tab
- ``<C-h>`` - Run current file (Python, C, Go, Shell)

Installation
------------

Clone this repository into ``~/configs_apps``:

.. code-block:: bash

    cd ~/configs_apps
    git clone git@github.com:bouillon/nvim.git

How to run
~~~~~~~~~~

Recommended — one pass as root, installs the system part and the user part
for ``vav`` without further questions:

.. code-block:: bash

    su -                                              # root password
    cd /home/vav/configs_apps/nvim && ./init.sh vav

If everything system-wide is already installed, you can run it as yourself;
``su`` then asks the root password only if something is missing:

.. code-block:: bash

    cd ~/configs_apps/nvim
    git pull          # or ,pull kot configs on the Mac — get the current script first
    ./init.sh

- No sudo: as a user the system steps ask the root password once (``su``); as
  root give the user name (``./init.sh vav``; ``sudo ./init.sh`` works the same,
  the user then defaults to ``$SUDO_USER``). As root without a user name it
  stops at once with an error.
- The script prints first how it runs («as root for user vav» / «as vav;
  system steps via su if needed»).
- System steps (only what is missing): ``apt-get install``, ``npm install -g``
  (``/usr/local``), the link ``/usr/local/bin/gopls -> /home/<user>/go/bin/gopls``
  (never into ``/root``). As a user they are collected into one
  ``su root -c``; if ``su`` fails the script stops and prints the commands for
  a root shell.
- User steps (config in ``~/.config/nvim``, vim-plug, ``:PlugInstall``,
  ``go install`` into ``~/go/bin``) run as that user — via ``su - <user>`` when
  started as root, so the files belong to the user.
- Verify: the last block «Check» must show ``OK`` for every line, e.g.
  ``OK   go   /usr/local/bin/gopls``, and end with «All language servers
  present»; exit code 0. Any ``MISS`` → exit code 1. In nvim on a ``.go``
  file ``:checkhealth vim.lsp`` shows gopls attached.

This will:

1. Configure git worktree to track files in your home directory
2. Move ``.config/nvim`` to ``~/.config/nvim``
3. Move ``.local`` files if present
4. Install every language server the config uses — apt for what Debian/Ubuntu
   ship (neovim, nodejs, go, rust + rust-src, ripgrep, ruff, build tools),
   ``npm -g`` for the Node servers, ``go install`` for gopls
5. Install vim-plug and run ``:PlugInstall``
6. Print a per-language self-check (OK / MISS)

It is idempotent — re-run any time; present tools are skipped.

Dependencies (installed by ``init.sh``; listed for reference)
-------------------------------------------------------------

- `neovim <https://neovim.io/>`_ (0.11+, for ``vim.lsp.config`` / ``vim.lsp.enable``)
- `vim-plug <https://github.com/junegunn/vim-plug>`_
- Python: `ruff <https://github.com/astral-sh/ruff>`_ + `pyright <https://github.com/microsoft/pyright>`_ (``npm -g pyright``)
- TypeScript / JavaScript: `typescript-language-server <https://github.com/typescript-language-server/typescript-language-server>`_
  + `eslint_d <https://github.com/mantoni/eslint_d.js>`_ + `prettier <https://prettier.io/>`_

  .. note::

     ``typescript`` is pinned to **5.x**. typescript-language-server wraps the
     classic ``tsserver``, which the 7.x native port of TypeScript no longer
     ships — with ``typescript@7`` the LSP fails to start ("Could not find a
     valid TypeScript installation").

- Rust: `rust-analyzer <https://rust-analyzer.github.io/>`_ **plus the
  ``rust-src`` component** — without it rust-analyzer logs "can't load standard
  library" and never answers (hover / go-to-definition return nothing).
- `yaml-language-server <https://github.com/redhat-developer/yaml-language-server>`_
- Go: `gopls <https://pkg.go.dev/golang.org/x/tools/gopls>`_ (``go install``)
- CSS: `stylelint-lsp <https://github.com/bmatcuk/stylelint-lsp>`_
- `ripgrep <https://github.com/BurntSushi/ripgrep>`_ (Telescope live-grep)


YAML Schema Validation
----------------------

The configuration includes yaml-language-server with custom schema mappings:

==================== ====================================
File pattern         Schema
==================== ====================================
``**/*.k8s.yaml``    Kubernetes (from schemaStore)
``**/*.ceph.yaml``   Rook CephCluster CRD
``**/*.kadm.yaml``   Permissive (kubeadm/kubelet configs)
==================== ====================================

JSON Schemas Setup
~~~~~~~~~~~~~~~~~~

Create a ``~/jsonschemas`` symlink pointing to your schema files:

.. code-block:: bash

    ln -s /path/to/your/schemas ~/jsonschemas

Required schema files:

- ``rook-cephcluster.schema.json`` - Rook CephCluster CRD schema
- ``permissive.schema.json`` - Permissive schema for kubeadm/kubelet configs

The nvim config uses ``$HOME`` to resolve the path dynamically.

To add more schemas, edit the ``yamlls`` config in ``init.vim``.
