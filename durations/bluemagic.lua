--[[
Copyright (c) 2024 Thorny

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local dataTracker;


--BLU can only wear a small subset of these but I copied the full tables for simplicity's sake, maybe eventually BLU sub will get high enough.
local regenDuration = {
    [28092] = 18, --Theo. Pantaloons
    [28113] = 18, --Theo. Pant. +1
    [23243] = 21, --Th. Pantaloons +2
    [23578] = 24, --Th. Pant. +3
    [11206] = 10, --Orison Mitts +1
    [11106] = 18, --Orison Mitts +2
    [27056] = 20, --Ebers Mitts
    [27057] = 22, --Ebers Mitts +1
    [27787] = 20, --Runeist Bandeau
    [27706] = 21, --Rune. Bandeau +1
    [23062] = 24, --Rune. Bandeau +2
    [23397] = 27, --Rune. Bandeau +3
    [26894] = 12, --Telchine Chas.
    [26265] = 15, --Lugh's Cape
    [21175] = 12 --Coeus
};

local refreshReceived = {
    [26323] = 20, --Gishdubar Sash
    [27464] = 15, --Inspirited Boots
    [28316] = 15, --Shabti Sabatons
    [28317] = 21, --Shab. Sabatons +1
    [11575] = 30 --Grapevine Cape
};

local function ApplyDiffusion(duration)
    if (dataTracker:GetBuffActive(356)) then
        local augments = dataTracker:ParseAugments();
        local merits = dataTracker:GetMeritCount(0x0BC2);
        local multiplier = 1 + ((merits - 1) * 0.05);
        if (augments.Generic[0x58D]) then --Mirage Charuqs variants
            multiplier = multiplier + (merits * 0.05);
        end
        duration = duration * multiplier;
    end
    return duration;
end

local function CalculateBlueMagicDuration(duration, diffusion, unbridled)
    if (diffusion) then
        duration = ApplyDiffusion(duration);
    end
    if unbridled and dataTracker:GetJobData().Main == 16 and dataTracker:GetJobData().MainLevel == 99 then
        duration = duration * (1 + (dataTracker:GetJobPointCount(16, 7) / 100));
    end
    return duration;
end

--TP only scales these durations while Chain Affinity is active, so both are captured when the cast begins.
local blueCast = {};
local function CalculateTpDuration(spellId, baseDuration, duration1500, duration3000, azureDuration)
    if (blueCast.SpellId == spellId) and ((os.clock() - blueCast.Time) < 30) then
        if blueCast.AzureLore then
            return azureDuration;
        elseif blueCast.ChainAffinity then
            local tp = math.min(math.max(blueCast.TP, 0), 3000);
            if (tp >= 1500) then
                return duration1500 + ((duration3000 - duration1500) * (tp - 1500) / 1500);
            end
            return baseDuration + ((duration1500 - baseDuration) * tp / 1500);
        end
    end
    return baseDuration;
end

local function Initialize(tracker, buffer, castStartHandlers)
    dataTracker = tracker;

    castStartHandlers:append(function(spellId)
        blueCast.SpellId = spellId;
        blueCast.Time = os.clock();
        blueCast.TP = AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0);
        blueCast.ChainAffinity = dataTracker:GetBuffActive(164);
        blueCast.AzureLore = dataTracker:GetBuffActive(163);
    end);

    --Metallic Body
    buffer[517] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 37;
    end

     --Refueling
    buffer[530] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 33;
    end

     --Memento Mori
    buffer[538] = function(targetId)
        return CalculateBlueMagicDuration(60, true, false), 190;
    end

     --Cocoon
    buffer[547] = function(targetId)
        return CalculateBlueMagicDuration(90, true, false), 93;
    end

     --Feather Barrier
    buffer[574] = function(targetId)
        return CalculateBlueMagicDuration(30, true, false), 92;
    end

     --Reactor Cool
    buffer[613] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 35;
    end

     --Saline Coat
    buffer[614] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 191;
    end

     --Plasma Charge
    buffer[615] = function(targetId)
        return CalculateBlueMagicDuration(600, true, false), 38; --Seems to be random between 10 and 15 minutes?
    end

     --Diamondhide
    buffer[632] = function(targetId)
        return CalculateBlueMagicDuration(900, false, false), 37;
    end

     --Warm-Up
    buffer[636] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 90;
    end

     --Amplification
    buffer[642] = function(targetId)
        return CalculateBlueMagicDuration(90, true, false), 190;
    end

     --Zephyr Mantle
    buffer[647] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 36;
    end

     --Triumphant Roar
    buffer[655] = function(targetId)
        return CalculateBlueMagicDuration(60, true, false), 91;
    end

     --Plenilune Embrace
    buffer[658] = function(targetId)
        return CalculateBlueMagicDuration(90, false, false), 91;
    end

     --Animating Wail
    buffer[661] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 33;
    end

     --Battery Charge
    buffer[662] = function(targetId)
        local duration = 300;
        if dataTracker:GetPlayerId() == targetId then
            duration = duration + dataTracker:EquipSum(refreshReceived);
        end
        return CalculateBlueMagicDuration(duration, true, false), 43;
    end

     --Regeneration
    buffer[664] = function(targetId)
        local duration = 90 + dataTracker:EquipSum(regenDuration);
        return CalculateBlueMagicDuration(duration, true, false), 42;
    end

     --Magic Barrier
    buffer[668] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 152;
    end

     --Fantod
    buffer[674] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 45;
    end

     --Occultation
    buffer[679] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 36;
    end

     --Barrier Tusk
    buffer[685] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 116;
    end

     --O. Counterstance
    buffer[696] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 486;        
    end

     --Nat. Meditation
    buffer[700] = function(targetId)
        return CalculateBlueMagicDuration(180, true, false), 91;
    end

     --Erratic Flutter
    buffer[710] = function(targetId)
        return CalculateBlueMagicDuration(300, true, false), 33;
    end

     --Harden Shell
    buffer[737] = function(targetId)
        return CalculateBlueMagicDuration(180, true, true), 93;
    end

     --Pyric Bulwark
    buffer[741] = function(targetId)
        return CalculateBlueMagicDuration(300, true, true), 150;
    end

     --Carcharian Verve
    buffer[745] = function(targetId)
        return CalculateBlueMagicDuration(60, true, true), 91; --This also has a 15 minute aquaveil, assuming that is less important than the attack bonus..?
    end

     --Mighty Guard
    buffer[750] = function(targetId)
        return CalculateBlueMagicDuration(180, true, true), 604;        
    end

    --Debuffs the server reports in the action packet.
    --Venom Shell
    buffer[513] = function(targetId)
        return 60, 3;
    end

    --Cold Wave
    buffer[535] = function(targetId)
        return 60, 129;
    end

    --Stinking Gas
    buffer[537] = function(targetId)
        return 60, 138;
    end

    --Filamented Hold
    buffer[548] = function(targetId)
        return 90, 13;
    end

    --Frightful Roar
    buffer[561] = function(targetId)
        return 180, 149;
    end

    --Sound Blast
    buffer[572] = function(targetId)
        return 30, 140;
    end

    --Jettatura
    buffer[575] = function(targetId)
        return 5, 28;
    end

    --Yawn
    buffer[576] = function(targetId)
        return 90, 2;
    end

    --Chaotic Eye
    buffer[582] = function(targetId)
        return 120, 6;
    end

    --Sheep Song
    buffer[584] = function(targetId)
        return 60, 2;
    end

    --Lowing
    buffer[588] = function(targetId)
        return 60, 31;
    end

    --Soporific
    buffer[598] = function(targetId)
        return 90, 2;
    end

    --Awful Eye
    buffer[606] = function(targetId)
        return 30, 136;
    end

    --Infrasonics
    buffer[610] = function(targetId)
        return 60, 148;
    end

    --Actinic Burst
    buffer[612] = function(targetId)
        return 16, 156;
    end

    --Temporal Shift
    buffer[616] = function(targetId)
        return 5, 10;
    end

    --Sandspray
    buffer[621] = function(targetId)
        return 120, 5;
    end

    --Enervation
    buffer[633] = function(targetId)
        return 30, 149;
    end

    --Light of Penance
    buffer[634] = function(targetId)
        return 30, 5;
    end

    --Added effects land silently, so these are estimates and only shown with /tt blumode.
    --Maelstrom
    buffer[515] = function(targetId)
        return 60, 136, true;
    end

    --Sandspin
    buffer[524] = function(targetId)
        return 60, 146, true;
    end

    --Ice Break
    buffer[531] = function(targetId)
        return 30, 11, true;
    end

    --Blitzstrahl
    buffer[532] = function(targetId)
        return 5, 10, true;
    end

    --Mysterious Light
    buffer[534] = function(targetId)
        return 60, 12, true;
    end

    --Poison Breath
    buffer[536] = function(targetId)
        return 60, 3, true;
    end

    --Terror Touch
    buffer[539] = function(targetId)
        return 60, 147, true;
    end

    --Magnetite Cloud
    buffer[555] = function(targetId)
        return 60, 12, true;
    end

    --Hecatomb Wave
    buffer[563] = function(targetId)
        return 60, 5, true;
    end

    --Radiant Breath
    buffer[565] = function(targetId)
        return 60, 13, true;
    end

    --Pinecone Bomb
    buffer[596] = function(targetId)
        return CalculateTpDuration(596, 90, 150, 210, 240), 2, true;
    end

    --Sprout Smack
    buffer[597] = function(targetId)
        return CalculateTpDuration(597, 180, 360, 400, 450), 13, true;
    end

    --Queasyshroom
    buffer[599] = function(targetId)
        return CalculateTpDuration(599, 90, 150, 180, 210), 3, true;
    end

    --Wild Oats
    buffer[603] = function(targetId)
        return CalculateTpDuration(603, 180, 360, 400, 450), 138, true;
    end

    --Bad Breath
    buffer[604] = function(targetId)
        return 60, 13, true;
    end

    --Frost Breath
    buffer[608] = function(targetId)
        return 60, 4, true;
    end

    --Disseverment
    buffer[611] = function(targetId)
        return 180, 3, true;
    end

    --Blastbomb
    buffer[618] = function(targetId)
        return 30, 11, true;
    end

    --Battle Dance
    buffer[620] = function(targetId)
        return CalculateTpDuration(620, 90, 480, 680, 800), 137, true;
    end

    --Head Butt
    buffer[623] = function(targetId)
        return 5, 10, true;
    end

    --Frypan
    buffer[628] = function(targetId)
        return 5, 10, true;
    end

    --Feather Storm
    buffer[638] = function(targetId)
        return CalculateTpDuration(638, 180, 360, 400, 450), 3, true;
    end

    --Tail Slap
    buffer[640] = function(targetId)
        return 5, 10, true;
    end

    --Mind Blast
    buffer[644] = function(targetId)
        return 90, 4, true;
    end

    --Regurgitation
    buffer[648] = function(targetId)
        return 30, 11, true;
    end

    --Seedspray
    buffer[650] = function(targetId)
        return 120, 149, true;
    end

    --Corrosive Ooze
    buffer[651] = function(targetId)
        return 90, 149, true;
    end

    --Spiral Spin
    buffer[652] = function(targetId)
        return 60, 146, true;
    end

    --Sub-zero Smash
    buffer[654] = function(targetId)
        return 180, 4, true;
    end
end

return Initialize;