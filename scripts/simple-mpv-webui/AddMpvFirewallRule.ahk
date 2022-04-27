#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#NoTrayIcon
SetBatchLines -1
ListLines Off
Process, Priority,, A
SetWorkingDir %A_ScriptDir%

full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
}

Loop, read, ..\..\script-opts\webui.conf
{
	if RegExMatch(A_LoopReadLine, "^port=(\d+)$", port) {
		break
	}
}
if (!port1)
	ExitApp

if (A_IsAdmin) {
		FwPolicy2 := ComObjCreate("HNetCfg.FwPolicy2")
		Rules := FwPolicy2.Rules
		for rule in Rules
			if (rule.Name == "mpv")
				Rules.Remove("mpv")

		NewRule := ComObjCreate("HNetCfg.FWRule"), NewRuleUdp := ComObjCreate("HNetCfg.FWRule")
		NewRule.Description                 := NewRule.Name := "mpv"
		NewRule.Protocol                    := NET_FW_IP_PROTOCOL_TCP := 6
		NewRule.LocalPorts                  := port1
		NewRule.RemoteAddresses             := "*"
		NewRule.LocalAddresses              := NewRule.RemotePorts := "*"
		NewRule.Direction                   := NET_FW_RULE_DIR_IN := 1
		NewRule.InterfaceTypes              := "All"
		NewRule.Enabled                     := True
		NewRule.Profiles                    := NET_FW_PROFILE2_PRIVATE := 0x2 ; | NET_FW_PROFILE2_PUBLIC := 0x4 | NET_FW_PROFILE2_DOMAIN := 0x1 / NET_FW_PROFILE2_ALL := 0x7fffffff
		NewRule.Action                      := NET_FW_ACTION_ALLOW := 1

		NewRuleUdp.Description              := NewRuleUdp.Name := NewRule.Name
		NewRuleUdp.Protocol                 := NET_FW_IP_PROTOCOL_UDP := 17
		NewRuleUdp.LocalPorts               := NewRule.LocalPorts
		NewRuleUdp.RemoteAddresses          := NewRule.RemoteAddresses
		NewRuleUdp.LocalAddresses           := NewRuleUdp.RemotePorts := NewRule.RemotePorts
		NewRuleUdp.Direction                := NewRule.Direction
		NewRuleUdp.InterfaceTypes           := NewRule.InterfaceTypes
		NewRuleUdp.Enabled                  := NewRule.Enabled
		NewRuleUdp.Profiles                 := NewRule.Profiles
		NewRuleUdp.Action                   := NewRule.Action
		
		Rules.Add(NewRule), Rules.Add(NewRuleUdp)
}