#!/usr/bin/env python3

import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
from faster_whisper import WhisperModel
import _thread

file_lines = []
total_duration = 0.0
current_seconds = 0.0
exit_flag = 0

def clear_uploaded():
    for filename in os.listdir('./uploaded/'):
        file_path = "{path}/{file}".format(path='./uploaded/', file=filename)
        os.remove(file_path)

@route('/recognize', method='POST')
def recognize():
    clear_uploaded()
    upload = request.files.get('upload')
    p_model_size = request.forms.get('model')
    p_lang = request.forms.get('lang')
    print(p_lang)
    name, ext = os.path.splitext(upload.filename)
    if ext.lower() not in ('.wav','.mp3','.m4a'):
        return "File extension not allowed."
    global model_size
    global model
    if p_model_size != model_size:
        model_size = p_model_size
        model = WhisperModel(model_size, device="cpu", compute_type="int8")
    timestamp=str(int(time.time()*1000))
    savedName=timestamp+ext
    save_path = "./uploaded/"
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    file_path = "{path}/{file}".format(path=save_path, file=savedName)
    if os.path.exists(file_path)==True:
        os.remove(file_path)
    upload.save(file_path)        
    ret = {}
    lines = []
    segments, info = model.transcribe(file_path, language=p_lang, beam_size=5, log_progress=True)
    print(segments)
    print(info)
    for segment in segments:
        print(segment)
        line = {"start":segment.start, "end":segment.end, "text":segment.text}
        lines.append(line)
    os.remove(file_path)
    ret["lines"] = lines
    return ret
    
@route('/recognizelongfile', method='POST')
def recognize_longfile():
    clear_uploaded()
    upload = request.files.get('upload')
    p_model_size = request.forms.get('model')
    p_lang = request.forms.get('lang')
    name, ext = os.path.splitext(upload.filename)
    if ext.lower() not in ('.wav','.mp3','.m4a'):
        return "File extension not allowed."
    global exit_flag
    exit_flag = 0
    global model_size
    global model
    if p_model_size != model_size:
        model_size = p_model_size
        model = WhisperModel(model_size, device="cpu", compute_type="int8")
    timestamp=str(int(time.time()*1000))
    savedName=timestamp+ext
    save_path = "./uploaded/"
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    file_path = "{path}/{file}".format(path=save_path, file=savedName)
    if os.path.exists(file_path)==True:
        os.remove(file_path)
    upload.save(file_path)        
    ret = {}
    segments, info = model.transcribe(file_path, language=p_lang, beam_size=5)
    print(segments)
    print(info)
    global total_duration
    global current_seconds
    current_seconds = 0
    total_duration = info.duration
    _thread.start_new_thread(transcribe, (segments,))
    ret["success"] = True
    return ret

@route('/getprogress', method=['GET', 'POST'])
def get_progress():
    global current_seconds
    global total_duration
    ret = {}
    ret["current"] = current_seconds
    ret["total"] = total_duration
    return ret
    
@route('/getresult', method=['GET', 'POST'])
def get_result():
    global file_lines
    ret = {}
    ret["lines"] = file_lines
    return ret

@route('/stop', method=['GET', 'POST'])
def stop():
    global exit_flag
    exit_flag = 1
    
def transcribe(segments):
    global current_seconds
    global total_duration
    global file_lines
    file_lines = []
    for segment in segments:
        print(segment)
        line = {"start":segment.start, "end":segment.end, "text":segment.text}
        current_seconds = segment.end
        file_lines.append(line)
        if exit_flag == 1:
            break
    current_seconds = total_duration

@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

if __name__ == '__main__':
    clear_uploaded()
    model_size = "small"
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    run(server="paste",host='0.0.0.0', port=8889)  