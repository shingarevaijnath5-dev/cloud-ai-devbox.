#!/usr/bin/env bash
set -Eeuo pipefail

log()  { printf '\n\033[1;34m[cloud-ai-devbox]\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[warning]\033[0m %s\n' "$*" >&2; }

HOME_DIR="${HOME:-/home/vscode}"
DEVTOOLS_DIR="$HOME_DIR/.local/share/cloud-ai-devbox"
FLUTTER_HOME="$DEVTOOLS_DIR/flutter"
ANDROID_SDK_ROOT="$DEVTOOLS_DIR/android-sdk"
NPM_PREFIX="$HOME_DIR/.npm-global"
ANDROID_API="${ANDROID_API:-36}"
ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-36.0.0}"

mkdir -p "$DEVTOOLS_DIR" "$NPM_PREFIX" "$HOME_DIR/.local/bin"

log "Installing system packages"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl git unzip zip xz-utils wget file clang cmake ninja-build \
  pkg-config libglu1-mesa libstdc++-12-dev
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

log "Configuring user-level npm packages and PATH"
npm config set prefix "$NPM_PREFIX"

PROFILE_BLOCK='# >>> cloud-ai-devbox environment >>>
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export FLUTTER_HOME="$HOME/.local/share/cloud-ai-devbox/flutter"
export ANDROID_SDK_ROOT="$HOME/.local/share/cloud-ai-devbox/android-sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
# <<< cloud-ai-devbox environment <<<'

if ! grep -q 'cloud-ai-devbox environment' "$HOME_DIR/.bashrc" 2>/dev/null; then
  printf '\n%s\n' "$PROFILE_BLOCK" >> "$HOME_DIR/.bashrc"
fi

export NPM_CONFIG_PREFIX="$NPM_PREFIX"
export FLUTTER_HOME="$FLUTTER_HOME"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$NPM_PREFIX/bin:$HOME_DIR/.local/bin:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

log "Installing OpenAI Codex CLI"
if ! command -v codex >/dev/null 2>&1; then
  curl -fsSL https://chatgpt.com/codex/install.sh | sh || warn "Codex install did not finish; retry later with the official installer."
else
  log "Codex CLI already installed"
fi

log "Installing Claude Code CLI"
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install did not finish; retry later with the official installer."
else
  log "Claude Code already installed"
fi

log "Installing Gemini CLI"
if ! command -v gemini >/dev/null 2>&1; then
  npm install -g @google/gemini-cli || warn "Gemini CLI install failed; retry later with: npm install -g @google/gemini-cli"
else
  log "Gemini CLI already installed"
fi

log "Installing Flutter stable SDK"
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
else
  log "Flutter SDK already present"
fi

install_android_command_line_tools() {
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  if [ -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
    log "Android command-line tools already installed"
    return 0
  fi

  local tmp_dir cmdline_file
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  cmdline_file="$(python3 - <<'PY'
import urllib.request
import xml.etree.ElementTree as ET

url = "https://dl.google.com/android/repository/repository2-1.xml"
with urllib.request.urlopen(url, timeout=45) as response:
    root = ET.fromstring(response.read())

def local_name(tag):
    return tag.rsplit("}", 1)[-1]

for package in root.iter():
    if local_name(package.tag) != "remotePackage":
        continue
    if package.attrib.get("path") != "cmdline-tools;latest":
        continue
    for archive in package.iter():
        if local_name(archive.tag) != "archive":
            continue
        host_os = None
        download_url = None
        for node in archive.iter():
            name = local_name(node.tag)
            if name == "host-os":
                host_os = node.text
            elif name == "url":
                download_url = node.text
        if host_os == "linux" and download_url:
            print(download_url)
            raise SystemExit(0)
raise SystemExit("Could not find Linux Android command-line tools in Google's repository metadata")
PY
)"
  curl -fsSL "https://dl.google.com/android/repository/$cmdline_file" -o "$tmp_dir/cmdline-tools.zip"
  unzip -q "$tmp_dir/cmdline-tools.zip" -d "$tmp_dir/unpacked"
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  mv "$tmp_dir/unpacked/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  rm -rf "$tmp_dir"
  trap - RETURN
}

log "Installing Android SDK command-line tools"
install_android_command_line_tools
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

log "Accepting Android SDK licenses where possible"
set +e
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null 2>&1
license_status=$?
set -e
if [ "$license_status" -ne 0 ]; then
  warn "Some Android SDK licenses could not be accepted automatically. Run: yes | sdkmanager --licenses"
fi

log "Installing Android platform and build tools (API $ANDROID_API)"
sdkmanager --sdk_root="$ANDROID_SDK_ROOT" \
  "platform-tools" \
  "platforms;android-$ANDROID_API" \
  "build-tools;$ANDROID_BUILD_TOOLS"

log "Configuring Flutter for Android builds"
flutter config --no-analytics
flutter config --android-sdk "$ANDROID_SDK_ROOT"
set +e
yes | flutter doctor --android-licenses >/dev/null 2>&1
set -e
flutter doctor -v || true

log "Setup finished"
printf '\nAvailable tools (authentication is separate):\n'
printf '  codex --version\n  claude --version\n  gemini --version\n  flutter doctor -v\n'
printf '\nStart a Flutter project:\n'
printf '  mkdir -p app && cd app && flutter create .\n'
printf 'Build a debug APK from the Flutter project directory:\n'
printf '  flutter build apk --debug\n'
printf '\nNote: standard Codespaces does not provide an Android emulator or USB passthrough.\n'
