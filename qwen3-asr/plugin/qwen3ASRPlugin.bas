B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private sh As Shell
	Private mUseGPU As Boolean
	Private mLanguage As String
	Private langMap As Map
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	langMap.Initialize
	langMap.Put("zh", "Chinese")
	langMap.Put("en", "English")
	langMap.Put("yue", "Cantonese")    ' Cantonese (ISO 639-3, sometimes "zh-yue")
	langMap.Put("ar", "Arabic")
	langMap.Put("de", "German")
	langMap.Put("fr", "French")
	langMap.Put("es", "Spanish")
	langMap.Put("pt", "Portuguese")
	langMap.Put("id", "Indonesian")
	langMap.Put("it", "Italian")
	langMap.Put("ko", "Korean")
	langMap.Put("ru", "Russian")
	langMap.Put("th", "Thai")
	langMap.Put("vi", "Vietnamese")
	langMap.Put("ja", "Japanese")
	langMap.Put("tr", "Turkish")
	langMap.Put("hi", "Hindi")
	langMap.Put("ms", "Malay")
	langMap.Put("nl", "Dutch")
	langMap.Put("sv", "Swedish")
	langMap.Put("da", "Danish")
	langMap.Put("fi", "Finnish")
	langMap.Put("pl", "Polish")
	langMap.Put("cs", "Czech")
	langMap.Put("fil", "Filipino")      ' Filipino uses ISO 639-2/3
	langMap.Put("fa", "Persian")
	langMap.Put("el", "Greek")
	langMap.Put("ro", "Romanian")
	langMap.Put("hu", "Hungarian")
	langMap.Put("mk", "Macedonian")
	Return "MyKey"
End Sub

Sub IsoToLanguage(IsoCode As String) As String
	If langMap.ContainsKey(IsoCode.ToLowerCase) Then
		Return langMap.Get(IsoCode.ToLowerCase)
	Else
		Return ""
	End If
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
		Case "stop"
			wait for (stop(Params.Get("preferencesMap"))) complete (done As Object)
		Case "getFileResult"
			Return ReadJSON(Params.Get("path"))
		Case "getDefaultParamValues"
			Return CreateMap()
		Case "longFileSupported"
			Return False
	End Select
	Return ""
End Sub


Public Sub stop(preferences As Map) As ResumableSub
	If sh.IsInitialized Then
		sh.KillProcess
	End If
	Return ""
End Sub

Public Sub createServer(lang As String,preferences As Map) As ResumableSub
	Dim needInitialization As Boolean = True
	Dim useGPU As Boolean = preferences.GetDefault("use_gpu",True)
	lang = IsoToLanguage(lang)
	If sh.IsInitialized Then
		If lang = mLanguage And useGPU = mUseGPU Then
			needInitialization = False
		End If
	End If
	If needInitialization Then
		Dim wavFolder As String = File.Combine(File.Combine(File.DirApp,"Qwen3-ASR"),"wav")
		File.WriteString(wavFolder,"cancel.wav","")
		Sleep(3000)
		For Each filename In File.ListFiles(wavFolder)
			File.Delete(wavFolder,filename)
		Next
		Dim os As String = DetectOS
		Dim exe As String = File.Combine(File.DirApp,"Qwen3-ASR\python\python.exe")
		If os = "linux" Then
			exe = "python3"
		End If
		Dim args As List
		args.Initialize
		args.Add("./server.py")
		args.Add("start")
		args.Add("./wav")
		If useGPU = False Then
			args.Add("--no-gpu")
			args.Add("--no-vulkan")
			args.Add("--provider")
			args.Add("CPU")
		End If
		If lang <> "" Then
			args.Add("--language")
			args.Add(lang)
		End If
		mUseGPU = useGPU
		mLanguage = lang
		Log(args)
		sh.Initialize("sh",exe,args)
		sh.WorkingDirectory = File.Combine(File.DirApp,"Qwen3-ASR")
		sh.Run(-1)
	End If
	Return ""
End Sub


Public Sub recognize(path As String,lang As String,preferences As Map) As ResumableSub
	wait for (createServer(lang,preferences)) complete (done As Object)
	Dim lines As List
	lines.Initialize
	Dim exe As String
	Dim args As List
	args.Initialize
	Dim os As String = DetectOS
	If os = "mac" Then
		exe = "ASR"
		sh.Initialize("sh",exe,args)
		sh.WorkingDirectory = File.Combine(File.DirApp,"Qwen3-ASR")
		sh.Run(-1)
		wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
		Log(StdOut)
		Log(StdErr)
		lines = ReadJSON(path)
		Return lines
	Else
		Dim wavFolder As String = File.Combine(File.Combine(File.DirApp,"Qwen3-ASR"),"wav")

		Dim targetPath As String = File.Combine(wavFolder,File.GetName(path))
		File.Copy(path,"",targetPath,"")
		Dim jsonPath As String = targetPath.Replace(".wav",".json")
		Do While True
			If File.Exists(jsonPath,"") Then
				lines = ReadJSON(targetPath)
				Exit
			End If
			Sleep(1000)
			Log(sh.GetTempErr)
			Log(sh.GetTempOut)
		Loop
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
