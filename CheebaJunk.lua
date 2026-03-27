local gfind = string.gmatch or string.gfind

do -- config
  CheebaJunk_vendor   = CheebaJunk_vendor   or {}
  CheebaJunk_delete   = CheebaJunk_delete   or {}
  CheebaJunk_open     = CheebaJunk_open     or {}
  CheebaJunk_textures = CheebaJunk_textures or {}

  -- Find an item in bags by its item string and return its icon texture
  local function GetTextureFromBags(itemLink)
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local rawlink = GetContainerItemLink(bag, slot)
        if rawlink then
          local _, _, link = string.find(rawlink, "(item:%d+:%d+:%d+:%d+)")
          if link == itemLink then
            return GetContainerItemInfo(bag, slot)  -- texture is first return value
          end
        end
      end
    end
  end

  SLASH_CHEEBAJUNK1, SLASH_CHEEBAJUNK2, SLASH_CHEEBAJUNK3 = "/cjunk", "/junk", "/cj"
  SlashCmdList["CHEEBAJUNK"] = function(message)
    local commandlist = { }
    local command

    for command in gfind(message, "[^ ]+") do
      table.insert(commandlist, string.lower(command))
    end

    -- open/close the UI panel (bare /cjunk with no args)
    if commandlist[1] == nil then
      CheebaJunk_Toggle()

    -- add vendor entry
    elseif commandlist[1] == "vendor" then
      local addstring = table.concat(commandlist," ",2)
      if addstring == "" then return end

      -- support item links; also cache the icon texture
      local _, _, itemLink = string.find(addstring, "(item:%d+:%d+:%d+:%d+)")
      local itemName
      if itemLink then
        itemName = GetItemInfo(itemLink)
        local tex = GetTextureFromBags(itemLink)
        if itemName and tex then
          CheebaJunk_textures[string.lower(itemName)] = tex
        end
      end

      addstring = itemName or addstring
      local lowerstring = string.lower(addstring)
      for _, v in pairs(CheebaJunk_vendor) do
        if v == lowerstring then
          DEFAULT_CHAT_FRAME:AddMessage("=> |cffff6633".. addstring .."|r is already in your vendor list")
          return
        end
      end

      table.insert(CheebaJunk_vendor, lowerstring)
      DEFAULT_CHAT_FRAME:AddMessage("=> adding |cff33ffcc".. addstring .."|r to your vendor list")

    -- add delete entry
    elseif commandlist[1] == "delete" then
      local addstring = table.concat(commandlist," ",2)
      if addstring == "" then return end

      -- support item links; also cache the icon texture
      local _, _, itemLink = string.find(addstring, "(item:%d+:%d+:%d+:%d+)")
      local itemName
      if itemLink then
        itemName = GetItemInfo(itemLink)
        local tex = GetTextureFromBags(itemLink)
        if itemName and tex then
          CheebaJunk_textures[string.lower(itemName)] = tex
        end
      end

      addstring = itemName or addstring
      local lowerstring = string.lower(addstring)
      for _, v in pairs(CheebaJunk_delete) do
        if v == lowerstring then
          DEFAULT_CHAT_FRAME:AddMessage("=> |cffff6633".. addstring .."|r is already in your delete list")
          return
        end
      end

      table.insert(CheebaJunk_delete, lowerstring)
      DEFAULT_CHAT_FRAME:AddMessage("=> adding |cff33ffcc".. addstring .."|r to your delete list")

    -- add open entry
    elseif commandlist[1] == "open" then
      local addstring = table.concat(commandlist," ",2)
      if addstring == "" then return end

      local _, _, itemLink = string.find(addstring, "(item:%d+:%d+:%d+:%d+)")
      local itemName
      if itemLink then
        itemName = GetItemInfo(itemLink)
        local tex = GetTextureFromBags(itemLink)
        if itemName and tex then
          CheebaJunk_textures[string.lower(itemName)] = tex
        end
      end

      addstring = itemName or addstring
      local lowerstring = string.lower(addstring)
      for _, v in pairs(CheebaJunk_open) do
        if v == lowerstring then
          DEFAULT_CHAT_FRAME:AddMessage("=> |cffff6633".. addstring .."|r is already in your open list")
          return
        end
      end

      table.insert(CheebaJunk_open, lowerstring)
      DEFAULT_CHAT_FRAME:AddMessage("=> adding |cff33ffcc".. addstring .."|r to your open list")

    -- remove entry
    elseif commandlist[1] == "rm" then
      local vendor = tonumber(commandlist[2])
      local delete = tonumber(commandlist[2]) - table.getn(CheebaJunk_vendor)
      local open   = tonumber(commandlist[2]) - table.getn(CheebaJunk_vendor) - table.getn(CheebaJunk_delete)

      if CheebaJunk_vendor[vendor] then
        DEFAULT_CHAT_FRAME:AddMessage("=> Removing entry " .. commandlist[2]
          .. " (" .. CheebaJunk_vendor[vendor]
          .. ") from your vendor list")
        table.remove(CheebaJunk_vendor, vendor)

      elseif CheebaJunk_delete[delete] then
        DEFAULT_CHAT_FRAME:AddMessage("=> Removing entry " .. commandlist[2]
          .. " (" .. CheebaJunk_delete[delete]
          .. ") from your deletion list")
        table.remove(CheebaJunk_delete, delete)

      elseif CheebaJunk_open[open] then
        DEFAULT_CHAT_FRAME:AddMessage("=> Removing entry " .. commandlist[2]
          .. " (" .. CheebaJunk_open[open]
          .. ") from your open list")
        table.remove(CheebaJunk_open, open)
      end
    -- purge duplicates
    elseif commandlist[1] == "purge" then
      local function dedupe(t)
        local seen = {}
        local removed = 0
        local i = 1
        while i <= table.getn(t) do
          if seen[t[i]] then
            table.remove(t, i)
            removed = removed + 1
          else
            seen[t[i]] = true
            i = i + 1
          end
        end
        return removed
      end
      local vr = dedupe(CheebaJunk_vendor)
      local dr = dedupe(CheebaJunk_delete)
      local or_ = dedupe(CheebaJunk_open)
      DEFAULT_CHAT_FRAME:AddMessage("=> Purge complete: removed |cffff6633"..vr.."|r vendor, |cffff6633"..dr.."|r delete, and |cffff6633"..or_.."|r open duplicates")

    elseif commandlist[1] == "ls" then
      local addstring = table.concat(commandlist," ",2)
      local printID = 0
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ee33Vendor Items:")
      for id, hl in pairs(CheebaJunk_vendor) do
        if string.find(hl, addstring) then
          DEFAULT_CHAT_FRAME:AddMessage(" |r[|cff33ee33"..id.."|r] "..hl)
        end
        printID = id
      end
      local deleteOffset = printID
      DEFAULT_CHAT_FRAME:AddMessage("|cffaa3333Delete Items:")
      for id, hl in pairs(CheebaJunk_delete) do
        if string.find(hl, addstring) then
          DEFAULT_CHAT_FRAME:AddMessage(" |r[|cffee3333"..id+deleteOffset.."|r] "..hl)
        end
        printID = id + deleteOffset
      end
      DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffOpen Items:")
      for id, hl in pairs(CheebaJunk_open) do
        if string.find(hl, addstring) then
          DEFAULT_CHAT_FRAME:AddMessage(" |r[|cff33aaff"..id+printID.."|r] "..hl)
        end
      end
    else
      DEFAULT_CHAT_FRAME:AddMessage("CheebaJunk Usage:")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk|cffaaaaaa - |rOpen/close the item list UI")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk vendor Fel Iron Blood Ring|cffaaaaaa - |rAutomatically vendors Fel Iron Rings")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk delete Light Hide|cffaaaaaa - |rAutomatically deletes Light Hide")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk open Thick-shelled Clam|cffaaaaaa - |rAutomatically opens clams/containers")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk rm 3|cffaaaaaa - |rRemoves entry '3' of your list")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk ls|cffaaaaaa - |rDisplays your current list")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk ls <text>|cffaaaaaa - |rSearch your current list for text")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk purge|cffaaaaaa - |rRemoves duplicate entries from both lists")
    end
  end
