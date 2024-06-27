
local orbs = {}

orbs.orbs = {
    {label="Weak Blood Orb", name="AWWayofTime:weakBloodOrb"},
    {label="Apprentice Blood Orb", name="AWWayofTime:apprenticeBloodOrb"},
    {label="Magician's Blood Orb", name="AWWayofTime:magicianBloodOrb"},
    {label="Master Blood Orb", name="AWWayofTime:masterBloodOrb"},
    {label="Archmage's Blood Orb", name="AWWayofTime:archmageBloodOrb"},
    {label="Transcendent Blood Orb", name="AWWayofTime:transcendentBloodOrb"},
    {label="Transparent Orb", name="BloodArsenal:transparent_orb"},
    {label="Blood Orb of Armok", name="Avaritia:Orb_Armok"},
    {label="Eldritch Blood Orb", name="ForbiddenMagic:EldritchOrb"},
};

function orbs.is_item_an_orb(item)
    if item == nil or item.name == nil then
        return false
    end

    for i, orb in pairs(orbs.orbs) do
        if orb.name == item.name then
            return true
        end
    end
    
    return false
end

function orbs.get_orb_label(name)
    for i, orb in pairs(orbs.orbs) do
        if orb.name == name then
            return orb.label
        end
    end

    return nil
end

return orbs
