set mouse=a  " enable mouse
set encoding=utf-8
set number
set cursorline
set noswapfile
set scrolloff=7

" Indentation settings
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent
set fileformat=unix
filetype indent on      " load filetype-specific indent files

" Horizontal split open below and right
set splitbelow
set splitright

" System clipboard integration
" macOS: works out of the box via pbcopy/pbpaste
" Linux KDE Plasma Wayland: uses Klipper via qdbus6
set clipboard=unnamedplus
if has('linux')
  let g:clipboard = {
    \   'name': 'KDEKlipper',
    \   'copy': {
    \      '+': ['nvim-clip-copy'],
    \      '*': ['nvim-clip-copy'],
    \    },
    \   'paste': {
    \      '+': ['nvim-clip-paste'],
    \      '*': ['nvim-clip-paste'],
    \   },
    \   'cache_enabled': 0,
    \ }
endif

inoremap jk <esc>

call plug#begin('~/.vim/plugged')

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'mfussenegger/nvim-lint'
Plug 'L3MON4D3/LuaSnip'

" color schemas
Plug 'morhetz/gruvbox'  " colorscheme gruvbox
Plug 'mhartington/oceanic-next'  " colorscheme OceanicNext
Plug 'kaicataldo/material.vim', { 'branch': 'main' }
Plug 'ayu-theme/ayu-vim'

Plug 'xiyaowong/nvim-transparent'

" Plug 'Pocco81/auto-save.nvim'
Plug 'justinmk/vim-sneak'

" TS/JS handled by LSP + Treesitter (add nvim-treesitter for best results)
Plug 'nvim-lua/plenary.nvim'

Plug 'prettier/vim-prettier', {
  \ 'do': 'npm install --frozen-lockfile --production',
  \ 'for': ['javascript', 'typescript', 'typescriptreact', 'javascriptreact', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'svelte', 'yaml', 'html'] }

Plug 'bmatcuk/stylelint-lsp'

Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Convenient floating terminal window
"Plug 'voldikss/vim-floaterm'

Plug 'ray-x/lsp_signature.nvim'

call plug#end()

" Leader bind to comma
let mapleader = ","

" Netrw file explorer settings
let g:netrw_banner = 0 " hide banner above files
let g:netrw_liststyle = 3 " tree instead of plain view
let g:netrw_browse_split = 3 " vertical split window when Enter pressed on file

" Automatically format frontend files with prettier after file save
let g:prettier#autoformat = 1
let g:prettier#autoformat_require_pragma = 0

" Disable quickfix window for prettier
let g:prettier#quickfix_enabled = 0

" Turn on vim-sneak
let g:sneak#label = 1

colorscheme gruvbox
"colorscheme OceanicNext
"let g:material_terminal_italics = 1
" variants: default, palenight, ocean, lighter, darker, default-community,
"           palenight-community, ocean-community, lighter-community,
"           darker-community
"let g:material_theme_style = 'darker'
"colorscheme material
if (has('termguicolors'))
  set termguicolors
endif

" variants: mirage, dark, dark
"let ayucolor="mirage"
"colorscheme ayu

" turn off search highlight
nnoremap ,<space> :nohlsearch<CR>

lua << EOF
-- Show source (Ruff/Pyright) in diagnostic floats
vim.diagnostic.config({
  float = {
    source = true,
  },
  virtual_text = {
    source = true,
  },
})

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- luasnip setup
local luasnip = require 'luasnip'
-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  completion = {
    autocomplete = false
  },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end,
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)

  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.format()<CR>', opts)

  require "lsp_signature".on_attach({
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      floating_window = true,
      floating_window_above_cur_line = true,
      floating_window_off_x = 20,
      doc_lines = 10,
      hint_prefix = '👻 '
    }, bufnr)  -- Note: add in lsp client on-attach
end

-- link pylint own implemented https://www.reddit.com/r/neovim/comments/15pj1oi/using_nvimlint_as_a_nullls_alternative_for_linters/
-- see https://github.com/mfussenegger/nvim-lint?tab=readme-ov-file

local lint = require("lint")
lint.linters_by_ft = {
    javascript = {
        "eslint_d"
    },
    typescript = {
        "eslint_d"
    },
    javascriptreact = {
        "eslint_d"
    },
    typescriptreact = {
        "eslint_d"
    },
}

-- trigger linter by leave the insert mode or save
vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
    callback = function()
        local lint_status, lint_mod = pcall(require, "lint")
        if lint_status then
            lint_mod.try_lint()
        end
    end,
})

-- end of pylint

-- TS setup
vim.lsp.config('ts_ls', {
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        on_attach(client, bufnr)
    end,
})
vim.lsp.enable('ts_ls')

-- Stylelint format after save
vim.lsp.config('stylelint_lsp', {
  settings = {
    stylelintplus = {
      --autoFixOnSave = true,
      --autoFixOnFormat = true,
    }
  }
})
vim.lsp.enable('stylelint_lsp')

-- Helper function to find ruff executable
local function get_ruff_cmd()
    -- Check for ruff in local .venv first
    local venv_ruff = vim.fn.getcwd() .. '/.venv/bin/ruff'
    if vim.fn.executable(venv_ruff) == 1 then
        return venv_ruff
    end
    -- Fall back to global ruff
    return 'ruff'
end

vim.lsp.config('ruff', {
    cmd = { get_ruff_cmd(), 'server' },
    on_attach = on_attach,
    init_options = {
        settings = {
            -- Any extra CLI arguments for `ruff` go here.
            args = {},
        }
    }
})
vim.lsp.enable('ruff')

