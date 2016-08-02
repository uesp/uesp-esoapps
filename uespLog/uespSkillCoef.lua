-- uespLogTradeData.lua -- by Dave Humphrey, dave@uesp.net
-- Code specific to mining skill coefficients.


uespLog.SkillCoefData = {}
uespLog.SkillCoefAbilityData = {}
uespLog.SkillCoefCalcData = {}
uespLog.SkillCoefBadData = {}
uespLog.SkillCoefSavedIds = {}
uespLog.SkillCoefAbilityCount = 0
uespLog.SkillCoefNumValidCoefCount = 0
uespLog.SkillCoefNumBadCoefCount = 0
uespLog.SkillCoefDataPointCount = 0
uespLog.SkillCoefDataIsCalculated = false

uespLog.SkillCoef_CaptureWykkyd_Prefix = "SkillCoef"
uespLog.SkillCoef_CaptureWykkyd_StartIndex = 1
uespLog.SkillCoef_CaptureWykkyd_IsWorking = false
uespLog.SkillCoef_CaptureWykkyd_EndIndex = 5
uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = 5
uespLog.SkillCoef_CaptureWykkyd_TimeDelayLoadSet = 5000   -- Takes a while for skill data to 'settle' sometimes

uespLog.SkillCoefArmorCountLA = 0
uespLog.SkillCoefArmorCountMA = 0
uespLog.SkillCoefArmorCountHA = 0
uespLog.SkillCoefWeaponCountDagger = 0
uespLog.SkillCoefArmorTypeCount = 0

uespLog.UESP_POWERTYPE_SOULTETHER    = -50
uespLog.UESP_POWERTYPE_LIGHTARMOR    = -51
uespLog.UESP_POWERTYPE_MEDIUMARMOR   = -52
uespLog.UESP_POWERTYPE_HEAVYARMOR    = -53
uespLog.UESP_POWERTYPE_WEAPONDAGGER  = -54
uespLog.UESP_POWERTYPE_ARMORTYPE     = -55
uespLog.UESP_POWERTYPE_DAMAGE        = -56
uespLog.UESP_POWERTYPE_ASSASSINATION = -57

uespLog.SKILLCOEF_CHECK_ABILITYID = 28302
uespLog.SKILLCOEF_CHECK_INDEX = 2
uespLog.SKILLCOEF_CHECK_VALUE = 300

uespLog.SKILLCOEF_BADFIT_MINR2 = 0.99


uespLog.SKILLCOEF_MECHANIC_NAMES = {
	[POWERTYPE_ULTIMATE] = "Ultimate",
	[POWERTYPE_HEALTH] = "Health",
	[POWERTYPE_MAGICKA] = "Magicka",
	[POWERTYPE_STAMINA] = "Stamina",
	[uespLog.UESP_POWERTYPE_SOULTETHER] = "Ultimate (ignore WD)",
	[uespLog.UESP_POWERTYPE_LIGHTARMOR] = "Light Armor",
	[uespLog.UESP_POWERTYPE_MEDIUMARMOR] = "Medium Armor",
	[uespLog.UESP_POWERTYPE_HEAVYARMOR] = "Heavy Armor",
	[uespLog.UESP_POWERTYPE_WEAPONDAGGER] = "Daggers",
	[uespLog.UESP_POWERTYPE_ARMORTYPE] = "Armor Types",
	[uespLog.UESP_POWERTYPE_DAMAGE] = "Spell + Weapon Damage",
	[uespLog.UESP_POWERTYPE_ASSASSINATION] = "Assassination Skills Slotted",
}


