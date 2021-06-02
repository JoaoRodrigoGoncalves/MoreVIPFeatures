#pragma semicolon 1

#define PLUGIN_VERSION "1.1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar c_ChatTag;
ConVar c_enableRespawn;
ConVar c_RespawnsPerMap;
ConVar c_bonusHealth;
ConVar c_bonusHealthHeadShot;
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
int i_bonusHealthHeadShot;
int i_bonusHealth;
int i_respawns;
int i_grenadeSlotsNeeded = 0;
bool b_enableRespawn = false;
char s_ChatTag[128];

int respawnsLeft[MAXPLAYERS + 1];
bool b_canRespawn = true;
bool b_inRound = false;

public Plugin myinfo = 
{
	name = "[CS:GO] MoreVIPFeatures",
	author = "JoaoRodrigoGamer",
	description = "More in-game features for VIP players",
	version = PLUGIN_VERSION,
	url = "https://joaogoncalves.eu/"
};

public void OnPluginStart()
{
	CreateConVar("MorevipFeatures_version", PLUGIN_VERSION, "MoreVIPFeatures version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_ChatTag = CreateConVar("MorevipFeatures_chatTag", "MoreVIPFeatures", "The used to be displayed on the chat. Eg. [MoreVIPFeatures] Test message");
	c_enableRespawn = CreateConVar("MorevipFeatures_respawn", "1", "Enable/disable respawning. 0 -> disabled, 1 -> enabled");
	c_RespawnsPerMap = CreateConVar("MorevipFeatures_respawns", "5", "Number os respawns per map");
	c_bonusHealth = CreateConVar("MorevipFeatures_bonusHealth", "10", "Bonus health amount the player gets per kill");
	c_bonusHealthHeadShot = CreateConVar("MorevipFeatures_bonusHealthHeadShot", "15", "Bonus health amount the player gets per headshot kill");
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
	GetConVarString(c_ChatTag, s_ChatTag, sizeof(s_ChatTag));
	b_enableRespawn = GetConVarBool(c_enableRespawn);
	i_respawns = GetConVarInt(c_RespawnsPerMap);
	i_bonusHealth = GetConVarInt(c_bonusHealth);
	i_bonusHealthHeadShot = GetConVarInt(c_bonusHealthHeadShot);
	i_MaxHealth = GetConVarInt(c_MaxHealth);
	b_armor = GetConVarBool(c_armor);
	b_helmet = GetConVarBool(c_helmet);
	b_mediShot = GetConVarBool(c_mediShot);
	b_taser = GetConVarBool(c_taser);
	b_taticalGrenade = GetConVarBool(c_taticalGrenade);
	b_grenade = GetConVarBool(c_grenade);
	b_flashbang = GetConVarBool(c_flashbang);
	b_smoke = GetConVarBool(c_smoke);
		
	b_taticalGrenade ? i_grenadeSlotsNeeded++ : false;
	b_grenade ? i_grenadeSlotsNeeded++ : false;
	b_flashbang ? i_grenadeSlotsNeeded++ : false;
	b_smoke ? i_grenadeSlotsNeeded++ : false;
	
	if(FindConVar("ammo_grenade_limit_total").IntValue < i_grenadeSlotsNeeded)
	{
		FindConVar("ammo_grenade_limit_total").IntValue = i_grenadeSlotsNeeded;
	}

	RegAdminCmd("sm_vipmenu", VipMenu, ADMFLAG_CUSTOM1, "Open Vip Menu");
	RegAdminCmd("sm_vipspawn", vipSpawn, ADMFLAG_CUSTOM1, "Respawn");
	
	/////////////////// HOOKS /////////////////////////
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

stock bool HasWeapon(int client, const char[] weapon) 
{ 
    int length = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");  
      
    for (int i= 0; i < length; i++)   
    {   
        int item = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);   

        if (item != -1)   
        {   
            char classname[64];  
             
            if (GetEntityClassname(item, classname, sizeof(classname))) 
            { 
                if (StrEqual(weapon, classname, false)) 
                { 
                    return true; 
                } 
            } 
        }   
    }  

    return false; 
}

public void OnClientPutInServer(int client)
{
	b_inRound = false;
	respawnsLeft[client] = i_respawns;
}

public void OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if((IsClientInGame(client)) && (GetClientTeam(client) >= 2) && (!b_inRound))
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
				if(!HasWeapon(client,"weapon_healthshot"))
				{
					GivePlayerItem(client, "weapon_healthshot");
				}
			}
			
			if(b_taticalGrenade)
			{
				if(!HasWeapon(client, "weapon_tagrenade"))
				{
					GivePlayerItem(client, "weapon_tagrenade");
				}
			}
			
			if(b_grenade)
			{
				if(!HasWeapon(client, "weapon_hegrenade"))
				{
					GivePlayerItem(client, "weapon_hegrenade");
				}
			}
			
			if(b_flashbang)
			{
				if(!HasWeapon(client, "weapon_flashbang"))
				{
					GivePlayerItem(client, "weapon_flashbang");
				}
			}
			
			if(b_smoke)
			{
				if(!HasWeapon(client, "weapon_smokegrenade"))
				{
					GivePlayerItem(client, "weapon_smokegrenade");
				}
			}
			
			if(b_taser)
			{
				if(!HasWeapon(client, "weapon_taser"))
				{
					GivePlayerItem(client, "weapon_taser");
				}
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
	
	char armor[100];
	char helmet[100];
	char mediShot[100];
	char taser[100];
	char taticalGrenade[100];
	char grenade[100];
	char flashbang[100];
	char smokeGrenade[100];
	
	Format(armor, sizeof(armor), "%t", "armor");
	Format(helmet, sizeof(helmet), "%t", "armor+helmet");
	Format(mediShot, sizeof(mediShot), "%t", "healthShot");
	Format(taser, sizeof(taser), "%t", "taser");
	Format(taticalGrenade, sizeof(taticalGrenade), "%t", "TAG");
	Format(grenade, sizeof(grenade), "%t", "grenade");
	Format(flashbang, sizeof(flashbang), "%t", "flashbang");
	Format(smokeGrenade, sizeof(smokeGrenade), "%t", "smokeGrenade");
	
	if(b_armor)
	{
		if(b_helmet)
		{
			vipFeatures.AddItem("0", helmet, ITEMDRAW_DISABLED);
		}
		else
		{
			vipFeatures.AddItem("0", armor, ITEMDRAW_DISABLED);
		}
	}
	
	if(b_mediShot)
	{
		vipFeatures.AddItem("1", mediShot, ITEMDRAW_DISABLED);
	}
	
	if(b_taser)
	{
		vipFeatures.AddItem("2", taser, ITEMDRAW_DISABLED);
	}
	
	if(b_taticalGrenade)
	{
		vipFeatures.AddItem("3", taticalGrenade, ITEMDRAW_DISABLED);
	}
	
	if(b_grenade)
	{
		vipFeatures.AddItem("4", grenade, ITEMDRAW_DISABLED);
	}
	
	if(b_flashbang)
	{
		vipFeatures.AddItem("5", flashbang, ITEMDRAW_DISABLED);
	}
	
	if(b_smoke)
	{
		vipFeatures.AddItem("6", smokeGrenade, ITEMDRAW_DISABLED);
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
		if(GetEventBool(event, "headshot"))
		{
			health = health + i_bonusHealthHeadShot;
			if(health > i_MaxHealth)
			{
				SetEntityHealth(attacker, i_MaxHealth);
			}
			else
			{
				SetEntityHealth(attacker, health);
			}
		}
		else
		{
			health = health + i_bonusHealth;
			if(health > i_MaxHealth)
			{
				SetEntityHealth(attacker, i_MaxHealth);
			}
			else
			{
				SetEntityHealth(attacker, health);
			}
		}
	}
	return Plugin_Continue;
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Just to be sure that the grenade slots are kept between rounds
	FindConVar("ammo_grenade_limit_total").IntValue = i_grenadeSlotsNeeded;
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
		if((!IsPlayerAlive(client))  && (GetClientTeam(client) >= 2))
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
	return CheckCommandAccess(client, "sm_vipmenu", ADMFLAG_CUSTOM1);
}