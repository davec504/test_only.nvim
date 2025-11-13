local M = {}
local wk = require("which-key")

local valid_identifiers = {
	test = true,
	it = true,
}

local function node_at_cursor()
	local ts_utils = require("nvim-treesitter.ts_utils")
	return ts_utils.get_node_at_cursor()
end

local function is_test_function_node(node)
	if not node then
		return false
	end
	local t = node:type()
	local name = vim.treesitter.get_node_text(node, 0)

	if valid_identifiers[name] then
		return true
	end

	if t == "property_identifier" then
		return valid_identifiers[name] == true
	elseif t == "member_expression" then
		local left = node:child(0)
		return is_test_function_node(left)
	else
		return false
	end
end

local function find_test_call(node)
	while node do
		if node:type() == "call_expression" then
			local func_node = node:child(0) -- first child is the function

			if is_test_function_node(func_node) then
				return node
			end
		end
		node = node:parent()
	end
	return nil
end

local function toggle_only(call)
	local func_node = call:child(0)
	local func_text = vim.treesitter.get_node_text(func_node, 0)
	local is_only = func_text:match("%.only") ~= nil

	print("is_only", is_only)
	local start_row = call:start()
	local lines = vim.api.nvim_buf_get_lines(0, start_row, start_row + 1, false)
	print("lines", vim.inspect(lines))
	local line = lines[1] or "" --fallback to empty string
	print("line", line)

	if is_only then
		-- remove .only from whatever the function is
		line = line:gsub("([%w_]+)%.only", "%1", 1)
	else
		-- add .only only if not already present
		if not line:match("([%w_]+)%.only") then
			-- find the first valid identifier in the line
			for id, _ in pairs(valid_identifiers) do
				if line:match(id) then
					line = line:gsub(id, id .. ".only", 1)
					break
				end
			end
		end
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
