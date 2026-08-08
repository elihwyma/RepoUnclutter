#!/bin/bash
set -euo pipefail

script_full_path=$(dirname "$0")
cd "$script_full_path" || exit 1

# Defaults (CI / normal run)
NO_SIGN=0
GPG_KEY="552EA88EA1A4111A473E07078DCECCDA42EFF199"

usage() {
	cat <<'EOF'
Usage: ./repo.sh [options]

Regenerate the APT repository index (Packages, Release) and optionally sign it.

Options:
  -h, --help          Show this help and exit
  --no-sign           Skip GPG signing of Release (useful for local runs)
  --gpg-key KEYID     GPG key id used to sign Release (default: Amy's key)

Examples:
  ./repo.sh                 Full regenerate + sign (CI default)
  ./repo.sh --no-sign       Generate Packages/Release without signing
  ./repo.sh --gpg-key ABCD  Sign with a different key id
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-h|--help)
			usage
			exit 0
			;;
		--no-sign)
			NO_SIGN=1
			shift
			;;
		--gpg-key)
			if [[ $# -lt 2 ]]; then
				echo "error: --gpg-key requires a KEYID argument" >&2
				exit 1
			fi
			GPG_KEY="$2"
			shift 2
			;;
		--gpg-key=*)
			GPG_KEY="${1#*=}"
			if [[ -z "$GPG_KEY" ]]; then
				echo "error: --gpg-key requires a KEYID argument" >&2
				exit 1
			fi
			shift
			;;
		*)
			echo "error: unknown option: $1" >&2
			echo "Try './repo.sh --help' for usage." >&2
			exit 1
			;;
	esac
done

rm -f Packages Packages.bz2 Packages.xz Packages.zst Release Release.gpg

echo "[Repository] Generating Packages..."
./RepoUnclutter
zstd -q -c19 Packages > Packages.zst
xz -c9 Packages > Packages.xz
bzip2 -c9 Packages > Packages.bz2

echo "[Repository] Generating Release..."
apt-ftparchive \
		-o APT::FTPArchive::Release::Origin="RepoUnclutter" \
		-o APT::FTPArchive::Release::Label="RepoUnclutter" \
		-o APT::FTPArchive::Release::Suite="stable" \
		-o APT::FTPArchive::Release::Version="2.0" \
		-o APT::FTPArchive::Release::Codename="ios" \
		-o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64" \
		-o APT::FTPArchive::Release::Components="main" \
		-o APT::FTPArchive::Release::Description="Repos but without the clutter" \
		release . > Release

if [[ "$NO_SIGN" -eq 1 ]]; then
	echo "[Repository] Skipping GPG signing (--no-sign)"
else
	echo "[Repository] Signing Release using GPG key ${GPG_KEY}..."
	gpg -abs -u "$GPG_KEY" -o Release.gpg Release
fi

echo "[Repository] Finished"
