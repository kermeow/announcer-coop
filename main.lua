-- name: Announcer
-- description: \\#33ff33\\Announcer\n\n\\#dcdcdc\\Announces star collection in chat.\nOptionally plays sound effects.\n\nMod by \\#646464\\kermeow\n\\#dcdcdc\\Sounds by \\#646464\\pyrule

---@type NetworkPlayer
local localPlayer = gNetworkPlayers[0]

---@return integer
local function star_id_bitmask()
	if gLevelValues.useGlobalStarIds then
		return 0xff
	end
	return 0x1f
end

local custom_star_names = {
	[COURSE_PSS] = {
		[1] = "Peach's Secret Slide",
		[2] = "Peach's Slide Under 21 Seconds",
	}
}

---@param course integer
---@param level integer
---@param area integer
---@param star integer
---@return string
local function get_star_name(course, level, area, star)
	local isMainCourse = course <= 15
	local starName = get_star_name_ascii(course, star, -1)
	if isMainCourse and star == 7 then -- 100 coins star
		starName = get_level_name_ascii(course, level, area, -1) .. "'s " .. starName
	end
	local customStars = custom_star_names[course]
	if customStars ~= nil then
		local customStar = customStars[star]
		if customStar ~= nil then
			return customStar
		end
	end
	return starName
end

---@class AnnouncerPacket
---@field player integer
---@field type "star" | "bowser"
---@field course integer
---@field level integer
---@field area integer
---@field star integer

local star_message = "%s\\#ffffff\\ got \\#33ff33\\[%s]\\#ffffff\\!"
local bowser_message = "%s\\#ffffff\\ beat \\#ff3300\\[%s]\\#ffffff\\!"

local star_sound = audio_sample_load("starAnnounce.mp3")
local bowser_sound = audio_sample_load("bowserAnnounce.mp3")

local play_star_sound = true
if mod_storage_exists("star_sound") then play_star_sound = mod_storage_load_bool("star_sound") end
local play_bowser_sound = true
if mod_storage_exists("bowser_sound") then play_bowser_sound = mod_storage_load_bool("bowser_sound") end

---@param data AnnouncerPacket
local function on_recv_packet(data)
	local player = network_player_from_global_index(data.player)
	if data.type == "star" then
		local starName = get_star_name(data.course, data.level, data.area, data.star + 1)
		djui_chat_message_create(string.format(star_message, player.name, starName))
		if not play_star_sound then return end
		if player ~= localPlayer then audio_sample_play(star_sound, gLakituState.pos, get_volume_sfx()) end
	end
	if data.type == "bowser" then
		local courseName
		if data.course == COURSE_BITDW then courseName = "Bowser in the Dark World" end
		if data.course == COURSE_BITFS then courseName = "Bowser in the Fire Sea" end
		if data.course == COURSE_BITS then courseName = "Bowser in the Sky" end
		djui_chat_message_create(string.format(bowser_message, player.name, courseName))
		if not play_bowser_sound then return end
		if player ~= localPlayer then audio_sample_play(bowser_sound, gLakituState.pos, get_volume_sfx()) end
	end
end

---@param star integer
---@param bowser boolean?
---@return AnnouncerPacket
local function make_packet(star, bowser)
	local type = "star"
	if bowser then type = "bowser" end
	return {
		player = localPlayer.globalIndex,
		type = type,
		course = localPlayer.currCourseNum,
		level = localPlayer.currLevelNum,
		area = localPlayer.currAreaIndex,
		star = star
	}
end

---@type Pointer_BehaviorScript
local bhv_bowserKey = get_behavior_from_id(id_bhvBowserKey)

---@param m MarioState
---@param object Object
---@param interactType InteractionType
---@param _ boolean
local function on_interact(m, object, interactType, _)
	if m.playerIndex ~= 0 then return end
	if interactType ~= INTERACT_STAR_OR_KEY then return end
	local subtype = object.oInteractionSubtype
	local bowser = (subtype == INT_SUBTYPE_GRAND_STAR) or (object.behavior == bhv_bowserKey)
	local star = (object.oBehParams >> 24) & star_id_bitmask()
	local packet = make_packet(star, bowser)
	network_send(true, packet)
	on_recv_packet(packet)
end

hook_event(HOOK_ON_PACKET_RECEIVE, on_recv_packet)
hook_event(HOOK_ON_INTERACT, on_interact)

hook_mod_menu_checkbox("Play sound on star announcement", play_star_sound, function(_, value)
	play_star_sound = value
	mod_storage_save_bool("star_sound", value)
end)
hook_mod_menu_checkbox("Play sound on Bowser announcement", play_bowser_sound, function(_, value)
	play_bowser_sound = value
	mod_storage_save_bool("bowser_sound", value)
end)

hook_mod_menu_button("Preview star sound", function(_)
	audio_sample_play(star_sound, gLakituState.pos, 1)
end)
hook_mod_menu_button("Preview Bowser sound", function(_)
	audio_sample_play(bowser_sound, gLakituState.pos, 1)
end)
