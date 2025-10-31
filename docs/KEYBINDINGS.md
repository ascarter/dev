# Zsh Line Editing Keybindings (Emacs Mode + Vim-Inspired Enhancements)

This document summarizes practical Zsh line editor (ZLE) keybindings when using the Emacs keymap (`bindkey -e`), plus the Vim-inspired enhancements added in your `.zshrc`.

Conventions:
- C- = Control
- M- = Meta (Option on macOS if configured, or press ESC then the key)
- DEL = Backspace key when it sends `^?`
- ⌘ = Command on macOS (handled via your terminal mappings, not ZLE)
- “(shell override)” indicates behavior differing from canonical GNU Emacs.

Your custom additions:
- M-h / M-l for left/right char movement
- M-j / M-k for down/up history navigation
- C-X C-E to open the current line in `$EDITOR`
- Explicit bindings for kill/yank operations
- Redundant movement bindings retained for clarity

Note: This is a focused, high-value subset—ZLE has more widgets than listed here.

---

## Minimal Cheat Sheet

| Category | Keys |
|----------|------|
| Movement | C-a C-e M-b M-f C-p C-n M-h M-l M-j M-k |
| Edit | C-w M-d C-k C-u C-y M-y M-t C-t |
| Search | C-r C-s C-g |
| History | C-p C-n M-p M-n |
| External Edit | C-x C-e |
| Clear Screen | C-l |
| Execute | Enter (C-m) |

## Cursor Movement

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Beginning of line | Move to start of current line | C-a | — | |
| End of line | Move to end of current line | C-e | — | |
| Backward char | Move one character left | C-b | M-h | Vim-like alt on HHKB |
| Forward char | Move one character right | C-f | M-l | Vim-like alt |
| Backward word | Move one word left | M-b | — | Word boundaries depend on WORDCHARS |
| Forward word | Move one word right | M-f | — | |
| Previous line / history | Move up in multi-line or history | C-p | M-k | M-k feels like Vim “k” |
| Next line / history | Move down in multi-line or history | C-n | M-j | M-j feels like Vim “j” |
| Beginning of buffer | Start of entire edit buffer | M-< | — | Rare in single-line prompts |
| End of buffer | End of entire edit buffer | M-> | — | |
| Exchange point & mark | Swap cursor with saved mark | C-x C-x | — | Requires mark set |
| Clear screen | Redraw prompt (like `clear`) | C-l | (Reserved for autosuggestion accept if enabled) | You left default untouched |
| Transpose chars | Swap characters around cursor | C-t | — | Cursor after second char |

---

## History Search & Navigation

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Incremental search backward | Live reverse search | C-r | — | |
| Incremental search forward | Live forward search | C-s | — | Disable flow control: `stty -ixon` |
| History search backward (prefix match) | Search older entries beginning with current buffer | M-p | — | |
| History search forward (prefix match) | Search newer matching entries | M-n | — | |
| Abort search / editing | Cancel current widget | C-g | — | |

---

## Deletion & Killing

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Delete char under cursor | Remove char or send EOF if line empty | C-d | — | EOF ends shell on empty line |
| Backspace (delete backward char) | Remove char before cursor | DEL (often ^?) | C-h | Redundant mapping |
| Kill (delete) previous word | Delete word to the left | C-w (shell override) / M-DEL | C-w (kept) | In Emacs proper C-w cuts region |
| Kill (delete) next word | Delete word to the right | M-d | M-d (explicit) | |
| Kill to end of line | Delete from cursor to EOL | C-k | C-k (explicit) | Adds to kill ring |
| Kill to beginning of line | Delete from cursor to BOL | (Readline style) C-u (Zsh: backward-kill-line) | C-u (explicit) | In Emacs C-u is universal-argument |
| Backward kill line | Same as above | backward-kill-line | Bound to C-u | Widget name clarification |
| Transpose words | Swap adjacent words | M-t | M-t (explicit) | |
| Delete backward char (alt) | Same as DEL | C-h | — | |
| Delete backward word (alt) | Same as C-w when no region | M-DEL | — | Terminal must send ESC DEL |
| Undo | Undo last change | C-x C-u | — | Limited linear undo |
| Redo | (Not default) | — | — | ZLE lacks full redo stack |

