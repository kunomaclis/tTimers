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

--Libs
local durations = require('durations.include');
local encoding = require('gdifonts.encoding');
local actionPacket = require('actionpacket');
local buffFlags = require('buffflags');

--Constants..
local abilityTypes = T{ 6, 14, 15 };
local actionMessages = T{
    Death = T{ 6, 20, 113, 406, 605, 646 },
    Expired = T{ 64, 204, 206, 350, 351 },
    Damage = T{ 2, 110, 252, 264, 317 },
    Steps = T{ 519, 520, 521, 591 },
    Applied = T{ 127, 203, 236, 237, 268, 270, 271, 277 },
};
local blueDebugEnabled = false;
local blueDebugFile;
local blueDebugPath;
local blueDebugRecentUntil = 0;
local blueDebugStartedAt = 0;
local blueDebugTargets = {};
local blueDebugCastContexts = {};
local blueDebugChecks = {};
local blueDebugPending = {};
local blueDebugRawActions = {};
local blueDebugRawExpirations = {};
local blueDebugRawMessages = {};
local blueDebugCastStats = {};
local blueDebugLastRequestSignature;
local blueDebugLastRequestAt = 0;
local blueDebugNextCastId = 0;
local ClearUncertainDebuffs;
local blueDebugAppliedMessages = T{ 236, 271, 277 };
local blueDebugExpectedStatuses = {
    [515] = T{ 136 },
    [524] = T{ 146 },
    [531] = T{ 11 },
    [532] = T{ 10 },
    [534] = T{ 12 },
    [536] = T{ 3 },
    [539] = T{ 147 },
    [555] = T{ 12 },
    [563] = T{ 5 },
    [565] = T{ 13, 6 },
    [596] = T{ 2 },
    [597] = T{ 13 },
    [599] = T{ 3 },
    [603] = T{ 138 },
    [604] = T{ 13, 6, 4, 11, 12, 3, 5 },
    [608] = T{ 4 },
    [611] = T{ 3 },
    [618] = T{ 11 },
    [620] = T{ 137 },
    [623] = T{ 10 },
    [628] = T{ 10 },
    [638] = T{ 3 },
    [640] = T{ 10 },
    [644] = T{ 4 },
    [671] = T{ 5, 11 },
};
local blueDebugStatusNames = {
    [2] = 'Sleep',
    [3] = 'Poison',
    [4] = 'Paralysis',
    [5] = 'Blindness',
    [6] = 'Silence',
    [10] = 'Stun',
    [11] = 'Bind',
    [12] = 'Weight',
    [13] = 'Slow',
    [31] = 'Plague',
    [129] = 'Frost',
    [136] = 'STR Down',
    [137] = 'DEX Down',
    [138] = 'VIT Down',
    [140] = 'INT Down',
    [146] = 'Accuracy Down',
    [147] = 'Attack Down',
    [148] = 'Evasion Down',
    [149] = 'Defense Down',
    [156] = 'Flash',
    [167] = 'Magic Defense Down',
};
local blueDebugCheckTypes = {
    [0x40] = 'Too Weak',
    [0x41] = 'Incredibly Easy Prey',
    [0x42] = 'Easy Prey',
    [0x43] = 'Decent Challenge',
    [0x44] = 'Even Match',
    [0x45] = 'Tough',
    [0x46] = 'Very Tough',
    [0x47] = 'Incredibly Tough',
};
local blueDebugCheckConditions = {
    [0xAA] = 'High Evasion, High Defense',
    [0xAB] = 'High Evasion',
    [0xAC] = 'High Evasion, Low Defense',
    [0xAD] = 'High Defense',
    [0xAE] = 'Neutral Evasion and Defense',
    [0xAF] = 'Low Defense',
    [0xB0] = 'Low Evasion, High Defense',
    [0xB1] = 'Low Evasion',
    [0xB2] = 'Low Evasion, Low Defense',
};

local function ClearBlueDebugContext(resetCapture)
    blueDebugRecentUntil = 0;
    blueDebugTargets = {};
    blueDebugCastContexts = {};
    blueDebugChecks = {};
    blueDebugPending = {};
    blueDebugCastStats = {};
    blueDebugLastRequestSignature = nil;
    blueDebugLastRequestAt = 0;
    if resetCapture then
        blueDebugRawActions = {};
        blueDebugRawExpirations = {};
        blueDebugRawMessages = {};
        blueDebugNextCastId = 0;
    end
end

local function CloseBlueDebug()
    local file = blueDebugFile;
    blueDebugFile = nil;
    blueDebugEnabled = false;
    ClearBlueDebugContext(true);
    if file then
        pcall(file.close, file);
    end
end

local function WriteBlueDebug(text)
    if blueDebugFile then
        blueDebugFile:write(string.format('%s +%.3f %s\n',
            os.date('%Y-%m-%d %H:%M:%S'), os.clock() - blueDebugStartedAt, text));
        blueDebugFile:flush();
    end
end

local function RunBlueDebug(context, callback, ...)
    local success, err = pcall(callback, ...);
    if success then
        return true;
    end

    local path = blueDebugPath;
    pcall(WriteBlueDebug, string.format('ERROR context=%q detail=%q', context, tostring(err)));
    if ClearUncertainDebuffs then
        pcall(ClearUncertainDebuffs);
    end
    CloseBlueDebug();
    Error(string.format('BLU debug capture stopped after %s failed: $H%s$R (%s)',
        context, tostring(err), tostring(path)));
    return false;
end

