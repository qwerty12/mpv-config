#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#NoTrayIcon
SetBatchLines -1
ListLines Off
Process, Priority,, A

RunAsTask() {                         ;  By SKAN,  http://goo.gl/yG6A1F,  CD:19/Aug/2014 | MD:24/Apr/2020

  Local CmdLine, TaskName, TaskExists, XML, TaskSchd, TaskRoot, RunAsTask
  Local TASK_CREATE := 0x2,  TASK_LOGON_INTERACTIVE_TOKEN := 3 

  Try TaskSchd  := ComObjCreate( "Schedule.Service" ),    TaskSchd.Connect()
    , TaskRoot  := TaskSchd.GetFolder( "\" )
  Catch
      Return "", ErrorLevel := 1    
  
  ScriptFullpath := getFinalPath(A_ScriptFullpath)
  if (!ScriptFullpath)
	ExitApp 1
  SplitPath, % ScriptFullpath,, ScriptDir
  CmdLine       := ( A_IsCompiled ? "" : """"  A_AhkPath """" )  A_Space  ( """" ScriptFullpath """"  )
  TaskName      := "[RunAsTask] " A_ScriptName " @" SubStr( "000000000"  DllCall( "NTDLL\RtlComputeCrc32"
                   , "Int",0, "WStr",CmdLine, "UInt",StrLen( CmdLine ) * 2, "UInt" ), -9 )

  Try RunAsTask := TaskRoot.GetTask( TaskName )
  TaskExists    := ! A_LastError 


  If ( not A_IsAdmin and TaskExists )      { 

    RunAsTask.Run( "" )
    ExitApp

  }

  If ( not A_IsAdmin and not TaskExists and not RegExMatch(DllCall("GetCommandLine", "str"), " /restart(?!\S)") )  { 

    Run *RunAs %CmdLine% /restart, %ScriptDir%, UseErrorLevel
    ExitApp

  }

  If ( A_IsAdmin and not TaskExists )      {  

    XML := "
    ( LTrim Join
      <?xml version=""1.0"" ?><Task xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task""><Regi
      strationInfo /><Triggers /><Principals><Principal id=""Author""><LogonType>InteractiveToken</LogonT
      ype><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><MultipleInstancesPolic
      y>Parallel</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><
      StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate>
      <StartWhenAvailable>false</StartWhenAvailable><RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAva
      ilable><IdleSettings><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleS
      ettings><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden><
      RunOnlyIfIdle>false</RunOnlyIfIdle><DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteApp
      Session><UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine><WakeToRun>false</WakeToRun><
      ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>4</Priority></Settings><Actions Context=""Author""><Exec>
      <Command>""" ( A_IsCompiled ? ScriptFullpath : A_AhkPath ) """</Command>
      <Arguments>" ( !A_IsCompiled ? """" ScriptFullpath  """" : "" )   "</Arguments>
      <WorkingDirectory>" ScriptDir "</WorkingDirectory></Exec></Actions></Task>
    )"    

    TaskRoot.RegisterTask( TaskName, XML, TASK_CREATE, "", "", TASK_LOGON_INTERACTIVE_TOKEN )

  }         

Return TaskName, ErrorLevel := 0
}

getFinalPath(path)
{
	static MAX_PATH := 260, GENERIC_READ := 0x80000000, FILE_SHARE_READ := 0x00000001, OPEN_EXISTING := 3, FILE_ATTRIBUTE_NORMAL := 128, INVALID_HANDLE_VALUE := -1
	ret := ""

	hFile := DllCall("CreateFileW", "WStr", path, "UInt", GENERIC_READ, "UInt", FILE_SHARE_READ, "Ptr", 0, "UInt", OPEN_EXISTING, "UInt", FILE_ATTRIBUTE_NORMAL, "Ptr", 0, "Ptr")
	if (hFile != INVALID_HANDLE_VALUE) {
		VarSetCapacity(out, MAX_PATH * 2)
		if (DllCall("GetFinalPathNameByHandleW", "Ptr", hFile, "WStr", out, "UInt", MAX_PATH, "UInt", 0, "UInt") < MAX_PATH)
			ret := LTrim(out, "\?")
		DllCall("CloseHandle", "Ptr", hFile)
	}

	return ret
}

getMpvPath()
{
	static mpvPath := ""
	if (mpvPath)
		return mpvPath

	EnvGet, SCOOP_HOME, SCOOP_HOME
	if (!SCOOP_HOME)
		SCOOP_HOME := "C:\Users\" . A_UserName . "\scoop"

	mpvPath := getFinalPath(SCOOP_HOME . "\apps\mpv-git\current\mpv.exe")
	if (mpvPath)
		mpvPath := Format("{:.1}{:L}", mpvPath, SubStr(mpvPath, 2))
	else
		ExitApp 1

	return mpvPath
}

RunAsTask()
if (A_IsAdmin) {
		FwPolicy2 := ComObjCreate("HNetCfg.FwPolicy2")
		Rules := FwPolicy2.Rules
;		for rule in Rules
;			if (rule.Name == "mpv") {
		Loop 4
			Rules.Remove("mpv")

		NewRule := ComObjCreate("HNetCfg.FWRule"), NewRuleUdp := ComObjCreate("HNetCfg.FWRule")
		NewRule.Description                 := NewRule.Name := "mpv"
		NewRule.ApplicationName             := getMpvPath()
		NewRule.Protocol                    := NET_FW_IP_PROTOCOL_TCP := 6
		NewRule.RemoteAddresses             := "*"
		NewRule.LocalAddresses              := NewRule.RemotePorts := "*"
		NewRule.Direction                   := NET_FW_RULE_DIR_IN := 1
		NewRule.InterfaceTypes              := "All"
		NewRule.Enabled                     := True
		NewRule.Profiles                    := NET_FW_PROFILE2_PRIVATE := 0x2 ; | NET_FW_PROFILE2_PUBLIC := 0x4 | NET_FW_PROFILE2_DOMAIN := 0x1 / NET_FW_PROFILE2_ALL := 0x7fffffff
		NewRule.Action                      := NET_FW_ACTION_ALLOW := 1

		NewRuleUdp.Description              := NewRuleUdp.Name := NewRule.Name
		NewRuleUdp.ApplicationName          := NewRule.ApplicationName
		NewRuleUdp.Protocol                 := NET_FW_IP_PROTOCOL_UDP := 17
		NewRuleUdp.RemoteAddresses          := NewRule.RemoteAddresses
		NewRuleUdp.LocalAddresses           := NewRuleUdp.RemotePorts := NewRule.RemotePorts
		NewRuleUdp.Direction                := NewRule.Direction
		NewRuleUdp.InterfaceTypes           := NewRule.InterfaceTypes
		NewRuleUdp.Enabled                  := NewRule.Enabled
		NewRuleUdp.Profiles                 := NewRule.Profiles
		NewRuleUdp.Action                   := NewRule.Action
		
		Rules.Add(NewRule), Rules.Add(NewRuleUdp)
}