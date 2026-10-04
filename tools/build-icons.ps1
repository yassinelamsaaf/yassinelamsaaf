# Builds every icon used by README.md: small cards of [mark + label].
#
#   powershell -File tools/build-icons.ps1
#   python tools/validate-icons.py
#
# Source is the Iconify API (https://iconify.design). Its "logos" collection is
# the brand-coloured artwork, which is what a Stack section needs. It also
# carries linkedin, which shields.io does not, and a phone glyph from the
# "mdi" collection. Everything is downloaded once and self-hosted in
# assets/logos/, so the README never depends on a third-party CDN at render time.
#
# Why cards and not bare marks: a mark like Next.js (#000000) or Express
# (#222222) is invisible against a dark GitHub theme. A card supplies its own
# light background, so every brand colour stays legible in both themes with no
# recolouring and no CSS. Cards are 18px tall and exactly as wide as their
# contents.

$ErrorActionPreference = 'Stop'
$repo   = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $repo 'assets\logos'
$tmpDir = Join-Path $env:TEMP 'iconify-src'
New-Item -ItemType Directory -Force -Path $outDir, $tmpDir | Out-Null

# Card geometry, in px.
$H      = 20        # card height
$PAD    = 6         # left/right inner padding
$MARK   = 13        # mark height inside the card
$MAXW   = 42        # cap on mark width, so one wordmark cannot dominate a row
$GAP    = 4         # space between mark and label
$FONT   = 10        # label font size
$RADIUS = 4.5
$BG     = '#f6f8fa' # GitHub's subtle light fill
$EDGE   = '#d8dee4' # softer than #d0d7de so the card reads as quiet
$INK    = '#1f2328' # GitHub's default text colour

# Helvetica advance widths (per 1000 em) as a proxy for the label metrics.
# GitHub renders these SVGs as images, so the real font is whatever the reader
# has installed; Helvetica/Arial are the closest common match, and PAD absorbs
# the remaining difference.
$table = @'
 278
! 278
" 355
# 556
$ 556
% 889
& 667
' 191
( 333
) 333
* 389
+ 584
, 278
- 333
. 278
/ 278
: 278
; 278
? 556
@ 1015
| 260
0 556
1 556
2 556
3 556
4 556
5 556
6 556
7 556
8 556
9 556
A 667
B 667
C 722
D 722
E 667
F 611
G 778
H 722
I 278
J 500
K 667
L 556
M 833
N 722
O 778
P 667
Q 778
R 722
S 667
T 611
U 722
V 667
W 944
X 667
Y 667
Z 611
a 556
b 556
c 500
d 556
e 556
f 278
g 556
h 556
i 222
j 222
k 500
l 222
m 833
n 556
o 556
p 556
q 556
r 333
s 500
t 278
u 556
v 500
w 722
x 500
y 500
z 500
'@

# Ordinal comparer: PowerShell's default hashtable is case-insensitive, which
# would collapse 'A' onto 'a' and lose the capitals-versus-lowercase widths.
$W = [System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::Ordinal)
foreach ($line in ($table -split "`n")) {
  if ($line.Length -ge 2) { $W[$line.Substring(0, 1)] = [int]$line.Substring(1).Trim() }
}

function Get-TextWidth([string]$s, [double]$size) {
  $sum = 0.0
  foreach ($ch in $s.ToCharArray()) {
    $k = $ch.ToString()
    if ($W.ContainsKey($k)) { $sum += $W[$k] } else { $sum += 556 }
  }
  ($sum / 1000.0) * $size
}

