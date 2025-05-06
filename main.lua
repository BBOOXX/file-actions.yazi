Popup = {
	Key = {
		cands = {
			{ on = "j", desc = "下一项" },
			{ on = "<Down>", desc = "下一项" },
			{ on = "k", desc = "上一项" },
			{ on = "<Up>", desc = "上一项" },
			{ on = "G", desc = "最后一项" },
			{ on = "g", desc = "第一项" },
			{ on = "<Esc>", desc = "取消" },
			{ on = "<Enter>", desc = "确认" },
		},
		key_to_action = {
			[1] = "next", -- on = "j"
			[2] = "next", -- on = "<Down>"
			[3] = "prev", -- on = "k"
			[4] = "prev", -- on = "<up>"
			[5] = "last", -- on = "G"
			[6] = "first", -- on = "gg"
			[7] = "cancel", -- on = "<Esc>"
			[8] = "confirm", -- on = "<Enter>"
		},
	},
}

Popup.Menu = {}
function Popup.Menu:new(item_list, around, onConfirm, onCancel)
	local newObj = {
		-- 设定滚动偏移量，即光标上下的保留行数
		scroll_offset = 3,
		-- 显示窗口最大项目数
		window_size = 10,
		-- 环绕模式
		around = around or false,
		-- 菜单的项目
		item_list = item_list,
		-- 确认的时候执行这个
		onConfirm = onConfirm or function(cursor)
			return cursor
		end,
		-- 取消的时候执行这个
		onCancel = onCancel or function()
			return
		end,
	}
	self.__index = self
	return setmetatable(newObj, self)
end

local miscellaneous = ya.sync(function(state)
	-- 获取同步上下文
	if state.old_render == nil then
		state.old_render = Root.render
	end

	local result = {}
	-- 光标下的文件
	result.cursor_files = {}
	local hovered = cx.active.current.hovered
	-- 空文件夹时 没有光标下的文件
	if hovered and not hovered.url.is_archive then
		table.insert(result.cursor_files, tostring(cx.active.current.hovered.url))
	end

	-- 已选择的文件
	result.selected_files = {}
	for _, url in pairs(cx.active.selected) do
		if not url.is_archive then
			table.insert(result.selected_files, tostring(url))
		end
	end
	-- 动作脚本路径
	--result.actions_path = string.format("%s/%s.yazi/actions", BOOT.plugin_dir, YAZI_PLUGIN_NAME)
	result.actions_path = string.format("%s/file-actions.yazi/actions", BOOT.plugin_dir)
	return result
end)

function Popup.center_layout(area, height)
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

function Popup.Menu.render(area, items, cursor)
	-- area : rect
	-- items : 菜单项目
	-- cursor : 窗口中光标的位置
	local list_items = {}
	for i, item in ipairs(items) do
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

Popup.Menu.draw_popup = ya.sync(function(state, display, height, items, cursor)
	-- 绘制窗口
	-- state : 装着咕噜的宝贝
	-- display : 绘制窗口吗？
	-- height : 窗口高度
	-- items : 菜单项目
	-- cursor : 窗口中光标的位置
	Root.render = function(self)
		if display then
			return ya.list_merge(
				state.old_render(self),
				Popup.Menu.render(Popup.center_layout(self._area, height), items, cursor)
			)
		end
		return state.old_render(self)
	end
	ya.render()
end)

