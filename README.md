# picoGPT in J

J port of [jaymody/picoGPT](https://github.com/jaymody/picoGPT), "An unnecessarily tiny implementation of GPT-2 in NumPy."

## Install

Download J (tested with J903 and base library 9.03.08, see [the wiki](https://code.jsoftware.com/wiki/System/Installation) for installation instructions). You will also need the `convert/pjson` addon:

```j
NB. If nothing is printed, the addon is already installed
install 'convert/pjson'
```

## Download models

Get the GPT-2 models you want by running the `download.sh` script (e.g. `./download.sh 124M`). If you can't run it, first make a `models/` directory and download the tokenizer files into it:
- [vocab.json](https://huggingface.co/gpt2/raw/main/vocab.json)
- [merges.txt](https://huggingface.co/gpt2/raw/main/merges.txt)

Then, download the `model.safetensors` and `config.json` for the model you want and place them in the corresponding `models/[model size]` directory (e.g. `models/124M`):
- 124M: [model.safetensors](https://huggingface.co/gpt2/resolve/main/model.safetensors), [config.json](https://huggingface.co/gpt2/raw/main/config.json)
- 355M: [model.safetensors](https://huggingface.co/gpt2-medium/resolve/main/model.safetensors), [config.json](https://huggingface.co/gpt2-medium/raw/main/config.json)
- 774M: [model.safetensors](https://huggingface.co/gpt2-large/resolve/main/model.safetensors), [config.json](https://huggingface.co/gpt2-large/raw/main/config.json)
- 1558M: [model.safetensors](https://huggingface.co/gpt2-xl/resolve/refs%2Fpr%2F5/model.safetensors) <!-- PR adding Safetensors checkpoint hasn't been merged yet -->, [config.json](https://huggingface.co/gpt2-xl/raw/main/config.json)

## Usage

Run `gpt2.ijs` (e.g. `jconsole gpt2.ijs`). Then:

```j
NB. Load model
model '124M'
NB. Generate 40 tokens by default
gen 'Alan Turing theorized that computers would one day become'

NB. Switch model
model '1558M'
NB. Generate 79 tokens. Assign the output to a variable to prevent it from
NB. being printed to the console twice.
out =. 79 gen 'The importance of nomenclature, notation, and language as tools of'
```

## Notes

- When the input length exceeds `n_ctx`, rather than throwing an exception, only the last `n_ctx` tokens are used.
- Instead of a progress bar, tokens are printed as they're generated.
- All calculations are done with 64-bit floats since J [doesn't have 32-bit floats](https://code.jsoftware.com/wiki/Vocabulary/NumericPrecisions) (not sure about 32-bit J, though).
- The [Safetensors format](https://github.com/huggingface/safetensors) is used since it's easier to parse. This means checkpoints are downloaded from HuggingFace rather than OpenAI's Azure storage. Filenames are also different:
    - `model.ckpt.*` -> `model.safetensors`
    - `hparams.json` -> `config.json`
    - `encoder.json` -> `vocab.json`
    - `vocab.bpe` -> `merges.txt`
- Thanks to [karpathy/minGPT](https://github.com/karpathy/minGPT) for having a [good explanation](https://github.com/karpathy/minGPT/blob/master/mingpt/bpe.py) of the BPE tokenizer.