# slug, label, iconify id (blank = text-only card), colour override, link
$items = @(
  # ---- contact row -------------------------------------------------------
  @{ s='linkedin';  l='LinkedIn';  i='logos/linkedin-icon';     col='';                 u='https://www.linkedin.com/in/yassine-lamsaaf/' },
  @{ s='github';    l='GitHub';    i='logos/github-icon';       col='';                 u='https://github.com/yassinelamsaaf' },
  @{ s='email';     l='Email';     i='logos/google-gmail'; col='';                 u='mailto:lamsaafyassine20@gmail.com' },
  @{ s='phone';     l='Phone';     i='mdi/phone';          col='%236e7681';        u='tel:+212655241037' },
  @{ s='portfolio'; l='Portfolio'; i='logos/vercel-icon';       col='';                 u='https://lamsaaf-yassine-portfolio.vercel.app' },

  # ---- languages ---------------------------------------------------------
  @{ s='java';       l='Java';       i='logos/java';       col=''; u='https://www.oracle.com/java/' },
  @{ s='javascript'; l='JavaScript'; i='logos/javascript'; col=''; u='https://www.javascript.com/' },
  @{ s='typescript'; l='TypeScript'; i='logos/typescript-icon'; col=''; u='https://www.typescriptlang.org/' },
  @{ s='python';     l='Python';     i='logos/python';     col=''; u='https://www.python.org/' },
  @{ s='c';          l='C';          i='logos/c';          col=''; u='https://isocpp.org/' },
  @{ s='cpp';        l='C++';        i='logos/c-plusplus'; col=''; u='https://isocpp.org/' },

  # ---- frontend ----------------------------------------------------------
  @{ s='react';    l='React';       i='logos/react';       col=''; u='https://react.dev/' },
  @{ s='nextjs';   l='Next.js';     i='logos/nextjs';      col=''; u='https://nextjs.org/' },
  @{ s='angular';  l='Angular';     i='logos/angular-icon';     col=''; u='https://angular.dev/' },
  @{ s='tailwind'; l='Tailwind CSS'; i='logos/tailwindcss-icon'; col=''; u='https://tailwindcss.com/' },
  @{ s='vite';     l='Vite';        i='logos/vite-icon';        col=''; u='https://vite.dev/' },
  @{ s='html5';    l='HTML5';       i='logos/html-5';      col=''; u='https://developer.mozilla.org/en-US/docs/Web/HTML' },
  @{ s='css3';     l='CSS3';        i='logos/css';         col=''; u='https://developer.mozilla.org/en-US/docs/Web/CSS' },

  # ---- backend -----------------------------------------------------------
  @{ s='spring';         l='Spring Boot';     i='logos/spring';          col=''; u='https://spring.io/projects/spring-boot' },
  @{ s='springsecurity'; l='Spring Security'; i='logos/spring';          col=''; u='https://spring.io/projects/spring-security' },
  @{ s='hibernate';      l='Hibernate';       i='logos/hibernate';       col=''; u='https://hibernate.org/' },
  @{ s='nodejs';         l='Node.js';         i='logos/nodejs';          col=''; u='https://nodejs.org/' },
  @{ s='express';        l='Express.js';      i='logos/express';         col=''; u='https://expressjs.com/' },
  @{ s='grpc';           l='gRPC';            i='logos/grpc';            col=''; u='https://grpc.io/' },
  @{ s='websocket';      l='WebSocket';       i='logos/websocket';       col=''; u='https://developer.mozilla.org/en-US/docs/Web/API/WebSocket' },
  @{ s='rest';           l='REST APIs';       i='';         col=''; u='https://spec.openapis.org/' },
  @{ s='jwt';            l='JWT';             i='logos/jwt';             col=''; u='https://jwt.io/' },
  @{ s='rbac';           l='RBAC';            i='';                      col=''; u='' },

  # ---- databases ---------------------------------------------------------
  @{ s='postgresql'; l='PostgreSQL'; i='logos/postgresql'; col=''; u='https://www.postgresql.org/' },
  @{ s='pgvector';   l='pgvector';   i='';                  col=''; u='' },
  @{ s='mysql';      l='MySQL';      i='logos/mysql-icon';      col=''; u='https://www.mysql.com/' },
  @{ s='mongodb';    l='MongoDB';    i='logos/mongodb';    col=''; u='https://www.mongodb.com/' },
  @{ s='redis';      l='Redis';      i='logos/redis';      col=''; u='https://redis.io/' },
  @{ s='firebase';   l='Firebase';   i='logos/firebase-icon';   col=''; u='https://firebase.google.com/' },
  @{ s='supabase';   l='Supabase';   i='logos/supabase-icon';   col=''; u='https://supabase.com/' },

  # ---- devops ------------------------------------------------------------
  @{ s='docker';     l='Docker';         i='logos/docker-icon';         col=''; u='https://www.docker.com/' },
  @{ s='compose';    l='Docker Compose'; i='';                    col=''; u='' },
  @{ s='kubernetes'; l='Kubernetes';     i='logos/kubernetes';     col=''; u='https://kubernetes.io/' },
  @{ s='argocd';     l='Argo CD';        i='logos/argo';           col=''; u='https://argo-cd.readthedocs.io/' },
  @{ s='actions';    l='GitHub Actions'; i='logos/github-actions'; col=''; u='https://github.com/features/actions' },
  @{ s='git';        l='Git';            i='logos/git-icon';            col=''; u='https://git-scm.com/' },
  @{ s='linux';      l='Linux';          i='logos/linux-tux';      col=''; u='https://www.kernel.org/' },
  @{ s='ssh';        l='SSH';            i='';                     col=''; u='' },
  @{ s='nginx';      l='Nginx';          i='logos/nginx';          col=''; u='https://nginx.org/' },
  @{ s='maven';      l='Maven';          i='logos/maven';          col=''; u='https://maven.apache.org/' },
  @{ s='kafka';      l='Kafka';          i='logos/kafka';          col=''; u='https://kafka.apache.org/' },
  @{ s='ollama';     l='Ollama';         i='';                     col=''; u='https://ollama.com/' },
  @{ s='vscode';     l='VS Code';       i='logos/visual-studio-code'; col=''; u='https://code.visualstudio.com/' }
)