vim.lsp.config('pyright', {
    on_attach = function(client, bufnr)
        -- Disable pyright formatting, let ruff handle it
        client.server_capabilities.documentFormattingProvider = false
        on_attach(client, bufnr)
    end,
    settings = {
        python = {
            analysis = {
                -- warnings in factory boy for meta class overide
                typeCheckingMode = "basic"
            }
        }
    }
})
vim.lsp.enable('pyright')

vim.lsp.config('rust_analyzer', {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
})
vim.lsp.enable('rust_analyzer')

local home = os.getenv("HOME")
local schema_path = "file://" .. home .. "/jsonschemas/"

vim.lsp.config('yamlls', {
    on_attach = on_attach,
    settings = {
        yaml = {
            schemaStore = { enable = true },
            validate = true,
            completion = true,
            hover = true,
            format = { enable = true },
            schemas = {
                kubernetes = { "**/*.k8s.yaml", "**/*.k8s.yml" },
                [schema_path .. "rook-cephcluster.schema.json"] = {
                    "**/*.ceph.yaml",
                    "**/*.ceph.yml"
                },
                [schema_path .. "permissive.schema.json"] = {
                    "**/*.kadm.yaml",
                    "**/*.kadm.yml"
                }
            }
        }
    }
})
vim.lsp.enable('yamlls')
EOF

" Delete buffer while keeping window layout (don't close buffer's windows).
" Version 2008-11-18 from http://vim.wikia.com/wiki/VimTip165
if v:version < 700 || exists('loaded_bclose') || &cp
  finish
endif
let loaded_bclose = 1
if !exists('bclose_multiple')
  let bclose_multiple = 1
endif

" Display an error message.
function! s:Warn(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl NONE
endfunction

" Command ':Bclose' executes ':bd' to delete buffer in current window.
" The window will show the alternate buffer (Ctrl-^) if it exists,
" or the previous buffer (:bp), or a blank buffer if no previous.
" Command ':Bclose!' is the same, but executes ':bd!' (discard changes).
" An optional argument can specify which buffer to close (name or number).
function! s:Bclose(bang, buffer)
  if empty(a:buffer)
    let btarget = bufnr('%')
  elseif a:buffer =~ '^\d\+$'
    let btarget = bufnr(str2nr(a:buffer))
  else
    let btarget = bufnr(a:buffer)
  endif
  if btarget < 0
    call s:Warn('No matching buffer for '.a:buffer)
    return
  endif
  if empty(a:bang) && getbufvar(btarget, '&modified')
    call s:Warn('No write since last change for buffer '.btarget.' (use :Bclose!)')
    return
  endif
  " Numbers of windows that view target buffer which we will delete.
  let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
  if !g:bclose_multiple && len(wnums) > 1
    call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
    return
  endif
  let wcurrent = winnr()
  for w in wnums
    execute w.'wincmd w'
    let prevbuf = bufnr('#')
    if prevbuf > 0 && buflisted(prevbuf) && prevbuf != btarget
      buffer #
    else
      bprevious
    endif
    if btarget == bufnr('%')
      " Numbers of listed buffers which are not the target to be deleted.
      let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
      " Listed, not target, and not displayed.
      let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
      " Take the first buffer, if any (could be more intelligent).
      let bjump = (bhidden + blisted + [-1])[0]
      if bjump > 0
        execute 'buffer '.bjump
      else
        execute 'enew'.a:bang
      endif
    endif
  endfor
  execute 'bdelete'.a:bang.' '.btarget
  execute wcurrent.'wincmd w'
endfunction
command! -bang -complete=buffer -nargs=? Bclose call <SID>Bclose(<q-bang>, <q-args>)
nnoremap <silent> <Leader>bd :Bclose<CR>

nnoremap gn :bn<cr>
nnoremap gp :bp<cr>
nnoremap gw :Bclose<cr>

" Run Python and C files by Ctrl+h
autocmd FileType python map <buffer> <C-h> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
autocmd FileType python imap <buffer> <C-h> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>

autocmd FileType c map <buffer> <C-h> :w<CR>:exec '!gcc' shellescape(@%, 1) '-o out; ./out'<CR>
autocmd FileType c imap <buffer> <C-h> <esc>:w<CR>:exec '!gcc' shellescape(@%, 1) '-o out; ./out'<CR>

autocmd FileType go map <buffer> <C-h> :w<CR>:exec '!go run' shellescape(@%, 1)<CR>
autocmd FileType go imap <buffer> <C-h> <esc>:w<CR>:exec '!go run' shellescape(@%, 1)<CR>

autocmd FileType sh map <buffer> <C-h> :w<CR>:exec '!bash' shellescape(@%, 1)<CR>
autocmd FileType sh imap <buffer> <C-h> <esc>:w<CR>:exec '!bash' shellescape(@%, 1)<CR>

autocmd FileType python set colorcolumn=88

" set relativenumber
" set rnu

let g:transparent_enabled = v:true

tnoremap <Esc> <C-\><C-n>

" Telescope bindings
nnoremap ,f <cmd>Telescope find_files<cr>
nnoremap ,g <cmd>Telescope live_grep<cr>

" Go to next or prev tab by H and L accordingly
nnoremap H gT
nnoremap L gt

" Clipboard now uses native integration via clipboard=unnamedplus
" Standard y/p commands work with system clipboard
" Use "+y and "+p if you need explicit clipboard register

" Autosave plugin

" lua << EOF
" require("auto-save").setup(
"     {
"     }
" )
" EOF

" Telescope fzf plugin
lua << EOF
require('telescope').load_extension('fzf')
EOF

" Colors for LSP diagnostic messages
hi DiagnosticError guifg=#ff6c6b
hi DiagnosticWarn  guifg=#ECBE7B
hi DiagnosticInfo  guifg=#51afef
hi DiagnosticHint  guifg=#c678dd


