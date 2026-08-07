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
    SIGNING_STATUS="Enabled (${GPG_KEY_ID})"
    SETUP_INSTRUCTIONS=$(cat <<EOF
      <section>
        <h2>1. Import Signing Key</h2>
        <div class="code-block">
          <button class="copy-btn" onclick="copyCode(this, 'step1')">Copy</button>
          <pre id="step1">curl -fsSL ${REPO_URL}/noctalia-signing-key.gpg | sudo pacman-key --add -
sudo pacman-key --lsign-key ${GPG_KEY_ID}</pre>
        </div>
      </section>
      <section>
        <h2>2. Configure Pacman</h2>
        <p style="font-size:0.875rem; color:var(--text-muted); margin-bottom:0.5rem;">Add the following block to <code>/etc/pacman.conf</code>:</p>
        <div class="code-block">
          <button class="copy-btn" onclick="copyCode(this, 'step2')">Copy</button>
          <pre id="step2">[noctalia]
SigLevel = Required DatabaseOptional
Server = ${REPO_URL}</pre>
        </div>
      </section>
      <section>
        <h2>3. Install Package</h2>
        <div class="code-block">
          <button class="copy-btn" onclick="copyCode(this, 'step3')">Copy</button>
          <pre id="step3">sudo pacman -Sy noctalia-git</pre>
        </div>
      </section>
EOF
)
else
    SIGNING_STATUS="Disabled (Unsigned)"
    SETUP_INSTRUCTIONS=$(cat <<EOF
      <section>
        <h2>1. Configure Pacman</h2>
        <p style="font-size:0.875rem; color:var(--text-muted); margin-bottom:0.5rem;">Add the following block to <code>/etc/pacman.conf</code>:</p>
        <div class="code-block">
          <button class="copy-btn" onclick="copyCode(this, 'step1')">Copy</button>
          <pre id="step1">[noctalia]
SigLevel = Optional TrustAll
Server = ${REPO_URL}</pre>
        </div>
      </section>
      <section>
        <h2>2. Install Package</h2>
        <div class="code-block">
          <button class="copy-btn" onclick="copyCode(this, 'step2')">Copy</button>
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
<title>Noctalia Repository</title>
<meta name="description" content="Automated daily builds of Noctalia for Arch Linux, served as a pacman repository via GitHub Pages.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0f172a;
    --card-bg: rgba(30, 41, 59, 0.7);
    --card-border: rgba(255, 255, 255, 0.1);
    --text-main: #f8fafc;
    --text-muted: #94a3b8;
    --accent: #8b5cf6;
    --accent-hover: #7c3aed;
    --accent-glow: rgba(139, 92, 246, 0.25);
    --code-bg: #090d16;
    --success: #10b981;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background-color: var(--bg);
    color: var(--text-main);
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 2rem 1rem;
    background-image: 
      radial-gradient(at 20% 20%, rgba(139, 92, 246, 0.15) 0px, transparent 50%),
      radial-gradient(at 80% 80%, rgba(59, 130, 246, 0.15) 0px, transparent 50%);
  }
  .container {
    width: 100%;
    max-width: 760px;
  }
  .card {
    background: var(--card-bg);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid var(--card-border);
    border-radius: 16px;
    padding: 2.5rem;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 8px 10px -6px rgba(0, 0, 0, 0.3);
  }
  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
    gap: 1rem;
  }
  h1 {
    font-size: 1.875rem;
    font-weight: 700;
    letter-spacing: -0.025em;
    background: linear-gradient(135deg, #ffffff 0%, #cbd5e1 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  .badge {
    display: inline-flex;
    align-items: center;
    gap: 0.375rem;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    font-size: 0.8125rem;
    font-weight: 500;
    background: rgba(16, 185, 129, 0.1);
    color: var(--success);
    border: 1px solid rgba(16, 185, 129, 0.2);
  }
  .badge-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background-color: var(--success);
    box-shadow: 0 0 8px var(--success);
  }
  .meta-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }
  .meta-item {
    background: rgba(15, 23, 42, 0.5);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 1rem;
  }
  .meta-label {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    margin-bottom: 0.25rem;
  }
  .meta-value {
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.9375rem;
    font-weight: 500;
    color: var(--text-main);
    word-break: break-all;
  }
  .meta-value a {
    color: var(--accent);
    text-decoration: none;
  }
  .meta-value a:hover {
    text-decoration: underline;
  }
  section {
    margin-top: 1.5rem;
  }
  h2 {
    font-size: 1.125rem;
    font-weight: 600;
    margin-bottom: 0.75rem;
    color: #f1f5f9;
  }
  .code-block {
    position: relative;
    background: var(--code-bg);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 1rem 1.25rem;
    margin-bottom: 1.25rem;
    overflow-x: auto;
  }
  pre {
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.875rem;
    line-height: 1.6;
    color: #e2e8f0;
  }
  .copy-btn {
    position: absolute;
    top: 0.625rem;
    right: 0.625rem;
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.1);
    color: var(--text-muted);
    border-radius: 6px;
    padding: 0.35rem 0.65rem;
    font-size: 0.75rem;
    cursor: pointer;
    transition: all 0.2s;
  }
  .copy-btn:hover {
    background: var(--accent);
    color: #fff;
    border-color: var(--accent);
  }
  .footer {
    margin-top: 2.5rem;
    padding-top: 1.25rem;
    border-top: 1px solid var(--card-border);
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 0.8125rem;
    color: var(--text-muted);
  }
  .footer a {
    color: var(--text-muted);
    text-decoration: none;
    transition: color 0.2s;
  }
  .footer a:hover {
    color: var(--accent);
  }
</style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="header">
        <h1>Noctalia Repository</h1>
        <div class="badge"><span class="badge-dot"></span> Active Arch Repo</div>
      </div>
      <div class="meta-grid">
        <div class="meta-item">
          <div class="meta-label">Package Version</div>
          <div class="meta-value">${VERSION}</div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Upstream Commit</div>
          <div class="meta-value"><a href="https://github.com/noctalia-dev/noctalia/commit/${COMMIT}" target="_blank" rel="noopener">${COMMIT_SHORT}</a></div>
        </div>
        <div class="meta-item">
          <div class="meta-label">Package Signing</div>
          <div class="meta-value">${SIGNING_STATUS}</div>
        </div>
      </div>
      ${SETUP_INSTRUCTIONS}
      <div class="footer">
        <span>Automated Arch Linux repository</span>
        <div>
          <a href="https://github.com/noctalia-dev/noctalia" target="_blank" rel="noopener">Upstream Repo</a> &bull;
          <a href="https://aur.archlinux.org/packages/noctalia-git" target="_blank" rel="noopener">AUR Package</a>
        </div>
      </div>
    </div>
  </div>
  <script>
    function copyCode(btn, elementId) {
      const code = document.getElementById(elementId).innerText;
      navigator.clipboard.writeText(code).then(() => {
        const orig = btn.innerText;
        btn.innerText = 'Copied!';
        setTimeout(() => btn.innerText = orig, 2000);
      });
    }
  </script>
</body>
</html>
EOF
