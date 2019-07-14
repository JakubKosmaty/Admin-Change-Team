#include <adminmenu>
#include <simple_colors>

#pragma semicolon 1
#pragma newdecls required

int g_iIgnoreFlags;

TopMenu g_tmAdminMenu;

#define			NAME 		"Admin Change Team"
#define			AUTHOR		"Master"
#define			VERSION		"1.0"
#define			URL			"https://cswild.pl/"

public Plugin myinfo =
{ 
	name	= NAME,
	author	= AUTHOR,
	version	= VERSION,
	url		= URL
};

public void OnPluginStart()
{
    char sBuffer[32];

    ConVar cvar = CreateConVar("Master_Admin_Change_Team_Ignore_Flag", "", "Players with flag ignore in menu", 0); cvar.AddChangeHook(OnCvarChange);
    cvar.GetString(sBuffer, sizeof(sBuffer));

    g_iIgnoreFlags = ReadFlagString(sBuffer);

    AutoExecConfig(true, "Master_Admin_Change_Team");

    TopMenu topmenu;

    if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
        OnAdminMenuReady(topmenu);

    LoadTranslations("Master_Admin_Change_Team.phrases");
}

public void OnCvarChange(ConVar cvar, char[] oldValue, char[] newValue)
{
	g_iIgnoreFlags = ReadFlagString(newValue);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu aTopMenus = TopMenu.FromHandle(aTopMenu);

    if(aTopMenus == g_tmAdminMenu)
		return;

    g_tmAdminMenu = aTopMenus;

    TopMenuObject CategoryId = g_tmAdminMenu.AddCategory("master_ct", Handle_change_team, "master_ct", ADMFLAG_BAN);

    if(CategoryId == INVALID_TOPMENUOBJECT)
		return;

    g_tmAdminMenu.AddItem("master_ct_item", Handle_change_team_item, CategoryId, "master_ct_item", ADMFLAG_BAN);
}

public void Handle_change_team(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int iClient, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
    {
        Format(buffer, maxlength, "%T", "Move_Player", iClient);
    }
}

public void Handle_change_team_item(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int iClient, char[] buffer, int maxlength)
{
    if(action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "%T", "Choose_Player", iClient);
    }
    else if(action == TopMenuAction_SelectOption)
    {
        BuildMenu(iClient);
    }
}

void BuildMenu(int iClient)
{
    Menu menu = new Menu(Menu_Handler);
    menu.SetTitle("%T", "Select_Player_To_Move", iClient);

    char sBuffer[128];

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i))
            continue;

        if(IsClientSourceTV(i))
            continue;

        if(HasFlag(i, g_iIgnoreFlags))
            continue;

        Format(sBuffer, sizeof(sBuffer), "%N", i);

        char sTarget[8];
        Format(sTarget, sizeof(sTarget), "%d", GetClientUserId(i));

        menu.AddItem(sTarget, sBuffer);
    }

    if(!menu.ItemCount)
    {
        Format(sBuffer, sizeof(sBuffer), "%T", "No_Players_Available", iClient);
        menu.AddItem(NULL_STRING, sBuffer, ITEMDRAW_DISABLED);
    }

    menu.ExitBackButton = true;
    menu.Display(iClient, 0);
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
            delete menu;
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack && g_tmAdminMenu)
            {
                g_tmAdminMenu.Display(client, TopMenuPosition_LastCategory);
            }
        }
        case MenuAction_Select:
        {
            char sBuffer[128];

            char sTargetUserID[8];
            menu.GetItem(param2, sTargetUserID, sizeof(sTargetUserID));

            Menu menuTeam = new Menu(MenuTeam_Handler);
            menuTeam.SetTitle("%T", "Choose_Team", client);

            Format(sBuffer, sizeof(sBuffer), "%T", "Spectator", client);
            menuTeam.AddItem(sTargetUserID, sBuffer);

            Format(sBuffer, sizeof(sBuffer), "%T", "Terrorists", client);
            menuTeam.AddItem(sTargetUserID, sBuffer);

            Format(sBuffer, sizeof(sBuffer), "%T", "Counter_Terrorists", client);
            menuTeam.AddItem(sTargetUserID, sBuffer);

            menuTeam.ExitBackButton = true;
            menuTeam.Display(client, 60);
        }
    }
}

public int MenuTeam_Handler(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
            delete menu;
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
            {
                BuildMenu(client);
            }
        }
        case MenuAction_Select:
        {
            char sTargetUserID[8];
            menu.GetItem(param2, sTargetUserID, sizeof(sTargetUserID));
    
            int target = GetClientOfUserId(StringToInt(sTargetUserID));

            if(target)
            {
                param2++;

                char sTeam[64];
                Format(sTeam, sizeof(sTeam), "%T", (param2 == 1) ? "Spectator" : (param2 == 2) ? "Terrorists" : "Counter_Terrorists", client);

                if(GetClientTeam(target) != param2)
                {
                    ChangeClientTeam(target, param2);

                    S_PrintToChat(client, "%T %T", "Chat_Tag", client, "Player_Moved", client, target, sTeam);

                    S_PrintToChat(target, "%T %T", "Chat_Tag", target, "Admin_Moved", target, client, sTeam);
            
                }
                else
                {
                    S_PrintToChat(client, "%T %T", "Chat_Tag", client, "Already_In_Team", client, target, sTeam);
                }
            }
            else
            {
                S_PrintToChat(client, "%T %T", "Chat_Tag", client, "Player_Is_Unavailable", client);
            }
        }
    }
}

bool HasFlag(int client, int flag)
{
	return view_as<bool>(GetUserFlagBits(client) & flag);
}
