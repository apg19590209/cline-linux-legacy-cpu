# Cline CLI on Linux x86_64 without AVX2

Unofficial compatibility build workflow for running current Cline CLI releases on older x86_64 Linux CPUs that provide SSE4.2/AVX but do not provide AVX2.

## Status

Validated on:

- Debian 13
- AMD GX-212JC SOC with Radeon R2E Graphics
- x86_64
- CPU flags: SSE4.2 and AVX present; AVX2 absent
- Cline CLI 3.0.62
- Bun 1.4.1
- Node.js 22.23.2

The resulting Cline CLI 3.0.62 binary:

- compiled successfully on the target machine
- passed the build-time `cline --version` smoke test
- launched the interactive OpenTUI interface successfully on the non-AVX2 CPU
- loaded the existing Cline configuration and project working directory successfully

## Why this exists

The published Cline CLI Linux x64 binary is a self-contained Bun executable. Older Cline releases were built with a Bun runtime that could require AVX2 on x86_64. On older CPUs without AVX2 this can result in an illegal-instruction failure before Cline starts.

This project keeps the Cline application source unchanged and rebuilds the CLI with a newer Bun runtime that runs on the tested SSE4.2/AVX CPU.

## Build

Use:

```sh
./build-cline-legacy-cpu.sh
```

The script pins:

- Cline: `cli-v3.0.62`
- Bun: `1.4.1`
- Node.js: `22.23.2`

It builds only the native Linux x64 target and leaves any existing `cline` installation untouched.

The final binary is produced under the Cline source tree at:

```text
apps/cli/dist/cli-linux-x64/bin/cline
```

## grpc-tools download workaround

On the validated Debian host, `node-pre-gyp` / `node-fetch` failed while downloading:

```text
https://node-precompiled-binaries.grpc.io/grpc-tools/v1.13.1/linux-x64.tar.gz
```

The same URL downloaded successfully with `curl`.

The build script therefore creates a temporary localhost mirror for this one prebuilt archive and points `grpc-tools` at it during `bun install`. This is a transport workaround only; the archive still comes from the official grpc-tools binary host.

## Upstream projects

- Cline: https://github.com/cline/cline
- Bun: https://github.com/oven-sh/bun
- Node.js: https://github.com/nodejs/node
- grpc-tools: https://github.com/grpc/grpc-node

## Licensing and third-party software

This repository contains only compatibility/build tooling and documentation. It does not include the upstream Cline source tree, dependency cache, or compiled Cline/Bun binaries.

Cline, Bun, Node.js, grpc-tools and their dependencies remain subject to their own copyright, licence, attribution and redistribution terms.

Any future redistribution of compiled third-party binaries should be reviewed separately for applicable licence and notice requirements.

## AI-assisted development

Portions of the compatibility investigation, debugging, testing and documentation were developed with assistance from ChatGPT (OpenAI).

All changes and test results were reviewed and accepted by the project maintainer. AI systems are acknowledged as development tools and are not listed as copyright holders or Git commit co-authors.

## Disclaimer

This is an unofficial community compatibility project and is not affiliated with or endorsed by Cline, Bun, Node.js, grpc, OpenAI, or their maintainers.
