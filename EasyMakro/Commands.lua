local ADDON_NAME, EM = ...
local L = EM.L

-- Zusätzliche Befehle, die ohne konkreten Zauber als eigenes Makro angelegt
-- werden können (tauchen in der Liste neben den Zaubern auf).
EM.Commands = {
    {
        key = "STARTATTACK",
        name = L.CMD_STARTATTACK,
        icon = "Interface\\Icons\\Ability_MeleeDamage",
        line = "/startattack",
    },
    {
        key = "PETATTACK",
        name = L.CMD_PETATTACK,
        icon = "Interface\\Icons\\Ability_Hunter_Pet_Assist",
        line = "/petattack",
    },
    {
        key = "PETFOLLOW",
        name = L.CMD_PETFOLLOW,
        icon = "Interface\\Icons\\Ability_Hunter_MendPet",
        line = "/petfollow",
    },
    {
        key = "FOLLOWTARGET",
        name = L.CMD_FOLLOWTARGET,
        icon = "Interface\\Icons\\INV_Misc_Foot_Centaur",
        line = "/follow target",
    },
    {
        key = "STOPCASTING",
        name = L.CMD_STOPCASTING,
        icon = "Interface\\Icons\\Spell_Nature_Slow",
        line = "/stopcasting",
    },
}

function EM:GetCommandByKey(key)
    for _, cmd in ipairs(self.Commands) do
        if cmd.key == key then
            return cmd
        end
    end
    return nil
end
