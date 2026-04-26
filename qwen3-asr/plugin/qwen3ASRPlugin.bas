B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private sh As Shell
	Private mPaths as List
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "qwen3-asrASR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "recognize"
			wait for (recognize(Array(Params.Get("path")),Params.Get("lang"),Params.Get("preferencesMap"))) complete (lines As List)
			Return lines
		Case "batchRecognize"
			wait for (recognize(Params.Get("paths"),Params.Get("lang"),Params.Get("preferencesMap"))) complete (lines As List)
		Case "stop"
			wait for (stop(Params.Get("preferencesMap"))) complete (done As Object)
		Case "getBatchProgress"
			Return getBatchProgress(Params.Get("preferencesMap"))
		Case "getFileResult"
			Return ReadJSON(Params.Get("path"))
		Case "getDefaultParamValues"
			Return CreateMap()
		Case "longFileSupported"
			Return False
		Case "batchSupported"
			Return True
	End Select
	Return ""
End Sub


Public Sub stop(preferences As Map) As ResumableSub
	If sh.IsInitialized Then
		sh.KillProcess
	End If
	Return ""
End Sub

Public Sub getBatchProgress(preferences As Map) As ResumableSub
	Dim progress As Map
	progress.Initialize
	progress.Put("current",-1)
	progress.Put("total",-1)
	Dim processed As Int = 0
	For Each path As String In mPaths
		If File.Exists(path.Replace(".wav",".json"),"") Then
			processed = processed + 1
		End If
	Next
	progress.Put("current",processed)
	progress.Put("total",mPaths.Size)
	Return progress
End Sub


Public Sub recognize(paths As List,lang As String,preferences As Map) As ResumableSub
	mPaths = paths
	Dim lines As List
	lines.Initialize
	Dim exe As String
	Dim args As List
	args.Initialize
	Dim os As String = DetectOS
	If os = "mac" Then
		exe = "ASR"
	Else
		Dim exe As String = "python"
		If os = "linux" Then
			exe = "python3"
		End If
		Dim transcribePath As String = "transcribe.py"
		args.Add(transcribePath)
		For Each path As String In paths
			args.Add(path)
		Next
		args.Add("-y")
	End If
	sh.Initialize("sh",exe,args)
	sh.WorkingDirectory = File.Combine(File.DirApp,"Qwen3-ASR")
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	Log(StdOut)
	Log(StdErr)
	If paths.Size = 1 Then
		lines = ReadJSON(paths.Get(0))
	End If
	Return lines
End Sub

Private Sub ReadJSON(path As String) As List
	Dim lines As List
	lines.Initialize
	Dim jsonPath As String = path.Replace(".wav",".json")
	Dim json As JSONParser
	json.Initialize(File.ReadString(jsonPath,""))
	Return json.NextArray
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

'windows, mac or linux
Sub DetectOS As String
	Dim os As String = GetSystemProperty("os.name", "").ToLowerCase
	If os.Contains("win") Then
		Return "windows"
	Else If os.Contains("mac") Then
		Return "mac"
	Else
		Return "linux"
	End If
End Sub
