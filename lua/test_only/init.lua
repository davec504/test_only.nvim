local M = {}
local wk = require("which-key")

local function node_at_cursor()
	local ts_utils = require("nvim-treesitter.ts_utils")
	return ts_utils.get_node_at_cursor()
end

local function find_parent_call(node)
	while node do
		if node:type() == "call_expression" then
			return node
		end
		node = node:parent()
	end
	return nil
end

M.inspect_node = function()
	local node = node_at_cursor()
	if not node then
		print("No node at cursor")
		return
	end
	local call = find_parent_call(node)
	if not call then
		print("Not inside a call expression")
		return
	end

	local ts_utils = require("nvim-treesitter.ts_utils")
	local text = vim.treesitter.get_node_text(call, 0)
	print("Nearest call expression in\n" .. text)
end

-- ======== WHICH KEY SETUP ====================

vim.keymap.set("n", "<M-ti>", function()
	M.inspect_node()
end, { noremap = true, silent = true, desc = "Inspect test call (tree-sitter)" })

wk.add({
	{ "<leader>t", group = "Test" }, -- group title
	{
		"<leader>ti",
		function()
			M.inspect_node()
		end,
		desc = "Inspect test call (Tree-sitter)",
		mode = "n",
	},
})

return M
