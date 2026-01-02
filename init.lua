-- =============================================
-- NVIM CONFIGURATION - ORGANIZED VERSION
-- =============================================

-- =============================================
-- 1. INITIAL SETUP & GLOBALS
-- =============================================

-- Base46 cache path for theme loading
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"

-- Set leader key to Space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic editor settings
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')
vim.cmd('set encoding=UTF-8')
vim.o.termguicolors = true  -- Enable 24-bit RGB colors
vim.cmd('set background=dark')

-- =============================================
-- 2. UTILITY FUNCTIONS
-- =============================================

-- Timer utilities (like JavaScript setInterval/setTimeout)
local function setInterval(interval, callback)
    local timer = vim.loop.new_timer()
    timer:start(interval, interval, vim.schedule_wrap(callback))
end

local function setTimeout(interval, callback)
    local timer = vim.loop.new_timer()
    timer:start(interval, 0, vim.schedule_wrap(callback))
end

-- Check if any floating windows or popups are visible
local function is_floating_or_popup_visible()
    if vim.fn.pumvisible() == 1 then
        return true
    end
    
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        if (config.zindex and config.zindex > 0) or 
           (config.relative and config.relative ~= "") then
            return true
        end
    end
    
    return false
end

-- =============================================
-- 3. PLUGIN MANAGEMENT (LAZY.NVIM)
-- =============================================

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ 
        "git", "clone", "--filter=blob:none", 
        "--branch=stable", lazyrepo, lazypath 
    })
    
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

-- Load lazy.nvim configuration
local lazy_config = require "configs.lazy"

-- Plugin specifications
require("lazy").setup({
    -- Core NvChad framework
    {
        "NvChad/NvChad",
        lazy = false,
        branch = "v2.5",
        import = "nvchad.plugins",
    },
    
    -- LSP & Autocompletion
    'neovim/nvim-lspconfig',
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    
    -- Snippets
    'L3MON4D3/LuaSnip',
    
    -- Debugging (DAP)
    'mfussenegger/nvim-dap',
    'leoluz/nvim-dap-go',
    { 
        "rcarriga/nvim-dap-ui", 
        dependencies = {
            "mfussenegger/nvim-dap", 
            "nvim-neotest/nvim-nio"
        } 
    },
    "theHamsta/nvim-dap-virtual-text",
    {'sebdah/vim-delve', lazy = false},
    
    -- LSP enhancements
    {
        "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
        lazy = false,
        config = function()
            require("lsp_lines").setup()
        end,
    },
    
    -- Icons
    {
        'glepnir/nerdicons.nvim', 
        cmd = 'NerdIcons', 
        config = function() 
            require('nerdicons').setup({}) 
        end
    },
    
    -- Additional plugins from plugins directory
    { import = "plugins" },
    
}, lazy_config)

-- =============================================
-- 4. THEME & UI CONFIGURATION
-- =============================================

-- Load Base46 theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- Editor options
require "options"
require "nvchad.autocmds"

-- Display settings
vim.o.number = true           -- Show line numbers
-- vim.o.relativenumber = true   -- Relative line numbers (commented out)
vim.o.cursorline = true       -- Highlight current line
vim.o.signcolumn = 'yes'      -- Reserve space for signs (LSP, etc.)
vim.o.wrap = false            -- Don't wrap lines
vim.o.clipboard = 'unnamedplus' -- System clipboard integration

-- Indentation settings
vim.o.tabstop = 4            -- Number of spaces a tab represents
vim.o.shiftwidth = 4         -- Spaces for indentation
vim.o.expandtab = true       -- Convert tabs to spaces
vim.o.smartindent = true     -- Smart auto-indenting

-- Autocompletion settings
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

-- Schedule mappings to load after UI
vim.schedule(function()
    require "mappings"
end)

-- =============================================
-- 5. LSP (LANGUAGE SERVER PROTOCOL) CONFIG
-- =============================================

-- Enhanced LSP capabilities for autocompletion
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
    'force',
    lspconfig_defaults.capabilities,
    require('cmp_nvim_lsp').default_capabilities()
)
local capabilities = lspconfig_defaults.capabilities

-- LSP keybindings on attach
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp-attach-format', { clear = true }),
    
    callback = function(args)
        local client_id = args.data.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        local bufnr = args.buf
        local opts = { buffer = bufnr }
        
        -- Navigation
        vim.keymap.set('n', 'ge', '<cmd>lua vim.diagnostic.open_float(ni, {focus=false})<CR>', opts)
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        
        -- Code actions
        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n', 'gw', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
        
        -- Build/run commands
        vim.api.nvim_set_keymap('n', '<F9>', ':make<cr>', { noremap = true })
        vim.api.nvim_set_keymap('n', '<F10>', ':make %:r<cr>', { noremap = true })
        vim.api.nvim_set_keymap('n', '<F22>', ':! %:r<cr>', { noremap = true })  -- Fallback for Shift-F10
        vim.api.nvim_set_keymap('n', '<S-F10>', ':! %:r<cr>', { noremap = true })
        
        -- Document highlighting if supported
        if client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_augroup("lsp_document_highlight", { clear = true })
            vim.api.nvim_clear_autocmds { buffer = bufnr, group = "lsp_document_highlight" }
            
            vim.api.nvim_create_autocmd("CursorHold", {
                callback = vim.lsp.buf.document_highlight,
                buffer = bufnr,
                group = "lsp_document_highlight",
                desc = "Document Highlight",
            })
            
            vim.api.nvim_create_autocmd("CursorMoved", {
                callback = vim.lsp.buf.clear_references,
                buffer = bufnr,
                group = "lsp_document_highlight",
                desc = "Clear All the References",
            })
        end
    end,
})

