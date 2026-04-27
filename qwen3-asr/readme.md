# Qwen3-ASR

Qwen3-ASR perform better than Whisper for many languages and it supports more languages like Chinese dialects.

GPU acceleration is supported (Vulkan and DirectML for Windows/Linux and Metal for macOS).

## Installation

### Windows

1. Download [Qwen3-ASR.zip](https://github.com/xulihang/Qwen3-ASR-GGUF/releases/download/packages/Qwen3-ASR.zip) and unzip it to Silhouette's root.
2. Download the models and unzip them to `Qwen3-ASR/model`.

   * [Qwen3-ASR-1.7B-gguf.zip](https://github.com/HaujetZhao/Qwen3-ASR-GGUF/releases/download/models/Qwen3-ASR-1.7B-gguf.zip)
   * [Qwen3-ForceAligner-0.6B-gguf.zip](https://github.com/HaujetZhao/Qwen3-ASR-GGUF/releases/download/models/Qwen3-ForceAligner-0.6B-gguf.zip)

It is based on this project: <https://github.com/HaujetZhao/Qwen3-ASR-GGUF>

### macOS

1. Download [ASR-swift.zip](https://github.com/xulihang/Qwen3-ASR-CLI/releases/download/build/ASR-swift.zip) and unzip the files to `Qwen3-ASR` under Silhouette's root.
2. Download the models and put the files under `Qwen3-ASR/models`.

   1. Download the ASR model and put the files under `Qwen3-ASR/models/Qwen3-ASR-1.7B-MLX-8bit`: [huggingface](https://huggingface.co/aufklarer/Qwen3-ASR-1.7B-MLX-8bit)/[国内地址](https://www.modelscope.cn/models/aufklarer/Qwen3-ASR-1.7B-MLX-8bit)
   2. Download the Aligner model and put the files under `Qwen3-ASR/models/Qwen3-ForcedAligner-0.6B-8bit`: [huggingface](https://huggingface.co/aufklarer/Qwen3-ForcedAligner-0.6B-8bit)/[国内地址](https://www.modelscope.cn/models/aufklarer/Qwen3-ForcedAligner-0.6B-8bit)
   
   
It is based on this project: <https://github.com/soniqo/speech-swift>
