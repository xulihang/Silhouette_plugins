B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultModelSize As String = "medium"
	Private defaultURL As String = "http://127.0.0.1:8889/recognize"
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "fasterWhisperASR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			paramsList.Add("model_size")
			Return paramsList
		Case "recognize"
			wait for (recognize(Params.Get("path"),Params.Get("lang"),Params.Get("preferencesMap"))) complete (lines As List)
			Return lines
		Case "getDefaultParamValues"
			Return CreateMap("url": defaultURL, _
			                 "model_size": defaultModelSize)
	End Select
	Return ""
End Sub

Public Sub recognize(path As String,lang As String,preferences As Map) As ResumableSub
	Dim lines As List
	lines.Initialize
	Dim job As HttpJob
	job.Initialize("",Me)
	Dim fd As MultipartFileData
	fd.Initialize
	fd.KeyName = "upload"
	fd.Dir = File.GetFileParent(path)
	fd.FileName = File.GetName(path)
	fd.ContentType = "audio/wav"
	Dim url As String = defaultURL
	Dim modelSize As String = defaultModelSize
	Try
		url = getMap("fasterWhisper",getMap("api",preferences)).GetDefault("url",defaultURL)
		modelSize = getMap("fasterWhisper",getMap("api",preferences)).GetDefault("model_size",defaultModelSize)
	Catch
		Log(LastException)
	End Try
	job.PostMultipart(url,CreateMap("model":modelSize), Array(fd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			lines = json.NextObject.Get("lines")
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return lines
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