-- Some skills have different mechanics that what the game data says
uespLog.SKILLCOEF_SPECIALTYPES = {

	-- NightBlade Grim Focus/Merciless Resolve/Relentless Focus
	-- Game mechanic says Magicka but main damage seems to work like an ultimate
	[61919] = POWERTYPE_ULTIMATE,
	[62111] = POWERTYPE_ULTIMATE,
	[62114] = POWERTYPE_ULTIMATE,
	[62117] = POWERTYPE_ULTIMATE,
	
	[61927] = POWERTYPE_ULTIMATE,
	[62099] = POWERTYPE_ULTIMATE,
	[62103] = POWERTYPE_ULTIMATE,
	[62107] = POWERTYPE_ULTIMATE,
	
	[61902] = POWERTYPE_ULTIMATE,
	[62090] = POWERTYPE_ULTIMATE,
	[64176] = POWERTYPE_ULTIMATE,
	[62096] = POWERTYPE_ULTIMATE,
	
	-- NightBlade Soul Shred/Soul Tether/Soul Siphon
	-- The health stealing portion seems to always use Spell Damage
	[25091] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36154] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36160] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36166] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	
	[35508] = { [6] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36172] = { [6] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36179] = { [6] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36186] = { [6] = uespLog.UESP_POWERTYPE_SOULTETHER },
	
	[35460] = { [5] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36193] = { [5] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36200] = { [5] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[36207] = { [5] = uespLog.UESP_POWERTYPE_SOULTETHER },
	
	-- Leeching Strikes
	[36908] = { [1] = POWERTYPE_MAGICKA, [2] = POWERTYPE_STAMINA, },
	[37989] = { [1] = POWERTYPE_MAGICKA, [2] = POWERTYPE_STAMINA, },
	[38002] = { [1] = POWERTYPE_MAGICKA, [2] = POWERTYPE_STAMINA, },
	[38015] = { [1] = POWERTYPE_MAGICKA, [2] = POWERTYPE_STAMINA, },
		
	-- 1H+Shield Absorb Magic
	-- Is a stamina ability but scales off of health
	[38317] = POWERTYPE_HEALTH,
	[41370] = POWERTYPE_HEALTH,
	[41375] = POWERTYPE_HEALTH,
	[41380] = POWERTYPE_HEALTH,
	
	-- Mages Guild Equilibrium/Spell Symmetry/Balance
	-- Are magicka abilities but scale off of health
	[31642] = POWERTYPE_HEALTH,
	[42247] = POWERTYPE_HEALTH,
	[42249] = POWERTYPE_HEALTH,
	[42251] = POWERTYPE_HEALTH,
	
	[40445] = POWERTYPE_HEALTH,
	[42253] = POWERTYPE_HEALTH,
	[42258] = POWERTYPE_HEALTH,
	[42263] = POWERTYPE_HEALTH,
	
	[40441] = POWERTYPE_HEALTH,
	[42268] = POWERTYPE_HEALTH,
	[42273] = POWERTYPE_HEALTH,
	[42278] = POWERTYPE_HEALTH,
	
	-- Undaunted Inner Fire/Inner Rage/Inner Beast
	-- Numbers 4/6 seem to work like ultimates
	[39475] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43353] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43358] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43363] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },

	[42060] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43383] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43388] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43393] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },

	[42056] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43368] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43373] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	[43378] = { [4] = POWERTYPE_ULTIMATE, [6] = POWERTYPE_ULTIMATE },
	
	-- Undaunted Necrotic Orb/Mystic Orb/Energy Orb
	-- Number 2 acts like an ultimate
	[39298] = { [2] = POWERTYPE_ULTIMATE },
	[43400] = { [2] = POWERTYPE_ULTIMATE },
	[43403] = { [2] = POWERTYPE_ULTIMATE },
	[43406] = { [2] = POWERTYPE_ULTIMATE },
	
	[42028] = { [2] = POWERTYPE_ULTIMATE },
	[43409] = { [2] = POWERTYPE_ULTIMATE },
	[43412] = { [2] = POWERTYPE_ULTIMATE },
	[43415] = { [2] = POWERTYPE_ULTIMATE },
	
	[42038] = { [2] = POWERTYPE_ULTIMATE },
	[43439] = { [2] = POWERTYPE_ULTIMATE },
	[43443] = { [2] = POWERTYPE_ULTIMATE },
	[43447] = { [2] = POWERTYPE_ULTIMATE },
	
	-- Undaunted Trapping Webs/Tangling Webs/Shadow Silk	
	-- Number 4 acts like an ultimate
	[39425] = { [4] = POWERTYPE_ULTIMATE },
	[43533] = { [4] = POWERTYPE_ULTIMATE },
	[43537] = { [4] = POWERTYPE_ULTIMATE },
	[43541] = { [4] = POWERTYPE_ULTIMATE },
	
	[42012] = { [4] = POWERTYPE_ULTIMATE },
	[43469] = { [4] = POWERTYPE_ULTIMATE },
	[43473] = { [4] = POWERTYPE_ULTIMATE },
	[43477] = { [4] = POWERTYPE_ULTIMATE },
	
	[41990] = { [4] = POWERTYPE_ULTIMATE },
	[43481] = { [4] = POWERTYPE_ULTIMATE },
	[43485] = { [4] = POWERTYPE_ULTIMATE },
	[43489] = { [4] = POWERTYPE_ULTIMATE },
	
	-- 1H & Shield Shielded Assault	
	-- Number 3 is based on health
	[38401] = { [3] = POWERTYPE_HEALTH },
	[41518] = { [3] = POWERTYPE_HEALTH },
	[41522] = { [3] = POWERTYPE_HEALTH },
	[41526] = { [3] = POWERTYPE_HEALTH },
	
	-- Fighters Guild Silver Shards/Silver Leash/Silver Bolts
	-- Its a stamina ability but number 4/5 scales on health
	--[40300] = { [1] = POWERTYPE_STAMINA },
	--[42659] = { [1] = POWERTYPE_HEALTH },
	--[42665] = { [1] = POWERTYPE_HEALTH },
	--[42671] = { [1] = POWERTYPE_HEALTH },

	--[40336] = { [1] = POWERTYPE_HEALTH },
	--[42677] = { [1] = POWERTYPE_HEALTH },
	--[42687] = { [1] = POWERTYPE_HEALTH },
	--[42696] = { [1] = POWERTYPE_HEALTH },
	
	--[35721] = { [4] = POWERTYPE_HEALTH },
	--[42647] = { [4] = POWERTYPE_HEALTH },
	--[42651] = { [4] = POWERTYPE_HEALTH },
	--[42655] = { [4] = POWERTYPE_HEALTH },
	
	-- Templar Repentance
	[26821] = { [2] = POWERTYPE_ULTIMATE, [3] = POWERTYPE_ULTIMATE },
	[27036] = { [2] = POWERTYPE_ULTIMATE, [3] = POWERTYPE_ULTIMATE },
	[27040] = { [2] = POWERTYPE_ULTIMATE, [3] = POWERTYPE_ULTIMATE },
	[27043] = { [2] = POWERTYPE_ULTIMATE, [3] = POWERTYPE_ULTIMATE },
	
	-- Templar Cleansing Ritual
	[22265] = { [5] = POWERTYPE_ULTIMATE },
	[27243] = { [5] = POWERTYPE_ULTIMATE },
	[27249] = { [5] = POWERTYPE_ULTIMATE },
	[27255] = { [5] = POWERTYPE_ULTIMATE },
	
	-- Templar Purifying Ritual/Ritual of Retribution
	[22259] = { [8] = POWERTYPE_ULTIMATE },
	[27261] = { [8] = POWERTYPE_ULTIMATE },
	[27269] = { [8] = POWERTYPE_ULTIMATE },
	[27275] = { [8] = POWERTYPE_ULTIMATE },
	
	-- Templar Extended Ritual
	[22262] = { [5] = POWERTYPE_ULTIMATE },
	[27281] = { [5] = POWERTYPE_ULTIMATE },
	[27288] = { [5] = POWERTYPE_ULTIMATE },
	[27295] = { [5] = POWERTYPE_ULTIMATE },
	
	-- Sorcerer Lightning Splash
	[23182] = { [3] = POWERTYPE_ULTIMATE },
	[30259] = { [3] = POWERTYPE_ULTIMATE },
	[30264] = { [3] = POWERTYPE_ULTIMATE },
	[30269] = { [3] = POWERTYPE_ULTIMATE },
	
	-- Sorcerer Liquid Lightning
	[23200] = { [3] = POWERTYPE_ULTIMATE },
	[30274] = { [3] = POWERTYPE_ULTIMATE },
	[30280] = { [3] = POWERTYPE_ULTIMATE },
	[30286] = { [3] = POWERTYPE_ULTIMATE },
	
	-- Sorcerer Lightning Flood
	[23205] = { [3] = POWERTYPE_ULTIMATE },
	[30292] = { [3] = POWERTYPE_ULTIMATE },
	[30297] = { [3] = POWERTYPE_ULTIMATE },
	[30302] = { [3] = POWERTYPE_ULTIMATE },
	
	-- Dragonknight Obsidian Shield	
	[29071] = { [1] = POWERTYPE_HEALTH },
	[33862] = { [1] = POWERTYPE_HEALTH },
	[33864] = { [1] = POWERTYPE_HEALTH },
	[33866] = { [1] = POWERTYPE_HEALTH },
	
	-- Dragonknight Igneous Shield	
	[29224] = { [1] = POWERTYPE_HEALTH },
	[33868] = { [1] = POWERTYPE_HEALTH },
	[33870] = { [1] = POWERTYPE_HEALTH },
	[33872] = { [1] = POWERTYPE_HEALTH },
	
	-- Dragonknight Fragmented Shield	
	[32673] = { [1] = POWERTYPE_HEALTH },
	[33875] = { [1] = POWERTYPE_HEALTH },
	[33878] = { [1] = POWERTYPE_HEALTH },
	[33881] = { [1] = POWERTYPE_HEALTH },
	
	-- Dragonknight Flames of Oblivion
	[32853] = { [2] = POWERTYPE_ULTIMATE },
	[34066] = { [2] = POWERTYPE_ULTIMATE },
	[34073] = { [2] = POWERTYPE_ULTIMATE },
	[34080] = { [2] = POWERTYPE_ULTIMATE },
	
	-- Dragonknight Standard
	[28988] = { [3] = POWERTYPE_HEALTH },
	[33955] = { [3] = POWERTYPE_HEALTH },
	[33959] = { [3] = POWERTYPE_HEALTH },
	[33963] = { [3] = POWERTYPE_HEALTH },
	
	-- Dragonknight Standard of Might	
	[32947] = { [5] = POWERTYPE_HEALTH },
	[34009] = { [5] = POWERTYPE_HEALTH },
	[34015] = { [5] = POWERTYPE_HEALTH },
	[34021] = { [5] = POWERTYPE_HEALTH },
	
	-- Dragonknight Shifting Standard	
	[32958] = { [3] = POWERTYPE_HEALTH },	
	[33967] = { [3] = POWERTYPE_HEALTH },
	[33977] = { [3] = POWERTYPE_HEALTH },
	[33987] = { [3] = POWERTYPE_HEALTH },
	
	-- Dragonknight Choking Talons	
	[20251] = { [5] = POWERTYPE_ULTIMATE },
	[32127] = { [5] = POWERTYPE_ULTIMATE },
	[32131] = { [5] = POWERTYPE_ULTIMATE },
	[32135] = { [5] = POWERTYPE_ULTIMATE },
	
	-- Dragonknight Dark Talons	
	[20245] = { [3] = POWERTYPE_ULTIMATE },
	[32105] = { [3] = POWERTYPE_ULTIMATE },
	[32108] = { [3] = POWERTYPE_ULTIMATE },
	[32111] = { [3] = POWERTYPE_ULTIMATE },
	
	-- Dragonknight Burning Talons	
	[20252] = { [5] = POWERTYPE_ULTIMATE },
	[32114] = { [5] = POWERTYPE_ULTIMATE },
	[32119] = { [5] = POWERTYPE_ULTIMATE },
	[32123] = { [5] = POWERTYPE_ULTIMATE },
		
	-- Vampire Devouring Swarm
	[38931] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[41933] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[41936] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	[41937] = { [3] = uespLog.UESP_POWERTYPE_SOULTETHER },
	
	-- Werewolf Werewolf Transformation
	[32455] = { [3] = POWERTYPE_STAMINA },
	[42356] = { [3] = POWERTYPE_STAMINA },
	[42357] = { [3] = POWERTYPE_STAMINA },
	[42358] = { [3] = POWERTYPE_STAMINA },
	
	-- Werewolf Werewolf Berserker
	[39076] = { [3] = POWERTYPE_STAMINA },
	[42377] = { [3] = POWERTYPE_STAMINA },
	[42378] = { [3] = POWERTYPE_STAMINA },
	[42379] = { [3] = POWERTYPE_STAMINA },

	-- Werewolf Pack Leader
	[39075] = { [3] = POWERTYPE_STAMINA },
	[42365] = { [3] = POWERTYPE_STAMINA },
	[42366] = { [3] = POWERTYPE_STAMINA },
	[42367] = { [3] = POWERTYPE_STAMINA },
	
	-- Alliance Support Replenishing Barrier	
	-- Although it's an ultimate the 3rd number seems to be only based off of magic
	[40239] = { [3] = POWERTYPE_MAGICKA },
	[46616] = { [3] = POWERTYPE_MAGICKA },
	[46619] = { [3] = POWERTYPE_MAGICKA },
	[46622] = { [3] = POWERTYPE_MAGICKA },
	
	-- Light Armor Dampen Magic
	[39186] = { [4] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[41109] = { [4] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[41111] = { [4] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[41113] = { [4] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	
	-- Light Armor Harness Magicka
	[39182] = { [5] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[41115] = { [5] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[41118] = { [5] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[41121] = { [5] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	
	--Heavy Armor Immovable Brute/Unstoppable
	[39205] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[41085] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[41088] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[41091] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	
	[39197] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[41097] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[41100] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[41103] = { [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	
-- Passives 

	-- Dual Wield Twin Blade and Blunt	
	[30893] = { [2] = POWERTYPE_STAMINA, [6] = uespLog.UESP_POWERTYPE_WEAPONDAGGER },
	[45482] = { [2] = POWERTYPE_STAMINA, [6] = uespLog.UESP_POWERTYPE_WEAPONDAGGER },
	
	-- Light Armor Spell Warding	
	[29663] = { [1] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[45559] = { [1] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	
	-- Light Armor Evocation	
	[29639] = { [2] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[45548] = { [2] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[45549] = { [2] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	
	-- Light Armor Recovery	
	[29665] = { [2] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	[45557] = { [2] = uespLog.UESP_POWERTYPE_LIGHTARMOR },
	
	-- Medium Armor Dexterity	
	[29743] = { [1] = uespLog.UESP_POWERTYPE_MEDIUMARMOR},
	[45563] = { [1] = uespLog.UESP_POWERTYPE_MEDIUMARMOR},
	[45564] = { [1] = uespLog.UESP_POWERTYPE_MEDIUMARMOR},
	
	-- Medium Armor Improved Sneak	
	[29738] = { [2] = uespLog.UESP_POWERTYPE_MEDIUMARMOR, [4] = uespLog.UESP_POWERTYPE_MEDIUMARMOR  },
	[45567] = { [2] = uespLog.UESP_POWERTYPE_MEDIUMARMOR, [4] = uespLog.UESP_POWERTYPE_MEDIUMARMOR  },
	
	-- Medium Armor Athletics	
	[29742] = { [3] = uespLog.UESP_POWERTYPE_MEDIUMARMOR },
	[45574] = { [3] = uespLog.UESP_POWERTYPE_MEDIUMARMOR },
	
	-- Medium Armor Wind Walker	
	[29687] = { [2] = uespLog.UESP_POWERTYPE_MEDIUMARMOR, [4] = uespLog.UESP_POWERTYPE_MEDIUMARMOR  },
	[45565] = { [2] = uespLog.UESP_POWERTYPE_MEDIUMARMOR, [4] = uespLog.UESP_POWERTYPE_MEDIUMARMOR  },
		
	-- Heavy Armor Resolve
	[29825] = { [1] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[45531] = { [1] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[45533] = { [1] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
		
	-- Heavy Armor Constitution
	[29769] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR, [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[45526] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR, [4] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
		
	-- Heavy Armor Juggernaut
	-- Note that skill output is truncated to integer values so fit accuracy may be low
	[29804] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[45546] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	
	-- Heavy Armor Rapid Mending
	-- Note that skill output is truncated to integer values so fit accuracy may be low
	[29791] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[45529] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	
	-- Nightblade Pressure Points
	[36636] = uespLog.UESP_POWERTYPE_ASSASSINATION,
	[45053] = uespLog.UESP_POWERTYPE_ASSASSINATION,	
	
	-- Nightblade Shadow Barrier	
	[18866] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR, [3] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	[45071] = { [2] = uespLog.UESP_POWERTYPE_HEAVYARMOR, [3] = uespLog.UESP_POWERTYPE_HEAVYARMOR },
	
	-- Soul Magic Soul Shatter
	[39266] = { [2] = POWERTYPE_HEALTH},
	[45583] = { [2] = POWERTYPE_HEALTH},
	
	-- Undaunted Undaunted Mettle
	[55366] = { [2] = uespLog.UESP_POWERTYPE_ARMORTYPE },	
	[55386] = { [2] = uespLog.UESP_POWERTYPE_ARMORTYPE },	
	
	-- Undaunted Undaunted Command
	[55584] = { [2] = POWERTYPE_HEALTH, [3] = POWERTYPE_STAMINA, [4] = POWERTYPE_MAGICKA },
	[55676] = { [2] = POWERTYPE_HEALTH, [3] = POWERTYPE_STAMINA, [4] = POWERTYPE_MAGICKA },
	
	-- Destruction Tri Focus
	[30948] = { [2] = POWERTYPE_HEALTH },
	[45500] = { [2] = POWERTYPE_HEALTH },	
	
	-- Two Handed Heavy Weapons
	[29375] = { [3] = POWERTYPE_STAMINA },
	[45430] = { [3] = POWERTYPE_STAMINA },
	
	-- Sorcerer Disintegrate/Implosion
	[31422] = { [3] = POWERTYPE_HEALTH, [6] = POWERTYPE_HEALTH },
	[45192] = { [3] = POWERTYPE_HEALTH, [6] = POWERTYPE_HEALTH },
	
	-- Templar Burning Light	
	--[31718] = { [2] = POWERTYPE_ULTIMATE },
	--[44730] = { [2] = POWERTYPE_ULTIMATE },
	[31718] = { [2] = POWERTYPE_STAMINA },		-- Temporary fix as the tooltip is bugged
	[44730] = { [2] = POWERTYPE_STAMINA },
	
	-- Imperial Red Diamond
	[36155] = { [2] = POWERTYPE_HEALTH },
	[45291] = { [2] = POWERTYPE_HEALTH },
	[45293] = { [2] = POWERTYPE_HEALTH },
	
	-- Redguard Adrenaline Rush
	[36546] = { [1] = POWERTYPE_STAMINA },
	[45313] = { [1] = POWERTYPE_STAMINA },
	[45315] = { [1] = POWERTYPE_STAMINA },
	
	-- Light Attacks
	[15435] = POWERTYPE_STAMINA,
	[16037] = POWERTYPE_STAMINA,
	[16145] = POWERTYPE_MAGICKA,
	[16165] = POWERTYPE_MAGICKA,
	[16277] = POWERTYPE_MAGICKA,
	[16499] = POWERTYPE_STAMINA,
	[16688] = POWERTYPE_STAMINA,
	[18350] = POWERTYPE_MAGICKA,
	[23604] = POWERTYPE_STAMINA,
	[29368] = { [1] = POWERTYPE_MAGICKA, [2] = POWERTYPE_ULTIMATE },
	[32464] = POWERTYPE_STAMINA,
	[55885] = POWERTYPE_STAMINA,
	[60774] = POWERTYPE_STAMINA,
	[60776] = POWERTYPE_STAMINA,
	[60778] = POWERTYPE_STAMINA,
	[60782] = POWERTYPE_STAMINA,
	[60785] = POWERTYPE_MAGICKA,
	[60794] = POWERTYPE_MAGICKA,
	[62426] = POWERTYPE_STAMINA,
	[63754] = POWERTYPE_STAMINA,
	
	-- Heavy Attacks
	[15279] = POWERTYPE_STAMINA,
	[15383] = POWERTYPE_MAGICKA,
	[16041] = POWERTYPE_STAMINA,
	[16212] = POWERTYPE_MAGICKA,
	[16220] = POWERTYPE_STAMINA,
	[16261] = POWERTYPE_MAGICKA,
	[16420] = POWERTYPE_STAMINA,
	[16691] = POWERTYPE_STAMINA,
	[18396] = POWERTYPE_MAGICKA,
	[18429] = POWERTYPE_STAMINA,
	[29365] = POWERTYPE_MAGICKA,
	[32477] = POWERTYPE_STAMINA,
	[55886] = POWERTYPE_STAMINA,
	[60775] = POWERTYPE_STAMINA,
	[60777] = POWERTYPE_STAMINA,
	[60779] = POWERTYPE_STAMINA,
	[60783] = POWERTYPE_STAMINA,
	[60786] = POWERTYPE_MAGICKA,
	[60796] = POWERTYPE_MAGICKA,
	
-- CP

	-- Resilient
	[61660] = POWERTYPE_HEALTH,
	
	-- Riposte
	[60229] = { [2] = uespLog.UESP_POWERTYPE_DAMAGE },
	
	-- Invigorating bash
	[60407] = POWERTYPE_HEALTH,
		
}


uespLog.OTHER_MISSING_SKILL_DATA = 
{
	-- Heavy Attacks
	15279,
	15383,
	16041,
	16212,
	16220,
	16261,
	16420,
	16691,
	18396,
	18429,
	29365,
	32477,
	55886,
	60775,
	60777,
	60779,
	60783,
	60786,
	60796,

		-- Light Attacks
	15435,
	16037,
	16145,
	16165,
	16277,
	16499,
	16688,
	18350,
	23604,
	29368,
	32464,
	55885,
	60774,
	60776,
	60778,
	60782,
	60785,
	60794,
	62426,
	63754,
	
		-- Pounce
	32632,     
	42108,
	42109,
	42110,
		-- Brutal Pounce
	39105,     
	42117,
	42118,
	42119,
		-- Feral Pounce
	39104,     
	42126,
	42127,
	42128,
		-- Hircine's Bounty
	58310,		
	58314,
	58315,
	58316,
		-- Hircine's Rage
	58317,		
	58319,
	58321,
	58323,
		-- Hircine's Fortitude
	58325,		
	58329,
	58332,
	58334,
	    -- Roar
	32633, 
	42143,
	42144,
	42145,
		-- Ferocious Roar
	39113,     
	42155,
	42156,
	42157,
		-- Rousing Roar
	39114,     
	42177,
	42178,
	42179,
		-- Piercing Howl
	58405,		
	58736,
	58738,
	58740,
		-- Howl of Despair
	58742,		
	58786,
	58790,
	58794,
		-- Howl of Agony
	58798,		
	58802,
	58805,
	58808,
		-- Infectious Claws
	58855,		
	58857,
	58859,
	58862,
		-- Claws of Anguish
	58864,		
	58870,
	58873,
	58876,
		-- Claws of Life
	58879,		
	58901,
	58904,
	58907,
}


SLASH_COMMANDS["/uespskillcoef"] = function(cmd)
	local cmds, cmd1 = uespLog.SplitCommands(cmd)
	local result
	
	if (cmd1 == "save") then
	
		if (not uespLog.IsSafetoSaveSkillCoef()) then
			uespLog.Msg("Error: Can't save skill data. Wait a few more seconds and try again.")
			return false
		end
		
		result = uespLog.CaptureSkillCoefData()

		if (result) then
			uespLog.Msg("Successfully captured skill data for current character/equipment.")
		else
			uespLog.Msg("Error: Failed to capture skill data for current character/equipment!")
		end
		
	elseif (cmd1 == "calc" or cmd1 == "compute") then
		result = uespLog.ComputeSkillCoef()
		
		if (result) then
			uespLog.Msg("Skill data calculated! Found "..tostring(uespLog.SkillCoefNumValidCoefCount).." skill variables with valid coefficients.")
			uespLog.Msg(".       Failed to compute coefficients for "..tostring(uespLog.SkillCoefNumBadCoefCount).." skill variables.")
		else
			uespLog.Msg("Error: Failed to calculate skill coefficients!")
		end
		
	elseif (cmd1 == "coef" or cmd1 == "show") then
		local skillName = uespLog.implodeOrder(cmds, " ", 2)
		uespLog.ShowSkillCoef(skillName)
	elseif (cmd1 == "savetemp") then
		local skillName = uespLog.implodeOrder(cmds, " ", 2)
		uespLog.SaveTempSkillCoef(skillName)
	elseif (cmd1 == "showdata") then
		local skillName = uespLog.implodeOrder(cmds, " ", 2)
		uespLog.ShowDataSkillCoef(skillName)
	elseif (cmd1 == "status") then
		local calcStatus = "not "
		
		if (uespLog.SkillCoefDataIsCalculated) then
			calcStatus = ""
		end
		
		uespLog.Msg("There are "..tostring(uespLog.SkillCoefAbilityCount).." skills with "..tostring(uespLog.SkillCoefDataPointCount).." data points for calculating skill coefficients.")
		uespLog.Msg("Skill data is "..calcStatus.."calculated with "..tostring(uespLog.SkillCoefNumValidCoefCount).." skill variables with valid coefficients.")
		uespLog.Msg(".       Failed to compute coefficients for "..tostring(uespLog.SkillCoefNumBadCoefCount).." skill variables.")
		
		if (uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
			local setName = uespLog.SkillCoef_CaptureWykkyd_Prefix .. uespLog.SkillCoef_CaptureWykkyd_CurrentIndex
			uespLog.Msg(".     Currently saving skill data for Wykkyd's set "..tostring(setName))
		end
	elseif (cmd1 == "clear" or cmd1 == "reset") then
		uespLog.ClearSkillCoefData()
		uespLog.Msg("Cleared all skill coefficient data.")
	elseif (cmd1 == "clearsaved" or cmd1 == "resetsaved") then
		uespLog.ClearSavedSkillCoefData()
		uespLog.Msg("Cleared any saved skill coefficient statistic data.")
	elseif (cmd1 == "listbad" or cmd1 == "showbad") then
		uespLog.ShowSkillCoefBadData()
	elseif (cmd1 == "listbadfit" or cmd1 == "showbadfit") then
		uespLog.ShowSkillCoefBadFitData(cmds[2])
	elseif (cmd1 == "savewyk") then
		uespLog.CaptureSkillCoefDataWykkyd(cmds[2], cmds[3], cmds[4])
	elseif (cmd1 == "addskill" or cmd1 == "add") then
		uespLog.SkillCoefAddSkill(cmds[2])
	elseif (cmd1 == "addcharskills") then
		uespLog.SkillCoefAddCharSkills()
	elseif (cmd1 == "addmissing") then
		uespLog.SkillCoefAddMissingSkills()
	elseif (cmd1 == "addall") then
		uespLog.SkillCoefAddAllSkills()
	elseif (cmd1 == "savelist") then
		uespLog.SkillCoefSaveSkillList()
	elseif (cmd1 == "loadlist") then
		uespLog.SkillCoefLoadSkillList()
	elseif (cmd1 == "resetlist") then
		uespLog.SkillCoefResetSkillList()
	elseif (cmd1 == "stop" or cmd1 == "end" or cmd1 == "abort") then
		uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = uespLog.SkillCoef_CaptureWykkyd_EndIndex + 1
		
		if (uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
			uespLog.SkillCoef_CaptureWykkyd_IsWorking = false
			uespLog.Msg("Stopped saving skill data using Wykkyd's sets...")
		end
	else
		uespLog.Msg("Saves and calculates coefficients for all skills the character knows. Note that the saved skill data is *not* saved when you /reloadui or logout.")
		uespLog.Msg("To use use the 'save' command with at least 3 different sets of character stat (spell damage/magicka or weapon damage/stamina) and then use the 'calc' command.")
		uespLog.Msg(".     /uespsavecoef ...       Normal command form")
		uespLog.Msg(".     /usc ...                       Short form")
		uespLog.Msg(".     /usc save                   Save current skill data")
		uespLog.Msg(".     /usc calc                   Calculate coefficients using saved data")
		uespLog.Msg(".     /usc coef [name]       Shows the coefficients for the given skill name")
		uespLog.Msg(".     /usc coef [id]             Shows the coefficients for the given skill ID")
		uespLog.Msg(".     /usc status                 Current status of saved skill data")
		uespLog.Msg(".     /usc reset                  Resets the saved skill data")
		uespLog.Msg(".     /usc resetsaved         Clears all saved data points from")
		uespLog.Msg(".     /usc savewyk [prefix] [start] [end]  Saves skill data using Wykkyd's Outfitter. For example: '/usc savewyk Test 1 9' would try to load the sets 'Test1'...'Test9' and save the skill data for each of them.")
		uespLog.Msg(".     /usc stop                          Stops a Wykkyd item set save in progress")
		uespLog.Msg(".     /usc savetemp [id]           Saves skill data to the tempData section")
		uespLog.Msg(".     /usc savetemp [name]")
		uespLog.Msg(".     /usc showdata [id]           Output raw data for a skill")
		uespLog.Msg(".     /usc showdata [name]")
		uespLog.Msg(".     /usc showbad                  Lists all any coefficients that are 'bad'")
		uespLog.Msg(".     /usc showbadfit [R2]        Lists all any coefficients with poor fits")
		uespLog.Msg(".     /usc addskill [id] [rank]    Adds the given skill to track when saving")
		uespLog.Msg(".     /usc addcharskills           Adds all character skills to track when saving")
		uespLog.Msg(".     /usc addmissing              Adds all currently defined missing skills")
	end

end

SLASH_COMMANDS["/usc"] = SLASH_COMMANDS["/uespskillcoef"]


function uespLog.SkillCoefSaveSkillList()
	local data
	local count = 0
	data = {}
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		count = count + 1
		data[#data + 1] = { id = abilityId, rank = abilityData['rank'] }
	end
	
	if (uespLog.savedVars.skillCoefAbilityList == nil) then
		uespLog.savedVars.skillCoefAbilityList = uespLog.DEFAULT_DATA
	end
	
	uespLog.savedVars.skillCoefAbilityList.data = data
	uespLog.Msg("Saved "..tostring(count).." abilities to the skillCoefAbilityList section.")
end


function uespLog.SkillCoefLoadSkillList()
	local data
	local count = 0
	local newCount = 0
	
	if (uespLog.savedVars.skillCoefAbilityList == nil) then
		uespLog.Msg("No skills found in skillCoefAbilityList section!")
		return
	end
	
	data = uespLog.savedVars.skillCoefAbilityList.data
	
	for _, abilityData in ipairs(data) do
		local _, isNew = uespLog.InitSkillCoefData(abilityData['id'], abilityData['rank'])
		
		if (isNew) then
			newCount = newCount + 1
		end
		
		count = count + 1
	end
	
	uespLog.Msg("Loaded "..tostring(newCount).." of "..tostring(count).." abilities from the skillCoefAbilityList section.")
end


function uespLog.SkillCoefResetSkillList()

	if (uespLog.savedVars.skillCoefAbilityList == nil) then
		uespLog.savedVars.skillCoefAbilityList = uespLog.DEFAULT_DATA
	end
	
	uespLog.savedVars.skillCoefAbilityList.data = {}
	uespLog.Msg("Reset the skillCoefAbilityList section.")
end


function uespLog.ShowSkillCoefBadData()

	if (uespLog.SkillCoefNumBadCoefCount == 0) then
		uespLog.Msg("No bad skill coefficient data found!")
		return
	end
	
	uespLog.Msg("Found "..tostring(#uespLog.SkillCoefBadData).." bad coefficient data...")
	
	for i,badSkill in ipairs(uespLog.SkillCoefBadData) do
		local abilityData = uespLog.SkillCoefAbilityData[badSkill.id]
		
		if (abilityData == nil) then
			uespLog.Msg(".      "..tostring(i)..": Unknown abilityId "..tostring(badSkill.id).."!")
		else
			uespLog.Msg(".      "..tostring(i)..": "..tostring(abilityData.name).." ("..tostring(badSkill.id)..") number #"..tostring(badSkill.numberIndex))
		end
	end

end


function uespLog.ShowSkillCoefBadFitData(maxR2)
	local count = 0
	local totalCount = 0

	if (maxR2 == nil or maxR2 == "") then
		maxR2 = uespLog.SKILLCOEF_BADFIT_MINR2
	else
		maxR2 = tonumber(maxR2)
	end
	
	uespLog.Msg("Listing all fits with R2 less than "..tostring(maxR2).."...")
	
	for id,coefData in pairs(uespLog.SkillCoefAbilityData) do
		local calcData = uespLog.SkillCoefCalcData[id]
		local hasOutputName = false
		
		if (calcData ~= nil and calcData.isValid) then
		
			for i,result in ipairs(calcData.result) do
				local doesVary = calcData.numbersVary[i]
								
				if (doesVary and result.R2 < maxR2) then
					local a  = string.format("%.7f", result.a)
					local b  = string.format("%.7f", result.b)
					local c  = string.format("%.7f", result.c)
					local R2 = string.format("%.7f", result.R2)
					local index = calcData.numbersIndex[i]
					local rank = tostring(coefData.rank)
					local typeName = uespLog.GetSkillMechanicName(result.type)
					
					if (not hasOutputName) then
						uespLog.Msg(""..tostring(coefData.name).." "..rank.." ("..tostring(coefData.id).."):")
						hasOutputName = true
					end
					
					count = count + 1
					totalCount = totalCount + 1
					uespLog.Msg(".     $"..tostring(index)..": "..a..", "..b..", "..c..", "..R2.."  ("..typeName..")")
				elseif (doesVary) then
					totalCount = totalCount + 1
				end
			end	
		end
	end
	
	uespLog.Msg("Found "..count.." of "..totalCount.." variables with poor fits.")
end


function uespLog.LogSkillCoefData()
	local logData = {}
	local rowData = {}
	
	uespLog.ClearSavedVarSection("tempData")
	
	table.insert(rowData, "Skill Name")
	table.insert(rowData, "ID")
	table.insert(rowData, "Level")
	table.insert(rowData, "Mechanic")
	table.insert(rowData, "Cost")
	table.insert(rowData, "NumVars")
	table.insert(rowData, "Description")
	table.insert(rowData, "mech1")
	table.insert(rowData, "a1")
	table.insert(rowData, "b1")
	table.insert(rowData, "c1")
	table.insert(rowData, "R1")
	table.insert(rowData, "mech2")
	table.insert(rowData, "a2")
	table.insert(rowData, "b2")
	table.insert(rowData, "c2")
	table.insert(rowData, "R2")
	table.insert(rowData, "mech3")
	table.insert(rowData, "a3")
	table.insert(rowData, "b3")
	table.insert(rowData, "c3")
	table.insert(rowData, "R3")
	table.insert(rowData, "mech4")
	table.insert(rowData, "a4")
	table.insert(rowData, "b4")
	table.insert(rowData, "c4")
	table.insert(rowData, "R4")
	table.insert(rowData, "mech5")
	table.insert(rowData, "a5")
	table.insert(rowData, "b5")
	table.insert(rowData, "c5")
	table.insert(rowData, "R5")
	table.insert(rowData, "mech6")
	table.insert(rowData, "a6")
	table.insert(rowData, "b6")
	table.insert(rowData, "c6")
	table.insert(rowData, "R6")
	
	local data = uespLog.savedVars.tempData.data
	data[#data+1] = uespLog.implode(rowData, ", ")
	
	logData.event = "SkillCoef::Start"
	logData.numSkills = uespLog.SkillCoefAbilityCount
	logData.numPoints = uespLog.SkillCoefDataPointCount
	uespLog.AppendDataToLog("all", logData, uespLog.GetTimeData())
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		local calcData = uespLog.SkillCoefCalcData[abilityId]
		
		if (calcData ~= nil) then
			uespLog.LogSkillCoefDataSkill(abilityData, calcData)
			uespLog.LogSkillCoefDataSkillCsv(abilityData, calcData)
		end
	end
	
	logData.event = "SkillCoef::End"
	uespLog.AppendDataToLog("all", logData)
end


function uespLog.LogSkillCoefDataSkill(abilityData, calcData)
	local logData = {}
	
	if (not calcData.isValid or calcData.result == nil or #(calcData.result) == 0) then
		return
	end
	
	logData.event = "SkillCoef"
	logData.desc = abilityData.newDesc
	logData.numVars = abilityData.numVars
	logData.name = abilityData.name
	logData.passive = 0
	logData.cost = abilityData.cost
	logData.rank = abilityData.rank
	logData.abilityId = abilityData.id
				
	if (abilityData.passive) then
		logData.passive = 1
	end
	
	for i,result in ipairs(calcData.result) do
		local doesVary = calcData.numbersVary[i]
		local a  = string.format("%.7f", result.a)
		local b  = string.format("%.7f", result.b)
		local c  = string.format("%.7f", result.c)
		local R2 = string.format("%.7f", result.R2)
		local avg = string.format("%.7f", result.avg)
		local index = calcData.numbersIndex[i]
		
		if (doesVary) then
			logData['a'..tostring(index)] = a
			logData['b'..tostring(index)] = b
			logData['c'..tostring(index)] = c
			logData['R'..tostring(index)] = R2
			logData['avg'..tostring(index)] = avg
			logData['type'..tostring(index)] = result.type
		end
	end	
	
	uespLog.AppendDataToLog("all", logData)
end


function uespLog.LogSkillCoefDataSkillCsv(abilityData, calcData)
	local rowData = {}
	
	if (not calcData.isValid or calcData.result == nil or #(calcData.result) == 0) then
		return
	end
	
	table.insert(rowData, "'"..abilityData.name.."'")
	table.insert(rowData, abilityData.id)
	table.insert(rowData, abilityData.rank)
	table.insert(rowData, abilityData.type)
	table.insert(rowData, abilityData.cost)
	table.insert(rowData, abilityData.numVars)
	table.insert(rowData, "'"..abilityData.newDesc.."'")
	
	for i,result in ipairs(calcData.result) do
		local doesVary = calcData.numbersVary[i]
		local a  = string.format("%.7f", result.a)
		local b  = string.format("%.7f", result.b)
		local c  = string.format("%.7f", result.c)
		local R2 = string.format("%.7f", result.R2)
		local index = calcData.numbersIndex[i]
		
		if (doesVary) then
			table.insert(rowData, result.type)
			table.insert(rowData, a)
			table.insert(rowData, b)
			table.insert(rowData, c)
			table.insert(rowData, R2)
		end
	end	
	
	local data = uespLog.savedVars.tempData.data
	data[#data+1] = uespLog.implode(rowData, ", ")
end


function uespLog.CaptureSkillCoefDataWykkyd(setPrefix, startIndex, endIndex)

	if (uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
		return false
	end
	
	if (setPrefix == nil or setPrefix == "" or startIndex == nil or endIndex == nil) then
		uespLog.Msg("Error: Missing required parameters! Command format is:")
		uespLog.Msg(".     /usc savewyk [prefix] [start] [end]")
		return false
	end
	
	startIndex = tonumber(startIndex)
	endIndex   = tonumber(endIndex)
	
	if (startIndex == nil or endIndex == nil) then
		uespLog.Msg("Error: 'start' and 'end' must be valid numbers! Command format is:")
		uespLog.Msg(".     /usc savewyk [prefix] [start] [end]")
		return false
	end
	
	if (SLASH_COMMANDS['/loadset'] == nil) then
		uespLog.Msg("Error: It doesn't look like the Wykkyd's Outfitter add-on is installed!")
		return false
	end
	
	uespLog.SkillCoef_CaptureWykkyd_Prefix = setPrefix
	uespLog.SkillCoef_CaptureWykkyd_StartIndex = startIndex
	uespLog.SkillCoef_CaptureWykkyd_EndIndex = endIndex
	uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = 1
	
	local startSet = setPrefix .. tostring(startIndex)
	local endSet = setPrefix .. tostring(endIndex)
	
	uespLog.Msg("Starting skill data capture using Wykkyd's sets "..tostring(startSet).."..."..tostring(endSet))
	
	uespLog.SkillCoef_CaptureWykkyd_IsWorking = true
	uespLog.CaptureNextSkillCoefDataWykkyd_LoadSet()

	return true
end


function uespLog.CaptureNextSkillCoefDataWykkyd_LoadSet()

	if (not uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
		return
	end

	if (uespLog.SkillCoef_CaptureWykkyd_CurrentIndex > uespLog.SkillCoef_CaptureWykkyd_EndIndex) then
		local startSet = uespLog.SkillCoef_CaptureWykkyd_Prefix .. tostring(uespLog.SkillCoef_CaptureWykkyd_StartIndex)
		local endSet = uespLog.SkillCoef_CaptureWykkyd_Prefix .. tostring(uespLog.SkillCoef_CaptureWykkyd_EndIndex)
		uespLog.Msg("Finished skill data capture using Wykkyd's sets "..tostring(startSet).."..."..tostring(endSet))
		uespLog.SkillCoef_CaptureWykkyd_IsWorking = false
		return
	end
	
	local setName = tostring(uespLog.SkillCoef_CaptureWykkyd_Prefix) .. tostring(uespLog.SkillCoef_CaptureWykkyd_CurrentIndex)
	SLASH_COMMANDS['/loadset'](setName)
	
	zo_callLater(uespLog.CaptureNextSkillCoefDataWykkyd_SaveData, uespLog.SkillCoef_CaptureWykkyd_TimeDelayLoadSet)
end


function uespLog.CaptureNextSkillCoefDataWykkyd_SaveData()

	if (not uespLog.SkillCoef_CaptureWykkyd_IsWorking) then
		return
	end
	
	if (not uespLog.IsSafetoSaveSkillCoef()) then
		uespLog.Msg("Error: Can't save skill data. Waiting a few more seconds and trying again...")
		zo_callLater(uespLog.CaptureNextSkillCoefDataWykkyd_SaveData, uespLog.SkillCoef_CaptureWykkyd_TimeDelayLoadSet/2)
		return false
	end
	
	local setName = tostring(uespLog.SkillCoef_CaptureWykkyd_Prefix) .. tostring(uespLog.SkillCoef_CaptureWykkyd_CurrentIndex)

	if (uespLog.CaptureSkillCoefData()) then
		uespLog.Msg("Saved skill data for Wykyyd's set '"..tostring(setName).."'.")
	else
		uespLog.Msg("Error: Failed to savedskill data for Wykyyd's set '"..tostring(setName).."'!")
	end
	
	uespLog.SkillCoef_CaptureWykkyd_CurrentIndex = uespLog.SkillCoef_CaptureWykkyd_CurrentIndex + 1
	uespLog.CaptureNextSkillCoefDataWykkyd_LoadSet()
end


function uespLog.SkillCoefAddMissingSkills()
	local newSkills = 0
	
	for k, skillData in ipairs(uespLog.MISSING_SKILL_DATA) do
		local abilityId = skillData[2]
		
		local result, isNew = uespLog.InitSkillCoefData(abilityId, rank)
		if (isNew) then newSkills = newSkills + 1 end
	end
	
	for k, abilityId in ipairs(uespLog.OTHER_MISSING_SKILL_DATA) do
		local result, isNew = uespLog.InitSkillCoefData(abilityId, 0)
		if (isNew) then newSkills = newSkills + 1 end
	end
	
	uespLog.Msg("Added "..newSkills.." missing skills to tracked data!")
		
end


function uespLog.SkillCoefAddAllSkills()
	local abilityId
	local endId =  100000
	local validAbilityCount = 0
	local newSkills = 0
	local logData = { }
	
	uespLog.Msg("Checking all skills for coefficient tracking...")
	
	for abilityId = 1, endId do
		if (DoesAbilityExist(abilityId)) then
			validAbilityCount = validAbilityCount + 1
			local desc = GetAbilityDescription(abilityId)
			
			if (desc ~= "") then
				local matchResult = desc:match("%d")

				if (matchResult ~= nil) then
					local result, isNew = uespLog.InitSkillCoefData(abilityId, 0)
					if (isNew) then newSkills = newSkills + 1 end
				end
			end

		end
	end

	uespLog.Msg("Added "..newSkills.." missing skills out of "..tostring(validAbilityCount).." possible skills to tracked data!")
	return true
end


function uespLog.SkillCoefAddCharSkills()
	local newSkills = 0
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local result, isNew
	
	uespLog.Msg("Adding all available character skills to tracked skill list...")
	
	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		local skillTypeName = uespLog.GetSkillTypeName(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
					
			for abilityIndex = 1, numSkillAbilities do
				local name, _, rank, passive, ultimate, purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				local level, maxLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
				local ability1 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				local ability2 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, true)
				
				if (level == 0 or level == nil) then 
					level = 1
				end
				
				if (progressionIndex ~= nil and progressionIndex > 0) then
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 1), 1)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 2), 2)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 3), 3)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 4), 4)
					if (isNew) then newSkills = newSkills + 1 end
					
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 1), 1)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 2), 2)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 3), 3)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 4), 4)
					if (isNew) then newSkills = newSkills + 1 end
					
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 1), 1)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 2), 2)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 3), 3)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 4), 4)
					if (isNew) then newSkills = newSkills + 1 end
				else
					result, isNew = uespLog.InitSkillCoefData(ability1, level)
					if (isNew) then newSkills = newSkills + 1 end
					result, isNew = uespLog.InitSkillCoefData(ability2, level + 1)
					if (isNew) then newSkills = newSkills + 1 end
				end
			
			end
		end
	end
	
	uespLog.Msg("Found "..tostring(newSkills).." new skills to track.")
	uespLog.SkillCoefAddCPPassives()
end


function uespLog.SkillCoefAddCPPassives()
	local numDisc = GetNumChampionDisciplines()
	local newSkills = 0
	
	for disciplineIndex = 1, numDisc do
		local numSkills = GetNumChampionDisciplineSkills(disciplineIndex)	
		
		for skillIndex = 1, numSkills do
			local unlockLevel = GetChampionSkillUnlockLevel(disciplineIndex, skillIndex)
			local abilityId = GetChampionAbilityId(disciplineIndex, skillIndex)
			
			if (unlockLevel ~= nil and unlockLevel > 0) then
				local result, isNew = uespLog.InitSkillCoefData(abilityId, 0)
				if (isNew) then newSkills = newSkills + 1 end
			end
		end
	end
	
	uespLog.Msg("Found "..tostring(newSkills).." new CP skills to track.")
end


function uespLog.SkillCoefAddSkill(abilityId, rank)
	local abilityId = tonumber(abilityId)
	local rank = tonumber(rank) or -1
	
	if (abilityId == nil or abilityId == "") then
		uespLog.Msg("Missing required abilityId!")
		return false
	end
	
	if (uespLog.SkillCoefAbilityData[abilityId] ~= nil) then
		uespLog.Msg("Skill "..tostring(abilityId).." is already being tracked...")
		return true
	end
	
	if (not DoesAbilityExist(abilityId) or GetAbilityName(abilityId) == "") then
		uespLog.Msg("Error: Skill "..tostring(abilityId).." is not valid!")
		return false
	end
	
	if (not uespLog.InitSkillCoefData(abilityId, rank)) then
		uespLog.Msg("Error: Failed to add skill "..tostring(abilityId).." to tracked skill list!")
		return false
	end
	
	uespLog.Msg("Now tracking skill "..tostring(abilityId).." when saving statistic data!")
	return true
end


function uespLog.SaveTempSkillCoef(name)
	local abilityId = tonumber(name)
	local coefData = nil
	local skillData = nil
	local calcData = nil
	
	if (name == nil or name == "") then
		uespLog.Msg("Missing required skill name or abilityId!")
		return false
	end
	
	if (abilityId ~= nil) then
		coefData = uespLog.SkillCoefAbilityData[abilityId]
		skillData = uespLog.SkillCoefData[abilityId]
		calcData = uespLog.SkillCoefCalcData[abilityId]
	else
		coefData, skillData, abilityId = uespLog.FindSkillAbilityData(name)
	end
	
	if (coefData == nil or skillData == nil or calcData == nil) then
		uespLog.Msg("Skill "..tostring(name).." does not exist in coefficient data!")
		return false
	end
	
	local tempData = uespLog.savedVars.tempData.data
	tempData[#tempData+1] = "Raw Skill Coefficient Data for "..tostring(coefData.name).." ("..tostring(abilityId).."), "..tostring(#skillData).." data points"
	local headerData = {}
	
	table.insert(headerData, "Magic")
	table.insert(headerData, "Stamina")
	table.insert(headerData, "Health")
	table.insert(headerData, "SpellDmg")
	table.insert(headerData, "WeaponDmg")
	table.insert(headerData, "Light")
	table.insert(headerData, "Medium")
	table.insert(headerData, "Heavy")
	table.insert(headerData, "Description")
	table.insert(headerData, "Value1")
	table.insert(headerData, "Value2")
	table.insert(headerData, "Value3")
	table.insert(headerData, "Value4")
	table.insert(headerData, "Value5")
	table.insert(headerData, "Value6")
	tempData[#tempData+1] = uespLog.implode(headerData, ", ")
		
	for i, data in ipairs(skillData) do
		local rowData = {}
		
		table.insert(rowData, data.mag)
		table.insert(rowData, data.sta)
		table.insert(rowData, data.hea)
		table.insert(rowData, data.sd)
		table.insert(rowData, data.wd)
		table.insert(rowData, data.la)
		table.insert(rowData, data.ma)
		table.insert(rowData, data.ha)
		table.insert(rowData, "'"..data.desc.."'")
		
		for j, number in ipairs(data.numbers) do
			table.insert(rowData, number)
		end
				
		tempData[#tempData+1] = uespLog.implode(rowData, ", ")
	end
	
	uespLog.Msg("Saved raw skill coefficient data for "..tostring(coefData.name).." ("..tostring(abilityId).."), "..tostring(#skillData).." data points")
	return true
end


function uespLog.ShowDataSkillCoef(name)
	local abilityId = tonumber(name)
	local coefData = nil
	local skillData = nil
	local calcData = nil
	
	if (name == nil or name == "") then
		uespLog.Msg("Missing required skill name or abilityId!")
		return false
	end
	
	if (abilityId ~= nil) then
		coefData = uespLog.SkillCoefAbilityData[abilityId]
		skillData = uespLog.SkillCoefData[abilityId]
		calcData = uespLog.SkillCoefCalcData[abilityId]
	else
		coefData, skillData, abilityId = uespLog.FindSkillAbilityData(name)
	end
	
	if (coefData == nil or skillData == nil or calcData == nil) then
		uespLog.Msg("Skill "..tostring(name).." does not exist in coefficient data!")
		return false
	end
	
	local tempData = uespLog.savedVars.tempData.data
	uespLog.Msg("Raw Skill Coefficient Data for "..tostring(coefData.name).." ("..tostring(abilityId).."), "..tostring(#skillData).." data points")
	local headerData = {}
	
	table.insert(headerData, "Mag")
	table.insert(headerData, "Sta")
	table.insert(headerData, "Hea")
	table.insert(headerData, "Spell")
	table.insert(headerData, "Weap")
	table.insert(headerData, "LA")
	table.insert(headerData, "MA")
	table.insert(headerData, "HA")
	table.insert(headerData, "Values...")
	uespLog.Msg(uespLog.implode(headerData, ", "))
		
	for i, data in ipairs(skillData) do
		local rowData = {}
		
		table.insert(rowData, data.mag)
		table.insert(rowData, data.sta)
		table.insert(rowData, data.hea)
		table.insert(rowData, data.sd)
		table.insert(rowData, data.wd)
		table.insert(rowData, data.la)
		table.insert(rowData, data.ma)
		table.insert(rowData, data.ha)
		
		for j, number in ipairs(data.numbers) do
			table.insert(rowData, number)
		end
				
		uespLog.Msg(uespLog.implode(rowData, ", "))
	end
	
	return true
end
	

function uespLog.ShowSkillCoef(name)
	local abilityId = tonumber(name)
	local coefData = nil
	local calcData = nil

	if (name == nil or name == "") then
		uespLog.Msg("Missing required skill name or abilityId!")
		return false
	end
	
	if (abilityId ~= nil) then
		coefData = uespLog.SkillCoefAbilityData[abilityId]
	else
		coefData, _, abilityId = uespLog.FindSkillAbilityData(name)
	end
	
	calcData = uespLog.SkillCoefCalcData[abilityId]
	
	if (coefData == nil or calcData == nil) then
		uespLog.Msg("Skill "..tostring(name).." does not exist in coefficient data!")
		return false
	end
	
	if (not calcData.isValid or calcData.result == nil) then
		uespLog.Msg("Coefficient data for skill "..tostring(name).." is not valid!")
		return false
	end
	
	local rank = tostring(coefData.rank)
	uespLog.Msg(""..tostring(coefData.name).." "..rank.." ("..tostring(coefData.id)..") has coefficient data for "..tostring(coefData.numVars).." variable(s):")
	
	for i,result in ipairs(calcData.result) do
		local doesVary = calcData.numbersVary[i]
		local a  = string.format("%.5f", result.a)
		local b  = string.format("%.5f", result.b)
		local c  = string.format("%.5f", result.c)
		local R2 = string.format("%.5f", result.R2)
		local index = calcData.numbersIndex[i]
		local typeName = uespLog.GetSkillMechanicName(result.type)
		
		if (doesVary) then
			uespLog.Msg(".     $"..tostring(index)..": "..a..", "..b..", "..c..", "..R2.."  ("..typeName..", values "..tostring(result.min).."-"..tostring(result.max)..")")
		end
	end	
	
	uespLog.Msg(tostring(coefData.newDesc))
	return true
end


function uespLog.FindSkillAbilityData(name)
	name = string.lower(name)
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		if (string.lower(abilityData.name) == name) then
			return abilityData, uespLog.SkillCoefData[abilityId], abilityId
		end
	end
	
	return nil, nil, nil
end


function uespLog.ClearSavedSkillCoefData()

	uespLog.savedVars.skillCoef.data.coefData = {}
	uespLog.SkillCoefData = uespLog.savedVars.skillCoef.data.coefData
	
	uespLog.SkillCoefSavedIds = {}
	uespLog.SkillCoefCalcData = {}
	uespLog.SkillCoefDataPointCount = 0
	uespLog.SkillCoefNumValidCoefCount = 0
	uespLog.SkillCoefNumBadCoefCount = 0
	uespLog.SkillCoefBadData = {}
	uespLog.SkillCoefDataIsCalculated = false
end


function uespLog.ClearSkillCoefData()

	uespLog.savedVars.skillCoef.data.coefData = {}
	uespLog.savedVars.skillCoef.data.abilityData = {}
	
	uespLog.SkillCoefData = uespLog.savedVars.skillCoef.data.coefData
	uespLog.SkillCoefAbilityData = uespLog.savedVars.skillCoef.data.abilityData
	
	uespLog.SkillCoefSavedIds = {}
	uespLog.SkillCoefCalcData = {}
	uespLog.SkillCoefAbilityCount = 0
	uespLog.SkillCoefDataPointCount = 0
	uespLog.SkillCoefNumValidCoefCount = 0
	uespLog.SkillCoefNumBadCoefCount = 0
	uespLog.SkillCoefBadData = {}
	uespLog.SkillCoefDataIsCalculated = false
end


function uespLog.CaptureSkillCoefData()
	local numSkillTypes = GetNumSkillTypes()
	local skillType
	local skillIndex
	local abilityIndex
	local skillCount = 0
	local result
		
	uespLog.Msg("Saving current skill data for character...")
	
	uespLog.SkillCoefArmorCountLA = uespLog.CountEquippedArmor(ARMORTYPE_LIGHT)
	uespLog.SkillCoefArmorCountMA = uespLog.CountEquippedArmor(ARMORTYPE_MEDIUM)
	uespLog.SkillCoefArmorCountHA = uespLog.CountEquippedArmor(ARMORTYPE_HEAVY)
	uespLog.SkillCoefArmorTypeCount = uespLog.CountEquippedArmorTypes()
	uespLog.SkillCoefWeaponCountDagger = uespLog.CountEquippedWeapons(WEAPONTYPE_DAGGER)
	
	uespLog.SkillCoefSavedIds = {}

	for skillType = 1, numSkillTypes do
		local numSkillLines = GetNumSkillLines(skillType)
		local skillTypeName = uespLog.GetSkillTypeName(skillType)
		
		for skillIndex = 1, numSkillLines do
			local numSkillAbilities = GetNumSkillAbilities(skillType, skillIndex)
					
			for abilityIndex = 1, numSkillAbilities do
				local name, _, rank, passive, ultimate, purchase, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, abilityIndex)
				local level, maxLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, abilityIndex)
				local ability1 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, false)
				local ability2 = GetSkillAbilityId(skillType, skillIndex, abilityIndex, true)
				local ability3 = -1
				local ability4 = -1
				local ability5 = -1
				
				if (level == 0 or level == nil) then 
					level = 1
				end
				
				
			
				if (progressionIndex ~= nil and progressionIndex > 0) then
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 1), 1)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 2), 2)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 3), 3)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 0, 4), 4)
					if (result) then skillCount = skillCount + 1 end
					
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 1), 1)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 2), 2)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 3), 3)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 1, 4), 4)
					if (result) then skillCount = skillCount + 1 end
					
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 1), 1)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 2), 2)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 3), 3)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(GetAbilityProgressionAbilityId(progressionIndex, 2, 4), 4)
					if (result) then skillCount = skillCount + 1 end
				else
					result = uespLog.SaveSkillCoefData(ability1, level)
					if (result) then skillCount = skillCount + 1 end
					result = uespLog.SaveSkillCoefData(ability2, level + 1)
					if (result) then skillCount = skillCount + 1 end
				end
			
			end
		end
	end
	
	skillCount = skillCount + uespLog.CaptureMissingSkillCoefData()
	
	uespLog.Msg(".     Saved data for "..tostring(skillCount).." skills!")
	uespLog.SkillCoefDataPointCount = uespLog.SkillCoefDataPointCount + 1
	return true
