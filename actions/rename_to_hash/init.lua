local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	-- stylua: ignore
	-- The script here won't work without "./"
	-- The script file must have execution permissions
	local output, err = Command("./md5name.sh")
		:cwd(opts.workpath) -- Enter the directory of the action plugin
		-- To avoid issues with spaces in filenames, here we use Tab to separate
		-- Therefore, in the script file, it must declare IFS=$'\t'
		:env("selection", table.concat(opts.selected, "\t"))
		:output()

	--For detailed usage of the 'output' and 'err' variables,
	--please refer to: https://yazi-rs.github.io/docs/plugins/utils#output
end

return M
