# Local setup: MusicGen → Demucs stem pipeline

This documents the working local install on this machine (ServerDeskHQ). It is
NOT upstream ComfyUI documentation — see `README.md` for that.

## What works

```
HuggingFaceMusicGen ──AUDIO──> DemucsAudioSeparator ──┬── vocals ──> SaveAudioAdvanced
                                                      ├── drums  ──> SaveAudioAdvanced
                                                      ├── bass   ──> SaveAudioAdvanced
                                                      └── other  ──> SaveAudioAdvanced
```

Verified end to end: generation, 4-stem separation, and playback of the output
through the onboard headphone jack.

## Interpreter

ComfyUI's dependencies are installed in a dedicated venv:

```
/home/mrnicholas/dictator-env/bin/python   (Python 3.12.15)
```

No other interpreter on this machine has them. All commands below use that
interpreter.

## Running

```bash
./run.sh                 # CPU mode, http://127.0.0.1:8188
```

Overridable: `PYTHON=`, `HOST=`, `PORT=`, `LOG=`.

Stop it with:

```bash
pkill -f 'main.py --cpu'
```

## GPU is not usable on this machine

The GTX 1070 is `sm_61` (compute capability 6.1). This ComfyUI pins
`comfy-kitchen==0.2.39` (see `requirements.txt`), which requires `sm_75+` with
CUDA 13+. The newest CUDA wheel the 1070 can use is cu124, which the pin
rejects. Consequences:

- Everything runs on CPU (`run.sh` passes `--cpu`).
- A 10 s MusicGen clip takes roughly 75 seconds to generate.
- `model_size: medium` / `large` are not realistic on 8 GB VRAM.

Getting the 1070 onto the GPU would require a ComfyUI build without the
`comfy-kitchen` pin, or accepting CPU.

## Custom nodes

Neither pack is in the ComfyUI public registry, and ComfyUI-Manager is not
installed, so both were cloned directly (the manual install path each project
documents):

```bash
cd custom_nodes

# Demucs 4-stem separator — provides DemucsAudioSeparator
git clone https://github.com/Meisoftcoltd/ComfyUI-Demucs-AudioSeparator

# MusicGen via HuggingFace transformers — provides HuggingFaceMusicGen
git clone https://github.com/ebrinz/ComfyUI-MusicGen-HF
```

Python dependencies installed into `/home/mrnicholas/dictator-env`:

```bash
/home/mrnicholas/dictator-env/bin/pip install \
    "demucs>=4.0.0" librosa soundfile \
    "transformers>=4.30.0" "accelerate>=0.20.0" scipy av
```

## Models

Downloaded automatically on first run — nothing to fetch by hand:

- MusicGen small (`facebook/musicgen-small`) → `models/musicgen` (~2.3 GB).
- htdemucs_ft → **HuggingFace hub cache**, at
  `~/.cache/huggingface/hub/models--adefossez--HTDemucs-ft` (~321 MB across 4
  `.safetensors` files). The node sets `torch.hub.set_dir(models/demucs)` and
  that directory stays empty; the weights do not land there. Listing the
  snapshot with plain `ls`/`du` is misleading — the files are symlinks into
  `blobs/`, so use `du -sh --dereference`.

## The workflow

`user/default/workflows/musicgen_demucs_stems.json` — open it from the ComfyUI
sidebar under **Workflows**. Generated from the API-format graph, so the node
layout on the canvas is auto-generated; rearrange and re-save if you like.

Stems are written to `output/stems/` as 44.1 kHz FLAC.

## Audio devices (ALSA — this machine has no PipeWire/PulseAudio)

From `aplay -l` / `arecord -l`:

| Purpose | Device | Card |
|---|---|---|
| Playback (headphones) | `hw:2,0` — `Generic_1` ALC897 Analog | onboard jack |
| Capture (recording) | `hw:3,0` — `U192k` UMC202HD | USB interface |

The UMC202HD is the *recording* device. Headphones go into the PC's onboard
jack, so playback must target the ALC897, not the interface. In a DAW
(Ardour), set output to card 2 and input to card 3.

Raw ALSA does not share devices the way PipeWire does: while a DAW holds
card 2 for output, other apps may be locked out of it.

## Known gotchas

- `SaveAudio` is deprecated and writes FLAC, not WAV. Use
  `SaveAudioAdvanced`.
- `aplay` cannot read FLAC. Converting to WAV first is required purely for
  `aplay`; DAWs import the FLAC directly.
- `SaveAudioAdvanced`'s `format` is a dynamic-combo widget. In API-format
  workflows it must be the flat string `"flac"`, not a nested object — a
  nested object fails with
  `SaveAudioAdvanced.execute() missing 1 required positional argument: 'format'`.
- The plan this was built from specified 48 kHz WAV, a `MusicGenNode`
  class, and "already installed Demucs". None of those were true: the
  pipeline is 44.1 kHz FLAC, the real class is `HuggingFaceMusicGen`, and
  no demucs package was present.
