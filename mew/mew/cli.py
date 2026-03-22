"""
mew.cli — entry point for the mew command.
"""

import sys
from pathlib import Path

from mew import __version__

_SYNOPSIS = """\
Usage: mew [options] file
       mew config [model|voice|show]

  Convert a study note to speech via KittenTTS.

Type 'mew --help' for full usage."""

_HELP = """\
Usage: mew [options] file
       mew config [model|voice|show]

  Preprocess a note file and synthesize it to speech via KittenTTS.

Subcommands:
  config          Interactively set model and voice preferences
  config model    Change model only
  config voice    Change voice only
  config delete   Delete a downloaded model
  config show     Print current model and voice settings

Options:
  -h, --help      Show this help message and exit
  -i              Intermediate only: preprocess and write .mew.md, skip synthesis
  -p              Pre-processed: skip preprocessing, synthesize file directly
      --version   Print version and exit

Output (default):   file.mew.wav
Output (-i):        file.mew.md
Input  (-p):        expects an already-preprocessed file

Run 'man mew' for full documentation."""


def _mew_stem(input_path: Path) -> Path:
    """Return the path with .mew inserted before the final extension removed.

    notes.md        -> notes.mew
    notes.mew.md    -> notes.mew   (already has .mew, strip the outer ext)
    """
    if input_path.suffixes[-2:] == [".mew", input_path.suffix]:
        # e.g. notes.mew.md -> strip the last suffix
        return input_path.with_suffix("")
    return input_path.with_suffix(".mew")


def main() -> None:
    args = sys.argv[1:]

    # ── config subcommand ─────────────────────────────────────────────────────
    if args and args[0] == "config":
        from mew import config
        config.main(args[1:])
        return

    # ── option parsing ────────────────────────────────────────────────────────
    mode = "default"  # "default" | "intermediate" | "preprocessed"
    positional: list[str] = []
    i = 0
    while i < len(args):
        a = args[i]
        if a in ("-h", "--help"):
            print(_HELP)
            return
        if a == "--version":
            print(f"mew {__version__}")
            return
        if a == "-i":
            mode = "intermediate"
            i += 1
            continue
        if a == "-p":
            mode = "preprocessed"
            i += 1
            continue
        if a == "--":
            positional += args[i + 1:]
            break
        if a.startswith("-"):
            print(f"mew: unknown option: {a}", file=sys.stderr)
            print("Try 'mew --help' for usage.", file=sys.stderr)
            sys.exit(1)
        positional.append(a)
        i += 1

    # Check mutual exclusivity: if both -i and -p appeared, mode would be
    # whichever came last — detect by re-scanning.
    if "-i" in args and "-p" in args:
        print("mew: -i and -p are mutually exclusive", file=sys.stderr)
        sys.exit(1)

    # ── no-arg synopsis ───────────────────────────────────────────────────────
    if not positional:
        print(_SYNOPSIS)
        return

    if len(positional) != 1:
        print("mew: expected exactly one argument", file=sys.stderr)
        print("Try 'mew --help' for usage.", file=sys.stderr)
        sys.exit(1)

    input_path = Path(positional[0])

    if not input_path.exists():
        print(f"mew: file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    stem = _mew_stem(input_path)

    if mode == "intermediate":
        # -i: preprocess only, write .mew.md
        from mew import preprocess
        out_md = stem.with_suffix(".mew.md")
        preprocess.process(str(input_path), str(out_md))
        print(out_md)
        return

    if mode == "preprocessed":
        # -p: skip preprocessing, synthesize directly
        from mew import speak
        out_wav = stem.with_suffix(".mew.wav")
        speak.synthesize(input_path.read_text(encoding="utf-8"), str(out_wav))
        print(out_wav)
        return

    # ── default: preprocess + synthesize ─────────────────────────────────────
    from mew import preprocess, speak
    import tempfile, os

    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".md", delete=False, encoding="utf-8"
    ) as tmp:
        tmp_path = tmp.name

    try:
        preprocess.process(str(input_path), tmp_path)
        out_wav = stem.with_suffix(".mew.wav")
        speak.synthesize(Path(tmp_path).read_text(encoding="utf-8"), str(out_wav))
    finally:
        os.unlink(tmp_path)

    print(out_wav)
