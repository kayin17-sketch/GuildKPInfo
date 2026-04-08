GuildKPInfo = GuildKPInfo or {}

local C = {}
GuildKPInfo.Core = C

C.members = {}
C.activeRaid = nil
C.inRaid = false

local DKP_PATTERN = "<(%d%d%d%d%d)>"

local function ExtractItemInfo(link)
  if not link then return nil, nil, nil end
  local _, _, itemID = strfind(link, "|Hitem:(%d+)")
  local _, _, itemName = strfind(link, "|h%[(.-)%]|h")
  if not itemName then return nil, nil, nil end

  local quality = nil
  if itemID then
    local _, _, q = GetItemInfo(tonumber(itemID))
    quality = q
  end

  return itemName, tonumber(itemID), quality
end

function C.RefreshGuildData()
  C.members = {}

  local numMembers = GetNumGuildMembers(true)
  if not numMembers or numMembers == 0 then return end

  for i = 1, numMembers do
    local name, rankName, rankIndex, level, class, zone, publicNote, officerNote, online =
      GetGuildRosterInfo(i)

    if name then
      local dkp = 0
      if officerNote then
        local _, _, dkpStr = strfind(officerNote, DKP_PATTERN)
        if dkpStr then
          dkp = tonumber(dkpStr) or 0
        end
      end

      local classUpper = strupper(class or "")
      C.members[table.getn(C.members) + 1] = {
        name = name,
        class = classUpper,
        className = class or "",
        rank = rankName or "",
        level = level or 0,
        dkp = dkp,
        online = online == 1
      }
    end
  end
end

function C.GetFilteredMembers(searchText, classFilter, onlineOnly)
  local result = {}
  local search = ""
  if searchText then
    search = strlower(gsub(searchText, "^%s*(.-)%s*$", "%1"))
  end
  local filterClass = classFilter and classFilter ~= "ALL" and classFilter or nil

  for i = 1, table.getn(C.members) do
    local m = C.members[i]

    if onlineOnly and not m.online then
    elseif filterClass and m.class ~= filterClass then
    elseif search ~= "" and not strfind(strlower(m.name), search, 1, true) then
    else
      result[table.getn(result) + 1] = m
    end
  end

  return result
end

function C.SortMembers(members, column, direction)
  local dir = (direction == "asc") and 1 or -1

  table.sort(members, function(a, b)
    local va, vb
    if column == "name" then
      va = strlower(a.name)
      vb = strlower(b.name)
      if va == vb then return false end
      return (va < vb) == (dir == 1)
    elseif column == "class" then
      va = a.class
      vb = b.class
      if va == vb then
        return (a.dkp > b.dkp)
      end
      return (va < vb) == (dir == 1)
    elseif column == "dkp" then
      if a.dkp == b.dkp then
        return strlower(a.name) < strlower(b.name)
      end
      return (a.dkp > b.dkp) == (dir == 1)
    elseif column == "online" then
      va = a.online and 1 or 0
      vb = b.online and 1 or 0
      if va == vb then
        return a.dkp > b.dkp
      end
      return (va > vb) == (dir == 1)
    end
    return false
  end)
end

