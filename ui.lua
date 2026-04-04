GuildKPInfo = GuildKPInfo or {}

local UI = {}
GuildKPInfo.UI = UI

UI.mainFrame = nil
UI.minimapButton = nil
UI.tabs = {}
UI.tabPanels = {}
UI.activeTab = 1

local MAIN_WIDTH = 500
local MAIN_HEIGHT = 450
local TITLE_HEIGHT = 25
local TAB_HEIGHT = 22
local MINIMAP_RADIUS = 80
local MINIMAP_BUTTON_SIZE = 33

local function UpdateMinimapPosition()
  if not UI.minimapButton then return end
  local angle = (GuildKPInfoDB and GuildKPInfoDB.minimapAngle) or -45
  local rad = angle * math.pi / 180
  local x = math.cos(rad) * MINIMAP_RADIUS
  local y = math.sin(rad) * MINIMAP_RADIUS
  UI.minimapButton:ClearAllPoints()
  UI.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateTitleBar(parent)
  local S = GuildKPInfo.Style

  local title = CreateFrame("Frame", "GKPITitleBar", parent)
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
  title:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)
  title:SetHeight(TITLE_HEIGHT)
  S.CreateBackdrop(title, nil, true)

  title:SetMovable(true)
  title:EnableMouse(true)
  title:RegisterForDrag("LeftButton")
  title:SetScript("OnDragStart", function() parent:StartMoving() end)
  title:SetScript("OnDragStop", function() parent:StopMovingOrSizing() end)

  local text = title:CreateFontString(nil, "OVERLAY")
  S.SetFont(text, 13)
  text:SetPoint("LEFT", title, "LEFT", 8, 0)
  text:SetText("|cff33ffccGuild|cffffffffKPInfo")

  local closeBtn = CreateFrame("Button", "GKPICloseBtn", title)
  S.SkinCloseButton(closeBtn, title, -3, -3)
  closeBtn:SetScript("OnClick", function() parent:Hide() end)

  return title
end

local function CreateTabButtons(parent)
  local S = GuildKPInfo.Style
  local tabNames = { "Members", "Raid Log" }

  local container = CreateFrame("Frame", "GKPITabContainer", parent)
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -TITLE_HEIGHT - 6)
  container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -TITLE_HEIGHT - 6)
  container:SetHeight(TAB_HEIGHT)

  UI.tabs = {}

  for i = 1, table.getn(tabNames) do
    local tab = CreateFrame("Button", "GKPITab" .. i, container, "UIPanelButtonTemplate")
    tab:SetHeight(TAB_HEIGHT)
    tab:SetText(tabNames[i])
    S.SkinTab(tab)

    if i == 1 then
      tab:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    else
      tab:SetPoint("TOPLEFT", UI.tabs[i - 1], "TOPRIGHT", 2, 0)
    end

    local tabWidth = 100
    tab:SetWidth(tabWidth)

    local btnText = tab:GetFontString()
    if btnText then
      S.SetFont(btnText, 11)
    end

    tab:SetID(i)
    tab:SetScript("OnClick", function()
      UI.SetActiveTab(this:GetID())
    end)

    UI.tabs[i] = tab
  end

  return container
end

local function CreateContentArea(parent)
  local S = GuildKPInfo.Style
  local content = CreateFrame("Frame", "GKPIContent", parent)
  content:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -TITLE_HEIGHT - TAB_HEIGHT - 10)
  content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
  S.CreateBackdrop(content)

  return content
end

function UI.SetActiveTab(index)
  UI.activeTab = index
  local S = GuildKPInfo.Style

  for i = 1, table.getn(UI.tabs) do
    local tab = UI.tabs[i]
    local btnText = tab:GetFontString()
    if i == index then
      if btnText then
        btnText:SetTextColor(S.COLORS.tab_active[1], S.COLORS.tab_active[2], S.COLORS.tab_active[3], 1)
      end
      tab:SetBackdropBorderColor(S.COLORS.tab_active[1], S.COLORS.tab_active[2], S.COLORS.tab_active[3], 1)
    else
      if btnText then
        btnText:SetTextColor(S.COLORS.tab_inactive[1], S.COLORS.tab_inactive[2], S.COLORS.tab_inactive[3], 1)
      end
      tab:SetBackdropBorderColor(S.COLORS.border[1], S.COLORS.border[2], S.COLORS.border[3], 1)
    end
  end

  for i = 1, table.getn(UI.tabPanels) do
    if i == index then
      UI.tabPanels[i]:Show()
    else
      UI.tabPanels[i]:Hide()
    end
  end

  if index == 1 then
    GuildKPInfo.Members.RefreshList()
  elseif index == 2 then
    GuildKPInfo.Raids.RefreshList()
  end
