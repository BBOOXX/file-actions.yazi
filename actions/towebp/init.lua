local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	local output, err = Command("which"):arg("magick"):output()

	if not output.status.success then
		ya.notify({
			title = "Imagemagick Required ",
			content = "This action script requires ImageMagick to function properly. Please install ImageMagick to continue.",
			timeout = 6.0,
			level = "warn",
		})
		return
	end

	local lossless
	local quality = 85
	local cancel = false
	local input_event

	-- 有损/无损 模式
	local menuOptions = {
		"Lossy mode",
		"Lossless mode",
	}
	-- 确认
	local onConfirm = function(cursor)
		lossless = (cursor == 2)
	end
	-- 取消
	-- stylua: ignore
	local onCancel = function() cancel = true end
	-- 菜单
	local menu = Popup.Menu:new(menuOptions, opts.flags.around, onConfirm, onCancel)
	menu:show()

	-- stylua: ignore
	if cancel then return end

	quality, input_event = ya.input({
		title = "Quality (1-100)",
		value = quality,
		position = {
			"top-center",
			y = 1,
			w = 20,
		},
	})

	-- stylua: ignore
	if input_event ~= 1 then return end
	quality = tonumber(quality)
	-- stylua: ignore
	if not quality  then return end

	quality = math.max(1, math.min(quality, 100))

	-- stylua: ignore
	-- The script here won't work without "./"
	-- The script file must have execution permissions
	output, err = Command("./towebp.sh")
		:cwd(opts.workpath) -- Enter the directory of the action plugin
		-- To avoid issues with spaces in filenames, here we use Tab to separate
		-- Therefore, in the script file, it must declare IFS=$'\t'
		:env("lossless", tostring(lossless))
		:env("quality", math.floor(quality))
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
