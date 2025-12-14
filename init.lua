-- ==================== 基本設定 ====================
-- クリップボード連携（システムのクリップボードを使う）
vim.opt.clipboard = "unnamedplus"

-- 行番号表示
vim.opt.number = true
vim.opt.relativenumber = true

-- インデント設定
vim.opt.tabstop = 2        -- タブ文字の幅
vim.opt.shiftwidth = 2     -- インデントの幅
vim.opt.expandtab = true   -- タブをスペースに変換
vim.opt.smartindent = true -- 自動インデント

-- 一番下の余白
vim.opt.scrolloff = 8

-- 改行コードをLFに固定
vim.opt.fileformat = "unix"
vim.opt.fileformats = { "unix", "dos", "mac" }

-- 文字コード設定
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- ==================== リーダーキー設定 ====================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ==================== キーマップ設定 ====================
-- jjでインサートモードからノーマルモードに戻る
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true })

-- oil.nvimでファイルエクスプローラーを開く
vim.keymap.set('n', '<leader>e', '<cmd>Oil<CR>', { noremap = true, silent = true, desc = 'Open oil.nvim' })

-- 検索ハイライトを消す
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true })

-- エラーメッセージ表示
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true, desc = 'Show diagnostic' })

-- エラーメッセージをクリップボードにヤンク
vim.keymap.set('n', '<leader>yd', function()
  local line = vim.fn.line('.') - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = line })
  
  if #diagnostics == 0 then
    print("No diagnostic on this line")
    return
  end
  
  local messages = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, diagnostic.message)
  end
  
  local text = table.concat(messages, "\n")
  
  vim.fn.setreg('+', text)
  vim.fn.setreg('*', text)
  vim.fn.setreg('"', text)
  
  print("Yanked: " .. text)
end, { noremap = true, silent = false, desc = 'Yank diagnostic' })

-- TypeScriptの型チェックを実行（ターミナルで表示）
vim.keymap.set('n', '<leader>tc', function()
  vim.cmd('split | terminal npx tsc --noEmit 2>&1')
  vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = true })
  vim.keymap.set('n', 'q', ':q<CR>', { buffer = true, noremap = true })
end, { desc = 'Run tsc' })

-- ディレクトリ検索してoilで開く（fdfindを使用）
vim.keymap.set('n', '<leader>fd', function()
  local handle = io.popen("fdfind --type d --strip-cwd-prefix")
  local result = handle:read("*a")
  handle:close()
  
  local cwd = vim.fn.getcwd()
  local items = {}
  for line in result:gmatch("[^\r\n]+") do
    local abs_path = cwd .. "/" .. line
    table.insert(items, { text = line, file = abs_path })
  end
  
  Snacks.picker({
    items = items,
    confirm = function(picker, item)
      if item and item.file then
        require("oil").open(item.file)
      end
    end
  })
end, { desc = "Find Directory and open in Oil" })

-- import { pipe } from fp-ts/functionを追加
-- fp-ts/functionが候補に出ない問題の解決
vim.keymap.set('n', '<leader>if', function()
  -- TypeScript/TSXファイル以外では実行しない
  local filetype = vim.bo.filetype
  if filetype ~= "typescript" and filetype ~= "typescriptreact" then
    print("This command is only for TypeScript files")
    return
  end
  
  -- ファイル全体を検索して、既にfp-ts/functionのインポートがあるか確認
  local has_import = vim.fn.search('from [\'"]fp-ts/function[\'"]', "nw") > 0
  
  if has_import then
    print("fp-ts/function import already exists")
    return
  end
  
  -- 最後のimport文の位置を探す
  local line = vim.fn.search("^import", "bnW")
  if line == 0 then
    line = 0  -- import文がなければファイルの先頭
  end
  
  -- インポート文を追加
  vim.fn.append(line, "import {  } from 'fp-ts/function'")
  print("Added fp-ts/function import")
end, { desc = "Add fp-ts/function import" })

-- ==================== 自動コマンド設定 ====================
-- Quickfixウィンドウで項目選択したら自動で閉じる
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>:cclose<CR>', { buffer = true, silent = true })
  end,
})

