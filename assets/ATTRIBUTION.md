# Icon attribution

Every file in `assets/logos/` is a generated card: a small rounded rectangle
holding one brand mark plus its name. Nothing is hand-drawn except the card
frame itself.

- **Source artwork:** the [Iconify](https://iconify.design) API. Its `logos`
  collection is the brand-coloured [SVG Logos](https://svglogos.dev) artwork,
  licensed [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
  The phone glyph comes from Iconify's `mdi` collection (Material Design Icons,
  Apache 2.0).
- **Why Iconify rather than shields.io:** shields.io bundles no LinkedIn icon
  and no phone icon at all, so those two badges render with a permanently blank
  icon slot whatever `logo=` is passed. Iconify has both. Simple Icons has also
  dropped LinkedIn (`cdn.simpleicons.org/linkedin` returns 404).
- **Why self-hosted rather than hot-linked:** the cards are downloaded once and
  committed, so the README renders identically forever and never breaks because
  a CDN changed a URL, rate-limited, or went down.

## Card design

| Property | Value | Why |
|:---|:---|:---|
| Height | 20px | small enough to read as a set, large enough to stay legible |
| Width | exact | `[padding][mark][gap][label][padding]`, nothing more |
| Corners | square | a rounded chip reads as a button; a square one reads as a label |
| Mark | 13px tall, capped at 42px wide | uniform height makes a row of marks look like a set; the width cap stops a wide wordmark dominating |
| Label | Helvetica 10px, `#1f2328` | |

Two treatments, because the two rows have different jobs.

**Stack.** Each category gets its own tint, so the five sections are
distinguishable at a glance and every brand-coloured mark still has a light
surface to sit on. Cards butt up against each other with a single space between.

| Group | Fill | Edge | |
|:---|:---|:---|:---|
| `lang` | `#dbeafe` | `#93c5fd` | blue |
| `front` | `#cffafe` | `#67e8f9` | cyan |
| `back` | `#dcfce7` | `#86efac` | green |
| `data` | `#ffedd5` | `#fdba74` | amber |
| `ops` | `#ede9fe` | `#c4b5fd` | violet |

**Contact.** All five cards share one neutral fill (`#f6f8fa` on `#d0d7de`) and
their marks are flattened to the label ink `#1f2328`. Five differently coloured
brand marks compete with the banner, and brand colour is not the point for a row
of contact links. Flattening also guarantees they read on either GitHub theme.

Because every card supplies its own light background, no mark had to be
recoloured. Next.js (`#000000`), Express (`#222222`), Kafka (`#1A1919`) and
WebSocket (`#231F20`) are all invisible against GitHub's dark theme, but they sit
on a `#f6f8fa`-or-tinted surface here and read correctly in both themes.

Most wordmarks are sourced from their square `-icon` variant (Angular, Docker,
Firebase, GitHub, Git, LinkedIn, MySQL, Supabase, Tailwind, TypeScript, Vite,
Vercel) so the marks sit at a consistent size. Five have no usable square variant
and keep the wordmark, width-capped: Express, Maven, MongoDB, Next.js, Spring and
Spring Security. Next.js has a square icon but it is white, so it would vanish.

Six cards are text-only, because no mark exists for them: `compose`, `ollama`,
`pgvector`, `rbac`, `rest`, `ssh`.

## Regenerating

```powershell
powershell -File tools/build-icons.ps1   # redownload and rebuild every card
python tools/validate-icons.py           # XML + geometry checks
```

Edit the `$items` array at the top of `build-icons.ps1`:

```powershell
@{ s='slug'; l='Label'; i='collection/icon'; col=''; g='group'; u='https://official.site/' }
```

Set `i=''` for a text-only card, `col='%23RRGGBB'` when the source icon needs an
explicit colour, and `u=''` to leave the card unlinked. `g` picks the fill and
edge from `$GROUPS`; adding a category is one entry there. Members of the
`contact` group are additionally flattened to a single ink colour.

`validate-icons.py` re-derives the card geometry from the metrics the build
script uses and fails on any disagreement: XML errors, a `viewBox` that
contradicts the declared size, a mark scaled wrong or off-centre, a label that
would clip, a text-only card that is not exactly as wide as its label, a corner
radius or group fill that is not the one configured, or a matte mark that still
carries a second colour or `currentColor`.

Note the download cache is keyed on both slug and source icon, so repointing an
entry at a different mark cannot silently reuse the previous file.

All product names and logos are trademarks of their respective owners. They are
used here for identification only.