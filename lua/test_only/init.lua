local M = {}
local wk = require("which-key")

local function node_at_cursor()
	local ts_utils = require("nvim-treesitter.ts_utils")
	return ts_utils.get_node_at_cursor()
end

local function find_test_call(node)
	while node do
		if node:type() == "call_expression" then
			local func = node:child(0) -- first child is the function
			if func and func:type() == "identifier" then
				local name = vim.treesitter.get_node_text(func, 0)
				if name == "test" then
					return node
				end
			end
		end
		node = node:parent()
	end
	return nil
end

local function toggle_only(call)
	local func_node = call:child(0)
	local is_only = false

	if func_node:type() == "member_expression" then
		local property = func_node:child(1)
		local prop_name = vim.treesitter.get_node_text(property, 0)
		if prop_name == "only" then
			is_only = true
		end
	end

	print("is_only", is_only)
	local start_row = call:start()
	local lines = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)
	print("lines", vim.inspect(lines))
	local line = lines[1] or "" --fallback to empty string
	print("line", line)

	if is_only then
		line = line:gsub("test%.only", "test")
	else
		line = line:gsub("test", "test.only", 1)
	end

	print("subbed line", line)
	vim.api.nvim_buf_set_lines(0, start_row, start_row + 1, false, { line })
end

M.inspect_node = function()
	local node = node_at_cursor()
	if not node then
		print("No node at cursor")
		return
	end
	local call = find_test_call(node)
	if not call then
		print("Not inside a call expression")
		return
	end

	toggle_only(call)
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
