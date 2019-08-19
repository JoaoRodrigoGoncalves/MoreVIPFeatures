#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar c_VIPflag;
ConVar c_ChatTag;
ConVar c_enableRespawn;
ConVar c_RespawnsPerMap;
ConVar c_bonusHealth;
ConVar c_MaxHealth;
ConVar c_armor;
ConVar c_helmet;
ConVar c_mediShot;
ConVar c_taser;
ConVar c_taticalGrenade;
ConVar c_grenade;
ConVar c_flashbang;
ConVar c_smoke;
bool b_smoke = false;
bool b_flashbang = false;
bool b_grenade = false;
bool b_taticalGrenade = false;
bool b_taser = false;
bool b_mediShot = false;
bool b_helmet = false;
bool b_armor = false;
int i_MaxHealth;
int i_bonusHealth;
int i_respawns;
bool b_enableRespawn = false;
char s_ChatTag[128];
char s_VIPflag[30];

int respawnsLeft[MAXPLAYERS + 1];
bool b_canRespawn = true;
bool b_inRound = false;

public Plugin myinfo = 
{
	name = "[CS:GO] MoreVIPFeatures",
	author = "JoaoRodrigoGamer",
	description = "More in-game features for VIP players",
	version = PLUGIN_VERSION,
	url = "https://joaogoncalves.myftp.org/"
};

