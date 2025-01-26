#!/usr/bin/env python3

import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
from faster_whisper import WhisperModel
    
@route('/recognize', method='POST')
def recognize():
    upload = request.files.get('upload')
    p_model_size = request.forms.get('model')
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
    segments, info = model.transcribe(file_path, beam_size=5)
    print(segments)
    for segment in segments:
        print(segment)
        line = {"start":segment.start, "end":segment.end, "text":segment.text}
        lines.append(line)
    os.remove(file_path)
    ret["lines"] = lines
    return ret    


@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

model_size = "large-v3"
model = WhisperModel(model_size, device="cpu", compute_type="int8")
run(server="paste",host='0.0.0.0', port=8889)  