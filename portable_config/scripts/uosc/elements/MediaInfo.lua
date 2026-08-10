-- ============================================================
-- 视频技术标签模块 (MediaInfo) — 独立脚本
-- 左下角显示视频/音频技术参数标签
-- 检测逻辑：内联实现（HDR Vivid 识别准确，单文件无需外部模块）
-- 样式/排序/设置：与 mpv_config-2026.04.15 保持一致
-- 配置文件：script-opts/mediainfo.conf
-- ============================================================

local Element = require('elements/Element')

-- ============================================================
-- 媒体格式检测逻辑（内联实现）
-- ============================================================
local function lower(value)
    return tostring(value or ''):lower()
end

local function compact(value)
    return lower(value):gsub('%+', 'plus'):gsub('[^%w]', '')
end

local function contains(text, needle)
    return tostring(text or ''):find(needle, 1, true) ~= nil
end

local function positive(value)
    local number = tonumber(value)
    return number ~= nil and number > 0
end

local function append_value(parts, value)
    if type(value) == 'string' or type(value) == 'number' then
        parts[#parts + 1] = tostring(value)
    end
end

local TRACK_FIELDS = {
    'codec', 'codec-desc', 'codec-profile', 'decoder-desc', 'demux-codec',
    'demux-channel-layout', 'title', 'format', 'lang',
}

local function append_track(parts, track)
    if type(track) ~= 'table' then return end
    for _, field in ipairs(TRACK_FIELDS) do append_value(parts, track[field]) end
    if type(track.metadata) == 'table' then
        for key, value in pairs(track.metadata) do
            append_value(parts, key)
            append_value(parts, value)
        end
    end
end

local function build_context(snapshot, track, extra, include_filename)
    local parts = {}
    append_track(parts, track)
    append_value(parts, extra)
    if include_filename ~= false then
        append_value(parts, snapshot.filename)
        append_value(parts, snapshot.media_title)
        append_value(parts, snapshot.path)
    end
    local raw = lower(table.concat(parts, ' '))
    return raw, compact(raw)
end

local function read_selected_track(kind)
    local current = mp.get_property_native('current-tracks/' .. kind, {})
    if type(current) == 'table' and current.type == kind then return current end
    local selected
    local count = 0
    local tracks = mp.get_property_native('track-list', {})
    if type(tracks) == 'table' then
        for _, track in ipairs(tracks) do
            if type(track) == 'table' and track.type == kind then
                count = count + 1
                if track.selected == true then return track end
                selected = selected or track
            end
        end
    end
    return count == 1 and selected or {}
end

local function read_snapshot()
    return {
        filename = mp.get_property('filename', ''),
        media_title = mp.get_property('media-title', ''),
        path = mp.get_property('path', ''),
        video_params = mp.get_property_native('video-params', {}),
        audio_params = mp.get_property_native('audio-params', {}),
        video_track = read_selected_track('video'),
        audio_track = read_selected_track('audio'),
        video_codec = mp.get_property('video-codec', ''),
        audio_codec = mp.get_property('audio-codec', ''),
        hwdec = mp.get_property('hwdec-current', ''),
        fps = mp.get_property_number('estimated-vf-fps', 0),
        container_fps = mp.get_property_number('container-fps', 0),
        audio_channel_count = mp.get_property_number('audio-params/channel-count', 0),
        audio_channels = mp.get_property_number('audio-channels', 0),
    }
end

local function dolby_vision_label(snapshot, context)
    local track = snapshot.video_track or {}
    local params = snapshot.video_params or {}
    local profile = tonumber(track['dolby-vision-profile'])
        or tonumber(params['dolby-vision-profile'])
    local detected = positive(profile)
        or track['dolby-vision-level'] ~= nil
        or params['dolby-vision-level'] ~= nil
        or contains(context, 'dolbyvision')
        or contains(context, 'dovi')
        or contains(context, 'dvhe')
        or contains(context, 'dvh1')
    if not detected then return nil end
    return profile and profile > 0 and ('Dolby Vision P' .. tostring(profile)) or 'Dolby Vision'
end

local function has_hdr10_plus(track, params, context)
    return track.hdr10plus == true
        or params.hdr10plus == true
        or positive(track['scene-max-r'])
        or positive(track['scene-max-g'])
        or positive(track['scene-max-b'])
        or positive(params['scene-max-r'])
        or positive(params['scene-max-g'])
        or positive(params['scene-max-b'])
        or contains(context, 'hdr10plus')
        or contains(context, 'hdr10p')
end

local function has_hdr10_static_metadata(track, params, context)
    return positive(track['max-cll'])
        or positive(track['max-fall'])
        or positive(track['min-luma'])
        or positive(track['max-luma'])
        or positive(params['max-cll'])
        or positive(params['max-fall'])
        or positive(params['min-luma'])
        or positive(params['max-luma'])
        or contains(context, 'hdr10')
end

local function detect_dynamic_range(snapshot, context)
    local track = type(snapshot.video_track) == 'table' and snapshot.video_track or {}
    local params = type(snapshot.video_params) == 'table' and snapshot.video_params or {}
    local dv = dolby_vision_label(snapshot, context)
    if dv then return dv end
    if params['hdr-vivid'] == true
        or track['hdr-vivid'] == true
        or contains(context, 'hdrvivid')
        or contains(context, 'cuvahdr') then
        return 'HDR Vivid'
    end
    local gamma = lower(params.gamma or params.transfer)
    local pq = gamma == 'pq' or gamma == 'smpte2084'
    if pq and has_hdr10_plus(track, params, context) then return 'HDR10+' end
    if gamma == 'hlg' or gamma == 'arib-std-b67' or gamma == 'aribstdb67'
        or contains(context, 'hlg') then
        return 'HLG'
    end
    if pq then
        return has_hdr10_static_metadata(track, params, context) and 'HDR10' or 'HDR'
    end
    return 'SDR'
end

local VIDEO_CODEC_RULES = {
    {'VVC', {'vvc', 'h266'}},
    {'AVS3', {'avs3'}},
    {'AVS2', {'avs2', 'davs2'}},
    {'AVS+', {'cavs'}},
    {'HEVC', {'hevc', 'h265', 'x265'}},
    {'EVC', {'evc'}},
    {'AVC', {'h264', 'x264', 'avc1', 'avc'}},
    {'AV1', {'av01', 'libaomav1', 'dav1d', 'av1'}},
    {'VP9', {'vp9'}},
    {'VP8', {'vp8'}},
    {'MPEG-2', {'mpeg2video', 'mpeg2'}},
    {'MPEG-4', {'mpeg4', 'xvid', 'divx'}},
    {'VC-1', {'vc1', 'wmv3'}},
    {'ProRes', {'prores'}},
    {'Theora', {'theora'}},
    {'JPEG XL', {'jpegxl', 'jxl'}},
    {'WebP', {'webp'}},
}

local function detect_video_codec(context)
    for _, rule in ipairs(VIDEO_CODEC_RULES) do
        for _, needle in ipairs(rule[2]) do
            if contains(context, needle) then return rule[1] end
        end
    end
    return ''
end

local function detect_audio_codec(snapshot, raw, context, codec_context)
    if contains(context, 'dolbyatmos') or contains(context, 'atmos')
        or raw:match('%f[%w]joc%f[%W]') then
        return 'Dolby Atmos'
    end
    if contains(context, 'dtsx') then return 'DTS:X' end
    if contains(codec_context, 'av3a') or contains(context, 'audiovivid')
        or contains(context, 'avs3audio') then
        return 'Audio Vivid'
    end
    if contains(context, 'dtshdmasteraudio') or contains(context, 'dtshdmaster')
        or contains(context, 'dtshdma') or contains(context, 'dtsma') then
        return 'DTS-HD MA'
    end
    if contains(context, 'dtshdhighresolutionaudio')
        or contains(context, 'dtshdhighresolution')
        or contains(context, 'dtshdhra') or contains(context, 'dtshighres') then
        return 'DTS-HD HRA'
    end
    if contains(context, 'truehd') or contains(context, 'mlpfba') then
        return 'Dolby TrueHD'
    end
    if contains(codec_context, 'eac3') or contains(context, 'dolbydigitalplus')
        or contains(context, 'ddplus') or contains(context, 'ddp') then
        return 'Dolby Digital Plus'
    end
    if contains(codec_context, 'ac3') or contains(context, 'dolbydigital') then
        return 'Dolby Digital'
    end
    if contains(codec_context, 'dca') or contains(codec_context, 'dts')
        or raw:match('%f[%w]dts%f[%W]') then
        return 'DTS'
    end
    if contains(codec_context, 'ac4') then return 'Dolby AC-4' end
    if contains(codec_context, 'mpegh') or contains(codec_context, 'mhm1')
        or contains(codec_context, 'mha1') then
        return 'MPEG-H Audio'
    end
    if contains(context, 'heaacv2') or contains(context, 'heaac2')
        or contains(context, 'sbrps') then
        return 'HE-AAC v2'
    end
    if contains(context, 'heaac') or contains(context, 'aacplus')
        or contains(context, 'sbr') then
        return 'HE-AAC'
    end
    if contains(context, 'dabplus') then return 'DAB+' end
    if contains(codec_context, 'flac') then return 'FLAC' end
    if contains(codec_context, 'alac') then return 'ALAC' end
    if contains(codec_context, 'wavpack') or contains(codec_context, 'wavpak') then return 'WavPack' end
    if contains(codec_context, 'tak') then return 'TAK' end
    if contains(codec_context, 'tta') then return 'TTA' end
    if contains(codec_context, 'ape') or contains(codec_context, 'monkeysaudio') then return 'APE' end
    if codec_context == 'wma' or contains(codec_context, 'wmav1')
        or contains(codec_context, 'wmav2') or contains(codec_context, 'wmapro')
        or contains(codec_context, 'wmavoice') or contains(codec_context, 'wmalossless')
        or contains(codec_context, 'windowsmediaaudio') then
        return 'WMA'
    end
    if contains(codec_context, 'opus') then return 'Opus' end
    if contains(codec_context, 'vorbis') then return 'Vorbis' end
    if contains(codec_context, 'aac') then return 'AAC' end
    if contains(codec_context, 'mp3') or contains(codec_context, 'mpa') then return 'MP3' end
    if contains(codec_context, 'pcm') or contains(codec_context, 'lpcm') then return 'PCM' end
    if contains(codec_context, 'mlp') then return 'MLP' end
    local fallback = tostring(snapshot.audio_codec or '')
    return fallback ~= '' and fallback:upper() or ''
end

local function direct_layout_label(value)
    local text = lower(value)
    local three = text:match('(%d+%.%d+%.%d+)')
    if three then return three end
    local two = text:match('(%d+%.%d+)')
    if two then return two end
    if text:find('stereo', 1, true) or text:find('2ch', 1, true) then return '2.0' end
    if text:find('mono', 1, true) or text:find('1ch', 1, true) then return '1.0' end
    return nil
end

local function speaker_layout_label(value)
    local text = tostring(value or ''):upper()
    local speakers = {}
    for token in text:gmatch('[A-Z][A-Z0-9]+') do speakers[token] = true end
    local top_names = {'TFL', 'TFR', 'TFC', 'TBL', 'TBR', 'TBC', 'TSL', 'TSR'}
    local main_names = {'FL', 'FR', 'FC', 'BL', 'BR', 'SL', 'SR', 'WL', 'WR', 'BC'}
    local top, main = 0, 0
    for _, name in ipairs(top_names) do if speakers[name] then top = top + 1 end end
    for _, name in ipairs(main_names) do if speakers[name] then main = main + 1 end end
    if main > 0 and top > 0 then
        return string.format('%d.%d.%d', main, speakers.LFE and 1 or 0, top)
    end
    return nil
end

local function detect_audio_layout(snapshot)
    local params = type(snapshot.audio_params) == 'table' and snapshot.audio_params or {}
    local track = type(snapshot.audio_track) == 'table' and snapshot.audio_track or {}
    local candidates = {
        params['hr-channels'], params.channels, params['channel-layout'],
        track['demux-channel-layout'], track['channel-layout'],
    }
    for _, value in ipairs(candidates) do
        local layout = direct_layout_label(value) or speaker_layout_label(value)
        if layout then return layout end
    end
    local filename_layout = direct_layout_label(snapshot.filename)
    if filename_layout then return filename_layout end
    local count = tonumber(params['channel-count'])
        or tonumber(snapshot.audio_channel_count)
        or tonumber(snapshot.audio_channels)
        or tonumber(track['demux-channel-count'])
        or 0
    if count == 8 then return '7.1' end
    if count == 6 then return '5.1' end
    if count == 2 then return '2.0' end
    if count == 1 then return '1.0' end
    return count > 0 and (tostring(count) .. 'ch') or ''
end

local function resolution_labels(width, height)
    if width <= 0 and height <= 0 then return '', '' end
    if width >= 7600 or height >= 4300 then return '8K', '8K UHD' end
    if width >= 3800 or height >= 2100 then return '4K', '4K UHD' end
    if width >= 2500 or height >= 1400 then return '1440P', '1440P QHD' end
    if width >= 1900 or height >= 1000 then return '1080P', '1080P' end
    if width >= 1200 or height >= 700 then return '720P', '720P' end
    if height > 0 then
        local label = tostring(math.floor(height + 0.5)) .. 'P'
        return label, label
    end
    return '', ''
end

local function format_fps(value)
    local fps = tonumber(value) or 0
    if fps <= 0 then return '' end
    local rounded = math.floor(fps + 0.5)
    if math.abs(fps - rounded) < 0.015 then return tostring(rounded) .. 'FPS' end
    local precision = math.abs(fps * 1001 / 1000 - rounded) < 0.02 and 3 or 2
    return string.format('%.' .. tostring(precision) .. 'fFPS', fps)
end

local function from_snapshot(snapshot)
    snapshot = type(snapshot) == 'table' and snapshot or {}
    local params = type(snapshot.video_params) == 'table' and snapshot.video_params or {}
    local width = tonumber(params.w or params.dw or params.width) or 0
    local height = tonumber(params.h or params.dh or params.height) or 0
    local video_raw, video_context = build_context(
        snapshot, snapshot.video_track, snapshot.video_codec, true
    )
    local audio_raw, audio_context = build_context(
        snapshot, snapshot.audio_track, snapshot.audio_codec, true
    )
    local _, audio_codec_context = build_context(
        snapshot, snapshot.audio_track, snapshot.audio_codec, false
    )
    local resolution, resolution_long = resolution_labels(width, height)
    local fps = tonumber(snapshot.fps) or 0
    if fps <= 0 then fps = tonumber(snapshot.container_fps) or 0 end
    return {
        video_present = width > 0 or height > 0,
        resolution = resolution,
        resolution_long = resolution_long,
        video_codec = detect_video_codec(video_context),
        dynamic_range = detect_dynamic_range(snapshot, video_context),
        fps = fps,
        fps_label = format_fps(fps),
        audio_codec = detect_audio_codec(
            snapshot, audio_raw, audio_context, audio_codec_context
        ),
        audio_layout = detect_audio_layout(snapshot),
        hwdec = snapshot.hwdec and snapshot.hwdec ~= '' and snapshot.hwdec ~= 'no'
            and 'HW' or 'SW',
    }
end

local function collect_media_info()
    return from_snapshot(read_snapshot())
end

-- ============================================================
-- 读取 mediainfo.conf 配置
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

-- ============================================================
-- 标签元素定义
-- ============================================================
local MediaInfo = class(Element)

function MediaInfo:new() return Class.new(self) end

function MediaInfo:init()
	Element.init(self, 'mediainfo', {render_order = 10, anchor_id = 'controls'})
	self._cache = nil
	self._last_fetch = 0
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
	self:observe_mp_property('audio-codec', invalidate)
	self:observe_mp_property('audio-params', invalidate)
	self:observe_mp_property('aid', invalidate_full)

	self:register_mp_event('file-loaded', function()
		self._cache = nil
		self._last_fetch = 0
		self:_start_initial_display()
		request_render()
	end)

	self:register_mp_event('video-reconfig', function()
		self._cache = nil
		self._last_fetch = 0
		request_render()
	end)
end

function MediaInfo:get_visibility()
	if not cfg_bool('mediainfo_enabled') then return 0 end
	return Element.get_visibility(self)
end

function MediaInfo:_start_initial_display()
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

-- ============================================================
-- 标签高亮判定（与 mpv_config-2026.04.15 完全一致）
-- ============================================================
local function is_highlight(s)
	if s:find('Dolby Vision') or s:find('Vivid') or s:find('HDR10')
		or s == '4K UHD' or s == '8K UHD'
		or s:find('TrueHD') or s:find('DTS%-HD') or s:find('^DTS$')
		or s == 'Dolby Atmos' or s == 'DTS:X'
		or s == 'Dolby AC-4' or s == 'MPEG-H Audio'
		or s == 'VVC' or s == 'AVS3' or s == 'AV1'
		or s == 'FLAC' or s == 'ALAC'
		or s:find('菁彩')
		or s:find('环绕声') then
		return true
	end
	-- N声道兜底(N>=6 即 5.1 以上规格高亮)
	local n = s:match('^(%d+)声道$')
	if n then return tonumber(n) >= 6 end
	return false
end

-- ============================================================
-- 标签文字转换（杲知检测结果 → mpv_config 版标签格式）
-- ============================================================

-- HDR 标签转换
local function convert_hdr_label(s)
	if s == 'HDR Vivid' then return 'HDR Vivid (菁彩影像)' end
	local p = s:match('^Dolby Vision P(%d+)$')
	if p then return 'Dolby Vision (P' .. p .. ')' end
	return s
end

-- 分辨率标签转换
local function convert_res_label(s)
	if s == '1440P QHD' then return '2K QHD' end
	return s
end

-- 帧率标签转换（统一取整数 FPS）
local function convert_fps_label(s)
	local fps_num = tonumber(s:match('([%d%.]+)')) or 0
	if fps_num > 0 then return string.format('%dFPS', math.floor(fps_num + 0.5)) end
	return s
end

-- 音频声道标签转换
local function convert_audio_ch_label(s)
	-- X.Y.Z 三维声布局
	local x, y, z = s:match('^(%d+)%.(%d+)%.(%d+)$')
	if x then
		if tonumber(x) >= 5 then return s .. ' 环绕声' end
		return s
	end
	-- X.Y 布局
	local x2, y2 = s:match('^(%d+)%.(%d+)$')
	if x2 then
		local xi, yi = tonumber(x2), tonumber(y2)
		if xi == 7 and yi == 1 then return '7.1 环绕声'
		elseif xi == 5 and yi == 1 then return '5.1 环绕声'
		elseif xi >= 9 and yi >= 1 then return s .. ' 环绕声'
		elseif xi == 2 and yi == 0 then return '2.0 立体声'
		elseif xi == 1 and yi == 0 then return '1.0 单声道'
		end
		return s
	end
	-- Nch → N声道
	local n = s:match('^(%d+)ch$')
	if n then return n .. '声道' end
	return s
end

-- 音频编码标签转换
local function convert_audio_codec_label(s)
	local map = {
		['Audio Vivid']       = 'Audio Vivid 菁彩音频',
		['Dolby TrueHD']      = 'TrueHD',
	}
	return map[s] or s
end

-- ============================================================
-- 收集标签（使用内联检测逻辑）
-- 排序：硬解/软解 → HDR → 编码 → 音频编码 → 音频声道 → 分辨率 → 帧率
-- ============================================================
function MediaInfo:_collect_tags()
	local now = mp.get_time()
	if now - self._last_fetch < 5 and self._cache then
		return self._cache
	end
	self._last_fetch = now

	local info = collect_media_info()
	if not info.video_present then
		self._cache = nil
		return nil
	end

	local tags = {}

	-- 硬解/软解
	local hw = info.hwdec == 'HW' and '硬解' or '软解'
	table.insert(tags, {text = hw, highlight = false, cat = 'hwdec'})

	-- HDR / 动态范围
	local hdr = convert_hdr_label(info.dynamic_range or '')
	if hdr ~= '' then
		table.insert(tags, {text = hdr, highlight = (hdr ~= 'SDR' and is_highlight(hdr)), cat = 'hdr'})
	end

	-- 视频编码
	local codec = info.video_codec or ''
	if codec ~= '' then
		table.insert(tags, {text = codec, highlight = is_highlight(codec), cat = 'codec'})
	end

	-- 音频编码
	local ac = convert_audio_codec_label(info.audio_codec or '')
	if ac ~= '' then
		table.insert(tags, {text = ac, highlight = is_highlight(ac), cat = 'audio_codec'})
	end

	-- 音频声道
	local ach = convert_audio_ch_label(info.audio_layout or '')
	if ach ~= '' then
		table.insert(tags, {text = ach, highlight = is_highlight(ach), cat = 'audio_ch'})
	end

	-- 分辨率
	local res = convert_res_label(info.resolution_long or '')
	if res ~= '' then
		table.insert(tags, {text = res, highlight = is_highlight(res), cat = 'res'})
	end

	-- 帧率
	local fps = convert_fps_label(info.fps_label or '')
	if fps ~= '' then
		local fps_num = tonumber(fps:match('%d+')) or 0
		table.insert(tags, {text = fps, highlight = (fps_num >= 60), cat = 'fps'})
	end

	self._cache = tags
	return tags
end

-- ============================================================
-- 标签样式配置（与 mpv_config-2026.04.15 一致）
-- ============================================================
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

function MediaInfo:_get_gradient_theme()
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

function MediaInfo:_tag_bg_color(cat)
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

-- ============================================================
-- 渲染（与 mpv_config-2026.04.15 样式完全一致）
-- ============================================================
function MediaInfo:render()
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

return MediaInfo