end

do -- autovendor
  local autovendor = CreateFrame("Frame")
  autovendor:Hide()

  autovendor:RegisterEvent("MERCHANT_SHOW")
  autovendor:RegisterEvent("MERCHANT_CLOSED")
  autovendor:SetScript("OnEvent", function()
    if event == "MERCHANT_CLOSED" then
      autovendor.merchant = nil
      autovendor:Hide()
    elseif event == "MERCHANT_SHOW" then
      autovendor.merchant = true
      autovendor:Show()
    end
  end)

  autovendor:SetScript("OnUpdate", function()
    -- throttle to to one item per .1 second
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end

    -- iterate through bag
    for bag = 0, 4, 1 do
      for slot = 1, GetContainerNumSlots(bag), 1 do
        local rawlink = GetContainerItemLink(bag, slot)
        local _, _, link = string.find((rawlink or ""), "(item:%d+:%d+:%d+:%d+)")
        local name, _, _, _, _, itemType = link and GetItemInfo(link)
        name = name and string.lower(name)

        if name and itemType ~= "Quest" then
          for i, vendor in pairs(CheebaJunk_vendor) do
            -- abort if the merchant window disappeared
            if not this.merchant then return end

            if name == vendor then
              -- cache icon before selling
              local tex = GetContainerItemInfo(bag, slot)
              if tex then CheebaJunk_textures[name] = tex end
              -- clear cursor and sell the item
              ClearCursor()
              UseContainerItem(bag, slot)
              -- continue next update
              return
            end
          end
        end
      end
    end

    -- stop processing
    this:Hide()
  end)
