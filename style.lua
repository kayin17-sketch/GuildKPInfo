GuildKPInfo = GuildKPInfo or {}

local S = {}
GuildKPInfo.Style = S

S.COLORS = {
  bg             = { 0.1, 0.1, 0.1, 0.85 },
  border         = { 0.3, 0.3, 0.3, 1.0 },
  highlight      = { 0.3, 1.0, 0.8, 1.0 },
  close          = { 1.0, 0.25, 0.25, 1.0 },
  text           = { 1.0, 1.0, 1.0, 1.0 },
  text_secondary = { 0.6, 0.6, 0.6, 1.0 },
  tab_active     = { 0.2, 1.0, 0.8, 1.0 },
  tab_inactive   = { 0.5, 0.5, 0.5, 1.0 },
}

S.CLASS_COLORS = {
  WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
  MAGE    = { r = 0.41, g = 0.80, b = 0.94 },
  ROGUE   = { r = 1.00, g = 0.96, b = 0.41 },
  DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
  HUNTER  = { r = 0.67, g = 0.83, b = 0.45 },
  SHAMAN  = { r = 0.14, g = 0.35, b = 1.00 },
  PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
  WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
  PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
}

S.CLASS_ICONS = {
  WARRIOR = "Interface\\Icons\\INV_Sword_27",
  MAGE    = "Interface\\Icons\\INV_Staff_13",
  ROGUE   = "Interface\\Icons\\INV_ThrowingKnife_04",
  DRUID   = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
  HUNTER  = "Interface\\Icons\\INV_Weapon_Bow_07",
  SHAMAN  = "Interface\\Icons\\INV_Jewelry_Talisman_04",
  PRIEST  = "Interface\\Icons\\INV_Staff_30",
  WARLOCK = "Interface\\Icons\\Spell_Shadow_Cripple",
  PALADIN = "Interface\\Icons\\INV_Hammer_01",
}

S.CLASS_ABBR = {
  WARRIOR = "War",
  MAGE    = "Mag",
  ROGUE   = "Rog",
  DRUID   = "Dru",
  HUNTER  = "Hun",
  SHAMAN  = "Sha",
  PRIEST  = "Pri",
  WARLOCK = "Wlk",
  PALADIN = "Pal",
}

S.CLASS_LIST = {
  "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST",
  "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"
}

S.QUALITY_COLORS = {
  [0] = { r = 0.616, g = 0.616, b = 0.616, hex = "|cff9d9d9d" },
  [1] = { r = 1.000, g = 1.000, b = 1.000, hex = "|cffffffff" },
  [2] = { r = 0.118, g = 1.000, b = 0.000, hex = "|cff1eff00" },
  [3] = { r = 0.000, g = 0.439, b = 0.867, hex = "|cff0070dd" },
  [4] = { r = 0.639, g = 0.208, b = 0.933, hex = "|cffa335ee" },
  [5] = { r = 1.000, g = 0.502, b = 0.000, hex = "|cffff8000" },
}

local BACKDROP = {
  bgFile = "Interface\\BUTTONS\\WHITE8X8",
  tile = false, tileSize = 0,
  edgeFile = "Interface\\BUTTONS\\WHITE8X8",
  edgeSize = 1,
  insets = { left = -1, right = -1, top = -1, bottom = -1 }
}

