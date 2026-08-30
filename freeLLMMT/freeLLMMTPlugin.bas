B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "freeLLMMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "batchtranslate"
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
			Return targetList
		Case "supportBatchTranslation"
			Return True
	End Select
	Return ""
End Sub

Sub batchTranslate(sourceList As List,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim url As String
	Try
		url=getMap("freeLLM",getMap("api",preferencesMap)).GetDefault("url","http://service.basiccat.org:5000/translate/batch")
	Catch
		Log(LastException)
		url = "http://service.basiccat.org:5000/translate/batch"
	End Try
	Dim body As Map
	body.Initialize
	body.Put("texts",sourceList)
	body.Put("target_lang",targetLang)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(body)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As Map
			Dim json As JSONParser
			json.Initialize(job.GetString)
			result=json.NextObject
			Dim results As List
			results=result.Get("results")
			For Each item As Map In results
				targetList.Add(item.Get("translated"))
			Next
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return targetList
End Sub

Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim url As String
	Try
		url=getMap("freeLLM",getMap("api",preferencesMap)).GetDefault("url","http://service.basiccat.org:5000/translate/batch")
	Catch
		Log(LastException)
		url = "http://service.basiccat.org:5000/translate/batch"
	End Try
	Dim texts As List
	texts.Initialize
	texts.Add(source)
	Dim body As Map
	body.Initialize
	body.Put("texts",texts)
	body.Put("target_lang",targetLang)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(body)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As Map
			Dim json As JSONParser
			json.Initialize(job.GetString)
			result=json.NextObject
			Dim results As List
			results=result.Get("results")
			Dim item As Map
			item=results.Get(0)
			target=item.Get("translated")
		Catch
			target=""
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
