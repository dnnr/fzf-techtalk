# slides.awk - parse slides.md into slides. One parser, two consumers.
#
#   awk -f slides.awk -v mode=index -v D='|'  slides.md   -> N D title D demo
#   awk -f slides.awk -v mode=meta  -v n=K    slides.md   -> kind TAB target
#   awk -f slides.awk -v mode=body  -v n=K    slides.md   -> slide K, verbatim
#   awk -f slides.awk -v mode=slide -v n=K    slides.md   -> meta line, then body
#   awk -f slides.awk -v mode=count           slides.md   -> number of slides
#
# `slide` is `meta` and `body` in one pass, so the preview parses the deck once
# per keystroke instead of twice.
#
# A slide opens at a `---` line and nowhere else - the first slide included, so
# anything above the first `---` is preamble and is dropped. Everything else is
# body, headings included. Comments set attributes on the open slide and may sit
# anywhere in it, in any order:
#
#     ---
#     # The whole idea
#     <!-- kind: title -->
#     <!-- demo: basics -->
#
# One "key: value" pair per comment - stack as many as you need.
# Keys: kind (md|title|link|txt), title, demo, hidden (true to drop the slide).
# Code fences are opaque - nothing inside ``` is ever a boundary.
#
# Written for mawk: no gensub, no match() captures.

function newslide() {
  sn++
  kind[sn] = "md"                          # the only field with a non-empty default
}

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function emit(L) {
  if (sn == 0) return                      # anything before the first slide
  body[sn] = body[sn] L "\n"
  if (L ~ /^[ \t]*$/) return
  if (first[sn] == "") first[sn] = trim(L) # link target, and title of last resort
}

function setattr(pair,   p, key, val) {
  if (sn == 0) return                      # a comment in the preamble
  p = index(pair, ":")
  if (p == 0) return
  key = trim(substr(pair, 1, p - 1))
  val = trim(substr(pair, p + 1))
  if (val ~ /^".*"$/) val = substr(val, 2, length(val) - 2)
  if (key == "kind")         kind[sn]   = val
  else if (key == "title")   title[sn]  = val
  else if (key == "demo")    demo[sn]   = val
  else if (key == "hidden")  hidden[sn] = (val == "true")
}

function trim_blanks(s) {
  sub(/^([ \t]*\n)+/, "", s)
  sub(/\n([ \t]*\n)+$/, "\n", s)
  return s
}

# a/b/c.fish -> c. A leading dot is not an extension: .bashrc stays .bashrc.
function basenoext(p,   b) {
  b = p; sub(/.*\//, "", b)
  if (b ~ /.\./) sub(/\.[^.]*$/, "", b)
  return b
}

function target_of(i) {
  return (kind[i] == "link") ? first[i] : ""
}

function title_of(i,   t) {
  if (title[i] != "") return title[i]
  if (kind[i] == "link") return basenoext(first[i])
  t = first[i]; sub(/^#+[ \t]*/, "", t)    # an opening heading is the title
  return (t != "") ? t : ("slide " i)
}

BEGIN { sn = 0; fence = 0; if (mode == "") mode = "index"; if (D == "") D = "|" }

{
  L = $0

  if (L ~ /^[ \t]*```/) { fence = 1 - fence; emit(L); next }
  if (fence)            { emit(L); next }

  if (L ~ /^---+[ \t]*$/) { newslide(); next }   # ---+, not -{3,}: mawk has no intervals

  if (L ~ /^[ \t]*<!--/ && L ~ /-->[ \t]*$/) {
    sub(/^[ \t]*<!--[ \t]*/, "", L)
    sub(/[ \t]*-->[ \t]*$/, "", L)
    setattr(L)
    next
  }

  emit(L)
}

END {
  if (mode == "count") { print sn; exit }    # sn is set in BEGIN, so this prints 0, not an empty line
  if (mode == "index") {
    for (i = 1; i <= sn; i++) if (!hidden[i]) printf "%d%s%s%s%s\n", i, D, title_of(i), D, demo[i]
    exit
  }
  n = n + 0                                  # -v n=3x must compare numerically, not as a string
  if (n < 1 || n > sn) exit 1
  if (mode == "meta")  { printf "%s\t%s\n", kind[n], target_of(n); exit }
  if (mode == "body")  { printf "%s", trim_blanks(body[n]); exit }
  if (mode == "slide") { printf "%s\t%s\n", kind[n], target_of(n); printf "%s", trim_blanks(body[n]); exit }
  exit 1
}