end

function UI.CreateMinimapButton()
  if UI.minimapButton then return end

  local btn = CreateFrame("Button", "GKPIMinimapButton", Minimap)
  btn:SetWidth(MINIMAP_BUTTON_SIZE)
  btn:SetHeight(MINIMAP_BUTTON_SIZE)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:EnableMouse(true)
  btn:RegisterForClicks("LeftButtonUp")
  btn:RegisterForDrag("LeftButton")

  local texture = btn:CreateTexture(nil, "BACKGROUND")
  texture:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  texture:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
  texture:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
  texture:SetVertexColor(0.85, 0.65, 0.13, 1)

  local border = btn:CreateTexture(nil, "BORDER")
  border:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  border:SetAllPoints(btn)
  border:SetVertexColor(0.6, 0.45, 0.05, 1)

  local inner = btn:CreateTexture(nil, "ARTWORK")
  inner:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  inner:SetPoint("TOPLEFT", texture, "TOPLEFT", 2, -2)
  inner:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", -2, 2)
  inner:SetVertexColor(1.0, 0.82, 0.25, 1)

  local letter = btn:CreateFontString(nil, "OVERLAY")
  letter:SetPoint("CENTER", btn, "CENTER", 0, 0)
  letter:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  letter:SetText("K")
  letter:SetTextColor(0.2, 0.1, 0.0, 1)

  btn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("|cff33ffccGuild|cffffffffKPInfo", 1, 1, 1)
    GameTooltip:AddLine("Click: Open / Close", 0.6, 0.6, 0.6, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  btn:SetScript("OnClick", function()
    UI.Toggle()
  end)

  btn:SetScript("OnDragStart", function()
    this:StartMoving()
    this.isDragging = true
  end)
  btn:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    this.isDragging = false

    local mx, my = Minimap:GetCenter()
    local bx, by = this:GetCenter()
    local angle = math.atan2(by - my, bx - mx) * 180 / math.pi

    if GuildKPInfoDB then
      GuildKPInfoDB.minimapAngle = angle
    end
    UpdateMinimapPosition()
  end)

  UI.minimapButton = btn
  UpdateMinimapPosition()
end

function UI.CreateMainWindow()
  if UI.mainFrame then return end

  local S = GuildKPInfo.Style

  local frame = CreateFrame("Frame", "GKPIMainFrame", UIParent)
  frame:SetWidth(MAIN_WIDTH)
  frame:SetHeight(MAIN_HEIGHT)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)
  frame:Hide()

  S.CreateBackdrop(frame)

  CreateTitleBar(frame)
  CreateTabButtons(frame)

  local content = CreateContentArea(frame)

  local membersFrame = GuildKPInfo.Members.CreateTab(content)
  membersFrame:SetAllPoints(content)
  UI.tabPanels[1] = membersFrame

  local raidsFrame = GuildKPInfo.Raids.CreateTab(content)
  raidsFrame:SetAllPoints(content)
  UI.tabPanels[2] = raidsFrame

  UI.mainFrame = frame

  UI.SetActiveTab(1)
end

function UI.Toggle()
  if not UI.mainFrame then
    UI.CreateMainWindow()
    GuildRoster()
  end

  if UI.mainFrame:IsShown() then
    UI.mainFrame:Hide()
  else
    UI.mainFrame:Show()
    GuildRoster()
    if UI.activeTab == 1 then
      GuildKPInfo.Members.RefreshList()
    elseif UI.activeTab == 2 then
      GuildKPInfo.Raids.RefreshList()
    end
  end
end
