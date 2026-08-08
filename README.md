# Noctalia Arch Repository

[![Build & Deploy Noctalia](https://github.com/dawn-used-yeet-alt/Noctalia-v5-test/actions/workflows/build-and-deploy.yml/badge.svg)](https://github.com/dawn-used-yeet-alt/Noctalia-v5-test/actions/workflows/build-and-deploy.yml)

Automated daily builds of [Noctalia](https://github.com/noctalia-dev/noctalia) for Arch Linux, served as a pacman repository via GitHub Pages.

## Usage

### With package signing (recommended)

If the repository has GPG signing enabled, first import the signing key (the key ID is displayed on the [repository landing page](https://dawn-used-yeet-alt.github.io/Noctalia-v5-test)):

```bash
curl -fsSL https://dawn-used-yeet-alt.github.io/Noctalia-v5-test/noctalia-signing-key.gpg | sudo pacman-key --add -
sudo pacman-key --lsign-key FACDAEC5C6FDA57B
```

Then add to `/etc/pacman.conf`:

```ini
[noctalia]
SigLevel = Required DatabaseOptional
Server = https://dawn-used-yeet-alt.github.io/Noctalia-v5-test
```

### Without package signing

If signing is not configured, add to `/etc/pacman.conf`:

```ini
[noctalia]
SigLevel = Optional TrustAll
Server = https://dawn-used-yeet-alt.github.io/Noctalia-v5-test
```

### Install

```bash
sudo pacman -Sy noctalia-git
```

## How It Works

A GitHub Actions workflow runs daily (and on manual dispatch) to:

1. Check if the upstream [noctalia](https://github.com/noctalia-dev/noctalia) repo has new commits.
2. If unchanged, re-use the existing package from GitHub Pages (with checksum verification).
3. If changed, build the latest `noctalia-git` package from the [AUR](https://aur.archlinux.org/packages/noctalia-git) inside an Arch Linux container.
4. Sign the package with GPG (if the `GPG_PRIVATE_KEY` secret is configured).
5. Deploy the package and repository database to GitHub Pages.

Pacman package cache is preserved between runs via `actions/cache` to speed up dependency installation.

## Enabling GPG Signing

To enable package signing:

1. Generate a GPG key (if you don't have one):
   ```bash
   gpg --batch --gen-key <<EOF
   %no-protection
   Key-Type: RSA
   Key-Length: 4096
   Name-Real: Noctalia Build
   Name-Email: noctalia@build.local
   Expire-Date: 0
   EOF
   ```

2. Export the private key:
   ```bash
   gpg --armor --export-secret-keys noctalia@build.local
   ```

3. Add it as a GitHub repository secret named `GPG_PRIVATE_KEY`:
   - Go to **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `GPG_PRIVATE_KEY`
   - Value: paste the full armored private key output

The workflow will automatically detect the secret and sign all packages and the repository database.

## License

[MIT](LICENSE)
