local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	-- 判断系统 如果是mac 需要 coreutils 因为脚本需要 grealpath
	local output, err = Command("uname"):arg("-s"):output()
	local OS = string.gsub(tostring(output.stdout), "%s$", "")
	if OS == "Darwin" then
		output, err = Command("which"):arg("grealpath"):output()
		if not output.status.success then
			ya.notify({
				title = "Coreutils Required ",
				content = "You can install coreutils by running brew install coreutils in the terminal.",
				timeout = 6.0,
				level = "warn",
			})
			return
		end
	end

	local choice_mode
	local compression_mode
	local cancel = false
	-- 文件是一个还是多个
	if #opts.selected == 1 then
		choice_mode = "single"
		compression_mode = "combined"
	else
		choice_mode = "multiple"
		-- 压缩成一个还是分别压缩
		local menuOptions = {
			"Compress to Zip",
			"Compress Each to Zip",
		}
		-- 确认
		local onConfirm = function(cursor)
			compression_mode = (cursor == 1) and "combined" or "separate"
		end
		-- 取消
		-- stylua: ignore
		local onCancel = function() cancel = true end
		-- 菜单
		local menu = Popup.Menu:new(menuOptions, opts.flags.around, onConfirm, onCancel)
		menu:show()
	end

	-- stylua: ignore
	if cancel then return end

	-- The script here won't work without "./"
	-- The script file must have execution permissions
	-- stylua: ignore
	output, err = Command("./ziparchive.sh")
		:cwd(opts.workpath) -- Enter the directory of the action plugin
		:env("choice_mode", choice_mode)
		:env("compression_mode", compression_mode)
		-- To avoid issues with spaces in filenames, here we use Tab to separate
		-- Therefore, in the script file, it must declare IFS=$'\t'
		:env("selection", table.concat(opts.selected, "\t"))
		:output()

	if opts.flags.debug then
		ya.err("====debug info====")
		if err ~= nil then
			ya.err("err:" .. tostring(err))
		else
			ya.err("OK? :" .. tostring(output.status.success))
			ya.err("Code:" .. tostring(output.status.code))
			ya.err("stdout:" .. output.stdout)
			ya.err("stderr" .. output.stderr)
		end
	end
	--For detailed usage of the 'output' and 'err' variables,
	--please refer to: https://yazi-rs.github.io/docs/plugins/utils#output
end

return M
