#!/usr/bin/env sh

MODELS_DIR="models"


mkcd() { mkdir -p "$1"; cd "$1"; }
download() {
    echo "Downloading $1"
    curl -C - -O -L "$2"
    echo
}
usage() {
    echo "usage: $0 [model size]"
    echo 'model sizes: ["124M", "355M", "774M", "1558M"]'
}


if [ $# -ne 1 ]; then
    usage
    exit 1
fi

mkcd "$MODELS_DIR"

download "vocab.json" "https://huggingface.co/gpt2/raw/main/vocab.json"
download "merges.txt" "https://huggingface.co/gpt2/raw/main/merges.txt"

branch="main"
case "$1" in
    124M)  hf_name="gpt2" ;;
    355M)  hf_name="gpt2-medium" ;;
    774M)  hf_name="gpt2-large" ;;
    # Use PR branch since the Safetensors PR hasn't been merged yet
    1558M) hf_name="gpt2-xl"; branch="refs%2Fpr%2F5" ;;
    *)
        echo "Unrecognized model size: $1"
        echo
        usage
        exit 1
        ;;
esac

mkcd "$1"
download "config.json"       "https://huggingface.co/$hf_name/raw/$branch/config.json"
download "model.safetensors" "https://huggingface.co/$hf_name/resolve/$branch/model.safetensors"