end


function uespLog.CaptureMissingSkillCoefData()
	skillCount = 0
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
	
		if (uespLog.SkillCoefSavedIds[abilityId] == nil) then
			uespLog.SaveSkillCoefData(abilityId)
			skillCount = skillCount + 1
		end
		
	end
	
	return skillCount
end


-- After equipping/unequipping items it can take several seconds until skill values 'reset'.
-- To check if the skill values have reset properly we check the value of a known skill to
-- see if it matches the expected value.
function uespLog.IsSafetoSaveSkillCoef()
	local description = GetAbilityDescription(uespLog.SKILLCOEF_CHECK_ABILITYID)
	 
	if (description == nil or description == "") then
		return true
	end
	
	local iter = string.gmatch(description, "%d+[.]?%d*")
	local i = 1
		
	for number in iter do
	
		if (i == uespLog.SKILLCOEF_CHECK_INDEX) then
			local value = tonumber(number)
			
			if (value ~= uespLog.SKILLCOEF_CHECK_VALUE) then
				uespLog.DebugExtraMsg("Error: Skill value of "..tostring(value).." does not match expected value of "..tostring(uespLog.SKILLCOEF_CHECK_VALUE).."!")
				return false
			end
		end
		
		i = i + 1
	end		
	
	return true
end