---

## Yank & Kill Ring

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Yank (paste last killed text) | Insert most recent kill | C-y | — | |
| Yank-pop (cycle through kill ring) | Replace last yank with earlier kill | M-y | — | Requires a prior yank (C-y) to start cycling |
| Copy region (kill-ring-save) | Add region to kill ring without deleting | M-w | — | Requires an active region |
| Kill region | Delete region | C-w (when region set) | — | Falls back to backward-kill-word w/o region |

Region use in shell is uncommon; you preserved semantic correctness by not remapping M-w.

---

## Case & Word Transformations

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Upcase word | Uppercase next word | M-u | — | |
| Downcase word | Lowercase next word | M-l | — | Potential conflict if remapped for movement in other setups |
| Capitalize word | Capitalize next word | M-c | — | |
| Transpose words | Swap adjacent words | M-t | — | Listed above also |

---

## Mark / Region (Optional / Advanced)

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Set mark | Start region | (Depends; often unbound) | (Not added) | You can bind: `bindkey '^@' set-mark-command` if terminal sends ^@ |
| Exchange point & mark | Toggle cursor with mark | C-x C-x | — | Requires existing mark |
| Kill/Cut region | Delete region (adds to kill ring) | C-w | — | |
| Copy region | Copy without delete | M-w | — | |

Region workflow is minimal in typical shell use; left untouched for correctness.

---

## Search / Miscellaneous

| Action | Description | Default Binding(s) | Added / Alternate | Notes |
|--------|-------------|--------------------|-------------------|-------|
| Complete word / insert match | Tab completion | TAB | — | Enhanced via your completion styles |
| List completions | Show completion menu | M-? | — | With `menu select`, arrow keys or M-j/k apply |
| Accept line | Execute command | Enter (C-m) | C-m / C-j | C-j also newline by default |
| Accept line then fetch next | Execute then load next history line | C-o | — | Useful for batch exec of sequential history |
| Edit line in external editor | Open buffer in `$EDITOR` | (Widget exists, unbound by default) | C-x C-e | You added this binding |
| Refresh / clear screen | Redraw prompt | C-l | — | Leaves your alternate space for autosuggestions |
| Abort current action | Cancel / return to prompt | C-g | — | |

---

## Your Vim-Inspired Enhancements (Summary)

| Enhancement | Purpose | Binding |
|-------------|---------|---------|
| M-h | Vim-style left | backward-char |
| M-l | Vim-style right | forward-char |
| M-j | Vim-style down / history next | down-line-or-history |
| M-k | Vim-style up / history previous | up-line-or-history |
| C-x C-e | Edit command line externally | edit-command-line |

---

## Conflict & Override Notes

| Key | Original Emacs Meaning | Current Behavior | Impact |
|-----|------------------------|------------------|--------|
| C-w (no region) | kill-region | backward-kill-word | Shell ergonomics preserved |
| C-u | universal-argument | backward-kill-line | Standard shell convention |
| M-h/M-l/M-j/M-k | (Unassigned / case actions / word move) | Movement shortcuts | Speeds navigation on HHKB |
| C-x C-e | (Unbound) | edit-command-line | Opens external editor |

---

## Restoring or Adjusting Behaviors

If you want backward kill on M-w (sacrificing region copy):
```zsh
bindkey '^[w' backward-kill-word
```

---

## Reference: Non-Plugin Enhancements You Already Use

- `compinit` with matcher-list fuzzy settings
- Extended globbing and history dedup
- Manual edit-command-line widget
- No external autosuggestion/highlighting plugins (keeps startup lean)

---

### Closing

This table set should give you fast recall and help reason about further tweaks without resorting to vi-mode or external plugins. Keep it as a living document—append custom widgets here if you create them.
