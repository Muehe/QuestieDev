QuestieDB = {...}

function QuestieDB:Initialize()
  QuestieDBZone:zoneCreateConvertion()
  QuestieDB:deleteFaction()
  QuestieDB:deleteClasses()
  --QuestieDB:pruneQuests()
end

function QuestieDB:ItemLookup(ItemId)
  itemName, itemLink = GetItemInfo(ItemId)
  Item = {}
  Item.Name = itemName
  Item.Link = itemLink
  return Item
end

QuestieDB._QuestCache = {}; -- stores quest objects so they dont need to be regenerated
QuestieDB._ItemCache = {};
QuestieDB._NPCCache = {};
QuestieDB._ObjectCache = {};
function QuestieDB:GetObject(ObjectID)
  if ObjectID == nil then
    return nil
  end
  if QuestieDB._ObjectCache[ObjectID] ~= nil then
    return QuestieDB._ObjectCache[ObjectID];
  end
  local raw = objData[ObjectID];
  if raw ~= nil then
    local obj = {};
	obj.Name = raw[1];
	obj.Spawns = raw[4];
	QuestieDB._ObjectCache[ObjectID] = obj;
	return obj;
  else
	Questie:Debug(DEBUG_SPAM, "[QuestieQuest]: Missing container ", ObjectID)
  end
end
function QuestieDB:GetItem(ItemID)
  if ItemID == nil then
    return nil
  end
  if QuestieDB._ItemCache[ItemID] ~= nil then
    return QuestieDB._ItemCache[ItemID];
  end
  local item = {};
  local raw = CHANGEME_Questie4_ItemDB[ItemID]; -- TODO: use the good item db, I need to talk to Muehe about the format, this is a temporary fix
  if raw ~= nil then
    item.Id = ItemID;
	item.Name = raw[1];
	item.Sources = {};
	for k,v in pairs(raw[3]) do -- droppedBy = 3, relatedQuests=2, containedIn=4
	  local source = {};
	  source.Type = "monster";
	  source.Id = v;
	  table.insert(item.Sources, source);
	end
	for k,v in pairs(raw[4]) do -- droppedBy = 3, relatedQuests=2, containedIn=4
	  local source = {};
	  source.Type = "object";
	  source.Id = v;
	  table.insert(item.Sources, source);
	end
  end
  QuestieDB._ItemCache[ItemID] = item;
  return item
end