function Popup.Menu:show()
	-- 显示范围 开始
	local window_start = 1
	-- 窗口高度
	local window_height = math.min(self.window_size, #self.item_list)
	-- 显示范围 结束 项目少就不用那么大窗口
	local window_end = window_height
	-- 光标在窗口内的位置
	local window_cursor = 1
	-- 光标实际位置
	local cursor = 1
	while true do
		-- 绘制窗口
		Popup.Menu.draw_popup(
			true,
			window_height,
			{ table.unpack(self.item_list, window_start, window_end) },
			window_cursor
		)

		-- 获取输入
		local key = ya.which({ cands = Popup.Key.cands, silent = true })
		local key_action = Popup.Key.key_to_action[key]

		::handle_key_action::
		-- 根据键入的动作调整光标位置或窗口显示范围
		if key_action == "next" then
			-- 在边界之前光标可以向下
			-- 或者滑窗到底了也允许光标向下
			if window_cursor < (window_height - self.scroll_offset) or window_end == #self.item_list then
				-- 环绕模式
				if self.around and window_cursor == window_height then
					key_action = "first" -- 跳转到顶部
					goto handle_key_action
				else
					-- 保证不出边界
					window_cursor = math.min(window_cursor + 1, window_height)
					cursor = math.min(cursor + 1, #self.item_list)
				end
			-- 到达边界则滚动内容 (调整滑窗)
			-- 滚到底会移动光标不用担心窗口继续滑动
			elseif window_cursor == (window_height - self.scroll_offset) then
				window_start = window_start + 1
				window_end = window_end + 1
				cursor = cursor + 1
			end
		-- 在边界之前光标可以向上
		-- 或者滑窗到顶了也允许光标向上
		elseif key_action == "prev" then
			if window_cursor > (1 + self.scroll_offset) or window_start == 1 then
				-- 环绕模式
				if self.around and window_cursor == 1 then
					key_action = "last" -- 跳转到底部
					goto handle_key_action
				else
					-- 保证不出边界
					window_cursor = math.max(window_cursor - 1, 1)
					cursor = math.max(cursor - 1, 1)
				end
			-- 到达边界则滚动内容 (调整滑窗)
			-- 滚到底会移动光标不用担心窗口继续滑动
			elseif window_cursor == (1 + self.scroll_offset) then
				window_start = window_start - 1
				window_end = window_end - 1
				cursor = cursor - 1
			end
		elseif key_action == "last" then -- 跳转到底部
			window_cursor = window_height
			window_start = #self.item_list - window_height + 1
			window_end = #self.item_list
			cursor = #self.item_list
		elseif key_action == "first" then -- 跳转到顶部
			window_cursor = 1
			window_start = 1
			window_end = window_height
			cursor = 1
		elseif key_action == "confirm" then -- 确认
			-- 恢复界面
			Popup.Menu.draw_popup(false)
			self.onConfirm(cursor)
			break
		elseif key_action == "cancel" or key_action == nil then -- 取消或未定义的输入
			-- 恢复界面
			Popup.Menu.draw_popup(false)
			self.onCancel()
			break
		end
	end
end

local entry = function(_, args)
	-- 插件参数
	local flags = { around = false, debug = false }
	for _, arg in pairs(args) do
		if flags[arg] ~= nil then
			flags[arg] = true
		end
	end

	local sync_state = miscellaneous()

	-- 没选择文件 光标下也没文件
	if #sync_state.cursor_files == 0 and #sync_state.selected_files == 0 then
		return
	end

	-- 没选择文件 使用光标下的文件
	if #sync_state.selected_files == 0 then
		sync_state.selected_files = sync_state.cursor_files
	end

	-- 获取文件 MIME
	local selected_mimetype_set = {}
	-- stylua: ignore
	local file_child, file_err = Command("file")
		:args({ "-bL", "--mime-type" })
		:args(sync_state.selected_files)
		:stdout(Command.PIPED)
		:spawn()

	if flags.debug and file_err then
		ya.err("file_err:" .. tostring(file_err))
	end

	while true do
		local line, event = file_child:read_line()
		if event == 0 then
			local mimetype = string.gsub(line, "%s$", "")
			selected_mimetype_set[mimetype] = true
		elseif event == 2 then
			break
		end
	end


	-- 获取动作列表
	-- stylua: ignore
	local action_child, action_err = Command("sh")
		:cwd(ya.quote(sync_state.actions_path))
		:args({"-c","ls -d */" })
		:stdout(Command.PIPED)
		:spawn()

	if flags.debug and action_err then
		ya.err("action_err:" .. tostring(action_err))
	end

	local action_paths = {}
	local action_names = {}
	while true do
		local line, event = action_child:read_line()
		if event == 0 then
			local action_path = string.gsub(line, "/%s$", "")
			-- 加载动作脚本配置信息
			local action_config = dofile(string.format("%s/%s/info.lua", sync_state.actions_path, action_path))
			-- 单一文件
			if action_config.single_or_multi == "single" and #sync_state.selected_files ~= 1 then
				goto continue_get_action
			end
			-- 多个文件
			if action_config.single_or_multi == "multi" and #sync_state.selected_files == 1 then
				goto continue_get_action
			end
			-- 检查不允许的MIME类型
			if action_config.disableMimes ~= nil then
				for _, mimetype in pairs(action_config.disableMimes) do
					if selected_mimetype_set[mimetype] then
						-- 直接跳过
						goto continue_get_action
					end
				end
			end
			-- 检查允许的MIME类型列表 有并且不是空的
			if action_config.enableMimes ~= nil and #action_config.enableMimes ~= 0 then
				-- 将允许表转换为集合便于快速查找
				local enableMimes_set = {}
				for _, mimetype in pairs(action_config.enableMimes) do
					enableMimes_set[mimetype] = true
				end
				for selected_mimetype in pairs(selected_mimetype_set) do
					-- 文件MIME在允许范围外
					if not enableMimes_set[selected_mimetype] then
						goto continue_get_action
					end
				end
			end
			-- 没有允许表或所选文件都在允许范围内 直接添加
			table.insert(action_names, action_config.name)
			table.insert(action_paths, action_path)
		elseif event == 2 then
			break
		end
		::continue_get_action::
	end

	-- 动作列表是空的
	if #action_paths == 0 then
		ya.notify({
			title = "Action Script Not Found ",
			content = "No action script available for this file type.",
			timeout = 6.0,
			level = "warn",
		})
		--ya.manager_emit("select_all", { state = "false" })
		return
	end

	local onConfirm = function(cursor)
		--ya.manager_emit("select_all", { state = "false" }) -- 取消选择
		local mod = dofile(string.format("%s/%s/init.lua", sync_state.actions_path, action_paths[cursor]))
		mod:init({
			-- 脚本工作目录
			workpath = sync_state.actions_path .. "/" .. action_paths[cursor],
			-- 所选文件
			selected = sync_state.selected_files,
			-- 插件的参数
			flags = flags,
		})
	end

	local menu = Popup.Menu:new(action_names, flags.around, onConfirm)
	menu:show()
end

return { entry = entry }