local BACKDROP_THIN = {
  bgFile = "Interface\\BUTTONS\\WHITE8X8",
  tile = false, tileSize = 0,
  edgeFile = "Interface\\BUTTONS\\WHITE8X8",
  edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

S.pfUILoaded = false
S.fontPath = "Fonts\\FRIZQT__.TTF"
S.fontSize = 12

function S.Initialize()
  if pfUI and pfUI.api and pfUI.font_default then
    S.pfUILoaded = true
    S.fontPath = pfUI.font_default
    if pfUI_config and pfUI_config.global and pfUI_config.global.font_size then
      S.fontSize = tonumber(pfUI_config.global.font_size) or 12
    end
  end
end

function S.CreateBackdrop(f, inset, legacy, transp)
  if not f then return end

  if S.pfUILoaded and pfUI.api and pfUI.api.CreateBackdrop then
    pfUI.api.CreateBackdrop(f, inset, legacy, transp)
    return
  end

  local bd = (not inset or inset <= 1) and BACKDROP_THIN or BACKDROP
  local c = S.COLORS

  if legacy then
    f:SetBackdrop(bd)
    f:SetBackdropColor(c.bg[1], c.bg[2], c.bg[3], transp or c.bg[4])
    f:SetBackdropBorderColor(c.border[1], c.border[2], c.border[3], c.border[4])
  else
    if f:GetBackdrop() then f:SetBackdrop(nil) end
    if not f.backdrop then
      local b = CreateFrame("Frame", nil, f)
      local level = f:GetFrameLevel()
      b:SetFrameLevel(level > 0 and level - 1 or 0)
      f.backdrop = b
    end
    f.backdrop:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
    f.backdrop:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
    f.backdrop:SetBackdrop(bd)
    f.backdrop:SetBackdropColor(c.bg[1], c.bg[2], c.bg[3], transp or c.bg[4])
    f.backdrop:SetBackdropBorderColor(c.border[1], c.border[2], c.border[3], c.border[4])
  end
end

function S.SkinButton(button, cr, cg, cb)
  local b = button
  if type(b) == "string" then b = getglobal(b) end
  if not b then return end

  if not cr or not cg or not cb then
    local _, class = UnitClass("player")
    if class and S.CLASS_COLORS[class] then
      cr = S.CLASS_COLORS[class].r
      cg = S.CLASS_COLORS[class].g
      cb = S.CLASS_COLORS[class].b
    else
      cr, cg, cb = 0.3, 1.0, 0.8
    end
  end

  S.CreateBackdrop(b, nil, true)
  b:SetNormalTexture("")
  b:SetHighlightTexture("")
  b:SetPushedTexture("")
  b:SetDisabledTexture("")

  if b.SetCheckedTexture and b:GetCheckedTexture() then
    b:GetCheckedTexture():SetTexture(cr, cg, cb, 0.25)
  end

  local origBorderR, origBorderG, origBorderB, origBorderA = S.COLORS.border[1], S.COLORS.border[2], S.COLORS.border[3], S.COLORS.border[4]

  b:SetScript("OnEnter", function()
    if this.locked then return end
    local bd = this.backdrop or this
    bd:SetBackdropBorderColor(cr, cg, cb, 1)
  end)
  b:SetScript("OnLeave", function()
    if this.locked then return end
    local bd = this.backdrop or this
    bd:SetBackdropBorderColor(origBorderR, origBorderG, origBorderB, origBorderA)
  end)

  S.SetFont(b)
end

function S.SkinTab(tab)
  tab:SetHeight(22)
  for _, v in ipairs({tab:GetRegions()}) do
    if v.SetTexture then v:SetTexture(nil) end
  end
  S.CreateBackdrop(tab, nil, true)
end

function S.SkinCloseButton(button, parent, ox, oy)
  if not button then return end
  S.SkinButton(button, 1, 0.25, 0.25)
  button:SetWidth(15)
  button:SetHeight(15)

  if parent then
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", ox or -2, oy or -2)
  end

  if not button.xText then
    button.xText = button:CreateFontString(nil, "ARTWORK")
  end
  button.xText:SetAllPoints(button)
  button.xText:SetFont(S.fontPath, 12, "OUTLINE")
  button.xText:SetText("X")
  button.xText:SetTextColor(1, 0.25, 0.25, 1)
end

function S.SkinInputBox(editbox)
  S.CreateBackdrop(editbox, nil, true)
  editbox:SetTextInsets(5, 5, 4, 4)
  editbox:SetAutoFocus(false)
  editbox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  S.SetFont(editbox)
end

function S.SkinScrollBar(_, parent)
  local slider = CreateFrame("Slider", nil, parent)
  slider:SetOrientation("VERTICAL")
  slider:SetPoint("TOPLEFT", parent, "TOPRIGHT", -7, 0)
  slider:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
  slider:SetThumbTexture("Interface\\BUTTONS\\WHITE8X8")
  slider:SetMinMaxValues(0, 0)
  slider:SetValue(0)

  local thumb = slider:GetThumbTexture()
  thumb:SetWidth(6)
  thumb:SetHeight(30)
  thumb:SetTexture(0.3, 1.0, 0.8, 0.5)

  parent.scrollOffset = 0
  parent.scrollMax = 0

  slider:SetScript("OnValueChanged", function()
    parent.scrollOffset = this:GetValue()
    if parent.scrollCallback then
      parent.scrollCallback(parent.scrollOffset)
    end
  end)

  parent:EnableMouseWheel(1)
  parent:SetScript("OnMouseWheel", function()
    local cur = parent.scrollOffset or 0
    local maxScroll = parent.scrollMax or 0
    local new = cur - arg1 * 20
    if new > maxScroll then new = maxScroll end
    if new < 0 then new = 0 end
    parent.scrollOffset = new
    slider:SetValue(new)
    if parent.scrollCallback then
      parent.scrollCallback(new)
    end
  end)

  slider.UpdateRange = function(contentHeight)
    local visibleHeight = parent:GetHeight() or 300
    local maxScroll = math.max(0, contentHeight - visibleHeight)
    parent.scrollMax = maxScroll
    slider:SetMinMaxValues(0, maxScroll)
    if parent.scrollOffset > maxScroll then
      parent.scrollOffset = maxScroll
      slider:SetValue(maxScroll)
    end
    local total = visibleHeight + contentHeight
    if total <= 0 or visibleHeight >= contentHeight then
      slider:Hide()
    else
      slider:Show()
      local ratio = visibleHeight / total
      slider:GetThumbTexture():SetHeight(math.max(20, math.floor(visibleHeight * ratio)))
    end
  end

  return slider
end

function S.GetClassColor(class)
  if class and S.CLASS_COLORS[class] then
    local c = S.CLASS_COLORS[class]
    return c.r, c.g, c.b, string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
  end
  return 0.6, 0.6, 0.6, "|cff999999"
end

function S.GetItemQualityColor(quality)
  quality = quality or 0
  if S.QUALITY_COLORS[quality] then
    local c = S.QUALITY_COLORS[quality]
    return c.r, c.g, c.b, c.hex
  end
  return 1, 1, 1, "|cffffffff"
end

function S.SetFont(obj, size)
  if not obj then return end
  local s = size or S.fontSize
  if obj.SetFont then
    obj:SetFont(S.fontPath, s, "OUTLINE")
  end
end

function S.CreateQuestionDialog(text, yesFunc, noFunc)
  if GKPIQuestionDialog and GKPIQuestionDialog:IsShown() then
    GKPIQuestionDialog:Hide()
    GKPIQuestionDialog = nil
    return
  end

  local d = CreateFrame("Frame", "GKPIQuestionDialog", UIParent)
  d:SetPoint("CENTER", 0, 0)
  d:SetFrameStrata("TOOLTIP")
  d:SetMovable(true)
  d:EnableMouse(true)
  d:RegisterForDrag("LeftButton")
  d:SetScript("OnDragStart", function() this:StartMoving() end)
  d:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  S.CreateBackdrop(d, nil, nil, 0.85)

  d.text = d:CreateFontString(nil, "LOW", "GameFontNormal")
  d.text:SetPoint("TOPLEFT", d, "TOPLEFT", 15, -15)
  d.text:SetPoint("TOPRIGHT", d, "TOPRIGHT", -15, -15)
  d.text:SetText(text)
  d.text:SetTextColor(1, 1, 1, 1)
  S.SetFont(d.text, 12)

  d.yes = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
  d.yes:SetWidth(100)
  d.yes:SetHeight(22)
  d.yes:SetText(YES)
  d.yes:SetPoint("TOPRIGHT", d.text, "BOTTOM", -5, -15)
  d.yes:SetScript("OnClick", function()
    if yesFunc then yesFunc() end
    this:GetParent():Hide()
  end)
  S.SkinButton(d.yes)

  d.no = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
  d.no:SetWidth(100)
  d.no:SetHeight(22)
  d.no:SetText(NO)
  d.no:SetPoint("TOPLEFT", d.text, "BOTTOM", 5, -15)
  d.no:SetScript("OnClick", function()
    if noFunc then noFunc() end
    this:GetParent():Hide()
  end)
  S.SkinButton(d.no)

  local close = CreateFrame("Button", nil, d)
  S.SkinCloseButton(close, d, -2, -2)
  close:SetScript("OnClick", function() this:GetParent():Hide() end)

  d:SetWidth(250)
  d:SetHeight(d.text:GetHeight() + 15 + 22 + 15 + 15)
end

function S.StripTextures(frame)
  if not frame then return end
  for _, v in ipairs({frame:GetRegions()}) do
    if v.SetTexture then v:SetTexture(nil) end
  end
end