local function HexString(data)
    local bytes = {};
    for i = 1,#data do
        bytes[#bytes + 1] = string.format('%02X', string.byte(data, i));
    end
    return table.concat(bytes);
end

local function GetBlueDebugPacketData(e)
    local data = e.data;
    local size = tonumber(e.size) or #data;
    if (size > 0) and (size < #data) then
        return string.sub(data, 1, size);
    end
    return data;
end

local function GetBlueDebugSpellName(spellId)
    local resource = AshitaCore:GetResourceManager():GetSpellById(spellId);
    if resource and resource.Name and resource.Name[1] then
        return encoding:ShiftJIS_To_UTF8(resource.Name[1]);
    end
    return string.format('Unknown Spell %u', spellId);
end

local function GetBlueDebugStatusName(statusId)
    return blueDebugStatusNames[statusId] or string.format('Status %u', statusId);
end

local function AddBlueDebugPending(targetId, statusId, spellId, castId, confirmed, now)
    local pending = blueDebugPending[targetId];
    if not pending then
        pending = {};
        blueDebugPending[targetId] = pending;
    end

    for i = #pending,1,-1 do
        if (now - pending[i].Time) > 1200 then
            table.remove(pending, i);
        elseif (pending[i].CastId == castId)
            and (pending[i].SpellId == spellId)
            and (pending[i].StatusId == statusId)
        then
            if confirmed and not pending[i].Confirmed then
                pending[i].Confirmed = true;
                pending[i].Time = now;
                return true;
            end
            return false;
        end
    end

    pending[#pending + 1] = {
        Time = now,
        SpellId = spellId,
        CastId = castId,
        StatusId = statusId,
        Confirmed = confirmed,
    };
    return true;
end

local function GetBlueDebugTarget(targetId)
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    local index = bit.band(targetId, 0x7FF);
    if entity:GetServerId(index) ~= targetId then
        index = 0;
        for i = 0x001,0x8FF do
            if entity:GetServerId(i) == targetId then
                index = i;
                break
            end
        end
    end

    if index == 0 then
        return 'Unknown', 0;
    end
    return entity:GetName(index), index;
end

local function GetBlueDebugTargetSafe(targetId)
    local success, name, index = pcall(GetBlueDebugTarget, targetId);
    if success then
        return name, index;
    end
    return 'Unknown', 0;
end

local function GetBlueDebugCastStats(castId, spellId)
    local stats = blueDebugCastStats[castId];
    if not stats then
        stats = {
            SpellId = spellId,
            SpellName = GetBlueDebugSpellName(spellId),
            Targets = 0,
            Lands = 0,
            Candidates = 0,
            NoEffect = 0,
            Durations = 0,
            ClearedTargets = 0,
        };
        blueDebugCastStats[castId] = stats;
    end
    return stats;
end

local function LogBlueDebugSummary(reason)
    local unresolved = {};
    local targetIds = {};
    for targetId,_ in pairs(blueDebugPending) do
        targetIds[#targetIds + 1] = targetId;
    end
    table.sort(targetIds);
    local now = os.clock();
    for _,targetId in ipairs(targetIds) do
        local pending = blueDebugPending[targetId];
        local entries = {};
        for _,entry in ipairs(pending) do
            unresolved[entry.CastId] = (unresolved[entry.CastId] or 0) + 1;
            entries[#entries + 1] = string.format('%u:%u:%u:%.3f',
                entry.CastId, entry.SpellId, entry.StatusId, now - entry.Time);
        end
        local targetName, targetIndex = GetBlueDebugTargetSafe(targetId);
        WriteBlueDebug(string.format(
            'UNRESOLVED reason=%s target=%u target_name=%q entity_index=%u pending=%q',
            reason, targetId, targetName, targetIndex, table.concat(entries, ',')));
    end
    for castId = 1,blueDebugNextCastId do
        local stats = blueDebugCastStats[castId];
        if stats and ((stats.Lands > 0) or (stats.Candidates > 0)
            or (stats.NoEffect > 0) or (stats.Durations > 0)
            or (stats.ClearedTargets > 0) or ((unresolved[castId] or 0) > 0))
        then
            WriteBlueDebug(string.format(
                'CAST_SUMMARY reason=%s cast_id=%u spell=%u spell_name=%q targets=%u lands=%u candidates=%u no_effect=%u durations=%u cleared_targets=%u unresolved=%u',
                reason, castId, stats.SpellId, stats.SpellName,
                stats.Targets, stats.Lands, stats.Candidates, stats.NoEffect,
                stats.Durations, stats.ClearedTargets, unresolved[castId] or 0));
        end
    end
end

local function LogBlueDebugTargetClear(targetId, reason)
    local pending = blueDebugPending[targetId];
    if not pending then
        return;
    end
    local targetName, targetIndex = GetBlueDebugTargetSafe(targetId);
    local casts = {};
    for _,entry in ipairs(pending) do
        casts[entry.CastId] = true;
    end
    local castIds = {};
    for castId,_ in pairs(casts) do
        castIds[#castIds + 1] = castId;
        local stats = blueDebugCastStats[castId];
        if stats then
            stats.ClearedTargets = stats.ClearedTargets + 1;
        end
    end
    table.sort(castIds);
    WriteBlueDebug(string.format(
        'TARGET_CLEARED reason=%s target=%u target_name=%q entity_index=%u pending=%u casts=%q',
        reason, targetId, targetName, targetIndex, #pending, table.concat(castIds, ',')));
end

local function GetBlueDebugEquipment()
    local items = {};
    for _,item in ipairs(durations:GetDataTracker():GetEquippedSet()) do
        items[#items + 1] = string.format('%02u:%u', item.Slot, item.Id);
    end
    table.sort(items);
    return table.concat(items, ',');
end

local function GetBlueDebugPlayerState()
    local memory = AshitaCore:GetMemoryManager();
    local player = memory:GetPlayer();
    local intBase = player:GetStat(4);
    local intModifier = player:GetStatModifier(4);
    local blueMagicSkill = player:GetCombatSkill(43);
    return {
        Time = os.clock(),
        TP = memory:GetParty():GetMemberTP(0),
        Level = player:GetMainJobLevel(),
        BlueMagicSkill = blueMagicSkill:GetSkill(),
        BlueMagicSkillCapped = blueMagicSkill:IsCapped(),
        IntBase = intBase,
        IntModifier = intModifier,
        IntTotal = intBase + intModifier,
        Equipment = GetBlueDebugEquipment(),
    };
end

local function LogBlueCheck(data, messageId)
    local targetId = struct.unpack('L', data, 0x08 + 1);
    local level = struct.unpack('L', data, 0x0C + 1);
    local checkType = struct.unpack('L', data, 0x10 + 1);
    local targetName, targetIndex = GetBlueDebugTarget(targetId);
    local difficulty = blueDebugCheckTypes[checkType] or 'Unknown';
    local condition = blueDebugCheckConditions[messageId] or 'Impossible to Gauge';
    if level > 0x7FFFFFFF then
        level = level - 0x100000000;
    end

    blueDebugTargets[targetId] = true;
    blueDebugChecks[targetId] = {
        Level = level,
        Difficulty = difficulty,
        Condition = condition,
    };
    WriteBlueDebug(string.format(
        'CHECK target=%u target_index=%u target_name=%q level=%d difficulty=%q condition=%q check_type=%u message=%u',
        targetId, targetIndex, targetName, level, difficulty, condition, checkType,
        messageId));
end

local function LogBlueCastRequest(data)
    local targetId = struct.unpack('L', data, 0x04 + 1);
    local spellId = struct.unpack('H', data, 0x0C + 1);
    local now = os.clock();
    local signature = string.format('%u:%u', spellId, targetId);
    if (signature == blueDebugLastRequestSignature) and ((now - blueDebugLastRequestAt) < 0.05) then
        return;
    end
    blueDebugLastRequestSignature = signature;
    blueDebugLastRequestAt = now;

    local targetName, targetIndex = GetBlueDebugTarget(targetId);
    local state = GetBlueDebugPlayerState();
    local check = blueDebugChecks[targetId];
    blueDebugNextCastId = blueDebugNextCastId + 1;
    state.CastId = blueDebugNextCastId;
    state.TargetId = targetId;
    blueDebugCastContexts[spellId] = state;
    GetBlueDebugCastStats(state.CastId, spellId);
    WriteBlueDebug(string.format(
        'REQUEST cast_id=%u spell=%u spell_name=%q target=%u target_index=%u target_name=%q target_level=%d target_difficulty=%q target_condition=%q player_tp=%u player_level=%u player_int=%d int_base=%d int_modifier=%d blue_magic_skill_base=%u blue_magic_skill_capped=%s equipment=%q',
        state.CastId, spellId, GetBlueDebugSpellName(spellId), targetId, targetIndex, targetName, check and check.Level or -1,
        check and check.Difficulty or 'Unknown', check and check.Condition or 'Unknown',
        state.TP, state.Level, state.IntTotal, state.IntBase, state.IntModifier,
        state.BlueMagicSkill, tostring(state.BlueMagicSkillCapped), state.Equipment));
end

local function LogBlueCastPacket(data)
    if (#data >= 0x0E)
        and (struct.unpack('H', data, 0x0A + 1) == 3)
        and (struct.unpack('H', data, 0x0C + 1) >= 513)
    then
        LogBlueCastRequest(data);
    end
end

local function LogBlueAction(packet, rawData)
    blueDebugRecentUntil = os.clock() + 2;
    local state = GetBlueDebugPlayerState();
    local request = blueDebugCastContexts[packet.Id];
    local requestAge = request and (state.Time - request.Time) or -1;
    if requestAge > 10 then
        request = nil;
        requestAge = -1;
    end
    local castId;
    if request then
        castId = request.CastId;
    else
        blueDebugNextCastId = blueDebugNextCastId + 1;
        castId = blueDebugNextCastId;
    end
    local spellName = GetBlueDebugSpellName(packet.Id);
    local castStats = GetBlueDebugCastStats(castId, packet.Id);
    castStats.Targets = #packet.Targets;
    WriteBlueDebug(string.format(
        'ACTION cast_id=%u actor=%u type=%u spell=%u spell_name=%q targets=%u player_tp=%u request_tp=%d request_age=%.3f player_level=%u player_int=%d int_base=%d int_modifier=%d blue_magic_skill_base=%u blue_magic_skill_capped=%s equipment=%q',
        castId, packet.UserId, packet.Type, packet.Id, spellName, #packet.Targets, state.TP,
        request and request.TP or -1, requestAge, state.Level, state.IntTotal, state.IntBase,
        state.IntModifier, state.BlueMagicSkill, tostring(state.BlueMagicSkillCapped), state.Equipment));
    if not blueDebugRawActions[packet.Id] then
        blueDebugRawActions[packet.Id] = true;
        WriteBlueDebug(string.format('RAW_ACTION spell=%u spell_name=%q raw=%s',
            packet.Id, spellName, HexString(rawData)));
    end

    local expectedStatuses = blueDebugExpectedStatuses[packet.Id];
    for targetIndex,target in ipairs(packet.Targets) do
        blueDebugTargets[target.Id] = true;
        local targetName, entityIndex = GetBlueDebugTarget(target.Id);
        local check = blueDebugChecks[target.Id];
        for actionIndex,action in ipairs(target.Actions) do
            local additionalEffect = action.AdditionalEffect;
            WriteBlueDebug(string.format(
                'RESULT cast_id=%u spell=%u spell_name=%q packet_target_index=%u action_index=%u target=%u entity_index=%u target_name=%q target_level=%d target_difficulty=%q target_condition=%q reaction=%u animation=%u effect=%u knockback=%u param=%u message=%u flags=%u additional=%s additional_damage=%u additional_param=%u additional_message=%u',
                castId, packet.Id, spellName, targetIndex, actionIndex, target.Id, entityIndex, targetName,
                check and check.Level or -1, check and check.Difficulty or 'Unknown',
                check and check.Condition or 'Unknown', action.Reaction, action.Animation,
                action.SpecialEffect, action.Knockback, action.Param, action.Message, action.Flags,
                additionalEffect and 'yes' or 'no',
                additionalEffect and additionalEffect.Damage or 0,
                additionalEffect and additionalEffect.Param or 0,
                additionalEffect and additionalEffect.Message or 0));

            local applied = blueDebugAppliedMessages:contains(action.Message);
            if applied then
                if AddBlueDebugPending(target.Id, action.Param, packet.Id, castId, true, state.Time) then
                    castStats.Lands = castStats.Lands + 1;
                    WriteBlueDebug(string.format(
                        'LAND cast_id=%u spell=%u spell_name=%q target=%u target_name=%q status=%u status_name=%q message=%u',
                        castId, packet.Id, spellName, target.Id, targetName, action.Param,
                        GetBlueDebugStatusName(action.Param), action.Message));
                end
            elseif action.Message == 75 then
                castStats.NoEffect = castStats.NoEffect + 1;
                WriteBlueDebug(string.format(
                    'NO_EFFECT cast_id=%u spell=%u spell_name=%q target=%u target_name=%q param=%u message=%u',
                    castId, packet.Id, spellName, target.Id, targetName, action.Param, action.Message));
            end

            if expectedStatuses and (action.Message ~= 75) and (action.Param > 0) then
                for _,statusId in ipairs(expectedStatuses) do
                    if not applied or (statusId ~= action.Param) then
                        if AddBlueDebugPending(target.Id, statusId, packet.Id, castId, false, state.Time) then
                            castStats.Candidates = castStats.Candidates + 1;
                            WriteBlueDebug(string.format(
                                'CANDIDATE cast_id=%u spell=%u spell_name=%q target=%u target_name=%q expected_status=%u status_name=%q',
                                castId, packet.Id, spellName, target.Id, targetName, statusId,
                                GetBlueDebugStatusName(statusId)));
                        end
                    end
                end
            end
        end
    end
    blueDebugCastContexts[packet.Id] = nil;
end

local function LogBlueActionMessage(data, messageId, reason)
    if blueDebugRawMessages[messageId] then
        return;
    end
    blueDebugRawMessages[messageId] = true;
    local targetId = struct.unpack('L', data, 0x08 + 1);
    local targetName, targetIndex = GetBlueDebugTarget(targetId);
    WriteBlueDebug(string.format(
        'MESSAGE reason=%s actor=%u target=%u target_name=%q entity_index=%u param1=%u param2=%u actor_index=%u target_index=%u message=%u raw=%s',
        reason,
        struct.unpack('L', data, 0x04 + 1),
        targetId,
        targetName,
        targetIndex,
        struct.unpack('L', data, 0x0C + 1),
        struct.unpack('L', data, 0x10 + 1),
        struct.unpack('H', data, 0x14 + 1),
        struct.unpack('H', data, 0x16 + 1),
        messageId,
        HexString(data)));
end

local function LogBlueExpiration(data, messageId)
    local targetId = struct.unpack('L', data, 0x08 + 1);
    local statusId = struct.unpack('H', data, 0x0C + 1);
    local pending = blueDebugPending[targetId];
    if not pending then
        return;
    end

    local now = os.clock();
    local matches = {};
    for i = #pending,1,-1 do
        if (now - pending[i].Time) > 1200 then
            table.remove(pending, i);
        elseif pending[i].StatusId == statusId then
            matches[#matches + 1] = pending[i];
            table.remove(pending, i);
        end
    end
    if #pending == 0 then
        blueDebugPending[targetId] = nil;
    end
    if (#matches == 0) and (#pending == 0) then
        return;
    end

    local targetName, targetIndex = GetBlueDebugTarget(targetId);
    if #matches == 0 then
        local candidates = {};
        for _,entry in ipairs(pending) do
            candidates[#candidates + 1] = string.format('%u:%u:%.3f',
                entry.CastId, entry.SpellId, now - entry.Time);
        end
        WriteBlueDebug(string.format(
            'EXPIRE_UNMATCHED target=%u target_name=%q entity_index=%u status=%u status_name=%q message=%u pending=%q',
            targetId, targetName, targetIndex, statusId, GetBlueDebugStatusName(statusId),
            messageId, table.concat(candidates, ',')));
        if not blueDebugRawExpirations[statusId] then
            blueDebugRawExpirations[statusId] = true;
            WriteBlueDebug(string.format('RAW_EXPIRE status=%u status_name=%q raw=%s',
                statusId, GetBlueDebugStatusName(statusId), HexString(data)));
        end
        return;
    end

    WriteBlueDebug(string.format(
        'EXPIRE target=%u target_name=%q entity_index=%u status=%u status_name=%q message=%u candidates=%u',
        targetId, targetName, targetIndex, statusId, GetBlueDebugStatusName(statusId),
        messageId, #matches));

    local selected;
    for _,entry in ipairs(matches) do
        if entry.Confirmed and ((not selected) or (entry.Time > selected.Time)) then
            selected = entry;
        end
    end
    if selected then
        WriteBlueDebug(string.format(
            'DURATION confidence=confirmed cast_id=%u spell=%u spell_name=%q target=%u target_name=%q status=%u status_name=%q seconds=%.3f',
            selected.CastId, selected.SpellId, GetBlueDebugSpellName(selected.SpellId),
            targetId, targetName, statusId, GetBlueDebugStatusName(statusId), now - selected.Time));
    elseif #matches == 1 then
        selected = matches[1];
        WriteBlueDebug(string.format(
            'DURATION confidence=candidate cast_id=%u spell=%u spell_name=%q target=%u target_name=%q status=%u status_name=%q seconds=%.3f',
            selected.CastId, selected.SpellId, GetBlueDebugSpellName(selected.SpellId),
            targetId, targetName, statusId, GetBlueDebugStatusName(statusId), now - selected.Time));
    else
        local candidates = {};
        for _,entry in ipairs(matches) do
            candidates[#candidates + 1] = string.format('%u:%u:%.3f',
                entry.CastId, entry.SpellId, now - entry.Time);
        end
        WriteBlueDebug(string.format(
            'DURATION_AMBIGUOUS target=%u target_name=%q status=%u status_name=%q candidates=%q',
            targetId, targetName, statusId, GetBlueDebugStatusName(statusId),
            table.concat(candidates, ',')));
    end
    if selected then
        local stats = blueDebugCastStats[selected.CastId];
        if stats then
            stats.Durations = stats.Durations + 1;
        end
    end

    if not blueDebugRawExpirations[statusId] then
        blueDebugRawExpirations[statusId] = true;
        WriteBlueDebug(string.format('RAW_EXPIRE status=%u status_name=%q raw=%s',
            statusId, GetBlueDebugStatusName(statusId), HexString(data)));
    end
end

local function LogBlueActionMessagePacket(data, messageId)
    local targetId = struct.unpack('L', data, 0x08 + 1);
    local checkType = struct.unpack('L', data, 0x10 + 1);
    if (messageId == 0xF9)
        or (blueDebugCheckConditions[messageId] and blueDebugCheckTypes[checkType])
    then
        LogBlueCheck(data, messageId);
    elseif actionMessages.Expired:contains(messageId) then
        LogBlueExpiration(data, messageId);
    elseif os.clock() <= blueDebugRecentUntil then
        LogBlueActionMessage(data, messageId, 'recent');
    elseif blueDebugTargets[targetId] then
        LogBlueActionMessage(data, messageId, 'tracked_target');
    end
end

local function LogBlueCastEvent(e)
    LogBlueCastPacket(GetBlueDebugPacketData(e));
end

local function LogBlueActionEvent(packet, e)
    LogBlueAction(packet, GetBlueDebugPacketData(e));
end

local function LogBlueActionMessageEvent(e, messageId)
    LogBlueActionMessagePacket(GetBlueDebugPacketData(e), messageId);
end

local function ClearBlueDebugTarget(targetId, reason)
    if blueDebugEnabled and reason then
        RunBlueDebug('target clear', LogBlueDebugTargetClear, targetId, reason);
    end
    blueDebugTargets[targetId] = nil;
    blueDebugChecks[targetId] = nil;
    blueDebugPending[targetId] = nil;
end
local dotPriority = T{
    [232] = 6,
    [25] = 5,
    [231] = 4,
    [24] = 3,
    [230] = 2,
    [23] = 1,
    [33] = 1,
};
local debuffOverrides = T{
};

--[[    
    timerData
    Data must contain the following members:
    Creation [os.clock()]
    Duration (number) - Time until timer expires, in seconds.
    TotalDuration (number) - Total duration of timer.
    Label [string]
    Local [table] - Table for storing items at scope of timer.  Member 'Delete' is reserved, and if set to true, removes the timer.
    Expiration [os.clock()]

    Data can optionally contain:
    Tooltip [string]
    Icon [string]
]]--

--[[
    buffData (stored in buffsByAction and buffsByTarget)
        ActionType(string) - Ability, Item, MobSkill, Spell, Weaponskill
        ActionId(number) - Action ID for resource lookups.
        Resource(ISpell/IAbility) - Resource for triggering action.
        BuffId(number) - Buff ID.
        Texture(string) - Texture.
        Targets(table) - List of effected players.
            Id(number) - Target ID.
            Creation(number) - Time the buff was created at.
            Delete(boolean) - Flag to true to clear on next render.
            Duration(number) - Initial duration.
            Expiration(number) - Time the buff expires.
            Name(string) - Name of the target.
]]
local activeTimers = T{};
local buffsByAction = {};
local buffsByTarget = {};
local pendingRoll = T { Time = -80 };
local rebuildTimers = false;


-- Clear any conflicting buffs from table.
local function ClearConflicts(targetId, buffId)
    local entry = buffsByTarget[targetId];
    if not entry then
        entry = T{};
        buffsByTarget[targetId] = entry;
        return entry;
    end

    --Clear all other instances of this buff..
    local flags = buffFlags[buffId];
    if (flags == nil) or (not flags.MultipleInstance) then
        for _,buffData in ipairs(entry) do
            if (buffData.BuffId == buffId) then
                local target = buffData.Targets[targetId];
                if target then
                    target.Delete = true;
                end
            end
        end
    end

    if (flags) then
        --Clear all conflicting buffs..
        for _,override in ipairs(flags.Override) do
            for _,buffData in ipairs(entry) do
                if (buffData.BuffId == override) then
                    local target = buffData.Targets[targetId];
                    if target then
                        target.Delete = true;
                    end
                end
            end
        end
    end

    return entry;
end

local defaultPaths = T{
    ['Ability'] = 'abilities/default.png',
    ['Item'] = 'items/default.png',
    ['Spell'] = 'spells/default.png',
    ['MobAbility'] = 'mobskills/default.png',
    ['MobSkill'] = 'mobskills/default.png',
    ['Weaponskill'] = 'weaponskills/default.png'
};
-- Determine the texture to be used for a given action.
local function GetActionIcon(actionTable)
    local override = debuffOverrides[actionTable.Key];
    if (override) then
        if GetFilePath(override) then
            actionTable.Icon = override;
            return;
        end
    end

    if (actionTable.BuffId ~= nil) and (actionTable.BuffId > 0) then
        actionTable.Icon = string.format('STATUS:%u', actionTable.BuffId);
        return;
    end

    local defaultPath = defaultPaths[actionTable.ActionType];
    if defaultPath and GetFilePath(defaultPath) then
        actionTable.Icon = defaultPath;
    end
end

local function GetActionName(actionTable)
    local type = actionTable.ActionType;
    if (type == 'Ability') then
        local res = AshitaCore:GetResourceManager():GetAbilityById(actionTable.ActionId + 512);
        if (res) then
            actionTable.Name = encoding:ShiftJIS_To_UTF8(res.Name[1]);
        else
            actionTable.Name = string.format('Ability[%u]', actionTable.ActionId);
        end
        return;
    end
    
    if (type == 'Item') then
        local res = AshitaCore:GetResourceManager():GetItemById(actionTable.ActionId);
        if (res) then
            actionTable.Name = encoding:ShiftJIS_To_UTF8(res.Name[1]);
        else
            actionTable.Name = string.format('Item[%u]', actionTable.ActionId);
        end
        return;
    end
    
    if (type == 'MobAbility') then
        local res = AshitaCore:GetResourceManager():GetAbilityById(actionTable.ActionId + 512);
        if (res) then
            actionTable.Name = encoding:ShiftJIS_To_UTF8(res.Name[1]);
        else
            actionTable.Name = string.format('MobAbility[%u]', actionTable.ActionId);
        end
        return;
    end

    if (type == 'MobSkill') then
        local res = AshitaCore:GetResourceManager():GetString('monsters.abilities', actionTable.ActionId);
        if (res) then
            actionTable.Name = encoding:ShiftJIS_To_UTF8(res.Name[1]);
        else
            actionTable.Name = string.format('MobSkill[%u]', actionTable.ActionId);
        end
        return;
    end
    
    if (type == 'Spell') then
        local res = AshitaCore:GetResourceManager():GetSpellById(actionTable.ActionId);
        if (res) then
            actionTable.Name = encoding:ShiftJIS_To_UTF8(res.Name[1]);
        else
            actionTable.Name = string.format('Spell[%u]', actionTable.ActionId);
        end
        return;
    end
    
    if (type == 'Weaponskill') then
        local res = AshitaCore:GetResourceManager():GetAbilityById(actionTable.ActionId);
        if (res) then
            actionTable.Name = encoding:ShiftJIS_To_UTF8(res.Name[1]);
        else
            actionTable.Name = string.format('Weaponskill[%u]', actionTable.ActionId);
        end
        return;
    end
end

local function MonsterIdToName(id)
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    local index = bit.band(id, 0x7FF);
    if (entity:GetServerId(index) ~= id) then
        index = 0;
        for i = 0x001,0x3FF do
            if (entity:GetServerId(i) == id) then
                index = i;
            end
        end
        for i = 0x700,0x8FF do
            if (entity:GetServerId(i) == id) then
                index = i;
            end
        end
    end

    if (index == 0) then
        return 'Unknown';
    elseif (gSettings.Debuff.ShowMobIndex) then
        return string.format('%s 0x%03X', entity:GetName(index), index);
    else
        return entity:GetName(index);
    end
end

local function RecordDebuff(targetId, actionType, actionId, buffId, duration, uncertain)
    local playerTable = buffsByTarget[targetId];
    if uncertain then
        if not playerTable then
            playerTable = T{};
            buffsByTarget[targetId] = playerTable;
        end
    else
        playerTable = ClearConflicts(targetId, buffId);
    end
    local key = string.format('%s:%u', actionType, actionId);

    local actionTable = buffsByAction[key];
    if not actionTable then
        actionTable = {};
        actionTable.ActionType = actionType;
        actionTable.ActionId = actionId;
        actionTable.BuffId = buffId;
        actionTable.Uncertain = uncertain;
        actionTable.Key = key;
        actionTable.Targets = T{};
        GetActionName(actionTable);
        if uncertain then
            actionTable.Name = '~' .. actionTable.Name;
        end
        GetActionIcon(actionTable);
        buffsByAction[key] = actionTable;
    end

    local target = actionTable.Targets[targetId];
    if not target then
        target = {};
        target.Id = targetId;
        target.Name = MonsterIdToName(targetId);
        actionTable.Targets[targetId] = target;
    end

    target.Creation = os.clock();
    target.Delete = false;
    target.Duration = duration;
    target.Expiration = os.clock() + duration;
    rebuildTimers = true;

    for _,entry in ipairs(playerTable) do
        if (entry == actionTable) then
            return;
        end
    end
    playerTable:append(actionTable);
end

local function HandleDiaBio(targetId, actionType, actionId, buffId, duration)
    local entry = buffsByTarget[targetId];
    if entry then
        local now = os.clock();
        local value = dotPriority[actionId];
        for _,buffData in pairs(entry) do
            if (buffData.ActionType == 'Spell') then
                local buffValue = dotPriority[buffData.ActionId];
                if (buffValue ~= nil) then
                    if buffData.Targets[targetId].Expiration > now then
                        if (buffValue >= value) then
                            return;
                        else
                            local target = buffData.Targets[targetId];
                            if target then
                                target.Delete = true;
                            end
                        end
                    end
                end
            end
        end
    end
    
    RecordDebuff(targetId, actionType, actionId, buffId, duration);
end

local stepBuffIds = T{
    [201] = 386,
    [202] = 391,
    [203] = 396,
    [312] = 448,
}
local function HandleStep(targetId, actionId)
    local mods = 0;
    local tracker = durations:GetDataTracker();
    if (tracker:GetJobData().Main == 19) then
        mods = tracker:GetJobPointCount(19, 1);
    end

    local entry = buffsByTarget[targetId];
    if entry then
        for _,buffData in pairs(entry) do
            if (buffData.ActionType == 'Ability') and (buffData.ActionId == actionId) then
                local target = buffData.Targets[targetId];
                if target then
                    local duration = 60;
                    local remainingDuration = target.Expiration - os.clock();
                    if remainingDuration > 0 then
                        duration = remainingDuration + 30 + mods;
                        if (duration > (120 + mods)) then
                            duration = 120 + mods; --Verify whether mods actually allow you more than 2min duration..
                        end
                    end
                    target.Creation = os.clock();
                    target.Duration = duration;
                    target.Expiration = os.clock() + duration;
                    rebuildTimers = true;
                    return;
                end
            end
        end
    end
    
    RecordDebuff(targetId, 'Ability', actionId, stepBuffIds[actionId], 60 + mods);
end

local function LogBlueTimerStart(uncertain, spellId, targetId, buffId, duration, messageId)
    WriteBlueDebug(string.format(
        'TIMER_START confidence=%s spell=%u spell_name=%q target=%u status=%u status_name=%q duration=%.3f message=%u',
        uncertain and 'assumed' or 'confirmed', spellId, GetBlueDebugSpellName(spellId),
        targetId, buffId, GetBlueDebugStatusName(buffId), duration, messageId));
end

local function HandleSpellComplete(packet)
    local localPlayer = packet.UserId == durations:GetDataTracker():GetPlayerId();
    for _,target in ipairs(packet.Targets) do
        for _,action in ipairs(target.Actions) do
            local messageId = action.Message;
            if (actionMessages.Applied:contains(messageId)) or (actionMessages.Damage:contains(messageId)) then
                local duration, buffId, uncertain = durations:GetSpellDuration(packet.Id, target.Id);
                if duration and (not uncertain or (blueDebugEnabled and localPlayer)) then
                    if type(buffId) == 'table' then
                        buffId = buffId[1];
                    end

                    local dotPrio = dotPriority[packet.Id];
                    if dotPrio then
                        HandleDiaBio(target.Id, 'Spell', packet.Id, buffId, duration);
                    else
                        RecordDebuff(target.Id, 'Spell', packet.Id, buffId, duration, uncertain);
                    end
                    if blueDebugEnabled and localPlayer and (packet.Id >= 513) then
                        RunBlueDebug('timer start', LogBlueTimerStart, uncertain,
                            packet.Id, target.Id, buffId, duration, messageId);
                    end
                end
            end
        end
    end
end

local function HandleAbilityComplete(packet)
    for _,target in ipairs(packet.Targets) do
        for _,action in ipairs(target.Actions) do
            if (actionMessages.Steps:contains(action.Message)) then
                HandleStep(target.Id, packet.Id, action.Param);
            elseif (actionMessages.Applied:contains(action.Message)) then
                local duration, buffId = durations:GetAbilityDuration(packet.Id, target.Id);

                if type(buffId) == 'table' then
                    buffId = buffId[1];
                end

                if duration then
                    RecordDebuff(target.Id, 'Ability', packet.Id, buffId, duration);
                end
            end
        end
    end    
end

local function HandleDebuffExpiration(buff, targetId)
    local flags = buffFlags[buff];
    if (flags) and (flags.MultipleInstance) then
        return;
    end
    
    local entry = buffsByTarget[targetId];
    if entry then
        local now = os.clock();
        for _,buffData in ipairs(entry) do
            if buffData.BuffId == buff then
                local target = buffData.Targets[targetId];
                if target then
                    target.Creation = now - target.Duration;
                    target.Expiration = now;
                    rebuildTimers = true;
                end
            end
        end
    end
end

local function HandleEnemyDeath(targetId)
    local entry = buffsByTarget[targetId];
    if entry then
        for _,buffData in ipairs(entry) do
            local target = buffData.Targets[targetId];
            if target then
                target.Expiration = 0;
                rebuildTimers = true;
            end
        end
    end
end

ClearUncertainDebuffs = function()
    for _,buffData in pairs(buffsByAction) do
        if buffData.Uncertain then
            for _,target in pairs(buffData.Targets) do
                target.Delete = true;
            end
            rebuildTimers = true;
        end
    end
end

local function CheckDistance(index)
    local distance = AshitaCore:GetMemoryManager():GetEntity():GetDistance(index);
    if (distance ~= 0) and (distance < 1225) then
        return true;
    end
end

ashita.events.register('packet_out', 'debuff_tracker_handleoutgoingpacket', function (e)
    if not blueDebugEnabled or (e.id ~= 0x01A) then
        return;
    end

    RunBlueDebug('cast request', LogBlueCastEvent, e);
end);

ashita.events.register('packet_in', 'debuff_tracker_handleincomingpacket', function (e)
    if blueDebugEnabled and (e.id == 0x00A) then
        RunBlueDebug('zone summary', LogBlueDebugSummary, 'zone');
        if blueDebugEnabled then
            RunBlueDebug('zone reset', WriteBlueDebug, 'ZONE_RESET');
            ClearUncertainDebuffs();
            ClearBlueDebugContext();
        end
    end

    if (e.id == 0x00E) then
        local flags = struct.unpack('B', e.data, 0x0A + 1);
        if (bit.band(flags, 0x20) == 0x20) and (CheckDistance(struct.unpack('H', e.data, 0x08 + 1))) then
            local targetId = struct.unpack('L', e.data, 0x04 + 1);
            HandleEnemyDeath(targetId);
            ClearBlueDebugTarget(targetId, 'entity_removed');
        elseif (bit.band(flags, 0x04) == 0x04) then
            local hp = struct.unpack('B', e.data, 0x1E + 1);
            if (hp == 0) then
                local targetId = struct.unpack('L', e.data, 0x04 + 1);
                HandleEnemyDeath(targetId);
                ClearBlueDebugTarget(targetId, 'hp_zero');
            end
        end
    end

    if (e.id == 0x028) then
        local packet = actionPacket:parse(e);
        if blueDebugEnabled
            and (packet.UserId == durations:GetDataTracker():GetPlayerId())
            and (packet.Type == 4)
            and (packet.Id >= 513)
        then
            RunBlueDebug('action packet', LogBlueActionEvent, packet, e);
        end
        local trackAction = (packet.UserId == durations:GetDataTracker():GetPlayerId());
        if (trackAction == false) then
            if (gSettings.Debuff.TrackMode == 'All Players') then
                local ent = AshitaCore:GetMemoryManager():GetEntity();
                for i = 0x400,0x6FF do
                    if (ent:GetServerId(i) == packet.UserId) then
                        trackAction = true;
                    end
                end
            elseif (gSettings.Debuff.TrackMode == 'Party Only') then
                local party = AshitaCore:GetMemoryManager():GetParty();
                for i = 1,5 do
                    if (party:GetMemberIsActive(i) == 1) and (party:GetMemberServerId(i) == packet.UserId) then
                        trackAction = true;
                    end
                end
            elseif (gSettings.Debuff.TrackMode == 'Alliance Only') then
                local party = AshitaCore:GetMemoryManager():GetParty();
                for i = 1,17 do
                    if (party:GetMemberIsActive(i) == 1) and (party:GetMemberServerId(i) == packet.UserId) then
                        trackAction = true;
                    end
                end
            end
        end

        if (trackAction) then
            --Spell Completion
            if (packet.Type == 4) then
                HandleSpellComplete(packet);
            end

            if (abilityTypes:contains(packet.Type)) then
                HandleAbilityComplete(packet);
            end
        end
    end

    if (e.id == 0x29) then
        local data = e.data;
        local messageId = bit.band(struct.unpack('H', data, 0x18 + 1), 0x7FFF);
        if blueDebugEnabled then
            RunBlueDebug('action message', LogBlueActionMessageEvent, e, messageId);
        end
        if (actionMessages.Death:contains(messageId)) then
            local targetId = struct.unpack('L', e.data, 0x08 + 1);
            HandleEnemyDeath(targetId);
            ClearBlueDebugTarget(targetId, 'death_message');
        end
        if (actionMessages.Expired:contains(messageId)) then
            HandleDebuffExpiration(struct.unpack('H', e.data, 0x0C + 1), struct.unpack('L', e.data, 0x08 + 1));
        end
    end
end);
local function TimeToString(timer)
    if (timer >= 3600) then
        local h = math.floor(timer / 3600);
        local m = math.floor(math.fmod(timer, 3600) / 60);
        return string.format('%i:%02i', h, m);
    else
        local m = math.floor(timer / 60);
        local s = math.floor(math.fmod(timer, 60));
        return string.format('%02i:%02i', m, s);
    end
end

local function ClearDeletedTimers()
    for _,timer in ipairs(activeTimers) do
        --Clear timers that have been deleted via UI..
        if (timer.Local.Delete) then
            for _,targetEntry in ipairs(timer.Targets) do
                targetEntry.Delete = true;
            end
            if (timer.Local.Block) then
                gSettings.Debuff.Blocked[timer.Key] = true;
                settings.save();
                timer.Local.Block = nil;
                print(chat.header(addon.name) .. chat.message('Blocked Debuff: ' .. timer.Key));
            end
            rebuildTimers = true;
        else
            --Flag a rebuild if timers have any expired members..
            local duration = timer.Targets[1].Expiration - os.clock();
            if ((duration * -1) > gSettings.Debuff.CompletionDuration) then
                for _,player in ipairs(timer.Targets) do
                    duration = player.Expiration - os.clock();
                    if ((duration * -1) > gSettings.Debuff.CompletionDuration) then
                        player.Delete = true;
                    end
                end
                rebuildTimers = true;
            end
        end
    end

    --Clear buffs and members..
    for key,buffData in pairs(buffsByAction) do
        local memberRemains = false;
        for id,player in pairs(buffData.Targets) do
            if (player.Delete) then
                buffData.Targets[id] = nil;
                rebuildTimers = true;
            else
                memberRemains = true;
            end
        end
        if not memberRemains then
            buffsByAction[key] = nil;
            rebuildTimers = true;
        end
    end

    --Clear entries from player table..
    for id,buffTable in pairs(buffsByTarget) do
        buffsByTarget[id] = buffTable:filteri(function(v)
            local myEntry = v.Targets[id];
            return (myEntry) and (myEntry.Delete ~= true);
        end);
    end
end

local function CreateTimer(buffData)
    local targetArray = T{};
    for playerId,data in pairs(buffData.Targets) do
        targetArray:append(data);
    end

    table.sort(targetArray, function(a,b)
        if (a.Expiration == b.Expiration) then
            return a.Name < b.Name;
        end
        return (a.Expiration < b.Expiration);
    end);


    local toolTipText;
    if (targetArray[2]) then
        toolTipText = '';
        for _,entry in ipairs(targetArray) do
            local timeRemaining = math.max(entry.Expiration - os.clock(), 0);
            local newLine = string.format('%s%-20s %s', (toolTipText == '') and '' or '\n', entry.Name, TimeToString(timeRemaining));
            toolTipText = toolTipText .. newLine;
        end
    end

    local count = #targetArray;
    local shortest = targetArray[1];
    
    local timerData = {};
    timerData.Creation = shortest.Creation;
    timerData.TotalDuration = shortest.Duration;
    timerData.Expiration = shortest.Expiration;
    timerData.Duration = math.max(timerData.Expiration - os.clock(), 0);
    timerData.Icon = buffData.Icon;
    if (count > 1) then
        timerData.Label = string.format('%s[%s+%u]', buffData.Name, shortest.Name, count-1);
    else
        timerData.Label = string.format('%s[%s]', buffData.Name, shortest.Name);
    end
    timerData.Local = {};
    timerData.Targets = targetArray;
    timerData.Key = buffData.Key;
    timerData.Tooltip = toolTipText;
    activeTimers:append(timerData);
end

local function CreateSplitTimers(buffData)
    local timers = T{};
    for id,target in pairs(buffData.Targets) do
        local targetTimer;
        for _,timer in ipairs(timers) do
            if (math.abs(timer.Expiration - target.Expiration) < 2) then
                targetTimer = timer;
                break;
            end
        end
        if not targetTimer then
            targetTimer = {
                BuffId = buffData.BuffId,
                Icon = buffData.Icon,
                Expiration = target.Expiration,
                Name = buffData.Name,
                Key = buffData.Key,
                Targets = {},
            };
            timers:append(targetTimer);
        end
        targetTimer.Targets[id] = target;
    end
    for _,timer in ipairs(timers) do
        CreateTimer(timer);
    end
end

--Split out all buff timers by resource key, then sort them out into new timers.
local function RebuildTimers(splitByDuration)
    activeTimers = T{};

    for key,buffData in pairs(buffsByAction) do
        if (gSettings.Debuff.Blocked[key] == nil) then
            if splitByDuration then
                CreateSplitTimers(buffData);
            else
                CreateTimer(buffData);
            end
        end
    end
end

local function UpdateTimer(timerData)
    timerData.Duration = math.max(timerData.Expiration - os.clock(), 0);
    if (timerData.Targets[2]) then
        local toolTipText = '';
        for _,entry in ipairs(timerData.Targets) do
            local timeRemaining = math.max(entry.Expiration - os.clock(), 0);
            local newLine = string.format('%s%-20s %s', (toolTipText == '') and '' or '\n', entry.Name, TimeToString(timeRemaining));
            toolTipText = toolTipText .. newLine;
        end
        timerData.Tooltip = toolTipText;
    else
        timerData.Tooltip = nil;
    end
end


local exports = {};

function exports:ToggleBlueDebug()
    if blueDebugEnabled then
        pcall(LogBlueDebugSummary, 'stop');
        pcall(WriteBlueDebug, 'STOP');
        ClearUncertainDebuffs();
        local path = blueDebugPath;
        CloseBlueDebug();
        return false, path;
    end

    local timestamp = os.date('%Y%m%d-%H%M%S');
    local directory = string.format('%sconfig/addons/%s/logs/', AshitaCore:GetInstallPath(), addon.name);
    if not ashita.fs.exists(directory) then
        local createDirectory = ashita.fs.create_directory or ashita.fs.create_dir;
        if type(createDirectory) == 'function' then
            createDirectory(directory);
        end
    end
    if not ashita.fs.exists(directory) then
        return nil, directory;
    end

    for suffix = 0,99 do
        local name = suffix == 0
            and string.format('blu-debug-%s.log', timestamp)
            or string.format('blu-debug-%s-%u.log', timestamp, suffix);
        blueDebugPath = directory .. name;
        if not ashita.fs.exists(blueDebugPath) then
            blueDebugFile = io.open(blueDebugPath, 'w');
            if blueDebugFile then
                break
            end
        end
    end

    if not blueDebugFile then
        blueDebugPath = directory .. string.format('blu-debug-%s-overflow.log', timestamp);
        blueDebugFile = io.open(blueDebugPath, 'w');
    end

    if not blueDebugFile then
        return nil, blueDebugPath;
    end

    blueDebugStartedAt = os.clock();
    ClearBlueDebugContext(true);
    blueDebugEnabled = true;
    local success, err = pcall(WriteBlueDebug,
        string.format('START addon_version=%s capture_version=10', tostring(addon.version)));
    if not success then
        local path = blueDebugPath;
        CloseBlueDebug();
        return nil, string.format('%s (%s)', path, tostring(err));
    end
    return true, blueDebugPath;
end

ashita.events.register('unload', 'debuff_tracker_bludebug_unload', function ()
    if blueDebugEnabled then
        pcall(LogBlueDebugSummary, 'unload');
        pcall(WriteBlueDebug, 'STOP reason=unload');
        ClearUncertainDebuffs();
    end
    CloseBlueDebug();
end);

local lastSetting;
function exports:Tick()
    ClearDeletedTimers();

    if (rebuildTimers) or (gSettings.Debuff.SplitByDuration ~= lastSetting) then
        lastSetting = gSettings.Debuff.SplitByDuration;
        RebuildTimers(lastSetting);
        rebuildTimers = false;
    else
        for _,timerData in ipairs(activeTimers) do
            UpdateTimer(timerData);
        end
    end
    
    return activeTimers;
end

return exports;