function uespLog.InitSkillCoefData(abilityId, rank)
	local name = GetAbilityName(abilityId)
	local description = GetAbilityDescription(abilityId)
	local isNew = false
		
	if (abilityId <= 0 or name == "" or description == "") then
		return false, false
	end
	
	if (uespLog.SkillCoefData[abilityId] == nil) then
		uespLog.SkillCoefData[abilityId] = {}
	end
	
	local cost, mechanic = GetAbilityCost(abilityId)
	local passive = IsAbilityPassive(abilityId)
	rank = rank or -1
	
	if (uespLog.SkillCoefAbilityData[abilityId] == nil) then
		isNew = true
		
		uespLog.SkillCoefAbilityData[abilityId] = 
		{
			["name"] = name,
			["rank"] = rank,
			["passive"] = passive,
			["cost"] = cost,
			["id"]   = abilityId,
			["desc"] = description,
			["type"] = mechanic,
			["data"] = {},
			["numVars"] = -1,
			["numbersVary"] = {},
			["numbersIndex"] = {},
		}
		
		uespLog.SkillCoefAbilityCount = uespLog.SkillCoefAbilityCount + 1
	elseif (uespLog.SkillCoefAbilityData[abilityId].rank <= 0 and rank > 0) then
		uespLog.SkillCoefAbilityData[abilityId].rank = rank
	end

	return true, isNew