public void OnPluginStart()
{
	CreateConVar("MorevipFeatures_version", PLUGIN_VERSION, "MoreVIPFeatures version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_VIPflag = CreateConVar("MorevipFeatures_flag", "o", "The VIP flag needed to get the VIP Features");
	c_ChatTag = CreateConVar("MorevipFeatures_chatTag", "MoreVIPFeatures", "The used to be displayed on the chat. Eg. [MoreVIPFeatures] Test message");
	c_enableRespawn = CreateConVar("MorevipFeatures_respawn", "1", "Enable/disable respawning. 0 -> disabled, 1 -> enabled");
	c_RespawnsPerMap = CreateConVar("MorevipFeatures_respawns", "5", "Number os respawns per map");
	c_bonusHealth = CreateConVar("MorevipFeatures_bonusHealth", "10", "Bonus health amount the player gets per kill");
	c_MaxHealth = CreateConVar("MorevipFeatures_maxHealth", "150", "Max health the player can have.");
	c_armor = CreateConVar("MorevipFeatures_armor", "1", "Should the player get armor? 0 -> no, 1 -> yes");
	c_helmet = CreateConVar("MorevipFeatures_helmet", "1", "Should the player get an helmet? 0 -> no, 1 -> yes");
	c_mediShot = CreateConVar("MorevipFeatures_mediShot", "1", "Should the player get a mediShot (health shot)? 0 -> no, 1 -> yes");
	c_taser = CreateConVar("MorevipFeatures_taser", "1", "Should the player get a taser? 0 -> no, 1 -> yes");
	c_taticalGrenade = CreateConVar("MorevipFeatures_taticalGrenade", "1", "Should the player get a tatical grenade? 0 -> no, 1 -> yes");
	c_grenade = CreateConVar("MorevipFeatures_grenade", "1", "Should the player get a grenade? 0 -> no, 1 -> yes");
	c_flashbang = CreateConVar("MorevipFeatures_flashbang", "1", "Should the player get a flashbang? 0 -> no, 1 -> yes");
	c_smoke = CreateConVar("MorevipFeatures_flashbang", "1", "Should the player get a flashbang? 0 -> no, 1 -> yes");
	
	AutoExecConfig(true, "MoreVIPFeatures");
	LoadTranslations("MoreVIPFeatures.phrases.txt");
	
	// Load ConVars to their buffers
	GetConVarString(c_VIPflag, s_VIPflag, sizeof(s_VIPflag));
	GetConVarString(c_ChatTag, s_ChatTag, sizeof(s_ChatTag));
	b_enableRespawn = GetConVarBool(c_enableRespawn);
	i_respawns = GetConVarInt(c_RespawnsPerMap);
	i_bonusHealth = GetConVarInt(c_bonusHealth);
	i_MaxHealth = GetConVarInt(c_MaxHealth);
	b_armor = GetConVarBool(c_armor);
	b_helmet = GetConVarBool(c_helmet);
	b_mediShot = GetConVarBool(c_mediShot);
	b_taser = GetConVarBool(c_taser);
	b_taticalGrenade = GetConVarBool(c_taticalGrenade);
	b_grenade = GetConVarBool(c_grenade);
	b_flashbang = GetConVarBool(c_flashbang);
	b_smoke = GetConVarBool(c_smoke);
	
	if(StrEqual(s_VIPflag, "a", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_RESERVATION);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_RESERVATION);
	}
	else if (StrEqual(s_VIPflag, "b", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_GENERIC);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_GENERIC);
	}
	else if (StrEqual(s_VIPflag, "c", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_KICK);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_KICK);
	}
	else if (StrEqual(s_VIPflag, "d", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_BAN);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_BAN);
	}
	else if (StrEqual(s_VIPflag, "e", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_UNBAN);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_UNBAN);
	}
	else if (StrEqual(s_VIPflag, "f", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_SLAY);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_SLAY);
	}
	else if (StrEqual(s_VIPflag, "g", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CHANGEMAP);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CHANGEMAP);
	}
	else if (StrEqual(s_VIPflag, "h", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CONVARS);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CONVARS);
	}
	else if (StrEqual(s_VIPflag, "i", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CONFIG);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CONFIG);
	}
	else if (StrEqual(s_VIPflag, "j", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CHAT);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CHAT);
	}
	else if (StrEqual(s_VIPflag, "k", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_VOTE);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_VOTE);
	}
	else if (StrEqual(s_VIPflag, "l", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_PASSWORD);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_PASSWORD);
	}
	else if (StrEqual(s_VIPflag, "m", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_RCON);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_RCON);
	}
	else if (StrEqual(s_VIPflag, "n", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CHEATS);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CHEATS);
	}
	else if (StrEqual(s_VIPflag, "z", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_ROOT);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_ROOT);
	}
	else if (StrEqual(s_VIPflag, "o", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM1);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM1);
	}
	else if (StrEqual(s_VIPflag, "p", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM2);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM2);
	}
	else if (StrEqual(s_VIPflag, "q", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM3);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM3);
	}
	else if (StrEqual(s_VIPflag, "r", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM4);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM4);
	}
	else if (StrEqual(s_VIPflag, "s", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM5);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM5);
	}
	else if (StrEqual(s_VIPflag, "t", true))
	{
		RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM6);
		RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM6);
	}
	else
	{
		SetFailState("[MoreVIPFeatures] %t", "Could not get flag");
	}
	
	/////////////////// HOOKS /////////////////////////
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public void OnClientPutInServer(int client)
{
	respawnsLeft[client] = i_respawns;
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if((IsClientInGame(client)) && (GetClientTeam(client) > 2) && (!b_inRound))
	{
		if(IsVIP(client))
		{
			if (GameRules_GetProp("m_bWarmupPeriod") == 0)
			{
				b_inRound = true;
			}

			////////
			if(b_armor)
			{
				SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
				if(b_helmet)
				{
					SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
				}
			}
			
			if(b_mediShot)
			{
				RemovePlayerItem(client, 12);
				GivePlayerItem(client, "weapon_healthshot");
			}
			
			if(b_taticalGrenade)
			{
				GivePlayerItem(client, "weapon_tagrenade");
			}
			
			if(b_grenade)
			{
				GivePlayerItem(client, "weapon_hegrenade");
			}
			
			if(b_flashbang)
			{
				GivePlayerItem(client, "weapon_flashbang");
			}
			
			if(b_smoke)
			{
				GivePlayerItem(client, "weapon_smokegrenade");
			}
			
			if(b_taser)
			{
				GivePlayerItem(client, "weapon_taser");
			}
			
		}
	}
	
}

