--***********************************************************
--**                    Ceilings! B42                      **
--**        ISBuildActionClient Hook for Building at z+1   **
--***********************************************************

print("ISBuildActionClientHook - Loading ISBuildAction hook...")

-- Check if ISBuildAction is available
if not ISBuildAction then
    print("ISBuildActionClientHook - ERROR: ISBuildAction not found!")
    return
end

-- Store original functions
local originalISBuildActionNew = ISBuildAction.new
local originalISBuildActionStart = ISBuildAction.start  
local originalISBuildActionPerform = ISBuildAction.perform

print("ISBuildActionClientHook - Original ISBuildAction functions stored")

--************************************************************************--
--** Helper function to check if an item is a ceiling entity
--************************************************************************--
local function isCeilingEntity(item)
    if not item then 
        return false 
    end
    
    -- Check for the flag set by ISBuildPanel hook
    if item.isCeilingBuild then
        return true
    end
    
    -- Fallback: Check if this item has an objectInfo with a name we recognize
    if item.objectInfo then
        if item.objectInfo.getName then
            local success, entityName = pcall(item.objectInfo.getName, item.objectInfo)
            if success then
                local ceilingEntities = {
                    "RoofTestFloor",
                    "rooftestfloor",
                }
                
                for _, ceilingName in ipairs(ceilingEntities) do
                    if entityName == ceilingName then
                        return true
                    end
                end
            end
        end
    end
    
    -- Fallback: check item name/type if available
    if item.name and luautils.stringStarts(item.name, "Roof") then
        return true
    end
    
    return false
end

--************************************************************************--
--** Hook ISBuildAction:new - Modify z coordinate for ceiling entities
--************************************************************************--
function ISBuildAction:new(character, item, x, y, z, north, spriteName, time)
    -- Check if this is a ceiling entity
    if isCeilingEntity(item) then
        local originalZ = z
        
        -- Use the ceilingZ from ISBuildPanel if available, otherwise calculate
        local ceilingZ = item.ceilingZ or (z + 1)
        z = ceilingZ  -- Build ceiling at the calculated level
        
        -- Mark this action as a ceiling build
        local action = originalISBuildActionNew(self, character, item, x, y, z, north, spriteName, time)
        action.isCeilingBuild = true
        action.originalZ = originalZ
        action.ceilingZ = ceilingZ
        
        return action
    else
        return originalISBuildActionNew(self, character, item, x, y, z, north, spriteName, time)
    end
end

--************************************************************************--
--** Hook ISBuildAction:start - Set ghost sprite at ceiling level
--************************************************************************--
function ISBuildAction:start()
    -- Call original start function
    originalISBuildActionStart(self)
    
    -- For ceiling builds, ensure the ghost sprite Z is correct
    if self.isCeilingBuild and self.item.ghostSprite then
        self.item.ghostSpriteZ = self.z  -- Make sure ghost is at ceiling level
    end
end

--************************************************************************--
--** Hook ISBuildAction:perform - Execute ceiling build at z+1
--************************************************************************--
function ISBuildAction:perform()
    -- Call original perform function (it will use our modified z coordinate)
    originalISBuildActionPerform(self)
end


print("ISBuildActionClientHook - ISBuildAction hooks installed successfully!")
