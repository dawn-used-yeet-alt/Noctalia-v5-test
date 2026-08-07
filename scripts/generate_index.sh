#!/bin/bash
# generate_index.sh — Create index.html for the Noctalia pacman repository.
# Usage: generate_index.sh <output_dir> <version> <commit> <gpg_key_id> <repo_url>
set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <output_dir> <version> <commit> <gpg_key_id> <repo_url>" >&2
  echo "  gpg_key_id may be empty (pass '' or \"\") to indicate unsigned mode." >&2
  exit 1
fi

OUTPUT_DIR="${1}"
VERSION="${2}"
COMMIT="${3}"
GPG_KEY_ID="${4}"
REPO_URL="${5}"

COMMIT_SHORT="${COMMIT:0:7}"

if [ -n "$GPG_KEY_ID" ]; then
    SIGNING_HTML="<span class=\"sig-on\"><span class=\"sig-dot\" aria-hidden=\"true\"></span>signed &middot; <code>${GPG_KEY_ID}</code></span>"
    SETUP_INSTRUCTIONS=$(cat <<EOF
      <section class="section">
        <p class="section-label">Step 01</p>
        <h2>Import signing key</h2>
        <div class="code-wrap">
          <button class="copy-btn" onclick="copyCode(this, 'step1')">copy</button>
          <pre id="step1">curl -fsSL ${REPO_URL}/noctalia-signing-key.gpg | sudo pacman-key --add -
sudo pacman-key --lsign-key ${GPG_KEY_ID}</pre>
        </div>
      </section>
      <section class="section">
        <p class="section-label">Step 02</p>
        <h2>Add repository to <code class="inline-path">/etc/pacman.conf</code></h2>
        <div class="code-wrap">
          <button class="copy-btn" onclick="copyCode(this, 'step2')">copy</button>
          <pre id="step2">[noctalia]
SigLevel = Required DatabaseOptional
Server = ${REPO_URL}</pre>
        </div>
      </section>
      <section class="section">
        <p class="section-label">Step 03</p>
        <h2>Install</h2>
        <div class="code-wrap">
          <button class="copy-btn" onclick="copyCode(this, 'step3')">copy</button>
          <pre id="step3">sudo pacman -Sy noctalia-git</pre>
        </div>
      </section>
EOF
)
else
    SIGNING_HTML="<span class=\"sig-off\">unsigned</span>"
    SETUP_INSTRUCTIONS=$(cat <<EOF
      <section class="section">
        <p class="section-label">Step 01</p>
        <h2>Add repository to <code class="inline-path">/etc/pacman.conf</code></h2>
        <p class="callout-warn">Signing is not configured. <code>TrustAll</code> disables signature verification — only proceed if you trust this source.</p>
        <div class="code-wrap">
          <button class="copy-btn" onclick="copyCode(this, 'step1')">copy</button>
          <pre id="step1">[noctalia]
SigLevel = Optional TrustAll
Server = ${REPO_URL}</pre>
        </div>
      </section>
      <section class="section">
        <p class="section-label">Step 02</p>
        <h2>Install</h2>
        <div class="code-wrap">
          <button class="copy-btn" onclick="copyCode(this, 'step2')">copy</button>
          <pre id="step2">sudo pacman -Sy noctalia-git</pre>
        </div>
      </section>
EOF
)
fi