-- ==================== lazy.nvimの自動インストール ====================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==================== プラグイン設定 ====================
require("lazy").setup({
  -- ファイルエクスプローラー（oil.nvim）
  {
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup({
        keymaps = {
          ["q"] = "actions.close", -- qで閉じる
        },
        win_options = {
          signcolumn = "yes:2",  -- これを追加
        },
      })
    end,
  },

  -- コメントアウト機能（Comment.nvim）
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- ファイル検索・Grep（snacks.nvim）
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },       -- 大きなファイルの最適化
      notifier = { enabled = true },      -- 通知機能
      quickfile = { enabled = true },     -- クイックファイル表示
      statuscolumn = { enabled = true },  -- ステータスカラム
      words = { enabled = true },         -- 単語のハイライト
    },
    keys = {
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
      { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Open Buffers (Current)" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent Files (All)" },
    },
  },

  -- シンタックスハイライト（Tree-sitter）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "typescript", "tsx", "javascript", "markdown" },
        highlight = {
          enable = true,
        },
      })
    end,
  },

  -- 括弧の自動補完（nvim-autopairs）
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      
      -- nvim-cmpと連携
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on(
        "confirm_done",
        cmp_autopairs.on_confirm_done()
      )
    end,
  },

  -- コードフォーマッター（conform.nvim）
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "eslint_d", "prettier" },
          typescript = { "eslint_d", "prettier" },
          javascriptreact = { "eslint_d", "prettier" },
          typescriptreact = { "eslint_d", "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          markdown = { "prettier" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,  -- prettierがなければLSPのフォーマッターを使う
        },
        format_on_save = function(bufnr)
          -- まずconform.nvimでフォーマット
          require("conform").format({ bufnr = bufnr })
          
          -- その後organize imports
          local params = vim.lsp.util.make_range_params()
          params.context = { only = { "source.organizeImports" } }
          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 200)
          for _, res in pairs(result or {}) do
            for _, action in pairs(res.result or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
              end
            end
          end
        end,
      })
    end,
  },

  -- 補完エンジン（nvim-cmp）
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP補完ソース
      "hrsh7th/cmp-buffer",    -- バッファ内の単語補完
      "hrsh7th/cmp-path",      -- パス補完
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] = cmp.mapping.select_next_item(),      -- Ctrl+n: 次の候補
          ['<C-j>'] = cmp.mapping.select_next_item(),      -- Ctrl+j: 次の候補
          ['<C-p>'] = cmp.mapping.select_prev_item(),      -- Ctrl+p: 前の候補
          ['<C-k>'] = cmp.mapping.select_prev_item(),      -- Ctrl+k: 前の候補
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),         -- ドキュメントスクロール（上）
          ['<C-f>'] = cmp.mapping.scroll_docs(4),          -- ドキュメントスクロール（下）
          ['<C-Space>'] = cmp.mapping.complete(),          -- 補完を手動で開く
          ['<C-e>'] = cmp.mapping.abort(),                 -- 補完を閉じる
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Enter: 選択確定
          ['<Tab>'] = cmp.mapping.select_next_item(),      -- Tab: 次の候補
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),    -- Shift+Tab: 前の候補
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- LSPからの補完
          { name = 'buffer' },   -- バッファ内の単語
          { name = 'path' },     -- ファイルパス
        }),
      })
    end,
  },

  -- TypeScriptエラーメッセージを分かりやすく表示（ts-error-translator）
  {
    "dmmulroy/ts-error-translator.nvim",
    config = function()
      require("ts-error-translator").setup()
    end,
  },

  -- カラースキーム（Iceberg）
  {
    "cocopon/iceberg.vim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("iceberg")
    end,
  },

  -- LSPインストーラー（Mason）
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- LSP設定（nvim-lspconfig）
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- LSP起動時にキーマップを設定
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)           -- 定義へジャンプ
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)          -- 宣言へジャンプ
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)       -- 実装へジャンプ
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)           -- 参照一覧
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)                 -- ホバー（関数の説明）
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)       -- リネーム
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)  -- コードアクション
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)    -- シグネチャヘルプ（引数の説明）
        end,
      })
    end,
  },

  -- TypeScript開発ツール（typescript-tools.nvim）
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { 
      "nvim-lua/plenary.nvim",
    },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      
      require("typescript-tools").setup({
        capabilities = capabilities,
        settings = {
          tsserver_file_preferences = {
            importModuleSpecifierPreference = "shortest",
            importModuleSpecifierEnding = "minimal",
          },
        },
        -- キーマップ設定
        on_attach = function(client, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts)
        end,
      })
    end,
  },

  -- 一番下の余白
  {
    'Aasim-A/scrollEOF.nvim',
    config = function()
      require('scrollEOF').setup()
    end
  },

  -- Neogit
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<CR>", desc = "Neogit" },
      { "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Neogit commit" },
    },
    config = function()
      require("neogit").setup({
        integrations = {
          diffview = true,
        },
      })
    end,
  },
  
  -- oil-git-status.nvim
  {
    "refractalize/oil-git-status.nvim",
    dependencies = {
      "stevearc/oil.nvim",
    },
    config = function()
      require("oil-git-status").setup({
        show_ignored = true,
      })
    end,
  },
})
