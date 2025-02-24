# faster-whisper

A Python server to use [faster-whisper](https://github.com/SYSTRAN/faster-whisper/) in Silhouette.


## How to Use

1. Install the dependent packages: `pip install faster-whisper bottle Paste`
2. Run the server: `python server.py`


**For convenience**, you can use the following Windows package.

1. Download the [faster.whisper.zip](https://github.com/xulihang/Silhouette_plugins/releases/download/packages/faster-whisper.zip) file and unzip it.
2. Download a model, like the small multilingual model ([link](https://github.com/xulihang/Silhouette_plugins/releases/download/packages/faster-whisper-small-model.zip)). Unzip it to the faster-whisper's folder. You can also download other models by yourself.
3. Run the server: `python server.py`


The model name can be specified in Silhouette's preferences. If the model is not installed locally, it will try to download from huggingface.