cat <<EOF > "$OUTPUT_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>noctalia-git — Arch Linux pacman repository</title>
<meta name="description" content="Automated daily builds of noctalia-git for Arch Linux, served as a pacman repository via GitHub Pages.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
  /* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V4
   * genre: editorial · theme: ink-on-paper documentation
   * contrast: all text pairs pass WCAG AA
   */
  :root {
    --color-bg:         #f8f8f6;
    --color-surface:    #ffffff;
    --color-border:     #d0d0cc;
    --color-border-sub: #e8e8e4;
    --color-text:       #111111;
    --color-text-muted: #6b6b6b;
    --color-accent:     #1a47b8;
    --color-code-bg:    #f2f2ee;
    --color-code-text:  #111111;
    --color-success:    #0a6640;
    --color-warn:       #8a4b00;
    --color-warn-bg:    #fdf7ed;
    --font-sans: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    --font-mono: "JetBrains Mono", "Fira Code", ui-monospace, "Cascadia Code", monospace;
    --space-1: 0.25rem;
    --space-2: 0.5rem;
    --space-3: 0.75rem;
    --space-4: 1rem;
    --space-6: 1.5rem;
    --space-8: 2rem;
    --space-12: 3rem;
    --radius: 3px;
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { overflow-x: clip; }

  body {
    font-family: var(--font-sans);
    background: var(--color-bg);
    color: var(--color-text);
    font-size: 1rem;
    line-height: 1.65;
    padding: var(--space-12) var(--space-4);
    min-height: 100vh;
  }

  .wrap {
    max-width: 640px;
    margin: 0 auto;
  }

  /* Header */
  .site-header {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: var(--space-3);
    padding-bottom: var(--space-6);
    border-bottom: 2px solid var(--color-text);
    margin-bottom: var(--space-6);
  }

  h1 {
    font-family: var(--font-mono);
    font-size: 1.25rem;
    font-weight: 500;
    font-style: normal;
    color: var(--color-text);
    overflow-wrap: anywhere;
    min-width: 0;
    letter-spacing: -0.01em;
  }

  .platform-label {
    font-family: var(--font-mono);
    font-size: 0.625rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    color: var(--color-text-muted);
    white-space: nowrap;
  }

  /* Meta strip */
  .meta-strip {
    display: flex;
    flex-wrap: wrap;
    column-gap: var(--space-8);
    row-gap: var(--space-2);
    margin-bottom: var(--space-12);
    font-family: var(--font-mono);
    font-size: 0.75rem;
    color: var(--color-text-muted);
  }

  .meta-strip b { font-weight: 500; color: var(--color-text); }
  .meta-strip a { color: var(--color-accent); text-decoration: none; }
  .meta-strip a:hover { text-decoration: underline; }

  .sig-on {
    display: inline-flex;
    align-items: center;
    gap: var(--space-1);
    color: var(--color-success);
  }

  .sig-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--color-success);
    flex-shrink: 0;
  }

  .sig-on code {
    font-family: var(--font-mono);
    color: var(--color-success);
    font-size: 0.75rem;
  }

  .sig-off { color: var(--color-warn); }

  /* Sections */
  .section {
    padding: var(--space-6) 0;
    border-bottom: 1px solid var(--color-border-sub);
  }

  .section:last-of-type { border-bottom: none; }

  .section-label {
    font-family: var(--font-mono);
    font-size: 0.5625rem;
    text-transform: uppercase;
    letter-spacing: 0.14em;
    color: var(--color-text-muted);
    margin-bottom: var(--space-2);
  }

  h2 {
    font-size: 0.9375rem;
    font-weight: 600;
    font-style: normal;
    color: var(--color-text);
    margin-bottom: var(--space-4);
    overflow-wrap: anywhere;
    min-width: 0;
  }

  code.inline-path {
    font-family: var(--font-mono);
    font-size: 0.8125rem;
    font-weight: 400;
    color: var(--color-text-muted);
    background: var(--color-code-bg);
    padding: 1px 5px;
    border-radius: var(--radius);
    border: 1px solid var(--color-border-sub);
  }

  .callout-warn {
    font-size: 0.875rem;
    color: var(--color-warn);
    background: var(--color-warn-bg);
    border-left: 3px solid var(--color-warn);
    border-radius: 0 var(--radius) var(--radius) 0;
    padding: var(--space-3) var(--space-4);
    margin-bottom: var(--space-4);
    line-height: 1.55;
  }

  .callout-warn code {
    font-family: var(--font-mono);
    font-size: 0.8125rem;
  }

  /* Code block */
  .code-wrap { position: relative; }

  pre {
    font-family: var(--font-mono);
    font-size: 0.8125rem;
    line-height: 1.8;
    color: var(--color-code-text);
    background: var(--color-code-bg);
    border: 1px solid var(--color-border-sub);
    border-radius: var(--radius);
    padding: var(--space-4);
    padding-right: 4.5rem;
    overflow-x: auto;
    tab-size: 2;
  }

  .copy-btn {
    position: absolute;
    top: var(--space-2);
    right: var(--space-2);
    font-family: var(--font-mono);
    font-size: 0.5625rem;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    background: var(--color-surface);
    border: 1px solid var(--color-border);
    color: var(--color-text-muted);
    border-radius: var(--radius);
    padding: 3px 9px;
    cursor: pointer;
    line-height: 1.6;
    transition: color 0.12s, border-color 0.12s;
  }

  .copy-btn:hover { color: var(--color-accent); border-color: var(--color-accent); }
  .copy-btn:focus-visible { outline: 2px solid var(--color-accent); outline-offset: 2px; }
  .copy-btn:active { opacity: 0.7; }

  /* Footer */
  .site-footer {
    margin-top: var(--space-8);
    padding-top: var(--space-6);
    border-top: 1px solid var(--color-border-sub);
    display: flex;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: var(--space-3);
    font-size: 0.8125rem;
    color: var(--color-text-muted);
  }

  .footer-links { display: flex; gap: var(--space-6); }
  .site-footer a { color: var(--color-text-muted); text-decoration: none; }
  .site-footer a:hover { color: var(--color-accent); text-decoration: underline; }

  /* Responsive */
  @media (max-width: 480px) {
    body { padding: var(--space-8) var(--space-4); }
    h1 { font-size: 1.0625rem; }
    .site-header { align-items: flex-start; gap: var(--space-2); }
    .meta-strip { column-gap: var(--space-6); }
    .footer-links { gap: var(--space-4); }
  }
</style>
</head>
<body>
<div class="wrap">

  <header class="site-header">
    <h1>noctalia-git</h1>
    <span class="platform-label">Arch Linux &middot; pacman</span>
  </header>

  <div class="meta-strip">
    <span>version <b>${VERSION}</b></span>
    <span>commit <b><a href="https://github.com/noctalia-dev/noctalia/commit/${COMMIT}" target="_blank" rel="noopener">${COMMIT_SHORT}</a></b></span>
    <span>signing ${SIGNING_HTML}</span>
  </div>

  ${SETUP_INSTRUCTIONS}

  <footer class="site-footer">
    <span>Automated daily builds &middot; GitHub Actions</span>
    <nav class="footer-links" aria-label="External links">
      <a href="https://github.com/noctalia-dev/noctalia" target="_blank" rel="noopener">upstream</a>
      <a href="https://aur.archlinux.org/packages/noctalia-git" target="_blank" rel="noopener">AUR</a>
    </nav>
  </footer>

</div>
<script>
  function copyCode(btn, id) {
    var text = document.getElementById(id).innerText;
    navigator.clipboard.writeText(text).then(function() {
      var orig = btn.innerText;
      btn.innerText = 'copied';
      setTimeout(function() { btn.innerText = orig; }, 2000);
    });
  }
</script>
</body>
</html>
EOF
