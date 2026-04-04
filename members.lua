GuildKPInfo = GuildKPInfo or {}

local M = {}
GuildKPInfo.Members = M

M.frame = nil
M.list = {}
M.searchText = ""
M.classFilter = "ALL"
M.sortColumn = "dkp"
M.sortDirection = "desc"
M.rows = {}
M.scrollOffset = 0
M.headerButtons = {}

local ROW_HEIGHT = 20
local HEADER_HEIGHT = 20
local TOOLBAR_HEIGHT = 30
local STATUS_HEIGHT = 22

local COLUMNS = {
  { key = "class",  label = "Class",  width = 50 },
  { key = "name",   label = "Name",   width = 190 },
  { key = "dkp",    label = "DKP",    width = 80 },
  { key = "online", label = "Status", width = 70 },
}

local COL_OFFSETS = { 4, 54, 244, 324 }

local function CreateMemberRow(parent, id)
  local S = GuildKPInfo.Style
  local row = CreateFrame("Button", "GKPIMembersRow" .. id, parent)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("LEFT", parent, "LEFT", 4, 0)
  row:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
  row:EnableMouse(true)
  row:Hide()

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints(row)
  row.bg:SetTexture(1, 1, 1, 0)

  row.classIcon = row:CreateTexture(nil, "ARTWORK")
  row.classIcon:SetWidth(16)
  row.classIcon:SetHeight(16)
  row.classIcon:SetPoint("CENTER", row, "LEFT", COL_OFFSETS[1] + 23, 0)
  row.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  row.classText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.classText, 10)
  row.classText:SetPoint("CENTER", row, "LEFT", COL_OFFSETS[1] + 23, 0)

  row.nameText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.nameText, 11)
  row.nameText:SetPoint("LEFT", row, "LEFT", COL_OFFSETS[2], 0)
  row.nameText:SetPoint("RIGHT", row, "LEFT", COL_OFFSETS[2] + COLUMNS[2].width, 0)
  row.nameText:SetJustifyH("LEFT")

  row.dkpText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.dkpText, 11)
  row.dkpText:SetPoint("LEFT", row, "LEFT", COL_OFFSETS[3], 0)
  row.dkpText:SetPoint("RIGHT", row, "LEFT", COL_OFFSETS[3] + COLUMNS[3].width, 0)
  row.dkpText:SetJustifyH("RIGHT")

  row.statusText = row:CreateFontString(nil, "ARTWORK")
  S.SetFont(row.statusText, 10)
  row.statusText:SetPoint("LEFT", row, "LEFT", COL_OFFSETS[4], 0)
  row.statusText:SetPoint("RIGHT", row, "LEFT", COL_OFFSETS[4] + COLUMNS[4].width, 0)
  row.statusText:SetJustifyH("CENTER")

  row:SetScript("OnEnter", function()
    if this.memberData then
      local r, g, b = S.GetClassColor(this.memberData.class)
      this.bg:SetTexture(r, g, b, 0.1)
    end
  end)
  row:SetScript("OnLeave", function()
    this.bg:SetTexture(1, 1, 1, 0)
  end)

  return row
end

local function CreateColumnHeaders(parent)
  local S = GuildKPInfo.Style
M.headerButtons = {}
M.onlineOnly = false

  for i = 1, table.getn(COLUMNS) do
    local col = COLUMNS[i]
    local btn = CreateFrame("Button", "GKPIHeader" .. col.key, parent)
    btn:SetHeight(HEADER_HEIGHT)
    btn:SetWidth(col.width)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", COL_OFFSETS[i], -TOOLBAR_HEIGHT - 4)

    S.CreateBackdrop(btn, nil, true)

    btn.label = btn:CreateFontString(nil, "OVERLAY")
    S.SetFont(btn.label, 11)
    btn.label:SetPoint("LEFT", btn, "LEFT", 4, 0)
    btn.label:SetPoint("RIGHT", btn, "RIGHT", -14, 0)
    btn.label:SetJustifyH("LEFT")
    btn.label:SetTextColor(S.COLORS.text_secondary[1], S.COLORS.text_secondary[2], S.COLORS.text_secondary[3], 1)
    btn.label:SetText(col.label)

    btn.arrow = btn:CreateFontString(nil, "OVERLAY")
    S.SetFont(btn.arrow, 10)
    btn.arrow:SetPoint("RIGHT", btn, "RIGHT", -3, 0)
    btn.arrow:SetText("")

    btn.colKey = col.key
    btn:SetScript("OnClick", function()
      if M.sortColumn == this.colKey then
        M.sortDirection = M.sortDirection == "desc" and "asc" or "desc"
      else
        M.sortColumn = this.colKey
        M.sortDirection = "desc"
      end
      if GuildKPInfoDB then
        GuildKPInfoDB.sortColumn = M.sortColumn
        GuildKPInfoDB.sortDirection = M.sortDirection
      end
      M.RefreshList()
    end)

    M.headerButtons[col.key] = btn
  end
