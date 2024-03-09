local M = {}

function M.init(_, opts)
	--脚本这里没有"./"不行
	--脚本文件要有执行权限
	local action_child = Command("./mp42hevc.sh")
		:cwd(opts.workpath) -- 进入动作插件目录
		--为了避免文件名中空格带来的问题这里使用 Tab 分割
		--所以脚本文件中要声明 IFS=$'\t'
		:env("selection", table.concat(opts.selected, "\t"))
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	-- TODO
	local status, err = action_child:wait()
end

return M