end

do -- autodelete
  local autodelete = CreateFrame("Frame")
  autodelete:Hide()

  autodelete:RegisterEvent("ITEM_PUSH")
  autodelete:SetScript("OnEvent", function()
    autodelete.expiry = GetTime() + 3
    autodelete:Show()
  end)

  autodelete:SetScript("OnUpdate", function()
    -- throttle to to one item per .1 second
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end

    -- iterate through bag
    for bag = 0, 4, 1 do
      for slot = 1, GetContainerNumSlots(bag), 1 do
        local rawlink = GetContainerItemLink(bag, slot)
        local _, _, link = string.find((rawlink or ""), "(item:%d+:%d+:%d+:%d+)")
        local name, _, _, _, _, itemType = link and GetItemInfo(link)
        name = name and string.lower(name)

        if name and itemType ~= "Quest" then
          for i, vendor in pairs(CheebaJunk_delete) do
            if name == vendor then
              -- cache icon before deleting
              local tex = GetContainerItemInfo(bag, slot)
              if tex then CheebaJunk_textures[name] = tex end
              -- clear cursor and delete the item
              ClearCursor()
              PickupContainerItem(bag, slot)
              DeleteCursorItem()
              -- continue next update
              return
            end
          end
        end
      end
    end

    -- stop processing only after grace period expires
    if GetTime() >= (this.expiry or 0) then
      this:Hide()
    end
  end)
end

do -- autoopen
  local autoopen = CreateFrame("Frame")
  autoopen:Hide()

  autoopen:RegisterEvent("ITEM_PUSH")
  autoopen:SetScript("OnEvent", function()
    -- delay start to let the loot session finish before we scan
    autoopen.startAt = GetTime() + 1
    autoopen.expiry  = GetTime() + 5
    autoopen:Show()
  end)

  autoopen:SetScript("OnUpdate", function()
    if GetTime() < (this.startAt or 0) then return end
    if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + .1 end
    if LootFrame:IsVisible() then return end

    for bag = 0, 4, 1 do
      for slot = 1, GetContainerNumSlots(bag), 1 do
        local rawlink = GetContainerItemLink(bag, slot)
        local _, _, link = string.find((rawlink or ""), "(item:%d+:%d+:%d+:%d+)")
        local name, _, _, _, _, itemType = link and GetItemInfo(link)
        name = name and string.lower(name)

        if name and itemType ~= "Quest" then
          for i, openitem in pairs(CheebaJunk_open) do
            if name == openitem then
              local tex = GetContainerItemInfo(bag, slot)
              if tex then CheebaJunk_textures[name] = tex end
              ClearCursor()
              UseContainerItem(bag, slot)
              return
            end
          end
        end
      end
    end

    if GetTime() >= (this.expiry or 0) then
      this:Hide()
    end
  end)
end
