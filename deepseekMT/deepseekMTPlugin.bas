B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultPrompt As String = $"Translate the following into {langcode} without explaination: {source}"$
	Private defaultPromptWithTerm As String = $"With the help of the terms defined in JSON: {term}, translate the following into {langcode} without explaination: {source}"$
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "deepseekMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("prompt")
			paramsList.Add("prompt_with_term")
			paramsList.Add("host")
			paramsList.Add("model")
			Return paramsList
		Case "batchtranslate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
			    terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (targetList As List)
			Return targetList
		Case "translate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
				terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (result As String)
			Return result
		Case "supportBatchTranslation"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("prompt":defaultPrompt, _ 
							 "prompt_with_term":defaultPromptWithTerm, _ 
			                 "host":"https://api.deepseek.com", _
							 "model":"deepseek-chat")
	End Select
	Return ""
End Sub

private Sub ConvertLang(lang As String) As String
	Dim map1 As Map
	map1.Initialize
	map1.Put("zh","Chinese")
	map1.Put("zh-CN","Simplified Chinese")
	map1.Put("zh-TW","Traditional Chinese")
	map1.Put("en","English")
	map1.Put("ja","Japanese")
	map1.Put("ko","Korean")
	map1.Put("ar","Arabic")
	map1.Put("de","German")
	map1.Put("fi","Finish")
	map1.Put("el","Greek")
	map1.Put("da","Danish")
	map1.Put("cs","Czech")
	map1.Put("ca","Catalan")
	map1.Put("fr","French")
	map1.Put("it","Italian")
	map1.Put("sv","Swedish")
	map1.Put("pt","Portuguese")
	map1.Put("nl","Dutch")
	map1.Put("pl","Polish")
	map1.Put("es","Spanish")
	map1.Put("id","Indonesian")
	map1.Put("hi","Hindi")
	map1.Put("vi","Vietnamese")
	map1.Put("ru","Russian")
	If map1.ContainsKey(lang) Then
		Return map1.Get(lang)
	End If
	Return lang
End Sub


Sub batchTranslate(sourceList As List, sourceLang As String, targetLang As String,preferencesMap As Map,terms As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	Dim sb As StringBuilder
	sb.Initialize
	For Each source As String In sourceList
		sb.Append(source.Replace(CRLF," "))
		sb.Append(CRLF)
	Next
	wait for (translate(sb.ToString,sourceLang,targetLang,preferencesMap,terms)) complete (target As String)
	For Each str As String In Regex.Split(CRLF,target)
		targetList.Add(str)
	Next
    Return targetList
End Sub

Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map,terms As Map) As ResumableSub
	Dim converted As Boolean
	Dim langCode As String = targetLang
	targetLang = ConvertLang(targetLang)
	If langCode <> targetLang Then
		converted = True
	End If
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	
	Dim key As String = getMap("deepseek",getMap("mt",preferencesMap)).Get("key")
	Dim prompt As String
	If terms.Size>0 Then
		prompt = getMap("deepseek",getMap("mt",preferencesMap)).GetDefault("prompt_with_term",defaultPromptWithTerm)
	Else
		prompt = getMap("deepseek",getMap("mt",preferencesMap)).GetDefault("prompt",defaultPrompt)
	End If
	 
	Dim host As String = getMap("deepseek",getMap("mt",preferencesMap)).GetDefault("host","https://api.deepseek.com")
	Dim url As String = host&"/chat/completions"
	Dim messages As List
	messages.Initialize
	Dim message As Map
	message.Initialize
	message.Put("role","user")
	If prompt.Contains("{langcode}") Then
		If converted Then
			message.Put("content",prompt.Replace("{langcode}",targetLang).Replace("{source}",source))
			'$"Translate the following into ${targetLang}: ${source}"$
		Else
			If terms.Size>0 Then
				message.Put("content",defaultPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",source))
			Else
				message.Put("content",$"Translate the following into the language whose ISO639-1 code is ${targetLang}: ${source}"$)
			End If
			
		End If
	Else
		message.Put("content",prompt.Replace("{source}",source))
	End If
	
	If terms.Size>0 Then
		Dim termsJsonG As JSONGenerator
		termsJsonG.Initialize(terms)
		Dim msg As String = message.Get("content")
		message.Put("content",msg.Replace("{term}",termsJsonG.ToString))
	End If
	Log(message)
	messages.Add(message)
	Dim model As String = getMap("deepseek",getMap("mt",preferencesMap)).GetDefault("model","deepseek-chat")
	Dim params As Map
	params.Initialize
	params.Put("model",model)
	params.Put("messages",messages)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&key)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject
			Dim choices As List
			choices = response.Get("choices")
			Dim choice As Map = choices.Get(0)
			Dim message As Map = choice.Get("message")
			target = message.Get("content")
			target = target.Trim
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