end


function uespLog.SaveSkillCoefData(abilityId, rank, passive)
	--POWERTYPE_MAGICKA == 0
	--POWERTYPE_STAMINA == 6
	--POWERTYPE_ULTIMATE == 10
	
	if (not uespLog.InitSkillCoefData(abilityId, rank)) then
		return false
	end
	
	uespLog.SkillCoefSavedIds[abilityId] = true
	
	local i = #(uespLog.SkillCoefData[abilityId])
	local description = GetAbilityDescription(abilityId)
	
	uespLog.SkillCoefData[abilityId][i+1] = 
	{
		["mag"]  = GetPlayerStat(STAT_MAGICKA_MAX),
		["sta"]  = GetPlayerStat(STAT_STAMINA_MAX),
		["hea"]  = GetPlayerStat(STAT_HEALTH_MAX),
		["sd"] 	 = GetPlayerStat(STAT_SPELL_POWER),
		["wd"]   = GetPlayerStat(STAT_POWER),
		["la"]   = uespLog.SkillCoefArmorCountLA,
		["ma"]   = uespLog.SkillCoefArmorCountMA,
		["ha"]   = uespLog.SkillCoefArmorCountHA,
		["dagger"] = uespLog.SkillCoefWeaponCountDagger,
		["armortypes"] = uespLog.SkillCoefArmorTypeCount,
		["desc"] = description,
	}
	
	return true