public Action vipSpawn(int client, int args)
{
	respawnPlayer(client);	
	return Plugin_Handled;
}

public Action VipMenu(int client, int agrs)
{
	Menu vipFeatures = new Menu(VipMenuHandler);
	vipFeatures.SetTitle("%t", "vipFeatures");
	
	if(b_armor)
	{
		if(b_helmet)
		{
			vipFeatures.AddItem("0", "kev + helmet", ITEMDRAW_DISABLED);
		}
		else
		{
			vipFeatures.AddItem("0", "kev", ITEMDRAW_DISABLED);
		}
	}
	
	if(b_mediShot)
	{
		vipFeatures.AddItem("1", "Health Shot", ITEMDRAW_DISABLED);
	}
	
	if(b_taser)
	{
		vipFeatures.AddItem("2", "Taser", ITEMDRAW_DISABLED);
	}
	
	if(b_taticalGrenade)
	{
		vipFeatures.AddItem("3", "TAG", ITEMDRAW_DISABLED);
	}
	
	if(b_grenade)
	{
		vipFeatures.AddItem("4", "he grenade", ITEMDRAW_DISABLED);
	}
	
	if(b_flashbang)
	{
		vipFeatures.AddItem("5", "flashbang", ITEMDRAW_DISABLED);
	}
	
	if(b_smoke)
	{
		vipFeatures.AddItem("6", "smoke", ITEMDRAW_DISABLED);
	}
	
	vipFeatures.ExitButton = true;
	vipFeatures.Display(client, 50);
}

public int VipMenuHandler(Menu menu, MenuAction action, int client, int selection)
{
	return Plugin_Handled;
}

public Action OnPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsVIP(attacker))
	{
		int health = GetEntProp(attacker, Prop_Send, "m_iHealth");
		health = health + i_bonusHealth;
		SetEntityHealth(attacker, health);
		if(health > i_MaxHealth)
		{
			SetEntityHealth(attacker, i_MaxHealth);
		}
	}
	return Plugin_Continue;
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	b_canRespawn = true;
}

public void OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	b_canRespawn = false;
	b_inRound = false;
}

public void respawnPlayer(int client)
{
	if(IsClientInGame(client))
	{
		if((!IsPlayerAlive(client))  && (GetClientTeam(client) > 2))
		{
			if(b_enableRespawn)
			{
				if(IsVIP(client))
				{
					if(b_canRespawn)
					{
						if(respawnsLeft[client] != 0)
						{
							char clientName[MAX_NAME_LENGTH];
							CS_RespawnPlayer(client);
							respawnsLeft[client] = respawnsLeft[client] - 1;
							if(GetClientName(client, clientName, sizeof(clientName)))
							{
								PrintHintTextToAll("%t", "%s respawned", clientName);
							}
							else
							{
								PrintHintTextToAll("%t", "player respawned");
							}
						}
						else
						{
							PrintToChat(client, "\x04[%s] \x0A%t", s_ChatTag, "out of respawns", i_respawns);
						}
					}
					else
					{
						PrintToChat(client, "\x04[%s] \x0A%t", s_ChatTag, "cannot respawn after round end");
					}
				}
				else
				{
					PrintToChat(client, "\x04[%s] \x0A%t", s_ChatTag, "vipFeature");
				}
			}
			else
			{
				PrintToChat(client, "\x04[%s] \x0A%T", s_ChatTag, "respawn disabled");
			}
		}
		else
		{
			PrintToChat(client, "\x04[%s] \x0A%t", s_ChatTag, "respawnAlive");
		}
	}
}

public bool IsVIP(int client)
{
	return CheckCommandAccess(client, "sm_vipmenu", ReadFlagString(s_VIPflag)) ? true : false;
}