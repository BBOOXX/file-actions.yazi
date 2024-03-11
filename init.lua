local cands = {
	{ on = "j", desc = "下一项" },
	{ on = "<Down>", desc = "下一项" },
	{ on = "k", desc = "上一项" },
	{ on = "<Up>", desc = "上一项" },
	{ on = "G", desc = "最后一项" },
	{ on = "g", desc = "第一项" },
	{ on = "<Esc>", desc = "取消" },
	{ on = "<Enter>", desc = "确认" },
}

local key_to_action = {
	[1] = "next", -- on = "j"
	[2] = "next", -- on = "<Down>"
	[3] = "prev", -- on = "k"
	[4] = "prev", -- on = "<up>"
	[5] = "last", -- on = "G"
	[6] = "first", -- on = "gg"
	[7] = "cancel", -- on = "<Esc>"
	[8] = "confirm", -- on = "<Enter>"
}

-- 设定滚动偏移量，即光标上下的保留行数
local scroll_offset = 3
-- 显示窗口最大项目数
local window_size = 10

local miscellaneous = ya.sync(function(state)
	-- 获取同步上下文
	if state.old_render == nil then
		state.old_render = Manager.render
	end

	local result = {}
	-- 已选择的文件
	result.selected_files = {}
	for _, url in pairs(cx.active.selected) do
		table.insert(result.selected_files, tostring(url))
	end
	-- 动作插件路径
	result.actions_path = string.format("%s/%s.yazi/actions", BOOT.plugin_dir, YAZI_PLUGIN_NAME)
	return result
end)

local function center_layout(area, height)
	-- 返回在 parent 区域居中的 rect
	-- height 窗口区域高度
	--luacheck: ignore parent_layout preview_layout
	local parent_layout, current_layout, preview_layout = table.unpack(ui
		.Layout()
		-- 配置文件定义的布局
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(MANAGER.ratio.parent, MANAGER.ratio.all),
			ui.Constraint.Ratio(MANAGER.ratio.current, MANAGER.ratio.all),
			ui.Constraint.Ratio(MANAGER.ratio.preview, MANAGER.ratio.all),
		})
		:split(area))
	--luacheck: ignore left_margin right_margin
	local left_margin, centered_content_layout, right_margin = table.unpack(ui
		.Layout()
		-- 左中右
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Ratio(1, 6),
			ui.Constraint.Ratio(4, 6),
			ui.Constraint.Ratio(1, 6),
		})
		:split(current_layout))

	--luacheck: ignore top_margin bottom_margin
	local top_margin, centered_ontent = table.unpack(ui
		.Layout()
		-- 上中没下
		:direction(ui.Layout.VERTICAL)
		:constraints({
			ui.Constraint.Length(1),
			ui.Constraint.Length(height + 2), -- 窗口高度加上Padding
		})
		:split(centered_content_layout))

	return centered_ontent
end

