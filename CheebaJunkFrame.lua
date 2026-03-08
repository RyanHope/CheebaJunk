-- CheebaJunkFrame.lua
-- Visual UI for browsing and managing the vendor/delete item lists

local ROWS = 14
local ROW_HEIGHT = 20
local currentTab = 1  -- 1=vendor, 2=delete

-- Scan bags to build a name->texture cache
local function ScanBags()
  if not CheebaJunk_textures then return end
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local rawlink = GetContainerItemLink(bag, slot)
      if rawlink then
        local _, _, itemLink = string.find(rawlink, "(item:%d+:%d+:%d+:%d+)")
        if itemLink then
          local name = GetItemInfo(itemLink)
          -- GetContainerItemInfo returns texture as its first value (works in all versions)
          local texture = GetContainerItemInfo(bag, slot)
          if name and texture then
            CheebaJunk_textures[string.lower(name)] = texture
          end
        end
      end
    end
  end
end

local function GetItemTexture(name)
  if CheebaJunk_textures and CheebaJunk_textures[name] then
    return CheebaJunk_textures[name]
  end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetCurrentList()
  return currentTab == 1 and CheebaJunk_vendor or CheebaJunk_delete
end

function CheebaJunkFrame_Update()
  ScanBags()
  local list = GetCurrentList()
  local total = table.getn(list)

  FauxScrollFrame_Update(CheebaJunkListScroll, total, ROWS, ROW_HEIGHT)
  local offset = FauxScrollFrame_GetOffset(CheebaJunkListScroll)

  if total == 0 then
    CheebaJunkEmptyLabel:Show()
  else
    CheebaJunkEmptyLabel:Hide()
  end

  for i = 1, ROWS do
    local row = getglobal("CheebaJunkRow"..i)
    if row then
      local dataIdx = i + offset
      if dataIdx <= total then
        local name = list[dataIdx]
        local icon  = getglobal("CheebaJunkRow"..i.."Icon")
        local label = getglobal("CheebaJunkRow"..i.."Name")
        if icon  then icon:SetTexture(GetItemTexture(name)) end
        if label then label:SetText(name) end
        row.dataIdx = dataIdx
        row:Show()
      else
        row:Hide()
      end
    end
  end
end

function CheebaJunkTab_OnClick()
  currentTab = this:GetID()
  PanelTemplates_Tab_OnClick(CheebaJunkFrame)
  CheebaJunkListScrollScrollBar:SetValue(0)
  CheebaJunkFrame_Update()
end

function CheebaJunkRow_OnRemoveClick()
  local row = this:GetParent()
  if row and row.dataIdx then
    local list = GetCurrentList()
    local name = list[row.dataIdx]
    if name then
      local listName = currentTab == 1 and "vendor" or "delete"
      table.remove(list, row.dataIdx)
      DEFAULT_CHAT_FRAME:AddMessage("=> Removed |cffff6633"..name.."|r from "..listName.." list")
      CheebaJunkFrame_Update()
    end
  end
end

function CheebaJunkRow_OnEnter()
  if this.dataIdx then
    local list = GetCurrentList()
    local name = list[this.dataIdx]
    if name then
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:AddLine(name, 1, 1, 1)
      local label = currentTab == 1 and "|cff33ffccAuto-vendor item|r" or "|cffff6666Auto-delete item|r"
      GameTooltip:AddLine(label)
      GameTooltip:AddLine("|cffaaaaaaClick X to remove from list|r")
      GameTooltip:Show()
    end
  end
end

function CheebaJunkRow_OnLeave()
  GameTooltip:Hide()
end

function CheebaJunkFrame_OnLoad()
  this:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  this:SetBackdropColor(0, 0, 0, 1)
  tinsert(UISpecialFrames, "CheebaJunkFrame")
  PanelTemplates_SetNumTabs(this, 2)
  PanelTemplates_SetTab(this, 1)
  this:RegisterEvent("VARIABLES_LOADED")
  this:RegisterEvent("BAG_UPDATE")
end

function CheebaJunkFrame_OnEvent()
  if event == "VARIABLES_LOADED" then
    CheebaJunk_textures = CheebaJunk_textures or {}
    CheebaJunkFrameTab1:SetText("Vendor Items")
    CheebaJunkFrameTab2:SetText("Delete Items")
    PanelTemplates_SetTab(CheebaJunkFrame, 1)
  elseif event == "BAG_UPDATE" then
    if CheebaJunkFrame:IsVisible() then
      CheebaJunkFrame_Update()
    end
  end
end

function CheebaJunkFrame_OnShow()
  CheebaJunk_textures = CheebaJunk_textures or {}
  CheebaJunkFrame_Update()
end

function CheebaJunk_Toggle()
  if CheebaJunkFrame:IsVisible() then
    HideUIPanel(CheebaJunkFrame)
  else
    ShowUIPanel(CheebaJunkFrame)
  end
end
