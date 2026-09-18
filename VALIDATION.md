# Validation notes

## Target host

Validated 18 September 2026 on Debian 13.

CPU:

```text
Architecture: x86_64
Model name: AMD GX-212JC SOC with Radeon(TM) R2E Graphics
sse4_2
avx
```

AVX2 was not present.

## Runtime checks

Bun 1.4.1 executed successfully on the target CPU:

```text
1.4.1
```

Node.js 22.23.2 executed successfully:

```text
v22.23.2
```

## Dependency install

The first dependency install attempts failed because the root filesystem ran out of space. After reclaiming space, the remaining blocker was the grpc-tools node-pre-gyp download path.

Direct `curl` of the exact grpc-tools archive succeeded. A localhost mirror of that downloaded archive was then used via:

```text
npm_config_grpc_tools_binary_host_mirror=http://127.0.0.1:<port>/
```

The install then completed successfully:

```text
bun install v1.4.1
$ husky
196 packages installed
```

## Build result

The Cline 3.0.62 Linux x64 target completed successfully:

```text
Building @cline/cli-linux-x64 (target: bun-linux-x64)...
Smoke test: .../apps/cli/dist/cli-linux-x64/bin/cline --version
Passed: 3.0.62
Built @cline/cli-linux-x64

Build complete. 1 targets built.
Packages:
  @cline/cli-linux-x64@3.0.62
```

The interactive Cline TUI was then launched directly from the resulting binary on the same non-AVX2 host and rendered normally.