-- Auto-format on save
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        local mode = vim.api.nvim_get_mode().mode
        local filetype = vim.bo.filetype
        
        if vim.bo.modified == true and mode == 'n' and filetype ~= "oil" then
            vim.cmd('lua vim.lsp.buf.format()')
        end
    end
})

-- =============================================
-- 6. AUTOCOMPLETION (CMP) CONFIG
-- =============================================

local cmp = require('cmp')
local luasnip = require("luasnip")
local select_opts = { behavior = 'select' }

-- Load snippets from VSCode
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    
    sources = {
        { name = 'nvim_lsp', priority = 99 },
        { name = 'luasnip', priority = 90 },
        { name = 'nvim_lua', priority = 80 },
        { name = 'cmp_tabnine', priority = 80 },
        { name = 'path', priority = 10 },
        { name = 'buffer', priority = 0 },
    },
    
    formatting = {
        fields = {'menu', 'abbr', 'kind'},
        format = function(entry, item)
            local menu_icon = {
                nvim_lsp = 'λ',
                luasnip = '⋗',
                buffer = 'Ω',
                path = '🖫',
            }
            item.menu = menu_icon[entry.source.name]
            return item
        end,
    },
    
    mapping = {
        ['<C-n>'] = cmp.mapping.select_next_item(select_opts),
        ['<C-p>'] = cmp.mapping.select_prev_item(select_opts),
        ['<C-f>'] = cmp.mapping.scroll_docs(-4),
        ['<C-b>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<Esc>'] = cmp.mapping.close(),
        
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item(select_opts)
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item(select_opts)
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
        
        ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }),
    },
})

-- =============================================
-- 7. LANGUAGE SERVERS SETUP
-- =============================================

-- Go
require'lspconfig'.gopls.setup{ capabilities = capabilities }

-- Lua
require'lspconfig'.lua_ls.setup{ capabilities = capabilities }

-- JSON
require'lspconfig'.jsonls.setup{ capabilities = capabilities }

-- SQL
require'lspconfig'.sqlls.setup{ capabilities = capabilities }

-- Elixir
vim.lsp.config('elixirls', {
    cmd = { "/home/olu/opt/elixir-ls-v0.28.0/launch.sh" }
})

-- Perl
require'lspconfig'.perlpls.setup{ capabilities = capabilities }

-- Python
require'lspconfig'.pyright.setup{ capabilities = capabilities }

-- HTML
require'lspconfig'.html.setup{ capabilities = capabilities }

-- GraphQL
require'lspconfig'.graphql.setup{}

-- Helm
require'lspconfig'.helm_ls.setup{}

-- ESLint (with auto-fix on save)
require'lspconfig'.eslint.setup({
    capabilities = capabilities,
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
        })
    end,
})

-- C/C++ family
require'lspconfig'.cmake.setup{ capabilities = capabilities }
require'lspconfig'.clangd.setup{ capabilities = capabilities }
require'lspconfig'.c3_lsp.setup{ capabilities = capabilities }

-- Shell scripting
require'lspconfig'.bashls.setup{ capabilities = capabilities }
require'lspconfig'.awk_ls.setup{ capabilities = capabilities }

-- Build systems
require'lspconfig'.autotools_ls.setup{ capabilities = capabilities }

-- GitLab CI filetype detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.gitlab-ci*.{yml,yaml}",
    callback = function()
        vim.bo.filetype = "yaml.gitlab"
    end,
})

-- =============================================
-- 8. NVIM-TREE CONFIG (WITH JUMPING FIX)
-- =============================================

require("nvim-tree").setup({
    sync_root_with_cwd = false,      -- Prevents jumping to top
    respect_buf_cwd = false,
    update_focused_file = {
        enable = true,
        update_root = false,         -- Critical: prevents jumping
        update_cwd = false,          -- Critical: prevents jumping
    },
    actions = {
        change_dir = {
            enable = true,
            global = false,          -- Critical: prevents jumping
        },
    },
})

-- Auto-reload tree without changing focus
vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    callback = function()
        require("nvim-tree.api").tree.reload()
    end,
})

-- =============================================
-- 9. SESSION MANAGEMENT (POSSESSION PLUGIN)
-- =============================================