end

local function InitClassDropdown(dropdown)
  local S = GuildKPInfo.Style

  UIDropDownMenu_Initialize(dropdown, function()
    local info = {}
    info.text = "All"
    info.checked = (M.classFilter == "ALL")
    info.func = function()
      M.classFilter = "ALL"
      UIDropDownMenu_SetText("All", dropdown)
      CloseDropDownMenus()
      M.RefreshList()
    end
    UIDropDownMenu_AddButton(info)

    for i = 1, table.getn(S.CLASS_LIST) do
      local classToken = S.CLASS_LIST[i]
      local r, g, b = S.GetClassColor(classToken)
      local colorHex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)

      info = {}
      info.text = colorHex .. (S.CLASS_ABBR[classToken] or classToken) .. "|r"
      info.checked = (M.classFilter == classToken)
      info.func = function()
        M.classFilter = classToken
        UIDropDownMenu_SetText(colorHex .. (S.CLASS_ABBR[classToken] or classToken) .. "|r", dropdown)
        CloseDropDownMenus()
        M.RefreshList()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
end

function M.RefreshList()
  if not M.frame or not M.frame:IsShown() then return end

  local S = GuildKPInfo.Style
  local Core = GuildKPInfo.Core
  local listArea = M.listArea
  if not listArea then return end

  local members = Core.GetFilteredMembers(M.searchText, M.classFilter, M.onlineOnly)
  Core.SortMembers(members, M.sortColumn, M.sortDirection)
  M.list = members

  local areaHeight = listArea:GetHeight() or 300
  local maxVisible = math.floor(areaHeight / ROW_HEIGHT)
  if maxVisible < 1 then maxVisible = 1 end

  for i = 1, table.getn(M.rows) do
    M.rows[i]:Hide()
  end

  local totalDKP = 0
  local onlineCount = 0
  local count = 0

  local startIdx = math.floor(M.scrollOffset / ROW_HEIGHT) + 1
  if startIdx < 1 then startIdx = 1 end

  for i = startIdx, math.min(table.getn(members), startIdx + maxVisible - 1) do
    local m = members[i]
    local rowIdx = i - startIdx + 1
    local row = M.rows[rowIdx]
    if not row then
      row = CreateMemberRow(listArea, rowIdx)
      M.rows[rowIdx] = row
    end

    row:SetPoint("TOP", listArea, "TOP", 0, -(rowIdx - 1) * ROW_HEIGHT)

    if S.CLASS_ICONS[m.class] then
      row.classIcon:SetTexture(S.CLASS_ICONS[m.class])
      row.classIcon:Show()
      row.classText:Hide()
    else
      row.classIcon:Hide()
      row.classText:Show()
      row.classText:SetText(S.CLASS_ABBR[m.class] or "?")
      local cr, cg, cb = S.GetClassColor(m.class)
      row.classText:SetTextColor(cr, cg, cb, 1)
    end

    local r, g, b, hex = S.GetClassColor(m.class)
    row.nameText:SetText(hex .. m.name .. "|r")
    row.dkpText:SetText(tostring(m.dkp))

    if m.online then
      row.statusText:SetText("|cff00ff00Online|r")
      onlineCount = onlineCount + 1
    else
      row.statusText:SetText("")
    end

    row.memberData = m
    row:Show()
    count = count + 1
    totalDKP = totalDKP + m.dkp
  end

  if M.scrollSlider then
    local contentHeight = table.getn(members) * ROW_HEIGHT
    if M.scrollSlider.UpdateRange then
      M.scrollSlider.UpdateRange(contentHeight)
    end
  end

  if M.statusText then
    M.statusText:SetText(
      table.getn(members) .. " members | Total DKP: " .. totalDKP .. " | Online: " .. onlineCount
    )
  end

  M.UpdateArrows()
end

function M.UpdateArrows()
  local S = GuildKPInfo.Style
  for key, btn in pairs(M.headerButtons) do
    if key == M.sortColumn then
      if M.sortDirection == "desc" then
        btn.arrow:SetText("|cff33ffccv|r")
      else
        btn.arrow:SetText("|cff33ffcc^|r")
      end
      btn.label:SetTextColor(S.COLORS.tab_active[1], S.COLORS.tab_active[2], S.COLORS.tab_active[3], 1)
    else
      btn.arrow:SetText("")
      btn.label:SetTextColor(S.COLORS.text_secondary[1], S.COLORS.text_secondary[2], S.COLORS.text_secondary[3], 1)
    end
  end
