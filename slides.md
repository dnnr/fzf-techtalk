---
<!-- kind: title -->
<!-- title: fzf  -->
<!-- banner created with https://manytools.org/hacker-tools/ascii-banner/ -->
███████╗███████╗███████╗
██╔════╝╚══███╔╝██╔════╝
█████╗    ███╔╝ █████╗  
██╔══╝   ███╔╝  ██╔══╝  
██║     ███████╗██║     
╚═╝     ╚══════╝╚═╝     

a low-barrier framework for interactive terminal apps (pretending to be a fuzzy finder)

Daniel Danner (inovex) · SoCraTes Soltau 2026


---
# Core idea: lines in, selection out
<!-- title: Lines in, selection out -->
<!-- demo: basics -->

fzf reads lines from standard input, offers the user a fuzzy search to filter them down, then prints the selected line(s) after confirmation:

    stdin → fzf → stdout

Without input, fzf falls back to walking the current directory recursively and using all file names as input.

Search features:
* `sbtrkt`   fuzzy match
* `'foo`     exact substring (non-fuzzy)
* `'foo'`    exact match of words (like regex `\bfoo\b`)
* `^music$`  prefix-/suffix-anchored
* `!fire`    inverted (exclude)
* `a | b`    OR

Basic CLI flags:
* `--exact` flips the meaning of `'`
* `--tac` reverses the line order
* `--multi` allows selecting multiple lines


---
# Mangling the input
<!-- demo: mangling -->

Most real input is columnar. fzf can search one part, show another, and return a third.

 * `--with-nth=N[,…]` ⇒ show only these fields
 * `--nth=N[,…]` ⇒ search only these fields (subset of `--with-nth` selection)
 * `--accept-nth=N[,…]` ⇒ print only these fields on accept

`N[,…]` are comma-separated 1-based field index expressions:
 * `-2` for 2nd to last
 * `2..5` for 2,3,4,5
 * `..-3` for all up to the 3rd to last

 `--with-nth` and `--accept-nth` can also take a template, e.g., `{2}: {1} ({n})`.

**Caveat:** fzf never searches hidden fields. 😔


---
# Preview window
<!-- demo: preview -->

`--preview=COMMAND` opens a split window showing the output of `COMMAND`.

Use the same field index expressions as for `--with-nth` to pass information about the selected line.

Use `--preview-window=` to control positioning, size, scrolling behavior, `tail -f`-like behavior, and so on.


---
# Fixed headers
<!-- demo: preview-header -->

Use `--preview-window=~N` to keep table headers visible when scrolling (great for `kubectl` or `sqlite3`).

(The same thing is available for the main list with `--header-lines=N`.)


---
# Responsive layout
<!-- demo: preview-responsive -->

Use `--preview-window="right,<100(bottom)"` to dynamically reconfigure the preview window when its width goes below a threshold


---
# Long-running previews
<!-- demo: preview-anim -->

The preview command doesn't need to finish before being displayed.

```fish
curl -s ascii.live/list | jq -r '.frames[]' \
    | fzf --preview 'curl -sN ascii.live/{}' \
    --preview-window 'right,70%,follow'
```


---
# Custom actions with --expect
<!-- demo: expect -->

Use `--expect=KEY[,…]` to tell fzf about additional keys that confirm a selection. When enabled, fzf outputs the key as the first line of its output, followed by the usual selection output.

Add `--print-query` to also capture whatever the user has entered.

Build a simple line-based file editor with that:

```fish
function edit_names
    set fzf_out (cat names.txt | fzf --tac --expect enter,ctrl-d,ctrl-n --print-query)
    [ (count $fzf_out) -le 1 ] && return 0  # ESC, do nothing
    switch $fzf_out[2]  # [2] is enter, ctrl-d or ctrl-n
        case "ctrl-d"
            sed -i "/^$fzf_out[3]\$/d" names.txt  # [3] is the selected line
            edit_names
        case "ctrl-n"
            echo "$fzf_out[1]" >> names.txt  # [1] is the entered query
            edit_names
        case "enter"
            echo $fzf_out[3]
    end
end
```


---
# Even better: --bind

Attach custom actions to keys (and events!) with `--bind=<KEY>:<ACTION>`, while fzf keeps running. Field index expressions can be used in `<ACTION>`, `{q}` expands to the current query.

Examples of events you can react to: input stream has loaded, terminal resize, cursor has moved, search results have changed, periodic timers

There are 149 actions you can take (as of v0.74.3). Some important or interesting ones:
 * `execute(<shell…>)` run a shell command
 * `become(<shell…>)` replace running fzf with a shell command (exec-like)
 * `reload(<shell…>)` replace input with output of a shell command
 * `transform(<actions…>)` run a shell command, whose output is interpreted as actions


---
# Reloading examples
<!-- demo: reload -->

Refresh periodically:
`ps | fzf --bind='every(1):reload(ps)'`

fzf stays useable while the command executes:
`seq 10 | fzf --bind='ctrl-r:reload(sleep 3; date; seq 10)'`

With `reload-sync(…)`, fzf first collects the full output before showing it.


---
# Transformation examples

Simple update loop:
`seq 10 | fzf --bind='every(1):transform:echo "change-header($(date))"'`

Chain multiple commands:
`seq 10 | fzf --bind='every(1):transform:echo "change-header($(date))+toggle-preview"' --preview=date`


---
# Robust line identity
<!-- demo: line-identity -->

Working with literal line content gets tricky on odd input. Put a controlled identifier in the first column, track it with `--id-nth=N[,…]` and `--track`

```fish
kubectl get pods -A | \
fzf --multi --track --id-nth 2 --accept-nth 2 --header-lines=1 \
--bind 'ctrl-r:reload-sync:kubectl get pods -A'
```

Hostile input can be mitigated with NUL termination:
```fish
find . -print0 | fzf --read0 --print0 | xargs -0 ls -l
```


---
# Crazy stuff
<!-- demo: listen -->

Pass `--listen[=SOCKET_PATH|[ADDR:]PORT]` to make fzf remote-controlled (defaults to a random port,
exposed to sub-processes via `$FZF_PORT`). For non-localhost, an API key must be set via `$FZF_API_KEY`.

---
<!-- kind: link -->
<!-- title: This slide deck -->
start