end


function uespLog.CountEquippedArmor(armorType)
	local numItems = GetBagSize(BAG_WORN)
	local armorCount = 0
	
	for i = 0, numItems do
		if (armorType == GetItemArmorType(BAG_WORN, i)) then
			armorCount = armorCount + 1
		end
	end
		
	return armorCount
end


function uespLog.CountEquippedArmorTypes()
	local numItems = GetBagSize(BAG_WORN)
	local laCount = 0
	local maCount = 0
	local haCount = 0
	local armorCount = 0
	
	for i = 0, numItems do
		armorType = GetItemArmorType(BAG_WORN, i)
		
		if (armorType == ARMORTYPE_LIGHT) then
			laCount = laCount + 1
		elseif (armorType == ARMORTYPE_MEDIUM) then
			maCount = maCount + 1			
		elseif (armorType == ARMORTYPE_HEAVY) then
			haCount = haCount + 1			
		end
	end
	
	if (laCount > 0) then
		armorCount = armorCount + 1
	end
	
	if (maCount > 0) then
		armorCount = armorCount + 1
	end
	
	if (haCount > 0) then
		armorCount = armorCount + 1
	end	
		
	return armorCount
end


function uespLog.CountEquippedWeapons(weaponType)
	-- Bar 1: 4/5
    -- Bar 2: 20/21
	local numItems = GetBagSize(BAG_WORN)
	local weaponCount = 0
	local activeBar = GetActiveWeaponPairInfo()
	
	if (activeBar == 1) then
	
		if (weaponType == GetItemWeaponType(BAG_WORN, 4)) then
			weaponCount = weaponCount + 1
		end
		
		if (weaponType == GetItemWeaponType(BAG_WORN, 5)) then
			weaponCount = weaponCount + 1
		end
	else
	
		if (weaponType == GetItemWeaponType(BAG_WORN, 20)) then
			weaponCount = weaponCount + 1
		end
		
		if (weaponType == GetItemWeaponType(BAG_WORN, 21)) then
			weaponCount = weaponCount + 1
		end
	end
		
	return weaponCount