end

function M.CreateTab(parent)
  local S = GuildKPInfo.Style

  local frame = CreateFrame("Frame", "GKPIMembersFrame", parent)
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
  frame:Hide()
  M.frame = frame

  local searchBox = CreateFrame("EditBox", "GKPISearchBox", frame)
  searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
  searchBox:SetPoint("TOPRIGHT", frame, "TOP", -35, -6)
  searchBox:SetHeight(20)
  S.SkinInputBox(searchBox)
  searchBox:SetAutoFocus(false)
  searchBox:SetText("")

  local placeholder = searchBox:CreateFontString(nil, "OVERLAY")
  S.SetFont(placeholder, 11)
  placeholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
  placeholder:SetPoint("RIGHT", searchBox, "RIGHT", -6, 0)
  placeholder:SetJustifyH("LEFT")
  placeholder:SetTextColor(0.5, 0.5, 0.5, 1)
  placeholder:SetText("Search member...")

  searchBox:SetScript("OnTextChanged", function()
    local text = this:GetText()
    if text and strlen(text) > 0 then
      placeholder:Hide()
    else
      placeholder:Show()
    end
    M.searchText = text or ""
    M.RefreshList()
  end)
  searchBox:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
  searchBox:SetScript("OnEditFocusLost", function()
    if not this:GetText() or strlen(this:GetText()) == 0 then
      placeholder:Show()
    end
  end)

  local scanBtn = CreateFrame("Button", "GKPIScanBtn", frame, "UIPanelButtonTemplate")
  scanBtn:SetPoint("LEFT", searchBox, "RIGHT", 4, 0)
  scanBtn:SetPoint("TOP", frame, "TOP", 0, -5)
  scanBtn:SetWidth(24)
  scanBtn:SetHeight(20)
  scanBtn:SetText("R")
  S.SkinButton(scanBtn, 0.3, 1.0, 0.8)
  scanBtn:SetScript("OnClick", function()
    GuildRoster()
    GuildKPInfo.Core.RefreshGuildData()
    M.RefreshList()
  end)

  local classDropdown = CreateFrame("Frame", "GKPIClassFilter", frame, "UIDropDownMenuTemplate")
  classDropdown:SetPoint("TOPLEFT", frame, "TOP", 10, -2)
  classDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -130, -2)
  UIDropDownMenu_SetWidth(120, classDropdown)
  UIDropDownMenu_SetText("All", classDropdown)
  InitClassDropdown(classDropdown)
  M.classDropdown = classDropdown

  local onlineBtn = CreateFrame("Button", "GKPIOnlineFilter", frame, "UIPanelButtonTemplate")
  onlineBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -4)
  onlineBtn:SetWidth(60)
  onlineBtn:SetHeight(20)
  S.SkinButton(onlineBtn, 0.3, 1.0, 0.8)

  local function UpdateOnlineBtnText()
    if M.onlineOnly then
      onlineBtn:SetText("Online")
    else
      onlineBtn:SetText("All")
    end
  end
  UpdateOnlineBtnText()

  onlineBtn:SetScript("OnClick", function()
    M.onlineOnly = not M.onlineOnly
    if GuildKPInfoDB then
      GuildKPInfoDB.onlineOnly = M.onlineOnly
    end
    UpdateOnlineBtnText()
    M.RefreshList()
  end)

  CreateColumnHeaders(frame)

  local listArea = CreateFrame("Frame", "GKPIMembersList", frame)
  listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -TOOLBAR_HEIGHT - HEADER_HEIGHT - 8)
  listArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, STATUS_HEIGHT + 4)
  M.listArea = listArea

  listArea.scrollCallback = function(offset)
    M.scrollOffset = offset
    M.RefreshList()
  end

  local statusBar = CreateFrame("Frame", "GKPIMembersStatus", frame)
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
  M.statusText = statusText

  M.scrollSlider = S.SkinScrollBar(nil, listArea)

  return frame
end

function M.RestoreSettings()
  if GuildKPInfoDB then
    M.sortColumn = GuildKPInfoDB.sortColumn or "dkp"
    M.sortDirection = GuildKPInfoDB.sortDirection or "desc"
    M.classFilter = GuildKPInfoDB.classFilter or "ALL"
    M.onlineOnly = GuildKPInfoDB.onlineOnly or false
  end
end