$report = @()

foreach ($it in $items) {
  $label = $it.l
  $textW = [math]::Round((Get-TextWidth $label $FONT), 2)
  $markW = 0.0
  $markSvg = ''

  if ($it.i) {
    $url = "https://api.iconify.design/$($it.i).svg"
    if ($it.col) { $url += "?color=$($it.col)" }
    # Cache on the source id, not the slug. Keying on the slug alone means
    # repointing an entry at a different mark silently reuses the stale file.
    $cached = Join-Path $tmpDir ("$($it.s).$($it.i -replace '[\\/]', '_').svg")
    if (-not (Test-Path $cached)) {
      Invoke-WebRequest -Uri $url -OutFile $cached -UseBasicParsing -TimeoutSec 30
    }
    $raw = Get-Content -Raw $cached -Encoding UTF8

    # Keep the mark's own viewBox; they vary (0 0 512 139, 0 0 24 24, ...)
    $vb = [regex]::Match($raw, 'viewBox\s*=\s*"([-\d\.\s]+)"').Groups[1].Value.Trim()
    if (-not $vb) { throw "no viewBox in $($it.s)" }
    $v = $vb -split '\s+' | ForEach-Object { [double]$_ }
    # Uniform height is what makes a row of marks read as a set, so height is the
    # primary constraint. Over-wide wordmarks are capped in width instead, which
    # shrinks them a little; below the cap they keep their full height.
    $scale = [math]::Min($MARK / $v[3], $MAXW / $v[2])
    $markW = [math]::Round($v[2] * $scale, 2)

    $inner = $raw -replace '(?s)^.*?<svg[^>]*>', '' -replace '(?s)</svg>\s*$', ''
    $markSvg = "<g transform=`"translate($PAD,$([math]::Round(($H - $MARK) / 2, 2))) scale($scale)`" data-vb=`"$vb`">$inner</g>"
  }

  $textX = $PAD + $markW + $(if ($markW) { $GAP } else { 0 })
  $cardW = [math]::Round($textX + $textW + $PAD, 2)
  $baseY = [math]::Round(($H + $FONT * 0.72) / 2, 2)

  $card = @(
    "<svg xmlns=`"http://www.w3.org/2000/svg`" xmlns:xlink=`"http://www.w3.org/1999/xlink`" width=`"$cardW`" height=`"$H`" viewBox=`"0 0 $cardW $H`">"
    "  <rect x=`"0.5`" y=`"0.5`" width=`"$($cardW - 1)`" height=`"$($H - 1)`" rx=`"$RADIUS`" fill=`"$BG`" stroke=`"$EDGE`"/>"
  )
  if ($markSvg) { $card += "  $markSvg" }
  $card += "  <text x=`"$textX`" y=`"$baseY`" font-family=`"Helvetica,Arial,sans-serif`" font-size=`"$FONT`" font-weight=`"500`" fill=`"$INK`">$label</text>"
  $card += "</svg>"

  Set-Content -Path (Join-Path $outDir "$($it.s).svg") -Value ($card -join "`n") -Encoding UTF8 -NoNewline
  $report += [pscustomobject]@{
    slug = $it.s; label = $label; w = $cardW
    mark = $(if ($it.i) { 'yes' } else { 'text-only' })
  }
}

$report | Format-Table -AutoSize | Out-String | Write-Output
"wrote $($report.Count) cards -> assets/logos/  (text-only: $(($report | Where-Object mark -eq 'text-only').Count))"