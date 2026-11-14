# Cris Desktop

A macOS packaging and distribution toolchain for a DSH-based personal assistant with DS Bot integration. **This is an independent project, not an official DeepSeek product.**

[中文](README.md) · [Documentation](docs/index.md) · [Support matrix](SUPPORT_MATRIX.md) · [Troubleshooting](docs/TROUBLESHOOTING.md)

## Current status

The repository contains post-processing scripts, blank profile templates and documentation. It does not contain the full upstream source, an application binary, model credentials or user data. There is no reviewed installer Release as of the support-matrix review date.

**The current public build is experimental and has a confirmed runtime defect.** npm may install an older host peer into the profile. Its `dsh-llm@0.0.1-rc.5` does not export `createSystemMessage`, preventing DS Bot from importing. Building a DMG and passing the structural checker do not prove the plugin or its interface works.

A separate Mac mini repair reportedly passed module, relocation and strict ad-hoc signature checks. Its code has not been merged into this public baseline, and its actual desktop/plugin/UI acceptance remains unverified because desktop-control access was denied. Do not describe the public repository as containing that repair.

## What it does

- Repackages an existing DSH Desktop v2.0.18 application on macOS.
- Adds a first-run template selecting DS Bot and its Deep View dependency.
- Starts with no preset provider, model credential or gateway route.
- Disables selected upstream update paths; it does not provide a working Cris update service.
- Creates a DMG and checks a limited set of resource/configuration properties.

DSH supplies the runtime, dsh-desktop the Electron shell, and DS Bot the Bot host/client functionality. Their upstream features are not automatically this project's verified support claims.

## Build entry point

Use the detailed [getting-started guide](docs/GETTING_STARTED.md) for verified source URLs, checksum verification, prerequisites, mounting and acceptance steps. The recorded build environment was macOS 15.3.1 arm64 with Node 24.22.2 and npm 11.19.1; other environments need separate verification.

After obtaining and verifying the upstream v2.0.18 application, an example invocation from the repository root is:

```bash
bash <<'BASH'
set -euo pipefail
SRC_APP="$HOME/cris-build/src/DSH Desktop.app"
OUT="$(mktemp -d "$HOME/cris-out.XXXXXX")"
test -d "$SRC_APP/Contents/Resources/app"
bash build/build-cris.sh --src-app "$SRC_APP" --out "$OUT"
printf 'OUT=%s\n' "$OUT"
BASH
```

Use a dedicated new output directory **outside the repository**. The current script removes existing same-name output applications and images, and may force-detach a same-name volume. Never use the input application path as the output target. Do not run this as a routine installer over existing personal data.

`--ds-bot-src` is an optional local dependency override. It is not a verified workaround for the host-peer defect. There is no full dependency lockfile or claim of bit-for-bit reproducibility.

## Verification and configuration

Set `OUT` to the actual path printed by your build, then run:

```bash
bash -euo pipefail -s -- "${OUT:?Set the actual build output path}" <<'BASH'
OUT="$1"
bash build/verify-artifact.sh "$OUT/Cris.app"
codesign --verify --deep --strict --verbose=2 "$OUT/Cris.app"
BASH
```

Before launching, use an independent test account/VM or verify complete application/data isolation. A new profile, a renamed app or `DSH_HOME` alone is insufficient. Check the final installed copy again, not an unrelated application at another path.

The first command checks structure; the second independently checks strict signatures. The public builder only attempts ad-hoc signing and continues on signing failure. Neither command proves Apple notarization, UI functionality or a safe binary distribution.

When the application and plugin are actually working, configure your provider, API base URL, model ID and credentials through the upstream model settings. No gateway or key is supplied. Do not post credentials, full configuration or session data in an Issue. Credential storage details depend on the actual DSH/provider version; this project does not guarantee Keychain or encryption.

## Limits and project direction

Windows/Linux packaging, a dedicated model setup wizard, a working update service and Apple notarization are not implemented here. Renaming the output does not rewrite its bundle identifier or isolate data. Existing-profile migration is not verified. Model services and upstream plugins may use the network; a blank seed is not an offline guarantee.

Priority is fixing host resolution, verifying real DS Bot activation/UI, improving output safety and strict nested signing, and pinning the dependency closure. See the [roadmap](docs/ROADMAP.md) and [verification guide](docs/VERIFICATION.md).

## Contributing and licensing

See [CONTRIBUTING](CONTRIBUTING.md), [SUPPORT](SUPPORT.md), [SECURITY](SECURITY.md) and [RELEASING](RELEASING.md). New files need explicit allowlisting, and publication requires independent review tied to an exact commit SHA. Source review does not authorize binary publication.

The repository's own scripts and documentation are MIT-licensed; preserve applicable upstream notices. DS Bot and Deep View declare Apache-2.0. Generated application components retain their own licenses. See [LICENSE](LICENSE), [upstream sources](docs/UPSTREAM.md) and [third-party notices](THIRD_PARTY_NOTICES.md).
