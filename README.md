# Show & Tell: fzf

A terminal slide deck about [fzf](https://github.com/junegunn/fzf) — built *in* fzf.

The deck is a single `fzf` process: the slide list is the candidate list, the
preview window is the slide, and pressing <kbd>Enter</kbd> drops you into a live
demo in a tmux popup.

## Running it

Requires **tmux** (the deck refuses to start outside it), plus `fzf`, `gum`,
`glow`, `fish`, `awk`, `sha1sum`, `realpath`, and `stat`. `bat`/`batcat` is
optional but recommended. Some individual demos also want `jq`, `curl`, or `kubectl`.

Developed and tested against **fzf 0.74.3**.

```sh
./start
```

Keys, as shown in the footer alongside an elapsed-time clock:

| Key | Action |
| --- | --- |
| `j` / `k` | next / previous slide |
| `J` / `space` | reveal and go to next slide |
| `K` | previous slide and unreveal all slides after that |
| <kbd>Enter</kbd> | open this slide's demo in a tmux popup |
| <kbd>Ctrl</kbd>+`s` | run a plain shell in a tmux popup |
| <kbd>Ctrl</kbd>+`q`/<kbd>Ctrl</kbd>+`c` | quit |

## Writing slides

A slide opens at a `---` line. Code fences are opaque, so nothing inside ``` ``` ``` is ever a
boundary.

```markdown
---
# My Title
<!-- kind: md -->
<!-- title: My title in the contents list -->
<!-- demo: my-title -->

This is the **body text** of this slide. Just markdown.
```

Attributes are one `key: value` per comment. A comment may sit anywhere in its slide, in any
order.

- **`kind`:** `md` (markdown rendered with `glow`; default if `kind` is unspecified), `title`
  (centered box via `gum`), `link` (the body is a path; that file is rendered as itself), or `txt`
  (raw ANSI, printed as-is)
- **`title`:** label in the contents list; falls back to the slide's first non-blank line, with
  a leading `#` stripped, so a slide that opens with a heading is labelled by it
- **`demo`:** the case in `demo` that <kbd>Enter</kbd> runs on this slide
- **`hidden`:** `true` hides the slide from the deck

## Implementation details

Rendered slides are cached in `.cache/` (gitignored), keyed by content and
preview geometry, so editing `slides.md` invalidates exactly the slides that
changed. The first miss at a given size warms the rest of the deck in the
background. `.cache/deck.start` holds the talk's start timestamp and you can
delete it to reset the clock.

Demos run with `FZF_DEFAULT_OPTS` unset, so your personal config never leaks
into a talk about defaults.
