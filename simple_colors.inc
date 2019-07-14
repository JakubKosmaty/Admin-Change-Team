char g_sColours[][] = 
{
    "{default}", "{red}", "{lightpurple}", "{green}", "{lime}", "{lightgreen}", "{lightred}", "{gray}", "{olive}", "{orange}", "{lightblue}", "{blue}", "{purple}"
},

g_sColoursCSGO[][] = 
{
    "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E"
};

stock void S_PrintToChat(int client, char[] szMessage, any ...)
{
    if(client && IsClientInGame(client) && !IsFakeClient(client))
    {
        char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];

        Format(szBuffer, sizeof(szBuffer), " \x01%s", szMessage);
        VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

        for(int i = 0; i < 13; i++)
        {
            ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColours[i], g_sColoursCSGO[i]);
        }
        ReplaceString(szNewMessage, sizeof(szNewMessage), "{TEAM}", "\x03");

        Handle hBf = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
        if(hBf != null)
        {
            if(GetUserMessageType() == UM_Protobuf)
            {
                Protobuf hProtoBuffer = UserMessageToProtobuf(hBf);
                hProtoBuffer.SetInt("ent_idx", client);
                hProtoBuffer.SetBool("chat", true);
                hProtoBuffer.SetString("msg_name", szNewMessage);
                hProtoBuffer.AddString("params", "");
                hProtoBuffer.AddString("params", "");
                hProtoBuffer.AddString("params", "");
                hProtoBuffer.AddString("params", "");
            }
            else
            {
                BfWrite hBfBuffer = UserMessageToBfWrite(hBf);
                hBfBuffer.WriteByte(client);
                hBfBuffer.WriteByte(true);
                hBfBuffer.WriteString(szNewMessage);
            }
        }
        EndMessage();
    }
}