require('possession').setup({
    session_dir = '/home/olu/.config/nvim/possesion/',
    silent = true,
    load_silent = true,
    
    autosave = {
        current = true,
        cwd = true,
        tmp = false,
        tmp_name = 'tmp',
        on_load = true,
        on_quit = true,
    },
    
    autoload = 'last',  -- or 'auto_cwd' or 'last_cwd'
    
    commands = {
        save = 'PossessionSave',
        load = 'PossessionLoad',
        save_cwd = 'PossessionSaveCwd',
        load_cwd = 'PossessionLoadCwd',
        rename = 'PossessionRename',
        close = 'PossessionClose',
        delete = 'PossessionDelete',
        show = 'PossessionShow',
        list = 'PossessionList',
        list_cwd = 'PossessionListCwd',
        migrate = 'PossessionMigrate',
    },
    
    plugins = {
        nvim_tree = true,
        delete_hidden_buffers = {
            hooks = { 'before_load' },
            force = false,
        },
    },
})

-- Session keybindings
vim.keymap.set('n', '<Leader>cc', ':PossessionClose!<CR>')
vim.keymap.set('n', '<Leader>ss', ':PossessionSave<CR>')
vim.keymap.set('n', '<Leader>co', ':Telescope possession list<CR>')

-- List sessions on startup
vim.api.nvim_create_autocmd('VimEnter', {
    command = "Telescope possession list"
})

-- Auto-save current session every minute
setInterval(60000, function()
    local curr_session = require('possession.session').get_session_name()
    local vim_mode = vim.api.nvim_exec('echo mode()', true)
    
    if not is_floating_or_popup_visible() then
        if vim_mode == 'n' or vim_mode == 'i' then
            if curr_session ~= nil and curr_session ~= '' then
                vim.cmd('set hidden')
                vim.cmd("PossessionSave! " .. curr_session)
            end
        end
    end
end)

-- =============================================
-- 10. ICONS (NVIM-WEB-DEVICONS)
-- =============================================

require'nvim-web-devicons'.setup({
    color_icons = true,
    default = true,
    strict = true,
    
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
})

-- =============================================
-- 11. DEBUGGER (DAP) CONFIGURATION
-- =============================================

local dap = require("dap")
local dapui = require("dapui")
require('dap-go').setup()
require("nvim-dap-virtual-text").setup()

-- GDB adapter for C/C++/Rust
dap.adapters.gdb = {
    id = 'gdb',
    type = 'executable',
    command = 'gdb',
    args = { '--quiet', '--interpreter=dap' },
}

-- Debug configurations
dap.configurations.c = {
    {
        name = "Launch",
        type = "gdb",
        request = "launch",
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
    },
    {
        name = "Select and attach to process",
        type = "gdb",
        request = "attach",
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        pid = function()
            local name = vim.fn.input('Executable name (filter): ')
            return require("dap.utils").pick_process({ filter = name })
        end,
        cwd = '${workspaceFolder}'
    },
    {
        name = 'Attach to gdbserver :1234',
        type = 'gdb',
        request = 'attach',
        target = 'localhost:1234',
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}'
    },
}

-- Reuse C config for C++ and Rust
dap.configurations.cpp = dap.configurations.c
dap.configurations.rust = dap.configurations.c

-- DAP UI setup
dapui.setup()
vim.fn.sign_define("DapBreakpoint", { text = "🐞" })

-- Debugger keybindings
vim.keymap.set('n', '<leader>db', function() require("dap").toggle_breakpoint() end,
    { noremap = true, desc = "Dap toggle breakpoints" })
vim.keymap.set('n', '<leader>dc', function() require("dap").continue() end,
    { noremap = true, desc = "Dap continue" })
vim.keymap.set('n', '<leader>di', function() require("dap").step_into() end,
    { desc = "Dap step into" })
vim.keymap.set('n', '<leader>df', function() require("dap").step_out() end,
    { noremap = true, desc = "Dap step out" })
vim.keymap.set('n', '<leader>dn', function() require("dap").step_over() end,
    { noremap = true, desc = "Dap step over" })
vim.keymap.set('n', '<leader>dib', function() require("dap").list_breakpoints() end,
    { noremap = true, desc = "Dap info breakpoints" })
vim.keymap.set('n', '<leader>div', function() require("dap").list_breakpoints() end,
    { noremap = true, desc = "Dap info locals" })
vim.keymap.set('n', '<leader>dt', function()
    require("dap").terminate()
    require("dapui").close()
    require("nvim-dap-virtual-text").toggle()
end, { noremap = true, desc = "Dap Terminate" })

-- DAP UI event listeners
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

-- =============================================
-- 12. DIAGNOSTICS CONFIG
-- =============================================

vim.diagnostic.config({
    virtual_text = false,    -- Disable inline diagnostic text
    virtual_lines = true,    -- Enable virtual lines for diagnostics
})

-- =============================================
-- END OF CONFIGURATION
-- =============================================