local function popup_render(area, iterms, cursor)
	-- area   : rect
	-- iterms : 项目
	-- cursor : 窗口中光标的位置
	local list_items = {}
	for i, item in ipairs(iterms) do
		list_items[#list_items + 1] = ui.ListItem(item):style(i == cursor and THEME.manager.hovered or nil)
	end
	return {
		-- 清理区域
		ui.Clear(area),
		-- 边框
		ui.Border(area, ui.Bar.ALL):type(ui.Border.ROUNDED):style(THEME.tasks.border),
		-- 列表
		ui.List(area:padding(ui.Padding.xy(1, 1)), list_items),
	}
end

local draw_popup = ya.sync(function(state, display, height, iterms, cursor)
	-- 绘制窗口
	-- state : 装着咕噜的宝贝
	-- display : 绘制窗口吗？
	-- height : 窗口高度
	-- iterms : 项目
	-- cursor : 窗口中光标的位置
	Manager.render = function(self, area)
		local renders = { state.old_render(self, area) }
		if display then
			local popup_layout = center_layout(area, height)
			table.insert(renders, popup_render(popup_layout, iterms, cursor))
		end
		return ya.flat(renders)
	end
	ya.render()
end)

local entry = function()
	local sync_state = miscellaneous()
	-- 获取动作列表
	-- stylua: ignore
	local action_child = Command("sh")
		:cwd(ya.quote(sync_state.actions_path))
		:args({"-c","ls -d */" })
		:stdout(Command.PIPED)
		:spawn()

	local action_list = {}
	while true do
		local line, event = action_child:read_line()
		if event == 0 then
			local action_name = string.gsub(line, "/%s$", "")
			table.insert(action_list, action_name)
		elseif event == 2 then
			break
		end
	end

	-- 动作列表是空的
	if #action_list == 0 then
		ya.err("啥都没有")
		--ya.manager_emit("select_all", { state = "false" })
		return
	end

	-- 选择的文件数量
	if #sync_state.selected_files == 0 then
		ya.err("啥也没选")
		return
	end

	-- 显示范围 开始
	local action_window_start = 1
	-- 显示范围 结束 项目少就不用那么大窗口
	local action_window_end = math.min(window_size, #action_list)
	-- 窗口高度
	local window_height = action_window_end
	-- 当前光标在窗口内的位置
	local window_cursor = 1
	-- 光标实际位置
	local cursor = 1

	while true do
		-- 绘制窗口
		draw_popup(
			true,
			window_height,
			{ table.unpack(action_list, action_window_start, action_window_end) }, --显示部分内容
			window_cursor
		)

		-- 获取输入
		local key = ya.which({ cands = cands, silent = true })
		local key_action = key_to_action[key]

		-- 根据键入的动作调整光标位置或窗口显示范围
		if key_action == "next" then
			-- 在边界之前光标可以向下
			-- 或者滑窗到底了也允许光标向下
			if window_cursor < (window_height - scroll_offset) or action_window_end == #action_list then
				-- 保证不出边界
				window_cursor = math.min(window_cursor + 1, window_height)
				cursor = math.min(cursor + 1, #action_list)
			-- 到达边界则滚动内容
			-- 滚到底会移动光标不用担心窗口继续滑动
			elseif window_cursor == (window_height - scroll_offset) then
				action_window_start = action_window_start + 1
				action_window_end = action_window_end + 1
				cursor = cursor + 1
			end
		-- 在边界之前光标可以向上
		-- 或者滑窗到顶了也允许光标向上
		elseif key_action == "prev" then
			if window_cursor > (1 + scroll_offset) or action_window_start == 1 then
				-- 保证不出边界
				window_cursor = math.max(window_cursor - 1, 1)
				cursor = math.max(cursor - 1, 1)
			-- 到达边界则滚动内容
			-- 滚到底会移动光标不用担心窗口继续滑动
			elseif window_cursor == (1 + scroll_offset) then
				action_window_start = action_window_start - 1
				action_window_end = action_window_end - 1
				cursor = cursor - 1
			end
		elseif key_action == "last" then -- 跳转到底部
			window_cursor = window_height
			action_window_start = #action_list - window_height + 1
			action_window_end = #action_list
			cursor = #action_list
		elseif key_action == "first" then -- 跳转到顶部
			window_cursor = 1
			action_window_start = 1
			action_window_end = window_height
			cursor = 1
		elseif key_action == "confirm" then -- 确认
			-- 取消选择
			ya.manager_emit("select_all", { state = "false" })
			-- 恢复界面
			draw_popup(false)
			-- 纸糊的部分
			package.path = sync_state.actions_path .. "/?/init.lua;" .. package.path
			local mod = require(action_list[cursor])
			mod:init({
				workpath = sync_state.actions_path .. "/" .. action_list[cursor],
				selected = sync_state.selected_files,
			})
			break
		elseif key_action == "cancel" or key_action == nil then
			-- 如果是取消或其他输入，恢复界面
			draw_popup(false)
			break
		end
	end
end

return { entry = entry }
