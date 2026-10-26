# Cloud AI DevBox

A GitHub Codespaces Linux development environment for AI coding CLIs, Flutter, Android APK builds, Python, Node.js, Java, Git, and VS Code in the browser.

## Start the cloud environment

1. Open this repository on GitHub.
2. Select **Code → Codespaces → Create codespace on main**.
3. Wait for the first setup to finish. It installs CLI tools, Flutter, and Android SDK components; the first run can take several minutes and downloads several gigabytes.
4. Open the integrated terminal in the Codespace.

The repository uses the root `.devcontainer.json` file, so no hidden directory needs to be created manually.

## Included tools

- OpenAI Codex CLI
- Claude Code CLI
- Google Gemini CLI
- Flutter stable SDK and Dart
- Android SDK command-line tools, platform tools, Android API 36, and Build Tools 36.0.0
- Node.js 22, Python 3.12, Java 21, Git, GitHub CLI, and VS Code Flutter/Python extensions

## Check the installation

Run these commands in the Codespaces terminal:

```bash
codex --version
claude --version
gemini --version
flutter doctor -v
```

Start an AI CLI from the project directory:

```bash
codex
claude
gemini
```

Each provider requires its own sign-in or API configuration. Installing a CLI does not grant paid AI access or bypass the provider's usage limits.

## Create a Flutter app

```bash
mkdir -p app
cd app
flutter create .
```

Preview a Flutter web app through Codespaces forwarded port 8080:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

To build a debug Android APK:

```bash
cd app
flutter build apk --debug
```

The APK will usually be at `app/build/app/outputs/flutter-apk/app-debug.apk`. Use the Codespaces file explorer or terminal to download the APK and install it on your Android phone.

## Important limitations and safety

- This is a Linux development container, not a full Windows desktop.
- Standard Codespaces does not provide an Android emulator or USB device passthrough. You can build APKs and test them on your phone.
- Codespaces usage and storage depend on your GitHub plan and billing settings. Stop the Codespace when you're done and review your billing page.
- Codex, Claude Code, and Gemini have separate authentication requirements and usage limits. A free Codespace does not make their model usage unlimited or free.
- Never commit API keys, access tokens, passwords, or credential files. Use the provider's sign-in flow or Codespaces secrets when needed.

## Re-run the setup

If setup was interrupted, run:

```bash
bash setup.sh
```

The script skips tools it can already find and reuses existing Flutter and Android SDK installs.
