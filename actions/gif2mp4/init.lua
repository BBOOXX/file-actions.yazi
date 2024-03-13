local M = {}

--luacheck: ignore output err
function M.init(_, opts)
	-- stylua: ignore
	local output, err = Command("which")
		:arg("ffmpeg")
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:output()

	if not output.status:success() then
		ya.notify({
			title = "FFmpeg Required ",
			content = "FFmpeg installation needed.",
			timeout = 6.0,
			level = "warn",
		})
		return
	end

	-- stylua: ignore
	-- The script here won't work without "./"
	-- The script file must have execution permissions
	output, err = Command("./gif2mp4.sh")
		:cwd(opts.workpath) -- Enter the directory of the action plugin
	-- To avoid issues with spaces in filenames, here we use Tab to separate
	-- Therefore, in the script file, it must declare IFS=$'\t'
		:env("selection", table.concat(opts.selected, "\t"))
		:output()

	ya.err("====debug info====")
	ya.err("OK? :" .. tostring(output.status:success()))
	ya.err("Code:" .. tostring(output.status:code()))
	ya.err("stdout:" .. output.stdout)
	ya.err("stderr" .. output.stderr)
	ya.err("err:" .. tostring(err))

	--For detailed usage of the 'output' and 'err' variables,
	--please refer to: https://yazi-rs.github.io/docs/plugins/utils#output
end

return M
