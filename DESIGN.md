---
name: gleam-zig docs
description: A graphite developer console where pink is the source language and amber is the output
colors:
  ground: "#0d1117"
  panel: "#12161d"
  elevated: "#181d26"
  seam: "#262c36"
  seam-soft: "#1d232c"
  text: "#e6edf3"
  dim: "#9ba5b3"
  faint: "#8a93a2"
  amber: "#f7a41d"
  amber-soft: "rgba(247, 164, 29, 0.13)"
  amber-tint: "#1b1810"
  amber-seam: "#443a22"
  pink: "#ffaff3"
  pink-tint: "#1a1420"
  pink-seam: "#453153"
  green: "#56d364"
  code-text: "#dbe2ea"
  code-dim: "#737e8d"
  code-str: "#e0c184"
typography:
  display:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(2.4rem, 5.6vw, 3.9rem)"
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: "-0.035em"
  headline:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(1.55rem, 3vw, 2.1rem)"
    fontWeight: 700
    lineHeight: 1.12
    letterSpacing: "-0.025em"
  title:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "1.1rem"
    fontWeight: 600
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.65
  label:
    fontFamily: "'JetBrains Mono', ui-monospace, 'SF Mono', Consolas, monospace"
    fontSize: "11px"
    fontWeight: 400
    letterSpacing: "0.1em"
  code:
    fontFamily: "'JetBrains Mono', ui-monospace, 'SF Mono', Consolas, monospace"
    fontSize: "12.5px"
    fontWeight: 400
    lineHeight: 1.6
rounded:
  sm: "6px"
  md: "8px"
  lg: "10px"
  xl: "12px"
spacing:
  chip: "2px 9px"
  cell: "12px 14px"
  panel: "16px 18px"
  gutter: "32px"
  section: "58px"
  gap-major: "52px"
components:
  button-primary:
    backgroundColor: "{colors.amber}"
    textColor: "#17120a"
    typography: "{typography.code}"
    rounded: "{rounded.md}"
    padding: "10px 17px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.text}"
    typography: "{typography.code}"
    rounded: "{rounded.md}"
    padding: "10px 17px"
  button-ghost-hover:
    backgroundColor: "{colors.elevated}"
  nav-link:
    textColor: "{colors.dim}"
    typography: "{typography.code}"
    rounded: "{rounded.sm}"
    padding: "7px 11px"
  panel:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.lg}"
  panel-head:
    backgroundColor: "{colors.elevated}"
    textColor: "{colors.dim}"
    typography: "{typography.label}"
    padding: "9px 16px"
  planned-chip:
    textColor: "{colors.dim}"
    typography: "{typography.label}"
    rounded: "{rounded.xl}"
    padding: "{spacing.chip}"
  note:
    backgroundColor: "{colors.amber-tint}"
    textColor: "{colors.text}"
    rounded: "{rounded.lg}"
    padding: "16px 20px"
---

# Design System: gleam-zig docs

## Overview

**Creative North Star: "The Graphite Console"**

The docs surface (gleam/docs/ only; the rest of the repo is compiler source
with no UI) reads like the environment its audience already works in: a
dark-first developer console on a graphite ground, built from hairline-seam
panels rather than floating cards. It refuses both the white feature-grid
docs default and the all-black terminal rut — the ground is #0d1117 graphite,
never pure black, and every container is a panel with a mono-labeled title
bar, like a tool window.