end


function uespLog.ParseSkillCoefData()

	for abilityId, skillsData in pairs(uespLog.SkillCoefData) do
		uespLog.ParseSkillCoefDataSkill(abilityId, skillsData)
	end
	
	return true
end


function uespLog.ParseSkillCoefDataSkill(abilityId, skillsData)

	for i,data in ipairs(skillsData) do
		local iter = string.gmatch(data['desc'], "%d+[.]?%d*")
		data['numbers'] = {}
		
		for number in iter do
			table.insert(data['numbers'], tonumber(number))
		end
		
	end
	
end


function uespLog.ComputeSkillCoef()
	uespLog.ParseSkillCoefData()
	
	if (uespLog.SkillCoefDataPointCount < 3) then
		uespLog.Msg("Error: You need a minimum of 3 data points to compute skill coefficients.")
		return false
	end
	
	uespLog.SkillCoefNumValidCoefCount = 0
	
	for abilityId, skillsData in pairs(uespLog.SkillCoefData) do
	
		if (uespLog.CheckSkillCoef(abilityId, skillsData)) then
			uespLog.ComputeSkillCoefSkill(abilityId, skillsData)
		end
		
	end
	
	uespLog.ReplaceSkillDescriptions()
	uespLog.LogSkillCoefData()
	uespLog.SkillCoefDataIsCalculated = true
	return true
end