function C.ParseRaidChat(msg, sender)
  if not msg then return nil end

  local hasItem = strfind(msg, "|Hitem:")
  if not hasItem then return nil end

  local hasDKP = strfind(msg, "[Dd][Kk][Pp]")
  if not hasDKP then return nil end

  local itemName, itemID, quality = ExtractItemInfo(msg)
  if not itemName then return nil end

  local cleanMsg = gsub(msg, "|c%x%x%x%x%x%x%x%x", "")
  cleanMsg = gsub(cleanMsg, "|Hitem:.-|h%[(.-)%]|h", "%1")
  cleanMsg = gsub(cleanMsg, "|r", "")

  local dkp = 0
  local _, dkpEnd = strfind(cleanMsg, "[Dd][Kk][Pp]")
  if dkpEnd then
    local afterDKP = strsub(cleanMsg, dkpEnd + 1)
    local _, _, dkpStr = strfind(afterDKP, "(%d+)")
    if dkpStr then
      dkp = tonumber(dkpStr) or 0
    else
      local beforeDKP = strsub(cleanMsg, 1, dkpEnd - 1)
      local lastNum = nil
      for num in string.gfind(beforeDKP, "(%d+)") do
        lastNum = num
      end
      if lastNum then dkp = tonumber(lastNum) or 0 end
    end
  end

  local player = sender or "Unknown"
  local _, _, p1 = strfind(cleanMsg, "%sto%s+(%a+)")
  if not p1 then _, _, p1 = strfind(cleanMsg, "%spor%s+(%a+)") end
  if not p1 then _, _, p1 = strfind(cleanMsg, "->%s*(%a+)") end
  if not p1 then _, _, p1 = strfind(cleanMsg, "(%a+)%s+bids") end
  if not p1 then _, _, p1 = strfind(cleanMsg, "(%a+)%s+offers") end
  if p1 and strlen(p1) >= 3 then
    player = p1
  end

  local _, _, link = strfind(msg, "(|Hitem:.-|h%[.-%]|h)")

  local entry = {
    itemName = itemName,
    itemID = itemID,
    quality = quality,
    player = player,
    dkp = dkp,
    time = date("%H:%M:%S"),
    sender = sender or "",
    itemLink = link or msg
  }

  if not C.activeRaid then return nil end

  return entry
end

function C.AddItemToRaid(entry)
  if not C.activeRaid then return false end
  C.activeRaid.items[table.getn(C.activeRaid.items) + 1] = entry
  return true
end

local RAID_ZONES = {
  ["Zul'Gurub"] = true,
  ["Molten Core"] = true,
  ["Blackwing Lair"] = true,
  ["Onyxia's Lair"] = true,
  ["Ruins of Ahn'Qiraj"] = true,
  ["Ahn'Qiraj"] = true,
  ["Temple of Ahn'Qiraj"] = true,
  ["Naxxramas"] = true,
  ["Karazhan"] = true,
  ["Gruul's Lair"] = true,
  ["Magtheridon's Lair"] = true,
  ["Serpentshrine Cavern"] = true,
  ["The Eye"] = true,
  ["The Battle for Mount Hyjal"] = true,
  ["Mount Hyjal"] = true,
  ["Black Temple"] = true,
  ["Sunwell Plateau"] = true,
  ["Zul'Aman"] = true,
}

function C.IsInRaidZone()
  local zone = GetRealZoneText()
  return zone and RAID_ZONES[zone] or false
end

function C.StartRaid()
  if C.activeRaid then return end

  local zone = GetRealZoneText() or "Unknown"

  C.activeRaid = {
    date = date("%Y-%m-%d"),
    startTime = date("%H:%M"),
    zone = zone,
    items = {}
  }

  C.inRaid = true
end

function C.EndRaid()
  if not C.activeRaid then return end

  local numItems = 0
  if C.activeRaid.items then
    numItems = table.getn(C.activeRaid.items)
  end

  if numItems > 0 then
    local db = GuildKPInfoDB
    if db and db.raids then
      db.raids[table.getn(db.raids) + 1] = {
        date = C.activeRaid.date,
        startTime = C.activeRaid.startTime,
        zone = C.activeRaid.zone,
        items = C.activeRaid.items
      }
    end
  end

  C.activeRaid = nil
  C.inRaid = false
end

function C.CheckRaidStatus()
  local numRaid = GetNumRaidMembers()
  if numRaid and numRaid > 0 then
    if not C.inRaid and C.IsInRaidZone() then
      C.StartRaid()
    end
  else
    if C.inRaid then
      C.EndRaid()
    end
  end
end

function C.GetRaidStats()
  local db = GuildKPInfoDB
  if not db or not db.raids then return 0, 0, 0 end

  local totalRaids = 0
  local totalItems = 0
  local totalDKP = 0

  for i = 1, table.getn(db.raids) do
    local raid = db.raids[i]
    local numItems = 0
    if raid.items then numItems = table.getn(raid.items) end
    if numItems > 0 then
      totalRaids = totalRaids + 1
      for j = 1, numItems do
        totalItems = totalItems + 1
        totalDKP = totalDKP + (raid.items[j].dkp or 0)
      end
    end
  end

  return totalRaids, totalItems, totalDKP
end
