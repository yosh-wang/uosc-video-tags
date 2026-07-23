--[[ uosc | https://github.com/tomasklaen/uosc ]]
local uosc_version = '5.12.0'

mp.commandv('script-message', 'uosc-version', uosc_version)

mp.set_property('osc', 'no')

assdraw = require('mp.assdraw')
opt = require('mp.options')
utils = require('mp.utils')
msg = require('mp.msg')
osd = mp.create_osd_overlay('ass-events')
QUARTER_PI_SIN = math.sin(math.pi / 4)

require('lib/std')

--[[ OPTIONS ]]

defaults = {
	timeline_style = 'line',
	timeline_line_width = 2,
	timeline_size = 40,
	progress = 'windowed',
	progress_size = 2,
	progress_line_width = 20,
	timeline_persistency = '',
	timeline_border = 1,
	timeline_step = '5',
	timeline_cache = true,
	timeline_heatmap = 'overlay',

	controls =
	'menu,gap,<video,audio>subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,gap,space,<video,audio>speed,space,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen',
	controls_size = 32,
	controls_margin = 8,
	controls_spacing = 2,
	controls_persistency = '',

	volume = 'right',
	volume_size = 40,
	volume_persistency = '',
	volume_border = 1,
	volume_step = 1,

	speed_persistency = '',
	speed_step = 0.1,
	speed_step_is_factor = false,

	menu_item_height = 36,
	menu_min_width = 260,
	menu_padding = 4,
	menu_type_to_search = true,

	top_bar = 'no-border',
	top_bar_size = 40,
	top_bar_persistency = '',
	top_bar_controls = 'right',
	top_bar_title = 'yes',
	top_bar_alt_title = '',
	top_bar_alt_title_place = 'below',
	top_bar_flash_on = 'video,audio',

	window_border_size = 1,

	autoload = false,
	shuffle = false,

	scale = 1,
	scale_fullscreen = 1.3,
	font = '',
	font_scale = 1,
	text_border = 1.2,
	border_radius = 4,
	color = '',
	opacity = '',
	animation_duration = 100,
	refine = '',
	flash_duration = 1000,
	proximity_in = 40,
	proximity_out = 120,
	total_time = false, -- deprecated by below
	destination_time = 'playtime-remaining',
	time_precision = 0,
	font_bold = false,
	autohide = false,
	buffered_time_threshold = 60,
	pause_indicator = 'flash',
	stream_quality_options = '4320,2160,1440,1080,720,480,360,240,144',
	video_types =
	'3g2,3gp,asf,avi,f4v,flv,h264,h265,m2ts,m4v,mkv,mov,mp4,mp4v,mpeg,mpg,ogm,ogv,rm,rmvb,ts,vob,webm,wmv,y4m',
	audio_types =
	'aac,ac3,aiff,ape,au,cue,dsf,dts,flac,m4a,mid,midi,mka,mp3,mp4a,oga,ogg,opus,spx,tak,tta,wav,weba,wma,wv',
	image_types = 'apng,avif,bmp,gif,j2k,jp2,jfif,jpeg,jpg,jxl,mj2,png,svg,tga,tif,tiff,webp',
	subtitle_types = 'aqt,ass,gsub,idx,jss,lrc,mks,pgs,pjs,psb,rt,sbv,slt,smi,sub,sup,srt,ssa,ssf,ttxt,txt,usf,vt,vtt',
	playlist_types = 'm3u,m3u8,pls,url,cue',
	load_types = 'video,audio,image',
	default_directory = '~/',
	show_hidden_files = false,
	use_trash = false,
	adjust_osd_margins = true,
	chapter_ranges = 'openings:30abf964,endings:30abf964,ads:c54e4e80',
	chapter_range_patterns = 'openings:オープニング;endings:エンディング',
	languages = 'slang,en',
	subtitles_directory = '~~/subtitles',
	disable_elements = '',
	ziggy_path = 'default',
}
options = table_copy(defaults)
function handle_options(changed_options)
	if changed_options.time_precision then
		timestamp_zero_rep_clear_cache()
	end
	update_config()
	update_human_times()
	Manager:disable('user', options.disable_elements)
	Elements:trigger('options')
	Elements:update_proximities()
	request_render()
end
opt.read_options(options, 'uosc', handle_options)
-- Normalize values
options.proximity_out = math.max(options.proximity_out, options.proximity_in + 1)
if options.chapter_ranges:sub(1, 4) == '^op|' then options.chapter_ranges = defaults.chapter_ranges end
if options.total_time and options.destination_time == 'playtime-remaining' then
	msg.warn('`total_time` is deprecated. Use `destination_time` instead.')
	options.destination_time = 'total'
elseif not itable_index_of({'total', 'playtime-remaining', 'time-remaining'}, options.destination_time) then
	options.destination_time = 'playtime-remaining'
end
if not itable_index_of({'left', 'right'}, options.top_bar_controls) then
	options.top_bar_controls = options.top_bar_controls == 'yes' and 'right' or nil
end

--[[ INTERNATIONALIZATION ]]
local intl = require('lib/intl')
t = intl.t
require('lib/char_conv')
fzy = require('lib/fzy')

--[[ CONFIG ]]
local config_defaults = {
	color = {
		foreground = serialize_rgba('ffffff').color,
		foreground_text = serialize_rgba('000000').color,
		background = serialize_rgba('000000').color,
		background_text = serialize_rgba('ffffff').color,
		window_border = serialize_rgba('000000').color,
		curtain = serialize_rgba('111111').color,
		success = serialize_rgba('a5e075').color,
		error = serialize_rgba('ff616e').color,
		match = serialize_rgba('69c5ff').color,
		heatmap = serialize_rgba('00adee').color,
	},
	opacity = {
		timeline = 0.9,
		position = 1,
		chapters = 0.8,
		slider = 0.9,
		slider_gauge = 1,
		controls = 0,
		speed = 0.6,
		menu = 1,
		submenu = 0.4,
		border = 1,
		title = 1,
		tooltip = 1,
		thumbnail = 1,
		curtain = 0.8,
		idle_indicator = 0.8,
		audio_indicator = 0.5,
		buffering_indicator = 0.3,
		playlist_position = 0.8,
		heatmap = 0.4,
	},
}
config = {
	version = uosc_version,
	open_subtitles_api_key = 'b0rd16N0bp7DETMpO4pYZwIqmQkZbYQr',
	open_subtitles_agent = 'uosc v' .. uosc_version,
	-- sets max rendering frequency in case the
	-- native rendering frequency could not be detected
	render_delay = 1 / 60,
	font = options.font ~= '' and options.font or mp.get_property('options/osd-font'),
	osd_margin_x = mp.get_property('osd-margin-x'),
	osd_margin_y = mp.get_property('osd-margin-y'),
	osd_alignment_x = mp.get_property('osd-align-x'),
	osd_alignment_y = mp.get_property('osd-align-y'),
	refine = create_set(comma_split(options.refine)),
	types = {
		video = comma_split(options.video_types),
		audio = comma_split(options.audio_types),
		image = comma_split(options.image_types),
		subtitle = comma_split(options.subtitle_types),
		playlist = comma_split(options.playlist_types),
		media = comma_split(options.video_types
			.. ',' .. options.audio_types
			.. ',' .. options.image_types
			.. ',' .. options.playlist_types),
		load = {}, -- populated by update_load_types() below
	},
	stream_quality_options = comma_split(options.stream_quality_options),
	top_bar_flash_on = comma_split(options.top_bar_flash_on),
	chapter_ranges = (function()
		---@type table<string, string[]> Alternative patterns.
		local alt_patterns = {}
		if options.chapter_range_patterns and options.chapter_range_patterns ~= '' then
			for _, definition in ipairs(split(options.chapter_range_patterns, ';+ *')) do
				local name_patterns = split(definition, ' *:')
				local name, patterns = name_patterns[1], name_patterns[2]
				if name and patterns then alt_patterns[name] = split(patterns, ',') end
			end
		end

		---@type table<string, {color: string; opacity: number; patterns?: string[]}>
		local ranges = {}
		if options.chapter_ranges and options.chapter_ranges ~= '' then
			for _, definition in ipairs(split(options.chapter_ranges, ' *,+ *')) do
				local name_color = split(definition, ' *:+ *')
				local name, color = name_color[1], name_color[2]
				if name and color
					and name:match('^[a-zA-Z0-9_]+$') and color:match('^[a-fA-F0-9]+$')
					and (#color == 6 or #color == 8) then
					local range = serialize_rgba(name_color[2])
					range.patterns = alt_patterns[name]
					ranges[name_color[1]] = range
				end
			end
		end
		return ranges
	end)(),
	color = table_copy(config_defaults.color),
	opacity = table_copy(config_defaults.opacity),
	cursor_leave_fadeout_elements = {'timeline', 'volume', 'top_bar', 'controls'},
	timeline_step = 5,
	timeline_step_flag = '',
}

function update_load_types()
	local extensions = {}
	local types = create_set(comma_split(options.load_types:lower()))

	if types.same then
		types.same = nil
		if state and state.type then types[state.type] = true end
	end

	for _, name in ipairs(table_keys(types)) do
		local type_extensions = config.types[name]
		if type(type_extensions) == 'table' then
			itable_append(extensions, type_extensions)
		else
			msg.warn('Unknown load type: ' .. name)
		end
	end

	config.types.load = extensions
end

-- Updates config with values dependent on options
function update_config()
	-- Required environment config
	if options.autoload then
		mp.commandv('set', 'keep-open', 'yes')
		mp.commandv('set', 'keep-open-pause', 'no')
	end

	-- Adds `{element}_persistency` config properties with forced visibility states (e.g.: `{paused = true}`)
	for _, name in ipairs({'timeline', 'controls', 'volume', 'top_bar', 'speed'}) do
		local option_name = name .. '_persistency'
		local value, flags = options[option_name], {}
		if type(value) == 'string' then
			for _, state in ipairs(comma_split(value)) do flags[state] = true end
		end
		config[option_name] = flags
	end

	-- Opacity
	config.opacity = table_assign({}, config_defaults.opacity, serialize_key_value_list(options.opacity,
		function(value, key)
			return clamp(0, tonumber(value) or config.opacity[key], 1)
		end
	))

	-- Color
	config.color = table_assign({}, config_defaults.color, serialize_key_value_list(options.color, function(value)
		return serialize_rgba(value).color
	end))

	-- Global color shorthands
	fg, bg = config.color.foreground, config.color.background
	fgt, bgt = config.color.foreground_text, config.color.background_text

	-- Timeline step
	do
		local is_exact = options.timeline_step:sub(-1) == '!'
		config.timeline_step = tonumber(is_exact and options.timeline_step:sub(1, -2) or options.timeline_step)
		config.timeline_step_flag = is_exact and 'exact' or ''
	end

	-- Other
	update_load_types()
end
update_config()

-- Default menu items
function create_default_menu_items()
	return {
		{title = t('Subtitles'), value = 'script-binding uosc/subtitles'},
		{title = t('Audio tracks'), value = 'script-binding uosc/audio'},
		{title = t('Stream quality'), value = 'script-binding uosc/stream-quality'},
		{title = t('Playlist'), value = 'script-binding uosc/items'},
		{title = t('Chapters'), value = 'script-binding uosc/chapters'},
		{
			title = t('Navigation'),
			items = {
				{
					title = t('Next'),
					hint = t('playlist or file'),
					value =
					'script-binding uosc/next',
				},
				{
					title = t('Prev'),
					hint = t('playlist or file'),
					value =
					'script-binding uosc/prev',
				},
				{title = t('Delete file & Next'), value = 'script-binding uosc/delete-file-next'},
				{title = t('Delete file & Prev'), value = 'script-binding uosc/delete-file-prev'},
				{title = t('Delete file & Quit'), value = 'script-binding uosc/delete-file-quit'},
				{title = t('Open file'), value = 'script-binding uosc/open-file'},
			},
		},
		{
			title = t('Utils'),
			items = {
				{
					title = t('Aspect ratio'),
					items = {
						{title = t('Default'), value = 'set video-aspect-override no'},
						{title = '16:9', value = 'set video-aspect-override "16:9"'},
						{title = '4:3', value = 'set video-aspect-override "4:3"'},
						{title = '2.35:1', value = 'set video-aspect-override "2.35:1"'},
					},
				},
				{title = t('Audio devices'), value = 'script-binding uosc/audio-device'},
				{title = t('Editions'), value = 'script-binding uosc/editions'},
				{title = t('Screenshot'), value = 'async screenshot'},
				{title = t('Key bindings'), value = 'script-binding uosc/keybinds'},
				{title = t('Show in directory'), value = 'script-binding uosc/show-in-directory'},
				{title = t('Open config folder'), value = 'script-binding uosc/open-config-directory'},
			},
		},
		{title = t('Quit'), value = 'quit'},
	}
end

--[[ STATE ]]

display = {ax = 0, ay = 0, bx = 1280, by = 720, width = 1280, height = 720, initialized = false}
cursor = require('lib/cursor')
state = {
	platform = (function()
		local platform = mp.get_property_native('platform')
		if platform then
			if itable_index_of({'windows', 'darwin'}, platform) then return platform end
		else
			if os.getenv('windir') ~= nil then return 'windows' end
			local homedir = os.getenv('HOME')
			if homedir ~= nil and string.sub(homedir, 1, 6) == '/Users' then return 'darwin' end
		end
		return 'linux'
	end)(),
	cwd = mp.get_property('working-directory'),
	path = nil, -- current file path or URL
	history = {}, -- history of last played files stored as full paths
	time = nil, -- current media playback time
	speed = 1,
	---@type number|nil
	duration = nil, -- current media duration
	max_seconds = nil, -- max seconds the time in timeline is expected to reach, accounted for speed
	time_human = nil, -- current playback time in human format
	destination_time_human = nil, -- depends on options.destination_time
	pause = mp.get_property_native('pause'),
	ime_active = mp.get_property_native('input-ime'),
	chapters = {},
	chapter_ranges = {},
	current_clipboard_backend = mp.get_property_native('current-clipboard-backend'),
	border = mp.get_property_native('border'),
	title_bar = mp.get_property_native('title-bar'),
	fullscreen = mp.get_property_native('fullscreen'),
	maximized = mp.get_property_native('window-maximized'),
	fullormaxed = mp.get_property_native('fullscreen') or mp.get_property_native('window-maximized'),
	render_timer = nil,
	render_last_time = 0,
	volume = mp.get_property_native('volume'),
	volume_max = mp.get_property_native('volume-max'),
	mute = nil,
	type = nil, -- video,image,audio
	is_idle = false,
	is_video = false,
	is_audio = false, -- true if file is audio only (mp3, etc)
	is_image = false,
	is_stream = false,
	has_image = false,
	has_audio = false,
	has_sub = false,
	has_chapter = false,
	has_playlist = false,
	shuffle = options.shuffle,
	---@type nil|{pos: number; paths: string[]}
	shuffle_history = nil,
	on_shuffle = function() state.shuffle_history = nil end,
	mouse_bindings_enabled = false,
	uncached_ranges = nil,
	cache = nil,
	cache_buffering = 100,
	cache_underrun = false,
	cache_duration = nil,
	core_idle = false,
	eof_reached = false,
	render_delay = config.render_delay,
	playlist_count = 0,
	playlist_pos = 0,
	margin_top = 0,
	margin_bottom = 0,
	margin_left = 0,
	margin_right = 0,
	hidpi_scale = 1,
	scale = 1,
	radius = 0,
}
buttons = require('lib/buttons')
thumbnail = {width = 0, height = 0, disabled = false}
external = {} -- Properties set by external scripts
key_binding_overwrites = {} -- Table of key_binding:mpv_command
Elements = require('elements/Elements')
Menu = require('elements/Menu')

-- State dependent utilities
require('lib/utils')
require('lib/text')
require('lib/ass')
require('lib/menus')

-- Determine path to ziggy
do
	local bin = 'ziggy-' .. (state.platform == 'windows' and 'windows.exe' or state.platform)
	config.ziggy_path = os.getenv('MPV_UOSC_ZIGGY') or
	options.ziggy_path == 'default' and join_path(mp.get_script_directory(), join_path('bin', bin)) or
	utils.join_path(mp.command_native({ 'expand-path', options.ziggy_path }), bin)
end

--[[ STATE UPDATERS ]]

function update_display_dimensions()
	state.scale = (state.hidpi_scale or 1) * (state.fullormaxed and options.scale_fullscreen or options.scale)
	state.radius = round(options.border_radius * state.scale)
	local real_width, real_height = mp.get_osd_size()
	if real_width <= 0 then return end
	display.bx, display.width, display.by, display.height = real_width, real_width, real_height, real_height
	display.initialized = true

	-- Tell elements about this
	Elements:trigger('display')

	-- Some elements probably changed their rectangles as a reaction to `display`
	Elements:update_proximities()
	request_render()
end

function update_fullormaxed()
	state.fullormaxed = state.fullscreen or state.maximized
	update_display_dimensions()
	Elements:trigger('prop_fullormaxed', state.fullormaxed)
	cursor:leave()
end

function update_duration()
	local duration = state._duration and ((state.rebase_start_time == false and state.start_time)
		and (state._duration + state.start_time) or state._duration)
	set_state('duration', duration)
	update_human_times()
end

function update_human_times()
	state.speed = state.speed or 1
	if state.time then
		if state.duration then
			if options.destination_time == 'playtime-remaining' then
				state.destination_time_human = format_time((state.time - state.duration) / state.speed, state.duration)
			elseif options.destination_time == 'total' then
				state.destination_time_human = format_time(state.duration, state.duration)
			else
				state.destination_time_human = format_time(state.time - state.duration, state.duration)
			end
		else
			state.destination_time_human = nil
		end
		state.time_human = format_time(state.time, state.duration or state.time)
	else
		state.time_human, state.destination_time_human = nil, nil
	end
end

-- Notifies other scripts such as console about where the unoccupied parts of the screen are.
function update_margins()
	if display.height == 0 then return end

	local function causes_margin(element)
		return element and element.enabled and (element:is_persistent() or element.min_visibility > 0.5)
	end
	local timeline, top_bar, controls, volume = Elements.timeline, Elements.top_bar, Elements.controls, Elements.volume
	-- margins are normalized to window size
	local left, right, top, bottom = 0, 0, 0, 0

	if causes_margin(controls) then
		bottom = (display.height - controls.ay) / display.height
	elseif causes_margin(timeline) then
		bottom = (display.height - timeline.ay) / display.height
	end

	if causes_margin(top_bar) then top = top_bar.title_by / display.height end

	if causes_margin(volume) then
		if options.volume == 'left' then
			left = volume.bx / display.width
		elseif options.volume == 'right' then
			right = volume.ax / display.width
		end
	end

	if top == state.margin_top and bottom == state.margin_bottom and
		left == state.margin_left and right == state.margin_right then
		return
	end

	state.margin_top = top
	state.margin_bottom = bottom
	state.margin_left = left
	state.margin_right = right

	if utils.shared_script_property_set then
		utils.shared_script_property_set('osc-margins', string.format('%f,%f,%f,%f', 0, 0, top, bottom))
	end
	mp.set_property_native('user-data/osc/margins', {l = left, r = right, t = top, b = bottom})

	if not options.adjust_osd_margins then return end
	local osd_margin_y, osd_margin_x, osd_factor_x = 0, 0, display.width / display.height * 720
	if config.osd_alignment_y == 'bottom' then
		osd_margin_y = round(bottom * 720)
	elseif config.osd_alignment_y == 'top' then
		osd_margin_y = round(top * 720)
	end
	if config.osd_alignment_x == 'left' then
		osd_margin_x = round(left * osd_factor_x)
	elseif config.osd_alignment_x == 'right' then
		osd_margin_x = round(right * osd_factor_x)
	end
	mp.set_property_native('osd-margin-y', osd_margin_y + config.osd_margin_y)
	mp.set_property_native('osd-margin-x', osd_margin_x + config.osd_margin_x)
end
function create_state_setter(name, callback)
	return function(_, value)
		set_state(name, value)
		if callback then callback() end
		request_render()
	end
end

function set_state(name, value)
	state[name] = value
	local state_event = state['on_' .. name]
	if state_event then state_event(value) end
	Elements:trigger('prop_' .. name, value)
end

function handle_file_end()
	local resume = false
	if not state.loop_file then
		if state.has_playlist then
			resume = state.shuffle and navigate_playlist(1)
		else
			resume = options.autoload and navigate_directory(1)
		end
	end
	-- Resume only when navigation happened
	if resume then mp.command('set pause no') end
end
local file_end_timer = mp.add_timeout(1, handle_file_end)
file_end_timer:kill()

function load_file_index_in_current_directory(index)
	if not state.path or is_protocol(state.path) then return end

	local serialized = serialize_path(state.path)
	if serialized and serialized.dirname then
		local files, _dirs, error = read_directory(serialized.dirname, {
			types = config.types.load,
			hidden = options.show_hidden_files,
		})

		if error then
			msg.error(error)
			return
		end

		sort_strings(files)
		if index < 0 then index = #files + index + 1 end

		if files[index] then
			mp.commandv('loadfile', join_path(serialized.dirname, files[index]))
		end
	end
end

function update_render_delay(name, fps)
	if fps then state.render_delay = 1 / fps end
end

function observe_display_fps(name, fps)
	if fps then
		mp.unobserve_property(update_render_delay)
		mp.unobserve_property(observe_display_fps)
		mp.observe_property('display-fps', 'native', update_render_delay)
	end
end

--[[ STATE HOOKS ]]

mp.register_event('file-loaded', function()
	local path = normalize_path(mp.get_property_native('path'))
	itable_delete_value(state.history, path)
	state.history[#state.history + 1] = path
	set_state('path', path)

	-- Flash top bar on requested file types
	for _, type in ipairs(config.top_bar_flash_on) do
		if state['is_' .. type] then
			Elements:flash({'top_bar'})
			break
		end
	end
end)
mp.register_event('end-file', function(event)
	set_state('path', nil)
	if event.reason == 'eof' then
		file_end_timer:kill()
		handle_file_end()
	end
end)
mp.observe_property('playback-time', 'number', create_state_setter('time', function()
	-- Create a file-end event that triggers right before file ends
	file_end_timer:kill()
	if state.duration and state.time and not state.pause then
		local remaining = (state.duration - state.time) / state.speed
		if remaining < 5 then
			local timeout = remaining - 0.02
			if timeout > 0 then
				file_end_timer.timeout = timeout
				file_end_timer:resume()
			else
				handle_file_end()
			end
		end
	end

	update_human_times()
end))
mp.observe_property('rebase-start-time', 'bool', create_state_setter('rebase_start_time', update_duration))
mp.observe_property('demuxer-start-time', 'number', create_state_setter('start_time', update_duration))
mp.observe_property('duration', 'number', create_state_setter('_duration', update_duration))
mp.observe_property('speed', 'number', create_state_setter('speed', update_human_times))
mp.observe_property('track-list', 'native', function(name, value)
	-- checks the file dispositions
	local types = {sub = 0, image = 0, audio = 0, video = 0}
	for _, track in ipairs(value) do
		if track.type == 'video' then
			if track.image or track.albumart then
				types.image = types.image + 1
			else
				types.video = types.video + 1
			end
		elseif types[track.type] then
			types[track.type] = types[track.type] + 1
		end
	end
	set_state('is_audio', types.video == 0 and types.audio > 0)
	set_state('is_image', types.image > 0 and types.video == 0 and types.audio == 0)
	set_state('has_image', types.image > 0)
	set_state('has_audio', types.audio > 0)
	set_state('has_many_audio', types.audio > 1)
	set_state('has_sub', types.sub > 0)
	set_state('has_many_sub', types.sub > 1)
	set_state('is_video', types.video > 0)
	set_state('has_many_video', types.video > 1)
	set_state('type', state.is_video and 'video' or state.is_audio and 'audio' or state.is_image and 'image' or nil)
	update_load_types()
	Elements:trigger('dispositions')
end)
mp.observe_property('editions', 'number', function(_, editions)
	if editions then set_state('has_many_edition', editions > 1) end
	Elements:trigger('dispositions')
end)
mp.observe_property('chapter-list', 'native', function(_, chapters)
	local chapters, chapter_ranges = serialize_chapters(chapters), {}
	if chapters then chapters, chapter_ranges = serialize_chapter_ranges(chapters) end
	set_state('chapters', chapters)
	set_state('chapter_ranges', chapter_ranges)
	set_state('has_chapter', #chapters > 0)
	Elements:trigger('dispositions')
end)
mp.observe_property('border', 'bool', create_state_setter('border'))
mp.observe_property('title-bar', 'bool', create_state_setter('title_bar'))
mp.observe_property('loop-file', 'native', create_state_setter('loop_file'))
mp.observe_property('ab-loop-a', 'number', create_state_setter('ab_loop_a'))
mp.observe_property('ab-loop-b', 'number', create_state_setter('ab_loop_b'))
mp.observe_property('playlist-pos-1', 'number', create_state_setter('playlist_pos'))
mp.observe_property('playlist-count', 'number', function(_, value)
	set_state('playlist_count', value)
	set_state('has_playlist', value > 1)
	Elements:trigger('dispositions')
end)
mp.observe_property('fullscreen', 'bool', create_state_setter('fullscreen', update_fullormaxed))
mp.observe_property('window-maximized', 'bool', create_state_setter('maximized', update_fullormaxed))
mp.observe_property('idle-active', 'bool', function(_, idle)
	set_state('is_idle', idle)
	Elements:trigger('dispositions')
	mp.commandv('script-message-to', 'thumbfast', 'clear')
end)
mp.observe_property('pause', 'bool', create_state_setter('pause', function() file_end_timer:kill() end))
mp.observe_property('volume', 'number', create_state_setter('volume'))
mp.observe_property('volume-max', 'number', create_state_setter('volume_max'))
mp.observe_property('mute', 'bool', create_state_setter('mute'))
mp.observe_property('osd-dimensions', 'native', function(name, val)
	update_display_dimensions()
	request_render()
end)
mp.observe_property('display-hidpi-scale', 'native', create_state_setter('hidpi_scale', update_display_dimensions))
mp.observe_property('cache', 'string', create_state_setter('cache'))
mp.observe_property('cache-buffering-state', 'number', create_state_setter('cache_buffering'))
mp.observe_property('demuxer-via-network', 'native', create_state_setter('is_stream', function()
	Elements:trigger('dispositions')
end))
mp.observe_property('demuxer-cache-state', 'native', function(prop, cache_state)
	local cached_ranges, bof, eof, uncached_ranges = nil, nil, nil, nil
	if cache_state then
		cached_ranges, bof, eof = cache_state['seekable-ranges'], cache_state['bof-cached'], cache_state['eof-cached']
		set_state('cache_underrun', cache_state['underrun'])
		set_state('cache_duration', not cache_state.eof and cache_state['cache-duration'] or nil)
	else
		cached_ranges = {}
		set_state('cache_underrun', false)
	end

	if not (state.duration and (#cached_ranges > 0 or state.cache == 'yes' or
			(state.cache == 'auto' and state.is_stream))) then
		if state.uncached_ranges then set_state('uncached_ranges', nil) end
		set_state('cache_duration', nil)
		return
	end

	-- Normalize
	local ranges = {}
	for _, range in ipairs(cached_ranges) do
		ranges[#ranges + 1] = {
			math.max(range['start'] or 0, 0),
			math.min(range['end'] or state.duration --[[@as number]], state.duration),
		}
	end
	table.sort(ranges, function(a, b) return a[1] < b[1] end)
	if bof then ranges[1][1] = 0 end
	if eof then ranges[#ranges][2] = state.duration end
	-- Invert cached ranges into uncached ranges, as that's what we're rendering
	local inverted_ranges = {{0, state.duration}}
	for _, cached in pairs(ranges) do
		inverted_ranges[#inverted_ranges][2] = cached[1]
		inverted_ranges[#inverted_ranges + 1] = {cached[2], state.duration}
	end
	uncached_ranges = {}
	local last_range = nil
	for _, range in ipairs(inverted_ranges) do
		if last_range and last_range[2] + 0.5 > range[1] then -- fuse ranges
			last_range[2] = range[2]
		else
			if range[2] - range[1] > 0.5 then -- skip short ranges
				uncached_ranges[#uncached_ranges + 1] = range
				last_range = range
			end
		end
	end

	set_state('uncached_ranges', uncached_ranges)
end)
mp.observe_property('display-fps', 'native', observe_display_fps)
mp.observe_property('estimated-display-fps', 'native', update_render_delay)
mp.observe_property('eof-reached', 'native', create_state_setter('eof_reached'))
mp.observe_property('core-idle', 'native', create_state_setter('core_idle'))

--[[ KEY BINDS ]]

-- Adds a key binding that respects rerouting set by `key_binding_overwrites` table.
---@param name string
---@param callback fun(event: table)
---@param flags nil|string
function bind_command(name, callback, flags)
	mp.add_key_binding(nil, name, function(...)
		if key_binding_overwrites[name] then
			mp.command(key_binding_overwrites[name])
		else
			callback(...)
		end
	end, flags)
end

bind_command('toggle-ui', function() Elements:toggle({'timeline', 'controls', 'volume', 'top_bar'}) end)
bind_command('flash-ui', function() Elements:flash({'timeline', 'controls', 'volume', 'top_bar'}) end)
bind_command('flash-timeline', function() Elements:flash({'timeline'}) end)
bind_command('flash-top-bar', function() Elements:flash({'top_bar'}) end)
bind_command('flash-volume', function() Elements:flash({'volume'}) end)
bind_command('flash-speed', function() Elements:flash({'speed'}) end)
bind_command('flash-pause-indicator', function() Elements:flash({'pause_indicator'}) end)
bind_command('flash-progress', function() Elements:flash({'progress'}) end)
bind_command('toggle-progress', function() Elements:maybe('timeline', 'toggle_progress') end)
bind_command('toggle-title', function() Elements:maybe('top_bar', 'toggle_title') end)
bind_command('decide-pause-indicator', function() Elements:maybe('pause_indicator', 'decide') end)
bind_command('menu', function() toggle_menu_with_items() end)
bind_command('menu-blurred', function() toggle_menu_with_items({mouse_nav = true}) end)
bind_command('keybinds', function()
	if Menu:is_open('keybinds') then
		Menu:close()
	else
		open_command_menu({type = 'keybinds', items = get_keybinds_items(), search_style = 'palette'})
	end
end)
bind_command('download-subtitles', open_subtitle_downloader)
bind_command('load-subtitles', create_track_loader_menu_opener({
	prop = 'sub',
	title = t('Load subtitles'),
	loaded_message = t('Loaded subtitles'),
	allowed_types = itable_join(config.types.video, config.types.subtitle),
}))
bind_command('load-audio', create_track_loader_menu_opener({
	prop = 'audio',
	title = t('Load audio'),
	loaded_message = t('Loaded audio'),
	allowed_types = itable_join(config.types.video, config.types.audio),
}))
bind_command('load-video', create_track_loader_menu_opener({
	prop = 'video',
	title = t('Load video'),
	loaded_message = t('Loaded video'),
	allowed_types = config.types.video,
}))
bind_command('subtitles', create_select_tracklist_type_menu_opener({
	title = t('Subtitles'),
	type = 'sub',
	prop = 'sid',
	enable_prop = 'sub-visibility',
	secondary = {prop = 'secondary-sid', icon = 'vertical_align_top', enable_prop = 'secondary-sub-visibility'},
	load_command = 'script-binding uosc/load-subtitles',
	download_command = 'script-binding uosc/download-subtitles',
}))
bind_command('audio', create_select_tracklist_type_menu_opener({
	title = t('Audio'), type = 'audio', prop = 'aid', load_command = 'script-binding uosc/load-audio',
}))
bind_command('video', create_select_tracklist_type_menu_opener({
	title = t('Video'), type = 'video', prop = 'vid', load_command = 'script-binding uosc/load-video',
}))
bind_command('playlist', create_self_updating_menu_opener({
	title = t('Playlist'),
	type = 'playlist',
	list_prop = 'playlist',
	footnote = t('Paste path or url to add.') .. ' ' .. t('%s to reorder.', 'ctrl+up/down/pgup/pgdn/home/end'),
	serializer = function(playlist)
		local items = {}
		local playlist_titles = mp.get_property_native('user-data/playlistmanager/titles') or {}
		for index, item in ipairs(playlist) do
			local is_url = is_protocol(item.filename)
			local title = type(item.title) == 'string' and #item.title > 0 and item.title or false
			items[index] = {
				title = is_url and (title or playlist_titles[item.filename] or url_decode(item.filename)) or
				serialize_path(item.filename).basename,
				hint = tostring(index),
				active = item.current,
				value = index,
			}
		end
		return items
	end,
	on_activate = function(event) mp.commandv('set', 'playlist-pos-1', tostring(event.value)) end,
	on_paste = function(event) mp.commandv('loadfile', tostring(event.value), 'append') end,
	on_key = function(event)
		if event.id == 'ctrl+c' and event.selected_item then
			local payload = mp.get_property_native('playlist/' .. (event.selected_item.value - 1) .. '/filename')
			set_clipboard(payload)
		end
	end,
	on_move = function(event)
		local from, to = event.from_index, event.to_index
		mp.commandv('playlist-move', tostring(from - 1), tostring(to - (to > from and 0 or 1)))
	end,
	on_remove = function(event) mp.commandv('playlist-remove', tostring(event.value - 1)) end,
}))
bind_command('chapters', create_self_updating_menu_opener({
	title = t('Chapters'),
	type = 'chapters',
	list_prop = 'chapter-list',
	active_prop = 'chapter',
	serializer = function(chapters, current_chapter)
		local items = {}
		chapters = normalize_chapters(chapters)
		for index, chapter in ipairs(chapters) do
			items[index] = {
				title = chapter.title or '',
				hint = format_time(chapter.time, state.duration),
				value = index,
				active = index - 1 == current_chapter,
			}
		end
		return items
	end,
	on_activate = function(event) mp.commandv('set', 'chapter', tostring(event.value - 1)) end,
}))
bind_command('editions', create_self_updating_menu_opener({
	title = t('Editions'),
	type = 'editions',
	list_prop = 'edition-list',
	active_prop = 'current-edition',
	serializer = function(editions, current_id)
		local items = {}
		for _, edition in ipairs(editions or {}) do
			local edition_id_1 = tostring(edition.id + 1)
			items[#items + 1] = {
				title = edition.title or t('Edition %s', edition_id_1),
				hint = edition_id_1,
				value = edition.id,
				active = edition.id == current_id,
			}
		end
		return items
	end,
	on_activate = function(event) mp.commandv('set', 'edition', event.value) end,
}))
bind_command('show-in-directory', function()
	-- Ignore URLs
	if not state.path or is_protocol(state.path) then return end

	if state.platform == 'windows' then
		utils.subprocess_detached({args = {'explorer', '/select,', state.path .. ' '}, cancellable = false})
	elseif state.platform == 'darwin' then
		utils.subprocess_detached({args = {'open', '-R', state.path}, cancellable = false})
	elseif state.platform == 'linux' then
		local result = utils.subprocess({args = {'nautilus', state.path}, cancellable = false})

		-- Fallback opens the folder with xdg-open instead
		if result.status ~= 0 then
			utils.subprocess({args = {'xdg-open', serialize_path(state.path).dirname}, cancellable = false})
		end
	end
end)
bind_command('stream-quality', open_stream_quality_menu)
bind_command('open-file', open_open_file_menu)
bind_command('shuffle', function()
	set_state('shuffle', not state.shuffle)
	mp.osd_message(state.shuffle and t('Shuffle ON') or t('Shuffle OFF'))
end)
bind_command('items', function()
	if state.has_playlist then
		mp.command('script-binding uosc/playlist')
	else
		mp.command('script-binding uosc/open-file')
	end
end)
bind_command('next', function() navigate_item(1) end)
bind_command('prev', function() navigate_item(-1) end)
bind_command('next-file', function() navigate_directory(1) end)
bind_command('prev-file', function() navigate_directory(-1) end)
bind_command('first', function()
	if state.has_playlist then
		mp.commandv('set', 'playlist-pos-1', '1')
	else
		load_file_index_in_current_directory(1)
	end
end)
bind_command('last', function()
	if state.has_playlist then
		mp.commandv('set', 'playlist-pos-1', tostring(state.playlist_count))
	else
		load_file_index_in_current_directory(-1)
	end
end)
bind_command('first-file', function() load_file_index_in_current_directory(1) end)
bind_command('last-file', function() load_file_index_in_current_directory(-1) end)
bind_command('delete-file-prev', function() delete_file_navigate(-1) end)
bind_command('delete-file-next', function() delete_file_navigate(1) end)
bind_command('delete-file-quit', function()
	mp.command('stop')
	if state.path and not is_protocol(state.path) then delete_file(state.path) end
	mp.command('quit')
end)
bind_command('menu-prev', function() Elements:maybe('menu', 'navigate_by_items', -1) end)
bind_command('menu-next', function() Elements:maybe('menu', 'navigate_by_items', 1) end)
bind_command('menu-prev-page', function() Elements:maybe('menu', 'navigate_by_page', -1) end)
bind_command('menu-next-page', function() Elements:maybe('menu', 'navigate_by_page', 1) end)
bind_command('menu-start', function() Elements:maybe('menu', 'navigate_by_items', -math.huge) end)
bind_command('menu-end', function() Elements:maybe('menu', 'navigate_by_items', math.huge) end)
bind_command('menu-activate', function() Elements:maybe('menu', 'activate_selected_item') end)
bind_command('menu-back', function() Elements:maybe('menu', 'back') end)
bind_command('audio-device', create_self_updating_menu_opener({
	title = t('Audio devices'),
	type = 'audio-device-list',
	list_prop = 'audio-device-list',
	active_prop = 'audio-device',
	serializer = function(audio_device_list, current_device)
		current_device = current_device or 'auto'
		local ao = mp.get_property('current-ao') or ''
		local items = {}
		for _, device in ipairs(audio_device_list) do
			if device.name == 'auto' or string.match(device.name, '^' .. ao) then
				local hint = string.match(device.name, ao .. '/(.+)')
				if not hint then hint = device.name end
				items[#items + 1] = {
					title = device.description:sub(1, 7) == 'Default'
						and t('Default %s', device.description:sub(9))
						or device.description,
					hint = hint,
					active = device.name == current_device,
					value = device.name,
				}
			end
		end
		return items
	end,
	on_activate = function(event) mp.commandv('set', 'audio-device', event.value) end,
}))
bind_command('paste', function()
	local has_playlist = mp.get_property_native('playlist-count') > 1
	mp.commandv('script-binding', 'uosc/paste-to-' .. (has_playlist and 'playlist' or 'open'))
end)
bind_command('paste-to-open', function()
	local payload = get_clipboard()
	if payload then mp.commandv('loadfile', payload) end
end)
bind_command('paste-to-playlist', function()
	-- If there's no file loaded, we use `paste-to-open`, which both opens and adds to playlist
	if state.is_idle then
		mp.commandv('script-binding', 'uosc/paste-to-open')
	else
		local payload = get_clipboard()
		if payload then
			mp.commandv('loadfile', payload, 'append')
			mp.commandv('show-text', t('Added to playlist') .. ': ' .. payload, 3000)
		end
	end
end)
bind_command('copy-to-clipboard', function()
	if state.path then
		set_clipboard(state.path)
	else
		mp.commandv('show-text', t('Nothing to copy'), 3000)
	end
end)
bind_command('open-config-directory', function()
	local config_path = mp.command_native({'expand-path', '~~/mpv.conf'})
	local config = serialize_path(normalize_path(config_path))

	if config then
		local args

		if state.platform == 'windows' then
			args = {'explorer', '/select,', config.path}
		elseif state.platform == 'darwin' then
			args = {'open', '-R', config.path}
		elseif state.platform == 'linux' then
			args = {'xdg-open', config.dirname}
		end

		utils.subprocess_detached({args = args, cancellable = false})
	else
		msg.error('Couldn\'t serialize config path "' .. config_path .. '".')
	end
end)

--[[ MESSAGE HANDLERS ]]

mp.register_script_message('show-submenu', function(id) toggle_menu_with_items({submenu = id}) end)
mp.register_script_message('show-submenu-blurred', function(id)
	toggle_menu_with_items({submenu = id, mouse_nav = true})
end)
mp.register_script_message('open-menu', function(json, submenu_id)
	local data = utils.parse_json(json)
	if type(data) ~= 'table' or type(data.items) ~= 'table' then
		msg.error('open-menu: received json didn\'t produce a table with menu configuration')
	else
		open_command_menu(data, {submenu = submenu_id, on_close = data.on_close})
	end
end)
mp.register_script_message('update-menu', function(json)
	local data = utils.parse_json(json)
	if type(data) ~= 'table' or type(data.items) ~= 'table' then
		msg.error('update-menu: received json didn\'t produce a table with menu configuration')
	else
		local menu = data.type and Menu:is_open(data.type)
		if menu then menu:update(data) end
	end
end)
mp.register_script_message('select-menu-item', function(type, item_index, menu_id)
	local menu = Menu:is_open(type)
	local index = tonumber(item_index)
	if menu and index and not menu.mouse_nav then
		index = round(index)
		if index > 0 and index <= #menu.current.items then
			menu:select_index(index, menu_id)
			menu:scroll_to_index(index, menu_id, true)
		end
	end
end)
mp.register_script_message('close-menu', function(type)
	if Menu:is_open(type) then Menu:close() end
end)
mp.register_script_message('menu-action', function(name, ...)
	local menu = Menu:is_open()
	if menu then
		local method = ({
			['search-cancel'] = 'search_cancel',
			['search-query-update'] = 'search_query_update',
		})[name]
		if method then menu[method](menu, ...) end
	end
end)
mp.register_script_message('thumbfast-info', function(json)
	local data = utils.parse_json(json)
	if type(data) ~= 'table' or not data.width or not data.height then
		thumbnail.disabled = true
		msg.error('thumbfast-info: received json didn\'t produce a table with thumbnail information')
	else
		thumbnail = data
		request_render()
	end
end)
mp.register_script_message('set', function(name, value)
	external[name] = value
	Elements:trigger('external_prop_' .. name, value)
end)
mp.register_script_message('toggle-elements', function(elements) Elements:toggle(comma_split(elements)) end)
mp.register_script_message('set-min-visibility', function(visibility, elements)
	local fraction = tonumber(visibility)
	local ids = comma_split(elements and elements ~= '' and elements or 'timeline,controls,volume,top_bar')
	if fraction then Elements:set_min_visibility(clamp(0, fraction, 1), ids) end
end)
mp.register_script_message('flash-elements', function(elements) Elements:flash(comma_split(elements)) end)
mp.register_script_message('overwrite-binding', function(name, command) key_binding_overwrites[name] = command end)
mp.register_script_message('disable-elements', function(id, elements) Manager:disable(id, elements) end)

--[[ ELEMENTS ]]

-- Dynamic elements
local constructors = {
	window_border = require('elements/WindowBorder'),
	buffering_indicator = require('elements/BufferingIndicator'),
	pause_indicator = require('elements/PauseIndicator'),
	top_bar = require('elements/TopBar'),
	timeline = require('elements/Timeline'),
	controls = options.controls and options.controls ~= 'never' and require('elements/Controls'),
	volume = itable_index_of({'left', 'right'}, options.volume) and require('elements/Volume'),
}

-- Required elements
require('elements/Curtain'):new()

-- Element manager
-- Handles creating and destroying elements based on disabled_elements user+script config.
Manager = {
	-- Managed disable-able element IDs
	_ids = itable_join(table_keys(constructors), {'idle_indicator', 'audio_indicator'}),
	---@type table<string, string[]> A map of clients and a list of element ids they disable
	_disabled_by = {},
	---@type table<string, boolean>
	disabled = {},
}

-- Set client and which elements it wishes disabled. To undo just pass an empty `element_ids` for the same `client`.
---@param client string
---@param element_ids string|string[]|nil `foo,bar` or `{'foo', 'bar'}`.
function Manager:disable(client, element_ids)
	self._disabled_by[client] = comma_split(element_ids)
	---@diagnostic disable-next-line: deprecated
	self.disabled = create_set(itable_join(unpack(table_values(self._disabled_by))))
	self:_commit()
end

function Manager:_commit()
	-- Create and destroy elements as needed
	for _, id in ipairs(self._ids) do
		local constructor = constructors[id]
		if not self.disabled[id] then
			if not Elements:has(id) and constructor then constructor:new() end
		else
			Elements:maybe(id, 'destroy')
		end
	end

	-- We use `on_display` event to tell elements to update their dimensions
	Elements:trigger('display')
end

-- Initial commit
Manager:disable('user', options.disable_elements)

-- ============================================================
-- 视频技术标签模块 (MediaInfo)
-- 左下角显示视频/音频技术参数标签
-- 完全独立模块，不修改原版 uosc 代码
-- 更新 uosc 时只需复制本模块到 main.lua 末尾
-- 所有配置项在 script-opts/mediainfo.conf 中设置
-- 模块使用独立的 load_tag_config() 函数读取配置，不依赖 opt.read_options()
-- ============================================================

local function load_tag_config()
	local cfg = {}
	local path = mp.find_config_file('script-opts/mediainfo.conf')
	if not path then return cfg end
	local f = io.open(path, 'r')
	if not f then return cfg end
	for line in f:lines() do
		line = line:gsub('#.*$', ''):match('^%s*(.-)%s*$')
		if line ~= '' then
			local k, v = line:match('^([^=]+)=(.*)$')
			if k then cfg[k:match('^%s*(.-)%s*$')] = v:match('^%s*(.-)%s*$') end
		end
	end
	f:close()
	return cfg
end

local tag_cfg = load_tag_config()

local function cfg_str(key, default)
	local v = tag_cfg[key]
	return (v and v ~= '') and v or default
end

local function cfg_num(key, default)
	local v = tonumber(tag_cfg[key])
	return v or default
end

local function cfg_bool(key)
	local v = tostring(tag_cfg[key] or ''):lower()
	return v == 'yes' or v == 'true' or v == '1'
end

local TagElement = require('elements/Element')
local VideoTags = class(TagElement)

function VideoTags:new() return Class.new(self) end

function VideoTags:init()
	TagElement.init(self, 'mediainfo', {render_order = 10, anchor_id = 'controls'})
	self._cache = nil
	self._last_fetch = 0
	self._hdr_vivid = false
	self._base_scale = nil
	self._initial_timer = nil

	local function invalidate()
		self._cache = nil
		request_render()
	end
	local function invalidate_full()
		self._cache = nil
		self._last_fetch = 0
		request_render()
	end

	self:observe_mp_property('pause', function() request_render() end)
	self:observe_mp_property('hwdec-current', invalidate)
	self:observe_mp_property('video-params', invalidate)
	self:observe_mp_property('estimated-vf-fps', invalidate)
	self:observe_mp_property('video-bitrate', invalidate)
	self:observe_mp_property('audio-codec', invalidate)
	self:observe_mp_property('audio-params', invalidate)
	self:observe_mp_property('aid', invalidate_full)

	self:register_mp_event('file-loaded', function()
		self._cache = nil
		self._last_fetch = 0
		self._hdr_vivid = false
		self:_probe_hdr_vivid()
		self:_start_initial_display()
		request_render()
	end)

	self:register_mp_event('video-reconfig', function()
		self._cache = nil
		self._last_fetch = 0
		request_render()
	end)

	self:_probe_hdr_vivid()
end

function VideoTags:get_visibility()
	if not cfg_bool('mediainfo_enabled') then return 0 end
	return TagElement.get_visibility(self)
end

function VideoTags:_start_initial_display()
	if self._initial_timer then self._initial_timer:kill() end
	local delay = cfg_num('mediainfo_initial_display', 0)
	if delay <= 0 then return end
	self.forced_visibility = 1
	request_render()
	self._initial_timer = mp.add_timeout(delay, function()
		local function getTo() return self.proximity end
		local function onTweenEnd() self.forced_visibility = nil end
		if self.enabled then
			self:tween_property('forced_visibility', self:get_visibility(), getTo, onTweenEnd)
		else
			onTweenEnd()
		end
	end)
end

function VideoTags:_hwdec_label()
	local hw = mp.get_property('hwdec-current', '')
	return (hw ~= '' and hw ~= 'no') and '硬解' or '软解'
end

function VideoTags:_hdr_label()
	if self._hdr_vivid then return 'HDR Vivid (菁彩影像)' end

	local vp = mp.get_property_native('video-params')
	if not vp then return 'SDR' end

	local track = mp.get_property_native('current-tracks/video', {})
	local dv_profile = track and tonumber(track['dolby-vision-profile'])
	if not dv_profile then
		local dp = mp.get_property('video-params/dolby-vision-profile', '')
		if dp ~= '' then dv_profile = tonumber(dp) end
	end
	if dv_profile and dv_profile > 0 then
		if dv_profile == 5 then return 'Dolby Vision (P5)'
		elseif dv_profile == 7 then return 'Dolby Vision (P7)'
		elseif dv_profile == 8 then return 'Dolby Vision (P8)'
		else return 'Dolby Vision (P' .. dv_profile .. ')' end
	end

	local dv_level = track and track['dolby-vision-level']
	if not dv_level then
		local dl = mp.get_property('video-params/dolby-vision-level', '')
		if dl ~= '' then dv_level = tonumber(dl) end
	end
	if dv_level then return 'Dolby Vision' end

	local function match_vivid(s)
		if type(s) == 'string' then
			local clean = s:lower():gsub('[%s%._%-]', '')
			return clean:find('hdrvivid') or clean:find('cuvahdr') or clean:find('cuva')
		end
		return false
	end
	local vivid = false
	if track then
		for k, v in pairs(track) do
			if match_vivid(k) or match_vivid(v) then vivid = true break end
		end
	end
	if not vivid and vp then
		for k, v in pairs(vp) do
			if match_vivid(k) or match_vivid(v) then vivid = true break end
		end
	end
	if not vivid then
		vivid = match_vivid(mp.get_property('filename'))
			or match_vivid(mp.get_property('media-title'))
			or match_vivid(mp.get_property('path'))
	end

	local gamma = tostring(vp['gamma'] or vp['transfer'] or ''):lower()
	local is_hdr = (gamma == 'pq' or gamma == 'smpte2084' or gamma == 'hlg' or gamma == 'arib-std-b67')
	if not is_hdr then
		local sp = tonumber(vp['sig-peak'])
		if sp and sp > 1 then is_hdr = true end
	end

	if vivid and is_hdr then return 'HDR Vivid (菁彩影像)' end

	if gamma == 'pq' or gamma == 'smpte2084' then
		local hdr10p = vp['scene-max-r'] or vp['scene-max-g'] or vp['scene-max-b']
		if not hdr10p and track then
			hdr10p = track['hdr10plus'] or track['scene-max-r'] or track['scene-max-g'] or track['scene-max-b']
		end
		if hdr10p then return 'HDR10+' end
		return 'HDR10'
	end

	if gamma == 'hlg' or gamma == 'arib-std-b67' then return 'HLG' end

	local sp = tonumber(vp['sig-peak'])
	if sp and sp > 1 then return 'HDR' end

	return 'SDR'
end

function VideoTags:_codec_label()
	local c = mp.get_property('video-params/codec', '')
	if c == '' then c = mp.get_property('video-codec', '') end
	local fn = mp.get_property('filename', ''):lower()
	local lc = c:lower()

	if lc:find('hevc') or lc:find('h265') or lc:find('h%.265')
		or fn:find('hevc') or fn:find('x265') or fn:find('h265') then
		return 'HEVC'
	elseif lc:find('avc') or lc:find('h264') or lc:find('h%.264')
		or fn:find('avc') or fn:find('x264') or fn:find('h264') then
		return 'AVC'
	elseif lc:find('av1') or fn:find('av1') then
		return 'AV1'
	elseif lc:find('vp9') or fn:find('vp9') then
		return 'VP9'
	end
	return c:upper()
end

function VideoTags:_resolution_label()
	local w = mp.get_property_number('video-params/w', 0)
	local h = mp.get_property_number('video-params/h', 0)
	if w <= 0 or h <= 0 then
		w = mp.get_property_number('width', 0)
		h = mp.get_property_number('height', 0)
	end
	if w <= 0 or h <= 0 then return '' end

	if w >= 7600 or h >= 4320 then return '8K UHD'
	elseif w >= 3800 or h >= 2160 then return '4K UHD'
	elseif w >= 2500 or h >= 1400 then return '2K QHD'
	elseif w >= 1900 or h >= 1000 then return '1080P'
	elseif w >= 1200 or h >= 700 then return '720P'
	else return tostring(math.floor(h)) .. 'P' end
end

function VideoTags:_fps_label()
	local fps = mp.get_property_number('estimated-vf-fps', 0)
	if fps <= 0 then fps = mp.get_property_number('container-fps', 0) end
	if fps > 0 then return string.format('%dFPS', math.floor(fps + 0.5)) end
	return ''
end

function VideoTags:_audio_ch_label()
	local hr = mp.get_property('audio-params/hr-channels', '')
	if hr ~= '' then
		hr = hr:lower()
		if hr:find('7%.1') then return '7.1 环绕声'
		elseif hr:find('5%.1') then return '5.1 环绕声'
		elseif hr:find('stereo') or hr:find('2ch') then return '2.0 立体声'
		elseif hr:find('mono') or hr:find('1ch') then return '1.0 单声道' end
	end

	local ch = mp.get_property_number('audio-params/channel-count', 0)
	if ch <= 0 then ch = mp.get_property_number('audio-channels', 0) end
	if ch == 8 then return '7.1 环绕声'
	elseif ch == 6 then return '5.1 环绕声'
	elseif ch == 2 then return '2.0 立体声'
	elseif ch == 1 then return '1.0 单声道'
	elseif ch > 0 then return tostring(ch) .. '声道' end
	return ''
end

function VideoTags:_audio_codec_label()
	local c = mp.get_property('audio-codec', '')
	if c == '' then return '' end
	c = c:lower()

	local track = mp.get_property_native('current-tracks/audio', {})
	local title = (track and track.title or ''):lower()

	if c:find('av3a') or c:find('audio.vivid') or c:find('audio_vivid')
		or title:find('av3a') or title:find('audio.vivid') or title:find('audio_vivid')
		or title:find('菁彩音频') then
		return 'Audio Vivid 菁彩音频'
	end

	if c:find('truehd') or c:find('mlp') then return 'TrueHD'
	elseif c:find('e%-ac%-3') or c:find('e%-ac3') or c:find('eac3') or c:find('dd%+') then return 'E-AC3'
	elseif c:find('ac%-3') or c:find('ac3') or c:find('dolby') then return 'Dolby Digital'
	elseif c:find('dts%-hd') or c:find('dtshd') or c:find('dts.hd') then return 'DTS-HD'
	elseif c:find('dts') or c:find('dca') then return 'DTS'
	elseif c:find('aac') then return 'AAC'
	elseif c:find('flac') then return 'FLAC'
	elseif c:find('opus') then return 'Opus'
	elseif c:find('mp3') then return 'MP3'
	elseif c:find('pcm') then return 'PCM' end
	return c:upper()
end

function VideoTags:_collect_tags()
	local now = mp.get_time()
	if now - self._last_fetch < 5 and self._cache then
		return self._cache
	end
	self._last_fetch = now

	local h = mp.get_property_number('video-params/h', 0)
	if h <= 0 then h = mp.get_property_number('height', 0) end
	if h <= 0 then self._cache = nil; return nil end

	local tags = {}

	local function is_highlight(s)
		return s:find('Dolby Vision') or s:find('Vivid') or s:find('HDR10')
			or s == '4K UHD' or s == '8K UHD'
			or s:find('TrueHD') or s:find('DTS%-HD') or s:find('^DTS$')
			or s:find('菁彩')
	end

	local hw = self:_hwdec_label()
	if hw ~= '' then table.insert(tags, {text = hw, highlight = false, cat = 'hwdec'}) end

	local hdr = self:_hdr_label()
	if hdr ~= '' then
		table.insert(tags, {text = hdr, highlight = (hdr ~= 'SDR' and is_highlight(hdr)), cat = 'hdr'})
	end

	local codec = self:_codec_label()
	if codec ~= '' then table.insert(tags, {text = codec, highlight = false, cat = 'codec'}) end

	local res = self:_resolution_label()
	if res ~= '' then
		table.insert(tags, {text = res, highlight = is_highlight(res), cat = 'res'})
	end

	local fps = self:_fps_label()
	if fps ~= '' then table.insert(tags, {text = fps, highlight = false, cat = 'fps'}) end

	local ach = self:_audio_ch_label()
	if ach ~= '' then table.insert(tags, {text = ach, highlight = false, cat = 'audio_ch'}) end

	local ac = self:_audio_codec_label()
	if ac ~= '' then
		table.insert(tags, {text = ac, highlight = is_highlight(ac), cat = 'audio_codec'})
	end

	self._cache = tags
	return tags
end

function VideoTags:_probe_hdr_vivid()
    self._hdr_vivid = false
    local filepath = mp.get_property('path')
    if not filepath or filepath == '' then return end

    local ext = filepath:match('%.([^%.]+)$')
    if ext then
        ext = ext:lower()
        if ext ~= 'mp4' and ext ~= 'mkv' and ext ~= 'ts' and ext ~= 'webm' and ext ~= 'hevc' then
            return
        end
    end

    -- ===== 改进后的 ffprobe 查找 =====
    local function find_ffprobe()
        -- 环境变量
        local env_path = os.getenv('FFPROBE_PATH')
        if env_path and env_path ~= '' then
            local fh = io.open(env_path, 'r')
            if fh then fh:close(); return env_path end
        end

        -- mpv 配置目录
        local conf_dir = mp.find_config_file('.') or ''
        if conf_dir ~= '' then
            local base_dir = conf_dir:gsub('[/\\][^/\\]+$', '')
            for _, name in ipairs({'ffprobe.exe', 'ffprobe'}) do
                local test = base_dir .. '/' .. name
                local fh = io.open(test, 'r')
                if fh then fh:close(); return test end
            end
        end

        -- mpv 可执行文件目录 (Windows)
        if state.platform == 'windows' then
            local mpv_exe = mp.get_property('exe-path', '')
            if mpv_exe ~= '' then
                local mpv_dir = mpv_exe:gsub('[/\\][^/\\]+$', '')
                for _, name in ipairs({'ffprobe.exe', 'ffprobe'}) do
                    local test = mpv_dir .. '/' .. name
                    local fh = io.open(test, 'r')
                    if fh then fh:close(); return test end
                end
            end
        end

        -- 脚本目录
        local script_dir = mp.get_property('options/script-dir', '')
        if script_dir ~= '' then
            for _, name in ipairs({'ffprobe.exe', 'ffprobe'}) do
                local test = script_dir .. '/' .. name
                local fh = io.open(test, 'r')
                if fh then fh:close(); return test end
            end
        end

        -- fallback 到系统 PATH
        return 'ffprobe'
    end

    local ffprobe = find_ffprobe()
    -- ===== 改进结束 =====

    mp.command_native_async({
        name = 'subprocess',
        playback_only = true,
        args = {ffprobe, '-v', 'error', '-select_streams', 'v:0',
            '-show_frames', '-read_intervals', '%+#1', '-of', 'json', filepath},
        capture_stdout = true,
        capture_stderr = false,
    }, function(ok, result)
        if ok and result and result.stdout and result.stdout ~= '' then
            local data = utils.parse_json(result.stdout)
            if data and data.frames and data.frames[1] and data.frames[1].side_data_list then
                for _, sd in ipairs(data.frames[1].side_data_list) do
                    if sd.side_data_type and sd.side_data_type:find('Vivid') then
                        self._hdr_vivid = true
                        self._cache = nil
                        request_render()
                        break
                    end
                end
            end
        end
    end)
end

local GRADIENT_THEMES = {
	bbblurry  = {base = '090916', e1 = '6419a9', e2 = '710a44', e3 = '693bb5', e4 = '4ea3d5'},
	lavender  = {base = '1A0A2E', e1 = '8B5CF6', e2 = 'D946EF', e3 = 'A78BFA', e4 = '6D28D9'},
	amethyst  = {base = '0F0A1A', e1 = '9B59B6', e2 = 'C39BD3', e3 = '7D3C98', e4 = '512E5F'},
	sapphire  = {base = '0A0F1E', e1 = '0F52BA', e2 = '4169E1', e3 = '1E90FF', e4 = '00BFFF'},
	midnight  = {base = '0A0A1E', e1 = '1E3A8A', e2 = '312E81', e3 = '2563EB', e4 = '60A5FA'},
	crimson   = {base = '1A0A0F', e1 = 'E11D48', e2 = 'F43F5E', e3 = 'FB7185', e4 = 'BE123C'},
	magenta   = {base = '1A0A1A', e1 = 'C026D3', e2 = 'D946EF', e3 = 'E879F9', e4 = '86198F'},
	amber     = {base = '1A140A', e1 = 'D97706', e2 = 'F59E0B', e3 = 'FBBF24', e4 = '92400E'},
	gold      = {base = '1A140A', e1 = 'B45309', e2 = 'F59E0B', e3 = 'FCD34D', e4 = '78350F'},
	bubblegum = {base = '1A0A14', e1 = 'EC4899', e2 = 'F472B6', e3 = 'F9A8D4', e4 = 'BE185D'},
	blush     = {base = '1A0A14', e1 = 'DB2777', e2 = 'F472B6', e3 = 'FBCFE8', e4 = '9D174D'},
	coral     = {base = '1A0F0A', e1 = 'FF6B6B', e2 = 'FF8E72', e3 = 'FFA07A', e4 = 'E05555'},
	plasma    = {base = '1A0A28', e1 = 'FF00FF', e2 = '00FFFF', e3 = 'FF00AA', e4 = '7F00FF'},
	electric  = {base = '0A0A28', e1 = '1E90FF', e2 = 'FF1493', e3 = '00FFFF', e4 = '7FFF00'},
	autumn    = {base = '1A0F0A', e1 = 'C2410C', e2 = 'D97706', e3 = 'EA580C', e4 = '9A3412'},
	rust      = {base = '1A0A0F', e1 = 'B7410E', e2 = 'CC5500', e3 = 'DA8A67', e4 = '8B3A0E'},
	aurora    = {base = '66002D', e1 = '87FF00', e2 = 'FFE060', e3 = 'FF6100', e4 = '00FFD4'},
}

function VideoTags:_get_gradient_theme()
	local name = cfg_str('mediainfo_theme', 'bbblurry')
	if name == 'custom' then
		return {
			base = cfg_str('mediainfo_gradient_base', '090916'),
			e1   = cfg_str('mediainfo_gradient_c1', '6419a9'),
			e2   = cfg_str('mediainfo_gradient_c2', '710a44'),
			e3   = cfg_str('mediainfo_gradient_c3', '693bb5'),
			e4   = cfg_str('mediainfo_gradient_c4', '4ea3d5'),
		}
	end
	return GRADIENT_THEMES[name] or GRADIENT_THEMES.bbblurry
end

function VideoTags:_tag_bg_color(cat)
	local map = {
		hwdec      = 'mediainfo_color_hwdec',
		codec      = 'mediainfo_color_codec',
		res        = 'mediainfo_color_res',
		fps        = 'mediainfo_color_fps',
		audio_ch   = 'mediainfo_color_audio_layout',
		audio_codec= 'mediainfo_color_audio_codec',
	}
	local key = map[cat]
	return key and cfg_str(key, '000000') or '000000'
end

function VideoTags:render()
	local ctrls = Elements.controls
	if not ctrls or not ctrls.enabled then return end

	local tags = self:_collect_tags()
	if not tags or #tags == 0 then return end

	local vis = self:get_visibility()
	if vis <= 0 then return end

	local ass = assdraw.ass_new()

	local intensity = cfg_num('mediainfo_scale_intensity', 1.0)
	if not self._ref_scale then self._ref_scale = display.height / 720 end
	self._ref_scale = math.max(self._ref_scale, display.height / 720)
	local base = display.height / 720
	local s = base + (self._ref_scale - base) * (1.0 - intensity)

	local font_size   = math.floor(cfg_num('mediainfo_font_size', 12) * s)
	local y_pad       = round(cfg_num('mediainfo_y_padding', 3) * s)
	local x_pad       = round(cfg_num('mediainfo_x_padding', 6) * s)
	local spacing     = round(cfg_num('mediainfo_gap', 5) * s)
	local y_off       = round(cfg_num('mediainfo_y_offset', 23) * s)

	local tag_h = font_size + y_pad * 2
	local x = ctrls.ax
	local bottom_y = ctrls.ay - y_off
	local top_y = bottom_y - tag_h
	local mid_y = top_y + tag_h / 2
	local radius = round(tag_h * 0.2)

	local font_name = options.font ~= '' and options.font or mp.get_property('osd-font', 'sans-serif')
	local start_x = x

	for _, tag in ipairs(tags) do
		local tw = text_width(tag.text, {size = font_size, font = font_name, bold = true})
		local right_x = x + tw + x_pad * 2

		if tag.highlight then
			local theme = self:_get_gradient_theme()
			local W = right_x - x
			local H = bottom_y - top_y

			local clip = assdraw.ass_new()
			clip:round_rect_cw(x, top_y, right_x, bottom_y, radius)
			local clip_str = '\\clip(4,' .. clip.text .. ')'

			ass:rect(x, top_y, right_x, bottom_y, {
				color = theme.base, radius = radius, opacity = vis,
			})

			local blur = math.max(4, math.floor(H * 0.65))
			local cblur = clip_str .. '\\blur' .. blur

			ass:rect(x + W * 0.46, top_y - H * 0.09, x + W * 1.16, top_y + H * 1.01, {
				color = theme.e1, radius = radius, opacity = vis * 0.45, clip = cblur,
			})
			ass:rect(x + W * 0.05, top_y + H * 0.12, x + W * 0.75, top_y + H * 1.22, {
				color = theme.e2, radius = radius, opacity = vis * 0.45, clip = cblur,
			})
			ass:rect(x - W * 0.53, top_y + H * 0.01, x + W * 0.17, top_y + H * 1.11, {
				color = theme.e3, radius = radius, opacity = vis * 0.45, clip = cblur,
			})
			ass:rect(x - W * 0.25, top_y + H * 0.85, x + W * 0.45, top_y + H * 1.95, {
				color = theme.e4, radius = radius, opacity = vis * 0.45, clip = cblur,
			})
		else
			ass:rect(x, top_y, right_x, bottom_y, {
				color = self:_tag_bg_color(tag.cat),
				radius = radius,
				opacity = vis * 0.35,
			})
		end

		ass:txt(x + x_pad, mid_y, 4, tag.text, {
			size = font_size, font = font_name, bold = true,
			color = 'FFFFFF', border = 0, shadow = 0, opacity = vis,
		})

		x = right_x + spacing
	end

	self:set_coordinates(start_x, top_y, x - spacing, bottom_y)
	return ass
end

VideoTags:new()
