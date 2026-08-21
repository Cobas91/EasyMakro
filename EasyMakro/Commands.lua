local ADDON_NAME, EM = ...

-- Zusaetzliche Befehle, die ohne konkreten Zauber als eigenes Makro angelegt
-- werden koennen (tauchen in der Liste neben den Zaubern auf).
EM.Commands = {
    {
        key = "STARTATTACK",
        name = "Auto-Attack starten",
        icon = "Interface\\Icons\\Ability_MeleeDamage",
        line = "/startattack",
    },
    {
        key = "PETATTACK",
        name = "Pet: Angriff",
        icon = "Interface\\Icons\\Ability_Hunter_Pet_Assist",
        line = "/petattack",
    },
    {
        key = "PETFOLLOW",
        name = "Pet: Folgen",
        icon = "Interface\\Icons\\Ability_Hunter_MendPet",
        line = "/petfollow",
    },
    {
        key = "FOLLOWTARGET",
        name = "Ziel folgen",
        icon = "Interface\\Icons\\INV_Misc_Foot_Centaur",
        line = "/follow target",
    },
    {
        key = "STOPCASTING",
        name = "Zauber abbrechen",
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
