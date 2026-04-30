B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private sh As Shell
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub


' must be available
public Sub GetNiceName() As String
	Return "FunasrASR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			Return paramsList
		Case "recognize"
			wait for (recognize(Params.Get("path"),Params.Get("lang"),Params.Get("preferencesMap"))) complete (lines As List)
			Return lines
		Case "getDefaultParamValues"
			Return CreateMap()
		Case "longFileSupported"
			Return False
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/Silhouette_plugins/tree/main/FunASR")
			Return o
		Case "getIsInstalledOrRunning"
			Try
				Dim key As String = getMap("Funasr",getMap("api",Params.Get("preferencesMap"))).Get("key")
				If key = "" Then
					Return False
				End If
			Catch
				Log(LastException)
				Return False
			End Try
			Return True
	End Select
	Return ""
End Sub


Public Sub recognize(path As String,lang As String,preferences As Map) As ResumableSub
	Dim os As String = DetectOS

	Dim lines As List
	lines.Initialize
	Dim args As List
	args.Initialize
	
	Dim exe As String = "java"
	If os = "mac" Then
		exe = "jdk-23/Contents/Home/bin/java"
	End If
	
	Dim key As String = getMap("Funasr",getMap("api",preferences)).Get("key")
	Dim jsonPath As String = path.Replace(".wav",".json")
	args.Add("-jar")
	args.Add("jars/FunASR.jar")
	args.Add(key)
	args.Add(path)
	args.Add(jsonPath)
	sh.Initialize("sh",exe,args)
	sh.WorkingDirectory = File.DirApp
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	Log(StdOut)
	Log(StdErr)
	lines = ReadJSON(path)
	Return lines
End Sub

Private Sub ReadJSON(path As String) As List
	Dim lines As List
	lines.Initialize
	Dim jsonPath As String = path.Replace(".wav",".json")
	Dim json As JSONParser
	json.Initialize(File.ReadString(jsonPath,""))

	Dim result As Map = json.NextObject
	Dim sentences As List = result.Get("sentences")
	For Each sentence As Map In sentences
		Dim words As List = sentence.Get("words")
		For Each word As Map In words
			Dim startTime As Double = word.Get("start") / 1000
			Dim endTime As Double = word.Get("end") / 1000
			word.Put("start",startTime)
			word.Put("end",endTime)
			word.Put("text",word.Get("text")&word.Get("punctuation"))
			lines.Add(word)
		Next
	Next
		
	Return lines
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