function uespLog.CheckSkillCoef(abilityId, skillsData)
	local numbersCheck = {}
	local abilityData = uespLog.SkillCoefAbilityData[abilityId]
	local calcData = uespLog.SkillCoefCalcData[abilityId]
	
	if (calcData == nil) then
		uespLog.SkillCoefCalcData[abilityId] = { }
		calcData = uespLog.SkillCoefCalcData[abilityId]
	end
	
	abilityData.numVars = 0
	calcData.numVars = 0
	calcData.numbersVary = {}
	calcData.numbersIndex = {}
	
	if (#skillsData == 0) then
		return false
	end
	
	for i,number in ipairs(skillsData[1].numbers) do
		table.insert(numbersCheck, number)
		table.insert(calcData.numbersVary, false)
	end
	
	for i = 2, #skillsData do
		for j,number in ipairs(skillsData[i].numbers) do
			if (number ~= numbersCheck[j]) then
				calcData.numbersVary[j] = true
			end
		end
	end
	
	local index = 1
	
	for i,number in ipairs(calcData.numbersVary) do
		if (calcData.numbersVary[i]) then
			abilityData.numVars = abilityData.numVars + 1
			calcData.numVars    = calcData.numVars + 1
			table.insert(calcData.numbersIndex, index)
			index = index + 1
		else
			table.insert(calcData.numbersIndex, 0)
		end
	end
	
	return (abilityData.numVars > 0)
end


function uespLog.ComputeSkillCoefSkill(abilityId, skillsData)
    -- z = ax + by + c
	-- x = Mag/Sta
	-- y = SD/WD
	-- z = Tooltip value
	-- X = [ a, b, c ]
	-- A X = B
	-- X = Ainv B	
	local abilityData = uespLog.SkillCoefAbilityData[abilityId]
	local calcData = uespLog.SkillCoefCalcData[abilityId]
	
	calcData.data = {}
	calcData.numPoints = #skillsData
	
	if (calcData.numPoints < 3) then
		return false
	end
	
	local numberCount = #(skillsData[1].numbers)
	
	if (numberCount < 0) then
		return false
	end
	
	local coefData = {}
	local allInvalid = true
	coefData.A = {}
	coefData.Ainv = {}
	coefData.isValid = true
	coefData.AisValid = { }
	coefData.B = {}
	coefData.result = {}
	
	for i = 1, numberCount do
		local numberType = uespLog.GetSkillCoefNumberMechanic(abilityData, i)
	
		if (calcData.numbersVary[i]) then
			local A = uespLog.SkillCoefComputeAMatrix(skillsData, abilityData, i)
			local Ainv, AisValid = uespLog.SkillCoefComputeAMatrixInv(A)
			local B = uespLog.SkillCoefComputeBMatrix(skillsData, abilityData, i)
			
			table.insert(coefData.A, A)
			table.insert(coefData.Ainv, Ainv)
			table.insert(coefData.AisValid, AisValid)
			table.insert(coefData.B, B)
			
			if (AisValid) then
				local result = uespLog.SkillCoefComputeMatrixMultAB(Ainv, B)
				result.R2 = uespLog.SkillCoefComputeR2(result, skillsData, abilityData, i)
				result.min, result.max, result.avg = uespLog.SkillCoefComputeMinMaxAvgNumbers(skillsData, i)
				result.type = numberType
				table.insert(coefData.result, result)
				
				if (not uespLog.isFinite(result.a) or not uespLog.isFinite(result.b) or not uespLog.isFinite(result.c) or not uespLog.isFinite(result.R2)) then
					uespLog.SkillCoefNumBadCoefCount = uespLog.SkillCoefNumBadCoefCount + 1
					table.insert(uespLog.SkillCoefBadData, { ['id'] = abilityId, ['numberIndex'] = i } )
				else
					allInvalid = false
					uespLog.SkillCoefNumValidCoefCount = uespLog.SkillCoefNumValidCoefCount + 1
				end
			else
				table.insert(coefData.result, { } )
			end
			
		else
			local value = skillsData[1].numbers[i]
			table.insert(coefData.result, { ['a']=0, ['b']=0, ['c']=value, ['R2']=1, ['min']=value, ['max']=value, ['avg']=value, ['type']=numberType } )
		end
		
	end
	
	calcData.data = coefData
	calcData.result = coefData.result
	calcData.isValid = not allInvalid
	return true
end


function uespLog.GetSkillCoefNumberMechanic(abilityData, numberIndex)
	local mechanic = abilityData.type
	local specialTypes = uespLog.SKILLCOEF_SPECIALTYPES[abilityData.id]
	
	if (specialTypes ~= nil) then
	
		if (type(specialTypes) == "table") then
		
			if (specialTypes[numberIndex] ~= nil) then
				mechanic = specialTypes[numberIndex]
			end
			
		else
			mechanic = specialTypes
		end
	end
	
	return mechanic	
end


function uespLog.GetSkillCoefXY(skill, abilityData, numberIndex)
	local x = skill.mag
	local y = skill.sd
	local mechanic = uespLog.GetSkillCoefNumberMechanic(abilityData, numberIndex)
			
	if (mechanic == uespLog.UESP_POWERTYPE_SOULTETHER) then
		x = math.max(skill.mag, skill.sta)
		y = skill.sd
	elseif (mechanic == uespLog.UESP_POWERTYPE_LIGHTARMOR) then
		x = skill.la
		y = 0
	elseif (mechanic == uespLog.UESP_POWERTYPE_MEDIUMARMOR) then
		x = skill.ma
		y = 0
	elseif (mechanic == uespLog.UESP_POWERTYPE_HEAVYARMOR) then
		x = skill.ha
		y = 0		
	elseif (mechanic == uespLog.UESP_POWERTYPE_ARMORTYPE) then
		x = skill.armortypes
		y = 0		
	elseif (mechanic == uespLog.UESP_POWERTYPE_WEAPONDAGGER) then
		x = skill.dagger
		y = 0
	elseif (mechanic == uespLog.UESP_POWERTYPE_DAMAGE) then
		x = skill.sd
		y = skill.wd
	elseif (mechanic == POWERTYPE_ULTIMATE) then
		x = math.max(skill.mag, skill.sta)
		y = math.max(skill.sd, skill.wd)
	elseif (mechanic == POWERTYPE_STAMINA) then
		x = skill.sta
		y = skill.wd
	elseif (mechanic == POWERTYPE_HEALTH) then
		x = skill.hea
		y = 0
	elseif (mechanic == uespLog.UESP_POWERTYPE_ASSASSINATION) then
		x = 0	-- TODO - Actually count skills
		y = 0		
	end
	
	return x, y
end


function uespLog.SkillCoefComputeR2(coef, skillsData, abilityData, numberIndex)
	local R2 = 0
	local count = #skillsData
	local averageZ = 0
	local SSres = 0
	local SStot = 0
	local x = 0
	local y = 0
	
	if (count == 0 or coef.a == nil ) then
		return R2
	end
	
	for i,skill in ipairs(skillsData) do
		local z = skill.numbers[numberIndex]
		averageZ = averageZ + z
	end
	
	averageZ = averageZ / count
	
	for i, skill in ipairs(skillsData) do
		x, y = uespLog.GetSkillCoefXY(skill, abilityData, numberIndex)
				
		local z = skill.numbers[numberIndex]
		local f = x * coef.a + y * coef.b + coef.c
		local e = z - f
		local d = z - averageZ
		
		SStot = SStot + d * d
		SSres = SSres + e * e
	end
	
	if (SStot == 0) then
		return R2
	end

	R2 = 1 - SSres / SStot
	return R2
end


function uespLog.SkillCoefComputeMatrixMultAB(A, B)
	local result = {}
	
	if (A.size == 2) then
		result.a = A[11] * B[1] + A[13] * B[3]
		result.b = 0
		result.c = A[31] * B[1] + A[33] * B[3]
	else
		result.a = A[11] * B[1] + A[12] * B[2] + A[13] * B[3]
		result.b = A[21] * B[1] + A[22] * B[2] + A[23] * B[3]
		result.c = A[31] * B[1] + A[32] * B[2] + A[33] * B[3]
	end
	
	return result
end


function uespLog.SkillCoefComputeAMatrix(skillsData, abilityData, numberIndex)
	-- A =  sum_i x[i]*x[i],    sum_i x[i]*y[i],    sum_i x[i]
	--		sum_i x[i]*y[i],    sum_i y[i]*y[i],    sum_i y[i]
	--		sum_i x[i],         sum_i y[i],         sum_i 1
	
	local A = {}
	local x = 0
	local y = 0
	
	A[11] = 0
	A[12] = 0
	A[13] = 0
	A[21] = 0
	A[22] = 0
	A[23] = 0
	A[31] = 0
	A[32] = 0
	A[33] = 0
	A['size'] = 3
	
	for i,skill in ipairs(skillsData) do
		x, y = uespLog.GetSkillCoefXY(skill, abilityData, numberIndex)
		
		A[11] = A[11] + x*x
		A[12] = A[12] + x*y
		A[13] = A[13] + x
		A[21] = A[21] + x*y
		A[22] = A[22] + y*y
		A[23] = A[23] + y
		A[31] = A[31] + x
		A[32] = A[32] + y
		A[33] = A[33] + 1
	end
	
	if (A[12] == 0 and A[21] == 0 and A[22] == 0 and A[23] == 0 and A[32] == 0) then
		A['size'] = 2
	end
	
	return A
end


function uespLog.SkillCoefComputeMinMaxAvgNumbers(skillsData, numberIndex)
	local minValue = 0
	local maxValue = 0
	local sum = 0
	
	if (#skillsData < 1) then
		return minValue, maxValue, sum
	end
	
	minValue = skillsData[1].numbers[numberIndex]
	maxValue = minValue
	sum = minValue
	
	for i = 2, #skillsData do
		skill = skillsData[i]
		value = skill.numbers[numberIndex]
		sum = sum + minValue
		
		if (minValue > value) then
			minValue = value
		end
		
		if (maxValue < value) then
			maxValue = value
		end
	end
	
	return minValue, maxValue, sum / #skillsData
end


function uespLog.SkillCoefComputeBMatrix(skillsData, abilityData, numberIndex)
	-- B =  sum_i x[i]*z[i],    sum_i y[i]*z[i],    sum_i z[i]
	
	local B = {}
	local x = 0
	local y = 0
	
	B[1] = 0
	B[2] = 0
	B[3] = 0
	
	for i, skill in ipairs(skillsData) do
		z = skill.numbers[numberIndex]
		x, y = uespLog.GetSkillCoefXY(skill, abilityData, numberIndex)
		
		B[1] = B[1] + x*z
		B[2] = B[2] + y*z
		B[3] = B[3] + z		
	end
	
	return B
end


function uespLog.SkillCoefComputeAMatrixInv(A)
	local Adet = uespLog.SkillCoefComputeAMatrixDet(A)
	local Ainv = {}
		
	if (det == 0) then
		Ainv['size'] = A['size']
		Ainv[11] = 0
		Ainv[12] = 0
		Ainv[13] = 0
		Ainv[21] = 0
		Ainv[22] = 0
		Ainv[23] = 0
		Ainv[31] = 0
		Ainv[32] = 0
		Ainv[33] = 0

		return Ainv, false
	end
	
	if (A.size == 2) then
		Ainv[11] = A[33] / Adet
		Ainv[12] = 0
		Ainv[13] = -A[13] / Adet
		Ainv[21] = 0
		Ainv[22] = 0
		Ainv[23] = 0
		Ainv[31] = -A[31] / Adet
		Ainv[32] = 0
		Ainv[33] = A[11] / Adet
	else
		Ainv[11] = (A[22]*A[33] - A[32]*A[23]) / Adet
		Ainv[12] = (A[13]*A[32] - A[33]*A[12]) / Adet
		Ainv[13] = (A[12]*A[23] - A[22]*A[13]) / Adet
		Ainv[21] = (A[23]*A[31] - A[33]*A[21]) / Adet
		Ainv[22] = (A[11]*A[33] - A[31]*A[13]) / Adet
		Ainv[23] = (A[13]*A[21] - A[23]*A[11]) / Adet
		Ainv[31] = (A[21]*A[32] - A[31]*A[22]) / Adet
		Ainv[32] = (A[12]*A[31] - A[32]*A[11]) / Adet
		Ainv[33] = (A[11]*A[22] - A[21]*A[12]) / Adet
	end
	
	Ainv['size'] = A['size']
	return Ainv, true
end	


function uespLog.SkillCoefComputeAMatrixDet(A)
	local Adet = 0
	
	if (A.size == 2) then
		Adet = A[11]*A[33] - A[31]*A[13]
	else
		Adet = A[11]*A[22]*A[33] + A[12]*A[23]*A[31] + A[13]*A[21]*A[32] - A[31]*A[22]*A[13] - A[32]*A[23]*A[11] - A[33]*A[21]*A[12]
	end
	
	return Adet
end


function uespLog.SkillCoefNumber_Average(numbers)
	local sum = 0
	local count = #numbers
	local average = 0
	
	for i,number in ipairs(numbers) do
		sum = sum + number
	end
	
	if (count ~= 0) then
		average = sum / count
	end
	
	return average, sum
end


function uespLog.SkillCoefNumber_AverageDiff(numbers, value)
	local sum = 0
	local count = #numbers
	local average = 0
	
	for i,number in ipairs(numbers) do
		sum = sum + number - value
	end
	
	if (count ~= 0) then
		average = sum / count
	end
	
	return average, sum
end


function uespLog.ReplaceSkillDescriptions()
	
	for abilityId, abilityData in pairs(uespLog.SkillCoefAbilityData) do
		uespLog.ReplaceSkillDescriptionAbility(abilityData)
	end
	
end


function uespLog.ReplaceSkillDescriptionAbility(abilityData)
	local i = 0
	local calcData = uespLog.SkillCoefCalcData[abilityData.id]
	
	if (calcData == nil) then
		return abilityData.desc
	end
    
	local newDesc = string.gsub(abilityData.desc, "%d+[.]?%d*", function (number)
		i = i + 1
	
		if (calcData.numbersVary[i]) then
			return "$" .. tostring(calcData.numbersIndex[i])
		end
		
    end)
	
	abilityData.newDesc = newDesc
	return newDesc
end


function uespLog.isFinite(number)
	return number > -math.huge and number < math.huge 
end


function uespLog.GetSkillMechanicName(mechanic)
	local name = uespLog.SKILLCOEF_MECHANIC_NAMES[mechanic]
	
	if (name == nil) then
		name = tostring(mechanic)
	end
	
	return name
end


function uespLog.UpdateSkillCoefCounts()
	local lastAbilityId = 0
	
	uespLog.SkillCoefAbilityCount = 0
	uespLog.SkillCoefNumValidCoefCount = 0
	uespLog.SkillCoefNumBadCoefCount = 0
	uespLog.SkillCoefDataPointCount = 0
	
	for k, v in pairs(uespLog.SkillCoefAbilityData) do
		uespLog.SkillCoefAbilityCount = uespLog.SkillCoefAbilityCount + 1
		lastAbilityId = k
	end
	
	if (uespLog.SkillCoefData[lastAbilityId] ~= nil) then
		uespLog.SkillCoefDataPointCount = #uespLog.SkillCoefData[lastAbilityId]
	end
	
end