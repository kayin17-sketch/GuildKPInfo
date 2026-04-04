GuildKPInfo = GuildKPInfo or {}

local R = {}
GuildKPInfo.Raids = R

R.frame = nil
R.raidFrames = {}
R.expandedRaids = {}
R.scrollOffset = 0

local RAID_HEADER_HEIGHT = 22
local ITEM_ROW_HEIGHT = 20
local TOOLBAR_HEIGHT = 30
local STATUS_HEIGHT = 22

local function CountRaidItems(raid)
  if not raid or not raid.items then return 0 end
  return table.getn(raid.items)
end

local function CreateRaidHeader(parent, id)
  local S = GuildKPInfo.Style

  local header = CreateFrame("Button", "GKPIRaidHeader" .. id, parent)
  header:SetHeight(RAID_HEADER_HEIGHT)
  header:SetPoint("LEFT", parent, "LEFT", 4, 0)
  header:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
  header:EnableMouse(true)
  header:Hide()

  S.CreateBackdrop(header, nil, true)

  header.expandIcon = header:CreateFontString(nil, "ARTWORK")
  S.SetFont(header.expandIcon, 11)
  header.expandIcon:SetPoint("LEFT", header, "LEFT", 6, 0)
  header.expandIcon:SetWidth(14)
  header.expandIcon:SetJustifyH("CENTER")
  header.expandIcon:SetText("|cff33ffcc>|r")

  header.text = header:CreateFontString(nil, "ARTWORK")
  S.SetFont(header.text, 11)
  header.text:SetPoint("LEFT", header, "LEFT", 22, 0)
  header.text:SetPoint("RIGHT", header, "RIGHT", -6, 0)
  header.text:SetJustifyH("LEFT")
  header.text:SetTextColor(1, 1, 1, 1)

  header:SetScript("OnEnter", function()
    header:SetBackdropBorderColor(S.COLORS.highlight[1], S.COLORS.highlight[2], S.COLORS.highlight[3], 1)
  end)
  header:SetScript("OnLeave", function()
    header:SetBackdropBorderColor(S.COLORS.border[1], S.COLORS.border[2], S.COLORS.border[3], 1)
  end)

  return header
end

local function CreateItemRow(parent, id)
  local S = GuildKPInfo.Style

  local row = CreateFrame("Frame", "GKPIRaidItem" .. id, parent)
  row:SetHeight(ITEM_ROW_HEIGHT)
  row:SetPoint("LEFT", parent, "LEFT", 24, 0)
  row:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
  row:Hide()

  row.itemText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.itemText, 10)
  row.itemText:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.itemText:SetPoint("RIGHT", row, "RIGHT", -160, 0)
  row.itemText:SetJustifyH("LEFT")

  row.playerText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.playerText, 10)
  row.playerText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
  row.playerText:SetWidth(86)
  row.playerText:SetJustifyH("LEFT")

  row.dkpText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.dkpText, 10)
  row.dkpText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  row.dkpText:SetWidth(64)
  row.dkpText:SetJustifyH("RIGHT")
  row.dkpText:SetTextColor(1, 0.82, 0, 1)

  return row
end

