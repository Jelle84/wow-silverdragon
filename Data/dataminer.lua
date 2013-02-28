-- (c) 2007 Nymbia.  see LGPLv2.1.txt for full details.
--this tool is run in the lua command line.  http://lua.org
--socket is required for internet data.
--get socket here: http://luaforge.net/projects/luasocket/
--if available curl will be used, which allows connection re-use

local SOURCE = SOURCE or "defaults.lua"
local DEBUG = tonumber(arg[1]) or DEBUG or 1

local WOWHEAD_URL = "http://www.wowhead.com/"

local function dprint(dlevel, ...)
	if dlevel and DEBUG >= dlevel then
		print(...)
	end
end

require "map" -- gets us zonename_to_zoneid

local url = require("socket.url")
local httptime, httpcount = 0, 0
local getpage
do
	local status, curl = pcall(require, "curl")
	if status then
		local temp
		local write = function (s, len)
			temp[#temp + 1] = s
			return len
		end
		local c = curl.easy_init()
		function getpage(url)
			dprint(2, "curl", url)
			temp = {}
			c:setopt(curl.OPT_URL, url)
			c:setopt(curl.OPT_WRITEFUNCTION, write)
			local stime = os.time()
			local err, info = c:perform()
			httptime = httptime + (os.time() - stime)
			httpcount = httpcount + 1
			if err ~= 0 then
				dprint(1, "curl error", url, info)
			else
				temp = table.concat(temp)
				if temp:len() > 0 then
					return temp
				end
			end
		end
	else
		local http = require("socket.http")

		function getpage(url)
			dprint(2, "socket.http", url)
			local stime = os.time()
			local r = http.request(url)
			httptime = httptime + (os.time() - stime)
			httpcount = httpcount + 1
			return r
		end
	end
end

if not NOCACHE then
	local real_getpage = getpage
	local status, sqlite = pcall(require, "lsqlite3")
	if status then
		db = sqlite.open("wowhead.db")
		db:exec([[
CREATE TABLE IF NOT EXISTS cache (
	url TEXT,
	content BLOB,
	time TEXT,
	PRIMARY KEY (url)
)]])
		local CACHE_TIMEOUT = CACHE_TIMEOUT or "+7 day"
		local select_stmt = db:prepare("SELECT content FROM cache WHERE url = ? AND datetime(time, '"..CACHE_TIMEOUT.."') > datetime('now')")
		local insert_stmt = db:prepare("INSERT INTO cache VALUES (?, ?, CURRENT_TIMESTAMP)")
		getpage = function (url)
			select_stmt:bind_values(url)
			local result = select_stmt:step()
			if result == sqlite3.ROW then
				result = select_stmt:get_value(0)
				select_stmt:reset()
				return result
			else
				select_stmt:reset()
			end
			local content = real_getpage(url)
			if content then
				insert_stmt:bind_values(url, content)
				insert_stmt:step()
				insert_stmt:reset()
			end
			return content
		end
	else
		local page_cache = {}
		getpage = function (url)
			local page = page_cache[url]
			if not page then
				page = real_getpage(url)
				page_cache[url] = page
			end
			return page
		end
	end
end

local function write_output(data)
	local f = assert(io.open(SOURCE, "w"))
	f:write([[
-- DO NOT EDIT THIS FILE; run dataminer.lua to regenerate.
local core = LibStub("AceAddon-3.0"):GetAddon("SilverDragon")
local module = core:GetModule("Data")
function module:GetDefaults()
	local defaults = {
]])
	for zone, mobs in pairs(data) do
		f:write('\t\t['..zone..'] = {\n')
		for id, mob in pairs(mobs) do
			f:write('\t\t\t['..id..'] = {')
			if mob.name then f:write('name="'..mob.name..'",') end
			if mob.id then f:write('id='..mob.id..',') end
			if mob.level then f:write('level='..mob.level..',') end
			if mob.creature_type then f:write('creature_type="'..mob.creature_type..'",') end
			if mob.elite then f:write('elite=true,') end
			if mob.tameable then f:write('tameable=true,') end
			if mob.locations then
				f:write('locations = {')
				for _,loc in pairs(mob.locations) do
					f:write(loc..',')
				end
				f:write('},')
			end
			f:write('},\n')
		end
		f:write('\t\t},\n')
	end
	f:write([[
	}
	return defaults
end
]])
	f:close()
	print('defaults written')
end

local npctypes = {
	[1] = 'Beast',
	[2] = 'Dragonkin',
	[3] = 'Demon',
	[4] = 'Elemental',
	[5] = 'Giant',
	[6] = 'Undead',
	[7] = 'Humanoid',
	[8] = 'Critter',
	[9] = 'Mechanical',
	[10] = 'Uncategorized',
}

local defaults

-- Mobs which, although rare, shouldn't be included
local blacklist = {
	[50091] = true, -- untargetable Julak-Doom component
}
-- Mobs which should be included even though they're not rare
local force_include = {
	17591, -- Blood Elf Bandit
	50409, -- Mysterious Camel Figurine
	50410, -- Mysterious Camel Figurine (remnants)
	3868, -- Blood Seeker (thought to share Aeonaxx's spawn timer)
	51236, -- Aeonaxx (engaged)
	58336, -- Darkmoon Rabbit
	-- Lost and Found!
	64004, -- Ghostly Pandaren Fisherman
	64191, -- Ghostly Pandaren Craftsman
	65552, -- Glinting Rapana Whelk
	64272, -- Jade Warrior Statue
	64227, -- Frozen Trail Packer
	--In 5.2, world bosses are no longer flagged as rare, even if they are.
	--Granted, 3 of 4 probably won't be rare. We include anyways because we always have.
	60491, -- Sha of Anger
	62346, -- Galleon
	69099, -- Nalak
	69161, -- Oondasta
}
local name_overrides = {
	[50410] = "Crumbled Statue Remnants",
	[51401] = "Madexx (red)",
	[51402] = "Madexx (green)",
	[51403] = "Madexx (black)",
	[51404] = "Madexx (blue)",
	[50154] = "Madexx (brown)",
	[51236] = "Aeonaxx (engaged)",
	[69769] = "Zandalari Warbringer (Slate)",
	[69841] = "Zandalari Warbringer (Amber)",
	[69842] = "Zandalari Warbringer (Jade)",
}

local function pack_coords(x, y)
	return math.floor(x * 10000 + 0.5) * 10000 + math.floor(y * 10000 + 0.5)
end
local function unpack_coords(coord)
	return math.floor(coord / 10000) / 10000, (coord % 10000) / 10000
end

local zones = {}
local function zone_mappings()
	local url = "http://static.wowhead.com/js/locale_enus.js?250"
	local page = getpage(url)
	if not page then return end
	dprint(3, "Loaded locales")
	page = page:match('g_zones = {([^}]+)};')
	if not page then return end
	dprint(3, "Found zones in locales", page)
	for id, zone in page:gmatch('"(%d+)":"([^"]+)"') do
		if zonename_to_zoneid[zone] then
			zones[id] = zonename_to_zoneid[zone]
			dprint(3, "added", id, zone)
		else
			dprint(1, "Skipping zone translation", id, zone)
		end
	end
end

local function npc_coords(id, zone)
	local url = WOWHEAD_URL.."npc="..id
	local page = getpage(url)
	if not page then return end
	
	page = page:match("g_mapperData = (%b{})")
	if not page then return end
	page = page:match(zone..": (%b{})")
	if not page then return end
	page = page:match("coords: (%b[])")
	if not page then return end
	
	coords = {}
	for entry in page:gmatch("%[[0-9%.,]+%]") do
		local x, y = entry:match("([0-9%.]+),([0-9%.]+)")
		table.insert(coords, {tonumber(x)/100, tonumber(y)/100})
	end
	dprint(3, 'found coords', id, zone, #coords)
	return coords
end

local function npc_tameable(id)
	local url = WOWHEAD_URL.."npc="..id
	local page = getpage(url)
	if not page then return end
	
	page = page:match("\\x5DTameable\\x20")
	if page then
		return true
	end
	return nil
end

local function npc_from_list_entry(entry)
	dprint(3, "Processing:", entry)
	local id = tonumber(entry:match("\"id\":(%d+)"))
	local name = entry:match("\"name\":['\"](.-)['\"],")
	name = name:gsub("\\'", "'")
	local level = tonumber(entry:match("\"maxlevel\":(%d+)"))
	if level == 9999 then
		level = -1 -- boss mobs
	end
	local ctype = tonumber(entry:match("\"type\":(%d+)"))
	if ctype == 10 then
		ctype = nil -- Uncategorized
	else
		ctype = npctypes[ctype]
	end
	local elite = (entry:match("\"classification\":(%d+)") == '2')
	local zoneids = entry:match("\"location\":%[([%d,]+)]") or ""
	dprint(3, "Found:", id, name, level, ctype, elite, zoneid)
	
	if blacklist[id] then
		return
	end

	if name_overrides[id] then
		name = name_overrides[id]
	end

	local instances = {}
	local in_a_zone = false
	for zoneid in zoneids:gfind("%d+") do
		local zone = zones[zoneid]
		if zone then
			local locations = {}
			local raw_coords = npc_coords(id, zoneid)
			if raw_coords and #raw_coords > 0 then
				for _,loc in pairs(raw_coords) do
					local x,y = unpack(loc)
					local is_new = true
					for _,oldloc in pairs(locations) do
						local old_x, old_y = unpack_coords(oldloc)
						if math.abs(old_x - x) < 0.05 and math.abs(old_y - y) < 0.05 then
							is_new = false
							break
						end
					end
					if is_new then
						table.insert(locations, pack_coords(x, y))
					end
				end
			end
			instances[zone] = {
				id = id,
				name = name,
				level = level,
				creature_type = ctype,
				locations = locations,
				elite = elite,
				tameable = npc_tameable(id),
			}
			in_a_zone = true
		else
			dprint(1, "Skipping adding to zone", zoneid)
		end
	end
	if not in_a_zone then
		instances[-1] = {
			id = id,
			name = name,
			level = level,
			creature_type = ctype,
			elite = elite,
			tameable = npc_tameable(id),
		}
	end
	return id, instances
end

local function npcs_from_list_page(url)
	local page = getpage(url)
	if not page then return end
	dprint(3, "Loaded page.")
	page = page:match("new Listview(%b())")
	if not page then return end
	dprint(3, "Found listview.")
	page = page:match("data: (%b[])")
	if not page then return end
	dprint(3, "Found data.")
	for entry in page:gmatch("%b{}") do
		local id, npc_zones = npc_from_list_entry(entry)
		if id then
			for zone, npc in pairs(npc_zones) do
				if not defaults[zone] then defaults[zone] = {} end
				defaults[zone][id] = npc
				print("Added "..id.." (".. npc.name ..") to "..zone)
			end
		end
	end
end

local function main()
	zone_mappings()
	defaults = {}
	for i,c in pairs(npctypes) do
		print("Acquiring rares for category: "..c)
		for expansion = 1, 5 do
			print("EXPANSION: "..expansion)
			-- run per-expansion to avoid caps on results-displayed
			local url = WOWHEAD_URL .. "npcs=" .. i .. "&filter=cl=4:2;cr=39;crs=" .. expansion .. ";crv=0"
			npcs_from_list_page(url)
		end
	end
	for i, id in ipairs(force_include) do
		print("Acquiring forced ID: "..id)
		local url = WOWHEAD_URL .. "npcs?filter=cr=37;crs=3;crv=" .. id
		
		npcs_from_list_page(url)
	end
	write_output(defaults)
end

main()