Color is never decorative: it carries syntax-derived meaning. Pink #FFAFF3
(sampled from Gleam's Lucy) marks the source language; amber #F7A41D
(sampled from the Zig mark) marks the output/runtime side and doubles as the
site's only interactive accent. The compile — pink becoming amber — is the
visual throughline, expressed in the split-ink headline, the two-pane compile
panels, and the tinted pipeline nodes. Evidence has its own typography:
every measurement sits in JetBrains Mono with tabular figures, and every
number traces to a dated run of record in the colophon.

One divergence from PRODUCT.md's baseline is deliberate and shipped: the
committed world is dark-only (`color-scheme: dark`), one canonical theme
with no light fork.

**Key Characteristics:**
- Graphite ground with three tonal surface steps (ground -> panel -> elevated), seamed by 1px hairlines
- Pink = source, amber = output; meaning-bearing color only
- Archivo for prose, JetBrains Mono for everything console-flavored: labels, nav, numbers, code
- Receipts culture: tabular-num measurements, plate captions, dated colophon
- Dashed outline = planned/unshipped; log rows = limits
- Near-still: one authored motion (the emitted pane streams in once)

## Colors

A graphite neutral ramp carrying two logo-sampled accents whose hue is semantic, not thematic.

### Primary
- **Zig Amber** (#f7a41d): the output/runtime side of every split, and by extension the site's action color — links, primary button, focus rings, selection, active TOC entry, inline code, `=>` list markers, WARN severity. Never invented; sampled from zig-mark.svg.
- **Amber Wash** (rgba(247,164,29,0.13)): inline-code background only.
- **Amber Ground** (#1b1810) / **Amber Seam** (#443a22): the tinted panel ground and hairline for output panes, callout notes, and output pipeline nodes — amber at region scale is a tint plus seam, never a fill.

### Secondary
- **Gleam Pink** (#ffaff3): the source-language side — Gleam keywords and generated-name tokens in code, source pane headers and dots, the `Gleam` word in the headline. Sampled from Lucy. Pink is never interactive.
- **Pink Ground** (#1a1420) / **Pink Seam** (#453153): source-pane and source-node tinted grounds and seams, mirroring the amber pair.

### Tertiary
- **Pass Green** (#56d364): verification-positive only — passing stat, prompt/`cd` tokens in shell blocks, check icons, the copy button's done state.

### Neutral
- **Graphite Ground** (#0d1117): page background and badge fills.
- **Panel** (#12161d): the default container surface.
- **Elevated** (#181d26): panel title bars, table header rows, hover fills.
- **Seam** (#262c36) / **Seam Soft** (#1d232c): 1px borders; seam for container outlines, seam-soft for internal dividers.
- **Text** (#e6edf3), **Dim** (#9ba5b3), **Faint** (#8a93a2): three-step text hierarchy — headings/strong, running prose, chrome labels.
- **Code Text** (#dbe2ea), **Code Dim** (#737e8d), **Code String** (#e0c184): the code-block palette; comments are code-dim italic, strings are the muted gold.

### Named Rules
**The Syntax-Derived Color Rule.** Pink means Gleam/source and amber means Zig/output — everywhere, at every scale. Neither is ever used as mood or decoration, and no accent hex is invented: both are sampled from the official logos.
**The Tint-Not-Fill Rule.** At region scale an accent appears only as its dark tint ground plus its seam (`amber-tint`/`amber-seam`, `pink-tint`/`pink-seam`). Full-strength accent fills are reserved for text, dots, and the primary button.

## Typography

**Display Font:** Archivo (with system-ui, sans-serif)
**Body Font:** Archivo (same family, weight-differentiated)
**Label/Mono Font:** JetBrains Mono (with ui-monospace, 'SF Mono', Consolas)

**Character:** A sturdy grotesque for prose against a workhorse coding mono for everything the console owns: navigation, panel labels, numbers, buttons, code. Ligatures are disabled in code (`font-variant-ligatures: none`) so emitted Zig reads verbatim.

### Hierarchy
- **Display** (700, clamp(2.4rem, 5.6vw, 3.9rem), 1.04, -0.035em): hero headline only; `text-wrap: balance`, max-width 22ch, split-ink accent spans.
- **Headline** (700, clamp(1.55rem, 3vw, 2.1rem), 1.12, -0.025em): section h2, underlined by a full-width seam (`h2.ruled`).
- **Title** (600, 1.1rem, -0.01em): h3 subsections.
- **Body** (400, 16px, 1.65): running prose in `dim`, max-width 68ch; emphasis promotes to `text` at 600.
- **Label** (mono, 10–11px, 0.1–0.14em tracking, uppercase): panel heads, rail heads, table headers, TOC label.
- **Code** (mono, 12.5–13px, 1.6): code panes and shell blocks; 12px for nav and TOC links.

### Named Rules
**The Tabular Receipt Rule.** Every measurement on the page — corpus counts, sizes, timings, commit hashes — is set in JetBrains Mono with `font-variant-numeric: tabular-nums` (the `.num` treatment). Prose figures never carry evidence.
**The Mono Chrome Rule.** Anything belonging to the console chrome (nav, labels, buttons, badges, chips, footer colophon) is mono; Archivo is reserved for reading.

## Layout

A single 1200px shell (`max-width: 1200px`, 32px gutters, 18px under 640px). The hero splits headline against a receipts status bar (1fr / 300px); below it the page runs a content-plus-rail grid (`minmax(0,1fr) / 208px`, 52px gap) with prose capped at 780px and a sticky mono TOC that highlights the active section via IntersectionObserver. Sections breathe at 58px top padding with `scroll-margin-top: 84px` under the sticky, blurred topbar. Compile panels split source/output 5fr/7fr. Everything collapses to one column at 1000px (TOC hidden, status bar goes 2-up), compile panes stack at 760px, inline nav links hide at 780px. Code blocks scroll horizontally rather than wrapping.

## Elevation & Depth

Depth is tonal and seamed, not shadowed: three surface steps (ground -> panel -> elevated) separated by 1px hairlines (`seam` for outlines, `seam-soft` for internal dividers). Exactly two elements cast shadows — the hero compile panel and the primary button — and both are soft black ambient drops, never colored glows. The sticky topbar gets depth from translucency instead: `color-mix` 86% ground over a `saturate(1.3) blur(12px)` backdrop.

### Shadow Vocabulary
- **Hero anchor** (`box-shadow: 0 24px 60px -32px rgba(0,0,0,0.55)`): the first-viewport compile panel only.
- **Primary button** (`0 2px 8px -2px rgba(0,0,0,0.5)`, deepening to `0 4px 12px -3px rgba(0,0,0,0.55)` with `translateY(-1px)` on hover).

### Named Rules
**The Hairline Seam Rule.** Structure comes from 1px seams and tonal steps; shadows are exceptional (two on the whole page) and always neutral black.

## Shapes

Soft-rectangular console geometry: containers at 10px radius (compile hero at 12px), interactive elements at 8px, small chrome at 5–6px, pipeline nodes at 9px. Pane dots are 7px circles; badges and chips are 12px-radius pills. Borders are always 1px solid — except the one meaningful exception: **a 1px dashed `faint` outline means planned/unshipped** (the `.planned` chip). List bullets are typographic (`=>` in amber mono), not glyphs. Corners never go sharp and never exceed 12px.

## Components

### Buttons
- **Shape:** softly rounded (8px), mono type (13px, weight 500–600), inline-flex with 8px icon gap.
- **Primary:** amber fill with near-black amber-derived ink (#17120a), 10px 17px padding, neutral drop shadow.
- **Hover / Focus:** primary lifts 1px with a deeper shadow; all interactive elements get a 2px amber `focus-visible` outline offset 2px.
- **Ghost:** transparent with a `seam` border and `text` label; hover fills with `elevated`.

### Chips
- **Badge** (`.badge`): mono 10.5px pill, `ground` fill, `seam` border, `dim` text — used for measured facts on panel heads (line counts, module counts).
- **Planned chip** (`.planned`): mono 10.5px pill, 1px **dashed** `faint` border, `dim` text — the sole marker for unshipped work, always paired with an issue number when one exists.

### Cards / Containers
- **The panel is the page's native container:** `panel` fill, 1px `seam` border, 10px radius, `overflow: hidden`.
- **Panel head:** an `elevated` title bar in uppercase mono label type with a `seam-soft` bottom rule; its right-aligned `.plate` slot carries lowercase provenance captions (10.5px, `faint`), hidden under 720px.
- **Accent variants:** source/output panes and notes swap to `pink-tint`/`amber-tint` grounds with matching seams (see the Tint-Not-Fill Rule).

### Inputs / Fields
None exist; the page has no forms.

### Navigation
- **Topbar:** sticky, translucent blurred graphite with a `seam-soft` bottom rule; mono lowercase links (12px, `dim`) that hover to `elevated` pills; the GitHub link is a bordered ghost pill; brand lockup pairs the two logo SVGs around a stroke arrow.
- **TOC rail:** sticky mono 12px list with a 1px left seam per item; hover/active turns text and border amber.

### Compile Panel (signature)
The system's identity component: a two-pane grid (source 5fr / output 7fr) inside a 12px-radius bordered shell. Left pane sits on `pink-tint` with a pink-labeled mono file header and pink dot; right pane on `amber-tint` with amber equivalents; each header carries its language's logo at 15px. Code runs 12.5px mono, ligatures off. A bottom `plate NN` caption bar states provenance ("emitted, verbatim", commit, what was elided). The hero instance streams its output lines in once (60ms stagger) — the page's one authored motion, fully disabled under `prefers-reduced-motion`.

### Receipts Status Bar (signature)
A stacked panel of stats under an uppercase "run of record · date" rail head: each stat is a large tabular-mono number (1.35rem, 600) with a smaller unit suffix and a two-line `dim` caption naming the oracle. Number color is semantic (green pass, amber measurements, neutral counts).

### Limits Log (signature)
Limits render as log output: a panel of grid rows (`62px severity / 220px what / 1fr why`) separated by `seam-soft` rules. Severity is mono 11px — `WARN` in amber, `INFO` in `dim` — with a bold `text` subject and `dim` explanation. Deliberate edges get the same finish as wins.

## Do's and Don'ts

### Do:
- **Do** route every accent through meaning: pink for Gleam/source, amber for Zig/output and interaction, green for verification-positive — nothing else gets color.
- **Do** set every number in `.num` tabular mono, and give every code panel a plate caption stating its provenance (commit, "emitted, verbatim", what was elided).
- **Do** mark unshipped work with the dashed `.planned` chip; dashed outline is the only vocabulary for "not built yet."
- **Do** build containers as panels: `panel` fill, 1px `seam` border, 10px radius, uppercase mono title bar on `elevated`.
- **Do** honor `prefers-reduced-motion` by killing all animation and smooth scroll (`* { animation: none; transition: none; }`).

### Don't:
- **Don't** use pure black or white surfaces; the world runs #0d1117 to #e6edf3, dark-only, one theme.
- **Don't** fill a region with full-strength accent; regions get tint grounds plus seams (amber-tint/amber-seam, pink-tint/pink-seam).
- **Don't** add shadows beyond the two shipped (hero compile panel, primary button), and never colored glows.
- **Don't** enable code ligatures or proportional figures in evidence; emitted code and measurements read verbatim.
- **Don't** add authored motion beyond entrance rises and the single hero stream; the console is near-still.
