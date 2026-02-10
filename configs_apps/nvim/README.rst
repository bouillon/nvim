Neovim Configuration
====================

Personal neovim configuration with LSP support for Python, TypeScript, Rust, and more.

Features
--------

- LSP integration: Pyright, Ruff, TypeScript, Rust Analyzer, Stylelint, YAML
- Autocompletion via nvim-cmp
- Linting via nvim-lint (eslint_d for JS/TS)
- Formatting via Prettier (JS/TS/CSS/etc.)
- Telescope for fuzzy finding
- Gruvbox colorscheme with transparency support
- YAML schema validation (Kubernetes, Rook/Ceph CRDs)

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
- `yaml-language-server <https://github.com/redhat-developer/yaml-language-server>`_ (YAML LSP)

After installation, run ``:PlugInstall`` in neovim to install plugins.

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
