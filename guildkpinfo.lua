GuildKPInfo = GuildKPInfo or {}

local eventFrame = CreateFrame("Frame", "GKPIEventFrame", UIParent)

local initialized = false

local function InitDB()
  if not GuildKPInfoDB then
    GuildKPInfoDB = {
      raids = {},
      minimapAngle = -45,
      sortColumn = "dkp",
      sortDirection = "desc",
      classFilter = "ALL",
    }
  end

  if not GuildKPInfoDB.raids then GuildKPInfoDB.raids = {} end
  if not GuildKPInfoDB.minimapAngle then GuildKPInfoDB.minimapAngle = -45 end
  if not GuildKPInfoDB.sortColumn then GuildKPInfoDB.sortColumn = "dkp" end
  if not GuildKPInfoDB.sortDirection then GuildKPInfoDB.sortDirection = "desc" end
  if not GuildKPInfoDB.classFilter then GuildKPInfoDB.classFilter = "ALL" end
end

local function OnLoad()
  if arg1 ~= "guildkpinfo" then return end
  InitDB()
end

local function OnEnterWorld()
  if initialized then return end
  initialized = true

  GuildKPInfo.Style.Initialize()
  GuildKPInfo.UI.CreateMinimapButton()
  GuildKPInfo.Members.RestoreSettings()
  GuildKPInfo.UI.CreateMainWindow()

  eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
  eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
  eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  eventFrame:RegisterEvent("CHAT_MSG_RAID")
  eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
  eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")

  local initialRefresh = CreateFrame("Frame", nil, UIParent)
  initialRefresh.elapsed = 0
  initialRefresh:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed >= 5 then
      this:SetScript("OnUpdate", nil)
      GuildRoster()
    end
  end)

  local autoRefresh = CreateFrame("Frame", "GKPIAutoRefresh", UIParent)
  autoRefresh.elapsed = 0
  autoRefresh:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed >= 300 then
      this.elapsed = 0
      GuildRoster()
    end
  end)
end

local function OnGuildUpdate()
  GuildKPInfo.Core.RefreshGuildData()
  if GuildKPInfo.UI.mainFrame and GuildKPInfo.UI.mainFrame:IsShown() then
    if GuildKPInfo.UI.activeTab == 1 then
      GuildKPInfo.Members.RefreshList()
    end
  end
end

local function OnRaidUpdate()
  GuildKPInfo.Core.CheckRaidStatus()
end

local function OnZoneChange()
  if GuildKPInfo.Core.inRaid and GuildKPInfo.Core.activeRaid then
    local zone = GetRealZoneText() or "Unknown"
    if zone ~= GuildKPInfo.Core.activeRaid.zone then
      GuildKPInfo.Core.EndRaid()
      GuildKPInfo.Core.StartRaid()
      if GuildKPInfo.Core.activeRaid then
        GuildKPInfo.Core.activeRaid.zone = zone
      end
    end
  end
end

local pendingItems = {}

local function ShiftPending()
  local val = pendingItems[1]
  local n = table.getn(pendingItems)
  for i = 2, n do
    pendingItems[i - 1] = pendingItems[i]
  end
  pendingItems[n] = nil
  return val
end

local function ProcessNextPendingItem()
  if table.getn(pendingItems) == 0 then return end

  local entry = ShiftPending()
  local S = GuildKPInfo.Style
  local _, _, _, qualityHex = S.GetItemQualityColor(entry.quality)

  local dialogText = "Register this loot?\n\n" ..
    qualityHex .. "[" .. entry.itemName .. "]|r  ->  |cffffffff" .. entry.player .. "|r\n" ..
    "|cffffd100" .. entry.dkp .. " DKP|r  |  By: |cff999999" .. entry.sender .. "|r"

  S.CreateQuestionDialog(dialogText,
    function()
      GuildKPInfo.Core.AddItemToRaid(entry)
      if GuildKPInfo.UI.mainFrame and GuildKPInfo.UI.mainFrame:IsShown() and GuildKPInfo.UI.activeTab == 2 then
        GuildKPInfo.Raids.RefreshList()
      end
      ProcessNextPendingItem()
    end,
    function()
      ProcessNextPendingItem()
    end
  )
end

local function OnRaidChat()
  if not GuildKPInfo.Core.inRaid then return end

  local msg = arg1
  local sender = arg2
  if not msg then return end

  local entry = GuildKPInfo.Core.ParseRaidChat(msg, sender)
  if entry then
    pendingItems[table.getn(pendingItems) + 1] = entry
    if not (GKPIQuestionDialog and GKPIQuestionDialog:IsShown()) then
      ProcessNextPendingItem()
    end
  end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    OnLoad()
  elseif event == "PLAYER_ENTERING_WORLD" then
    OnEnterWorld()
  elseif event == "GUILD_ROSTER_UPDATE" then
    OnGuildUpdate()
  elseif event == "RAID_ROSTER_UPDATE" then
    OnRaidUpdate()
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    OnZoneChange()
  elseif event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING" then
    OnRaidChat()
  end
end)

SLASH_GKPI1 = "/gkpi"
SLASH_GKPI2 = "/dkp"
SlashCmdList["GKPI"] = function()
  GuildKPInfo.UI.Toggle()
end
