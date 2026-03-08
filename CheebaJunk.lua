local gfind = string.gmatch or string.gfind

do -- config
  CheebaJunk_vendor   = CheebaJunk_vendor   or {}
  CheebaJunk_delete   = CheebaJunk_delete   or {}
  CheebaJunk_textures = CheebaJunk_textures or {}

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
      local itemName, texture
      if itemLink then
        local n, _, _, _, _, _, _, _, _, t = GetItemInfo(itemLink)
        itemName, texture = n, t
      end

      addstring = itemName or addstring
      if itemName and texture then
        CheebaJunk_textures[string.lower(itemName)] = texture
      end

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
      local itemName, texture
      if itemLink then
        local n, _, _, _, _, _, _, _, _, t = GetItemInfo(itemLink)
        itemName, texture = n, t
      end

      addstring = itemName or addstring
      if itemName and texture then
        CheebaJunk_textures[string.lower(itemName)] = texture
      end

      local lowerstring = string.lower(addstring)
      for _, v in pairs(CheebaJunk_delete) do
        if v == lowerstring then
          DEFAULT_CHAT_FRAME:AddMessage("=> |cffff6633".. addstring .."|r is already in your delete list")
          return
        end
      end

      table.insert(CheebaJunk_delete, lowerstring)
      DEFAULT_CHAT_FRAME:AddMessage("=> adding |cff33ffcc".. addstring .."|r to your delete list")

    -- remove entry
    elseif commandlist[1] == "rm" then
      local vendor = tonumber(commandlist[2])
      local delete = tonumber(commandlist[2]) - table.getn(CheebaJunk_vendor)

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
      DEFAULT_CHAT_FRAME:AddMessage("=> Purge complete: removed |cffff6633"..vr.."|r vendor and |cffff6633"..dr.."|r delete duplicates")

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
      DEFAULT_CHAT_FRAME:AddMessage("|cffaa3333Delete Items:")
      for id, hl in pairs(CheebaJunk_delete) do
        if string.find(hl, addstring) then
          DEFAULT_CHAT_FRAME:AddMessage(" |r[|cffee3333"..id+printID.."|r] "..hl)
        end
      end
    else
      DEFAULT_CHAT_FRAME:AddMessage("CheebaJunk Usage:")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk|cffaaaaaa - |rOpen/close the item list UI")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk vendor Fel Iron Blood Ring|cffaaaaaa - |rAutomatically vendors Fel Iron Rings")
      DEFAULT_CHAT_FRAME:AddMessage("|cffaaffdd/cjunk delete Light Hide|cffaaaaaa - |rAutomatically deletes Light Hide")
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
        local name = link and GetItemInfo(link)
        name = name and string.lower(name)

        if name then
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
        local name = link and GetItemInfo(link)
        name = name and string.lower(name)

        if name then
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

    -- stop processing
    this:Hide()
  end)
end
