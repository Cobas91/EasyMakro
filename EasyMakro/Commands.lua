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
        -- "Ability_Hunter_Pet_Assist" wurde erst in Mists of Pandaria
        -- hinzugefuegt und existiert in Classic Era nicht (Icon blieb leer,
        -- Makro-Icon liess sich dadurch nicht per Drag auf die Aktionsleiste
        -- ziehen). 132270 = Growl, in Classic Era vorhanden.
        icon = 132270,
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
        -- "INV_Misc_Foot_Centaur" ist ebenfalls erst ab Mists of Pandaria
        -- vorhanden. Ability_Tracking existiert seit Classic.
        icon = "Interface\\Icons\\Ability_Tracking",
        line = "/follow target",
    },
    {
        key = "STOPCASTING",
        name = L.CMD_STOPCASTING,
        -- "Spell_Nature_Slow" liess sich nicht als existierendes
        -- Classic-Icon verifizieren. Ability_Warrior_Disarm ist bestaetigt
        -- seit Classic vorhanden.
        icon = "Interface\\Icons\\Ability_Warrior_Disarm",
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