function QuestieDB:GetQuest(QuestID)
  if QuestID == nil then
    return nil
  end
  if QuestieDB._QuestCache[QuestID] ~= nil then
    return QuestieDB._QuestCache[QuestID];
  end
  --[[ 	[916] = {"Webwood Venom",{{2082,},nil,nil,},{{2082,},nil,},3,4,"A",nil,nil,nil,{nil,nil,{{5166,nil},},},nil,nil,nil,nil,nil,nil,},
  --key
  --name = 1
  --starts = 2
  --npc = starts1
  --obj = starts2
  --itm = starts3
  --ends = 3
  --npc = ends1
  --obj = ends2
  --minLevel = 4
  --level = 5
  --RequiredRaces = 6
  --RequiredClasses = 7
  --objectives = 8
  --trigger = 9
  --ReqCreatureOrGOOrItm = 10
  --npc = ReqCreatureOrGOOrItm1
  --obj = ReqCreatureOrGOOrItm2
  --itm = ReqCreatureOrGOOrItm3
  --SrcItemId = 11
  -- 12 DB_PRE_QUEST_GROUP
  -- 13 DB_PRE_QUEST_SINGLE
  -- 14 DB_SUB_QUESTS
  -- 15 DB_QUEST_GROUP
  -- 16 DB_EXCLUSIVE_QUEST_GROUP]]--
  rawdata = qData[QuestID] -- shouldnt rawdata be local
  if(rawdata)then
    QO = {}
    QO.Id = QuestID --Key
    QO.Name = rawdata[1] --Name - 1
    QO.Starts = {} --Starts - 2
    QO.Starts["NPC"] = rawdata[2][1] --2.1
    QO.Starts["GameObject"] = rawdata[2][2] --2.2
    QO.Starts["Item"] = rawdata[2][3] --2.3
    QO.Ends = {} --ends 3
    --QO.Ends["NPC"] = rawdata[3][1]
    --QO.Ends["GameObject"] = rawdata[3][2]

	--[4495] = {"A Good Friend",{{8583,},nil,nil,},{{8584,},nil,}
	--QO.Finisher = {};
	-- reorganize to match wow api
	if rawdata[3][1] ~= nil then
	  for k,v in pairs(rawdata[3][1]) do
	    --if _v ~= nil then
	      --for k,v in pairs(_v) do
	        if v ~= nil then
	          local obj = {};
		      obj.Type = "monster"
		      obj.Id = v

			  -- this speeds up lookup
			  obj.Name = npcData[v]
			  if obj.Name ~= nil then
			    obj.Name = string.lower(obj.Name[1]);
			  end

		      QO.Finisher = obj; -- there is only 1 finisher --table.insert(QO.Finisher, obj);
		    end
		  --end
		--end
	  end
	end
	if rawdata[3][2] ~= nil then
	  for k,v in pairs(rawdata[3][2]) do
	    --if _v ~= nil then
	      --for k,v in pairs(_v) do
	        if v ~= nil then
	          local obj = {};
		      obj.Type = "object"
		      obj.Id = v

			  -- this speeds up lookup
			  obj.Name = objData[v]
			  if obj.Name ~= nil then
			    obj.Name = string.lower(obj.Name[1]);
			  end

		      QO.Finisher = obj; -- there is only 1 finisher
		    end
		  --end
		--end
	  end
	end



    QO.MinLevel = rawdata[4]
    QO.Level = rawdata[5]
    QO.RequiredRaces = rawdata[6]
    QO.RequiredClasses = rawdata[7]
    QO.ObjectiveText = rawdata[8]
    QO.Triggers = rawdata[9] --List of coordinates
    QO.ObjectiveData = {} -- to differentiate from the current quest log info
	--    type
    --String - could be the following things: "item", "object", "monster", "reputation", "log", or "event". (from wow api)

	if QO.Triggers ~= nil then
	  for k,v in pairs(QO.Triggers) do
	      local obj = {};
		  obj.Type = "event"
		  obj.Coordinates = v
		  table.insert(QO.ObjectiveData, obj);
	  end
	end

	if rawdata[10][1] ~= nil then
	  for _k,_v in pairs(rawdata[10][1]) do
	    if _v ~= nil then
	      for k,v in pairs(_v) do
	        if v ~= nil then
	          local obj = {};
		      obj.Type = "monster"
		      obj.Id = v

			  -- this speeds up lookup
			  obj.Name = npcData[v]
			  if obj.Name ~= nil then
			    obj.Name = string.lower(obj.Name[1]);
			  end

		      table.insert(QO.ObjectiveData, obj);
		    end
		  end
		end
	  end
	end
	if rawdata[10][2] ~= nil then
	  for _k,_v in pairs(rawdata[10][2]) do
	    if _v ~= nil then
	      for k,v in pairs(_v) do
	        if v ~= nil then
	          local obj = {};
		      obj.Type = "object"
		      obj.Id = v

			  obj.Name = objData[v]
			  if obj.Name ~= nil then
			    obj.Name = string.lower(obj.Name[1]);
			  end

		      table.insert(QO.ObjectiveData, obj);
		    end
		  end
		end
	  end
	end
	if rawdata[10][3] ~= nil then
	  for _k,_v in pairs(rawdata[10][3]) do
	    if _v ~= nil then
	      for k,v in pairs(_v) do
	        if v ~= nil then
	          local obj = {};
		      obj.Type = "item"
		      obj.Id = v

			  obj.Name = CHANGEME_Questie4_ItemDB[v]
			  if obj.Name ~= nil then
			    obj.Name = string.lower(obj.Name[1]);
			  end

		      table.insert(QO.ObjectiveData, obj);
		    end
		  end
		end
	  end
	end
    --QO.Objectives["NPC"] = rawdata[10][1] --{NPCID, Different name of NPC or object}
    --QO.Objectives["GameObject"] = rawdata[10][2] --{GOID, Different name of NPC or object}
    --QO.Objectives["Item"] = rawdata[10][3]
    --QO.SrcItemId = rawdata[11] --A quest item given by a questgiver of some kind.
    if(rawdata[12] ~= nil and rawdata[13] ~= nil) then
      Questie:Debug(DEBUG_CRITICAL, "ERRRRORRRRRRR not mutually exclusive!")
    end
    if(rawdata[12] ~= nil) then
      QO.RequiredQuest = rawdata[12]
    else
      QO.RequiredQuest = rawdata[13]
    end
	if questRequirementFixes[QuestID] ~= nil then
	  QO.RequiredQuest = questRequirementFixes[QuestID]
	end
    QO.SubQuests = rawdata[14] --Quests that give questitems that are used in later quests (See STV manual)
    QO.QuestGroup = rawdata[15] --Quests that are part of the same group, example complete this group of quests to open the next one.
    QO.ExclusiveQuestGroup = rawdata[16]
    QuestieDB._QuestCache[QuestID] = QO
    return QO
  else
    return nil
  end
end

function QuestieDB:GetNPC(NPCID)
  if NPCID == nil then
    return nil
  end
  --[key] = {1 Name,2 minHP,3 maxHP,4 minLevel,5 maxLevel,6 rank,7 spawns,8 waypoint,9 zone, 10 starts, 11 ends},

  if(QuestieDB._NPCCache[NPCID]) then
    return QuestieDB._NPCCache[NPCID]
  end
  rawdata = npcData[NPCID]
  if(rawdata)then
    NPC = {}
    NPC.Type = "NPC" --This can be used to look at which type it is, Gameobject and Items will have the same! (should be monster to match wow api)
    NPC.Id = NPCID
    NPC.Name = rawdata[DB_NAME]
    NPC.MinHealth = rawdata[DB_MIN_LEVEL_HEALTH]
    NPC.MaxHealth = rawdata[DB_MAX_LEVEL_HEALTH]
    NPC.MinLevel = rawdata[DB_MIN_LEVEL]
    NPC.MaxLevel = rawdata[DB_LEVEL]
    NPC.Rank = rawdata[DB_RANK]
    NPC.Spawns = rawdata[DB_NPC_SPAWNS]
    NPC.Waypoints = rawdata[DB_NPC_WAYPOINTS]
    NPC.Starts = rawdata[DB_NPC_STARTS]
    NPC.Ends = rawdata[DB_NPC_ENDS]
    QuestieDB._NPCCache[NPCID] = NPC
    return NPC
  else
    return nil
  end
end
-- DB keys
DB_NAME, DB_NPC, NOTE_TITLE = 1, 1, 1;
DB_STARTS, DB_OBJ, NOTE_COMMENT, DB_MIN_LEVEL_HEALTH = 2, 2, 2, 2;
DB_ENDS, DB_ITM, NOTE_ICON, DB_MAX_LEVEL_HEALTH = 3, 3, 3, 3;
DB_MIN_LEVEL, DB_ZONES, DB_VENDOR, DB_OBJ_SPAWNS, DB_TRIGGER_MARKED = 4, 4, 4, 4, 4;
DB_LEVEL, DB_ITM_QUEST_REW = 5, 5;
DB_REQ_RACE, DB_RANK, DB_ITM_NAME = 6, 6, 6;
DB_REQ_CLASS, DB_NPC_SPAWNS = 7, 7;
DB_OBJECTIVES, DB_NPC_WAYPOINTS = 8, 8;
DB_TRIGGER, DB_ZONE = 9, 9;
DB_REQ_NPC_OR_OBJ_OR_ITM, DB_NPC_STARTS = 10, 10;
DB_SRC_ITM, DB_NPC_ENDS = 11, 11;
DB_PRE_QUEST_GROUP = 12;
DB_PRE_QUEST_SINGLE = 13;
DB_SUB_QUESTS = 14;
DB_QUEST_GROUP = 15;
DB_EXCLUSIVE_QUEST_GROUP = 16;


---------------------------------------------------------------------------------------------------
-- Returns the Levenshtein distance between the two given strings
-- credit to https://gist.github.com/Badgerati/3261142
function QuestieDB:Levenshtein(str1, str2)
    local len1 = string.len(str1)
    local len2 = string.len(str2)
    local matrix = {}
    local cost = 0
    -- quick cut-offs to save time
    if (len1 == 0) then
        return len2
    elseif (len2 == 0) then
        return len1
    elseif (str1 == str2) then
        return 0
    end
    -- initialise the base matrix values
    for i = 0, len1, 1 do
        matrix[i] = {}
        matrix[i][0] = i
    end
    for j = 0, len2, 1 do
        matrix[0][j] = j
    end
    -- actual Levenshtein algorithm
    for i = 1, len1, 1 do
        for j = 1, len2, 1 do
            if (string.byte(str1,i) == string.byte(str2,j)) then
                cost = 0
            else
                cost = 1
            end
            matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
        end
    end
    -- return the last value - this is the Levenshtein distance
    return matrix[len1][len2]
end

--Deletes opposite factions quests, saves time!
function QuestieDB:deleteFaction()
    englishFaction, _ = UnitFactionGroup("player")
    local fac = ""
    if(englishFaction == "Alliance") then
      fac = "A"
    else
      fac = "H"
    end
    for key, data in pairs(qData) do
        if (data[DB_REQ_RACE] ~= "AH") and (data[DB_REQ_RACE] ~= fac) then
            qData[key] = nil;
        end
    end
    Questie:Debug(DEBUG_DEVELOP, "Opposite factions quests deleted");
end

function QuestieDB:deleteClasses()
    localizedClass, englishClass, classIndex = UnitClass("player");
    local classes = {"Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Death Knight", "Shaman", "Mage", "Warlock", "Druid"};
    local playerClass = false;
    for key, name in pairs(classes) do
        if string.upper(name) == englishClass then
            Questie:Debug(DEBUG_DEVELOP, "Identified class as : ", name, "/", englishClass);
            playerClass = key - 1;
        end
    end
    if playerClass then
        for key, data in pairs(qData) do
            if data[DB_REQ_CLASS] then
                local found = false;
                for k, class in pairs(data[DB_REQ_CLASS]) do
                    if class == playerClass then
                        found = true;
                    end
                end
                if not found then
                    qData[key] = nil;
                end
            end
        end
    end
    Questie:Debug(DEBUG_DEVELOP, "Other class quests deleted");
end

questRequirementFixes = {
  [46] = {39},
  [3903] = {18},
  [33] = {783}
}

qHide = {
  --Stray quests
  [3861] = true, --CLUCK!
  --World event quests
  --Fetched from https://classic.wowhead.com/world-event-quests
  [7904] = true,
  [8571] = true,
  [7930] = true,
  [7931] = true,
  [7935] = true,
  [7932] = true,
  [7933] = true,
  [7934] = true,
  [7936] = true,
  [7981] = true,
  [7940] = true,
  [8744] = true,
  [8803] = true,
  [8768] = true,
  [8788] = true,
  [8767] = true,
  [9319] = true,
  [9386] = true,
  [7045] = true,
  [6984] = true,
  [9365] = true,
  [9339] = true,
  [8769] = true,
  [171] = true,
  [5502] = true,
  [7885] = true,
  [8647] = true,
  [7892] = true,
  [8715] = true,
  [8719] = true,
  [8718] = true,
  [8673] = true,
  [8726] = true,
  [8866] = true,
  [925] = true,
  [7881] = true,
  [7882] = true,
  [8353] = true,
  [8354] = true,
  [172] = true,
  [1468] = true,
  [8882] = true,
  [8880] = true,
  [7889] = true,
  [7894] = true,
  [1658] = true,
  [7884] = true,
  [8357] = true,
  [8360] = true,
  [8648] = true,
  [8677] = true,
  [7907] = true,
  [7906] = true,
  [7929] = true,
  [7927] = true,
  [7928] = true,
  [8683] = true,
  [910] = true,
  [8684] = true,
  [8868] = true,
  [8862] = true,
  [7903] = true,
  [8727] = true,
  [8863] = true,
  [8864] = true,
  [8865] = true,
  [8878] = true,
  [8877] = true,
  [8356] = true,
  [8359] = true,
  [9388] = true,
  [9389] = true,
  [911] = true,
  [8222] = true,
  [8653] = true,
  [8652] = true,
  [6961] = true,
  [7021] = true,
  [7024] = true,
  [7022] = true,
  [7023] = true,
  [7896] = true,
  [7891] = true,
  [8679] = true,
  [8311] = true,
  [8312] = true,
  [8646] = true,
  [7890] = true,
  [8686] = true,
  [8643] = true,
  [8149] = true,
  [8150] = true,
  [8355] = true,
  [8358] = true,
  [8651] = true,
  [558] = true,
  [8881] = true,
  [8879] = true,
  [1800] = true,
  [8867] = true,
  [8722] = true,
  [7897] = true,
  [8762] = true,
  [8746] = true,
  [8685] = true,
  [8714] = true,
  [8717] = true,
  [7941] = true,
  [7943] = true,
  [7939] = true,
  [8223] = true,
  [7942] = true,
  [8619] = true,
  [8724] = true,
  [8861] = true,
  [8860] = true,
  [8723] = true,
  [8645] = true,
  [8654] = true,
  [8678] = true,
  [8671] = true,
  [7893] = true,
  [8725] = true,
  [8322] = true,
  [8409] = true,
  [8636] = true,
  [8670] = true,
  [8642] = true,
  [8675] = true,
  [8720] = true,
  [8682] = true,
  [7899] = true,
  [8876] = true,
  [8650] = true,
  [7901] = true,
  [7946] = true,
  [8635] = true,
  [1687] = true,
  [8716] = true,
  [8713] = true,
  [8721] = true,
  [9332] = true,
  [9331] = true,
  [9324] = true,
  [9330] = true,
  [9326] = true,
  [9325] = true,
  [1657] = true,
  [7042] = true,
  [6963] = true,
  [8644] = true,
  [8672] = true,
  [8649] = true,
  [1479] = true,
  [7063] = true,
  [7061] = true,
  [9368] = true,
  [9367] = true,
  [8763] = true,
  [8799] = true,
  [8873] = true,
  [8874] = true,
  [8875] = true,
  [8870] = true,
  [8871] = true,
  [8872] = true,
  [8373] = true,
  [7062] = true,
  [6964] = true,
  [1558] = true,
  [7883] = true,
  [7898] = true,
  [8681] = true,
  [7900] = true,
  [6962] = true,
  [7025] = true,
  [8883] = true,
  [7902] = true,
  [7895] = true,
  [9322] = true,
  [9323] = true,
  [8676] = true,
  [8688] = true,
  [8680] = true,
  [8828] = true,
  [8827] = true,
  [8674] = true,
  [915] = true,
  [4822] = true,
  [7043] = true,
  [6983] = true,
  [7937] = true,
  [7938] = true,
  [7944] = true,
  [7945] = true,
  --Commendation Signet
  [8811] = true,
  [8820] = true,
  [8843] = true,
  [8841] = true,
  [8839] = true,
  [8837] = true,
  [8835] = true,
  [8833] = true,
  [8831] = true,
  [8826] = true,
  [8825] = true,
  [8824] = true,
  [8823] = true,
  [8822] = true,
  [8821] = true,
  [8819] = true,
  [8812] = true,
  [8844] = true,
  [8842] = true,
  [8840] = true,
  [8838] = true,
  [8836] = true,
  [8834] = true,
  [8832] = true,
  [8830] = true,
  [8818] = true,
  [8817] = true,
  [8816] = true,
  [8815] = true,
  [8814] = true,
  [8813] = true,
  [8845] = true,
  --love is in the air
  [8903] = true,
  [8904] = true,
  [8897] = true,
  [8898] = true,
  [8899] = true,
  --Rocknot's Ale instance quest shown in SG/BS at lvl 1
  [4295] = true,
  --The Gordok Ogre Suit dire maul isntance quest
  [5518] = true,
  [5519] = true,
  --aq40 raid quest
  [8595] = true,
  [8579] = true,
  --weekly fish tourney
  [8225] = true,
  [8221] = true,
  [8224] = true,
  [8225] = true,
  [8193] = true,
  [8226] = true,
  --Zinge's Assessment
  [8980] = true,
  --mount exchange/replacement
  [7678] = true,
  [7677] = true,
  [7673] = true,
  [7674] = true,
  [7671] = true,
  [7665] = true,
  [7675] = true,
  [7664] = true,
  [7672] = true,
  [7676] = true,
  --Wool/Silk/Mageweave/Runecloth donation
  [7791] = true,
  [7808] = true,
  [7835] = true,
  [7834] = true,
  [7831] = true,
  [7827] = true,
  [7824] = true,
  [7823] = true,
  [7822] = true,
  [7821] = true,
  [7818] = true,
  [7817] = true,
  [7814] = true,
  [7811] = true,
  [7809] = true,
  [7805] = true,
  [7792] = true,
  [7804] = true,
  [7803] = true,
  [7800] = true,
  [7799] = true,
  [7798] = true,
  [7795] = true,
  [7794] = true,
  [7793] = true,
  [7833] = true,
  [7826] = true,
  [7820] = true,
  [7813] = true,
  [7807] = true,
  [7802] = true,
  [7836] = true,
  --The Alliance Needs Your Help! shown for horde (aq40 quest in city. Maybe not needed?)
  [8795] = true,
  [8796] = true,
  [8797] = true,
  --Love Song for Narain //- Deep AQ scepter chain. Shown for all at 60
  [8599] = true,
  --Darkmoon Faire
  [7905] = true,
  [7926] = true,
  --Steamwheedle / Bloodsail reputation quests
  [9266] = true,
  [9259] = true,
  [9267] = true,
  [9272] = true,
  [1036] = true,
  [4621] = true,
  --fishing tournament
  [8194] = true,
  [8193] = true,
  [8221] = true,
  [8224] = true,
  [8225] = true,
  [8193] = true,
  [8226] = true,
  [8228] = true,
  [8229] = true,
  --love is in the air
  [8982] = true,
  [9026] = true,
  [8983] = true,
  [9027] = true,
  [8900] = true,
  [8901] = true,
  [8902] = true,
  [9024] = true,
  [9025] = true,
  [8979] = true,
  --mount replacement
  [7662] = true,
  [7663] = true,
  [7660] = true,
  [7661] = true,
  --tier 0.5 bracers turn in
  [8905] = true,
  [8906] = true,
  [8907] = true,
  [8908] = true,
  [8909] = true,
  [8910] = true,
  [8911] = true,
  [8912] = true,
  [8913] = true,
  [8914] = true,
  [8915] = true,
  [8916] = true,
  [8917] = true,
  [8918] = true,
  [8919] = true,
  [8920] = true,
  --PvP Warsong Gulch. Slay alliance/ slay horde shown for both alliance and horde
  [8290] = true,
  [7788] = true,
  [7871] = true,
  [7872] = true,
  [7873] = true,
  [8291] = true,
  [8295] = true,
  [7789] = true,
  [7874] = true,
  [7875] = true,
  [7876] = true,
  [8294] = true,
  --Brood of Nozdormu aq40 rep epic ring quest.
  [8747] = true,
  [8748] = true,
  [8749] = true,
  [8750] = true,
  [8752] = true,
  [8753] = true,
  [8754] = true,
  [8755] = true,
  [8757] = true,
  [8758] = true,
  [8759] = true,
  [8760] = true,
  --Profession quests
  [7652] = true,
  [2771] = true,
  [6625] = true,
  [8194] = true,
  [2751] = true,
  [384] = true,
  [2757] = true,
  [6610] = true,
  [5307] = true,
  [8307] = true,
  [3321] = true,
  [862] = true,
  [5141] = true,
  [5145] = true,
  [2178] = true,
  [1580] = true,
  [5144] = true,
  [5146] = true,
  [1581] = true,
  [7649] = true,
  [7650] = true,
  [7651] = true,
  [2765] = true,
  [1559] = true,
  [1579] = true,
  [2764] = true,
  [1618] = true,
  [3630] = true,
  [3632] = true,
  [3634] = true,
  [3635] = true,
  [3637] = true,
  [3526] = true,
  [3629] = true,
  [3633] = true,
  [4181] = true,
  [6623] = true,
  [2754] = true,
  [5103] = true,
  [6609] = true,
  [6612] = true,
  [7653] = true,
  [7654] = true,
  [7655] = true,
  [7656] = true,
  [7657] = true,
  [7658] = true,
  [7659] = true,
  [2759] = true,
  [2755] = true,
  [8317] = true,
  [8193] = true,
  [2853] = true,
  [2860] = true,
  [3644] = true,
  [3645] = true,
  [3646] = true,
  [3647] = true,
  [1582] = true,
  [6607] = true,
  [2752] = true,
  [8225] = true,
  [8224] = true,
  [8221] = true,
  [4161] = true,
  [866] = true,
  [3379] = true,
  [8313] = true,
  [3639] = true,
  [3641] = true,
  [3643] = true,
  [2761] = true,
  [5306] = true,
  [7321] = true,
  [1578] = true,
  [5305] = true,
  [5283] = true,
  [5301] = true,
  [2763] = true,
  [2762] = true,
  [2773] = true,
  [2760] = true,
  [2756] = true,
  [2758] = true,
  [3638] = true,
  [3640] = true,
  [3642] = true,
  [3385] = true,
  [3402] = true,
  [5284] = true,
  [5302] = true,
  [2772] = true,
  [6611] = true,
  [2753] = true,
  [6622] = true,
  [6624] = true,
  [5143] = true,
  [5148] = true,
  [2847] = true,
  [2854] = true,
  [2851] = true,
  [2858] = true,
  [2850] = true,
  [2857] = true,
  [2852] = true,
  [2859] = true,
  [2848] = true,
  [2855] = true,
  [2849] = true,
  [2856] = true,
  [6608] = true,
  [90] = true, --Seasoned Wolf Kabobs Unsure if this is a profession quest.
  --All PVP Quests
  [7385] = true,
  [7362] = true,
  [7081] = true,
  [8080] = true,
  [8154] = true,
  [8155] = true,
  [8156] = true,
  [8297] = true,
  [8262] = true,
  [8260] = true,
  [8261] = true,
  [7223] = true,
  [8368] = true,
  [8389] = true,
  [8426] = true,
  [8427] = true,
  [8428] = true,
  [8429] = true,
  [8430] = true,
  [8431] = true,
  [8432] = true,
  [8433] = true,
  [8434] = true,
  [8435] = true,
  [6846] = true,
  [7281] = true,
  [7282] = true,
  [6825] = true,
  [6943] = true,
  [6826] = true,
  [6827] = true,
  [6942] = true,
  [6941] = true,
  [7122] = true,
  [7124] = true,
  [8374] = true,
  [8391] = true,
  [8392] = true,
  [8393] = true,
  [8394] = true,
  [8395] = true,
  [8396] = true,
  [8397] = true,
  [8398] = true,
  [5893] = true,
  [6982] = true,
  [8371] = true,
  [8385] = true,
  [8370] = true,
  [8390] = true,
  [8436] = true,
  [8437] = true,
  [8439] = true,
  [8440] = true,
  [8441] = true,
  [8442] = true,
  [8443] = true,
  [8115] = true,
  [8114] = true,
  [7386] = true,
  [8123] = true,
  [8160] = true,
  [8161] = true,
  [8162] = true,
  [8299] = true,
  [7421] = true,
  [8265] = true,
  [8263] = true,
  [8264] = true,
  [7367] = true,
  [7368] = true,
  [7165] = true,
  [7170] = true,
  [7001] = true,
  [7027] = true,
  [7224] = true,
  [7301] = true,
  [7302] = true,
  [7361] = true,
  [8372] = true,
  [8386] = true,
  [8399] = true,
  [8400] = true,
  [8401] = true,
  [8402] = true,
  [8403] = true,
  [8404] = true,
  [8405] = true,
  [8406] = true,
  [8407] = true,
  [8408] = true,
  [8367] = true,
  [8388] = true,
  [7364] = true,
  [8272] = true,
  [8271] = true,
  [7164] = true,
  [7169] = true,
  [7423] = true,
  [7241] = true,
  [8369] = true,
  [5892] = true,
  [6985] = true,
  [6881] = true,
  [7202] = true,
  [7382] = true,
  [6901] = true,
  [7166] = true,
  [7171] = true,
  [6801] = true,
  [7922] = true,
  [7923] = true,
  [7924] = true,
  [7925] = true,
  [8293] = true,
  [6847] = true,
  [6848] = true,
  [6781] = true,
  [6741] = true,
  [8081] = true,
  [8124] = true,
  [8157] = true,
  [8158] = true,
  [8159] = true,
  [8163] = true,
  [8164] = true,
  [8165] = true,
  [8298] = true,
  [8300] = true,
  [7426] = true,
  [7161] = true,
  [7162] = true,
  [7789] = true,
  [7874] = true,
  [7875] = true,
  [7876] = true,
  [8294] = true,
  [7002] = true,
  [7026] = true,
  [8266] = true,
  [8267] = true,
  [8268] = true,
  [8269] = true,
  [7163] = true,
  [7168] = true,
  [7123] = true,
  [7425] = true,
  [7365] = true,
  [8122] = true,
  [8121] = true,
  [7886] = true,
  [7887] = true,
  [7888] = true,
  [7921] = true,
  [8292] = true,
  [7366] = true,
  [7142] = true,
  [8105] = true,
  [8120] = true,
  [8166] = true,
  [8167] = true,
  [8168] = true,
  [8169] = true,
  [8170] = true,
  [8171] = true,
  [7141] = true,
  [7167] = true,
  [7172] = true,
  [7082] = true,
  [7363] = true,
  [7181] = true,
  [7121] = true,
  [7381] = true,
  [7261] = true,
  [7101] = true,
  [7102] = true,
  [7422] = true,
  [7788] = true,
  [7871] = true,
  [7872] = true,
  [7873] = true,
  [8291] = true,
  [7401] = true,
  [7427] = true,
  [7428] = true,
  [7402] = true,
  [7424] = true,
  [6861] = true,
  [6862] = true,
  [8001] = true,
  --More pvp quests ?? strange Ones
  [8387] = true,
  [8375] = true,
  [8383] = true,
  [8438] = true,
  [8384] = true,
  [7863] = true,
  [7864] = true,
  [7865] = true,
  [7866] = true,
  [7867] = true,
  [7868] = true,
}