function R.RefreshList()
  if not R.frame or not R.frame:IsShown() then return end

  local S = GuildKPInfo.Style
  local listArea = R.listArea
  if not listArea then return end

  local db = GuildKPInfoDB
  if not db or not db.raids then return end

  for i = 1, table.getn(R.raidFrames) do
    local rf = R.raidFrames[i]
    rf.header:Hide()
    for j = 1, table.getn(rf.itemRows) do
      rf.itemRows[j]:Hide()
    end
  end

  local y = 0
  local totalItems = 0
  local totalDKP = 0

  for i = table.getn(db.raids), 1, -1 do
    local raid = db.raids[i]
    local numItems = CountRaidItems(raid)
    local isExpanded = R.expandedRaids[i]

    if not R.raidFrames[i] then
      R.raidFrames[i] = {
        header = CreateRaidHeader(listArea, i),
        itemRows = {}
      }
    end

    local rf = R.raidFrames[i]
    local header = rf.header

    header:SetPoint("TOP", listArea, "TOP", 0, -y)
    header.text:SetText(raid.date .. " - " .. raid.zone .. " (" .. numItems .. " items)")
    header.expandIcon:SetText(isExpanded and "|cff33ffccv|r" or "|cff33ffcc>|r")
    header.raidIndex = i
    header:SetScript("OnClick", function()
      local idx = this.raidIndex
      R.expandedRaids[idx] = not R.expandedRaids[idx]
      R.RefreshList()
    end)
    header:Show()
    y = y + RAID_HEADER_HEIGHT

    if isExpanded and raid.items then
      for j = 1, numItems do
        local item = raid.items[j]
        if not rf.itemRows[j] then
          rf.itemRows[j] = CreateItemRow(listArea, i .. "_" .. j)
        end
        local itemRow = rf.itemRows[j]
        itemRow:SetPoint("TOP", listArea, "TOP", 0, -y)

        local _, _, _, qualityHex = S.GetItemQualityColor(item.quality)
        itemRow.itemText:SetText(qualityHex .. "[" .. item.itemName .. "]|r")
        itemRow.playerText:SetText("|cffffffff-> " .. item.player .. "|r")
        itemRow.dkpText:SetText(tostring(item.dkp) .. " DKP")

        itemRow:Show()
        y = y + ITEM_ROW_HEIGHT

        totalItems = totalItems + 1
        totalDKP = totalDKP + (item.dkp or 0)
      end
    end
  end

  if R.statusText then
    local totalRaids = table.getn(db.raids)
    R.statusText:SetText(
      totalRaids .. " raids | " .. totalItems .. " items | Total gastado: " .. totalDKP .. " DKP"
    )
  end

  if R.scrollSlider and R.scrollSlider.UpdateRange then
    R.scrollSlider.UpdateRange(y)
  end
end

function R.ExportLog()
  local db = GuildKPInfoDB
  if not db or not db.raids or table.getn(db.raids) == 0 then return end

  local lines = {}
  for i = 1, table.getn(db.raids) do
    local raid = db.raids[i]
    lines[table.getn(lines) + 1] = "Raid: " .. raid.zone .. " (" .. raid.date .. ")"
    if raid.items then
      for j = 1, table.getn(raid.items) do
        local item = raid.items[j]
        lines[table.getn(lines) + 1] = "- " .. item.itemName .. " -> " .. item.player .. " (" .. item.dkp .. " DKP)"
      end
    end
    lines[table.getn(lines) + 1] = "---"
  end

  local exportText = ""
  for i = 1, table.getn(lines) do
    if i > 1 then exportText = exportText .. "\n" end
    exportText = exportText .. lines[i]
  end

  StaticPopupDialogs["GKPI_EXPORT"] = {
    text = "Ctrl+C to copy:",
    button1 = OKAY,
    hasEditBox = 1,
    hasWideEditBox = 1,
    OnShow = function()
      local editBox = getglobal(this:GetName() .. "WideEditBox")
      if editBox then
        editBox:SetText(exportText)
        editBox:SetFocus()
        editBox:HighlightText()
      end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
  }
  StaticPopup_Show("GKPI_EXPORT")
end

function R.CreateTab(parent)
  local S = GuildKPInfo.Style

  local frame = CreateFrame("Frame", "GKPIRaidsFrame", parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
  frame:Hide()
  R.frame = frame

  local exportBtn = CreateFrame("Button", "GKPIExportBtn", frame, "UIPanelButtonTemplate")
  exportBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -4)
  exportBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -4)
  exportBtn:SetHeight(22)
  exportBtn:SetText("Exportar Log")
  S.SkinButton(exportBtn)
  exportBtn:SetScript("OnClick", function()
    R.ExportLog()
  end)

  local listArea = CreateFrame("Frame", "GKPIRaidsList", frame)
  listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -TOOLBAR_HEIGHT)
  listArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, STATUS_HEIGHT + 4)
  R.listArea = listArea

  R.scrollSlider = S.SkinScrollBar(nil, listArea)

  local statusBar = CreateFrame("Frame", "GKPIRaidsStatus", frame)
  statusBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)
  statusBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
  statusBar:SetHeight(STATUS_HEIGHT)
  S.CreateBackdrop(statusBar, nil, true)

  local statusText = statusBar:CreateFontString(nil, "OVERLAY")
  S.SetFont(statusText, 10)
  statusText:SetPoint("LEFT", statusBar, "LEFT", 6, 0)
  statusText:SetPoint("RIGHT", statusBar, "RIGHT", -6, 0)
  statusText:SetJustifyH("LEFT")
  statusText:SetTextColor(S.COLORS.text_secondary[1], S.COLORS.text_secondary[2], S.COLORS.text_secondary[3], 1)
  R.statusText = statusText

  return frame
end
