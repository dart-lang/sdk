# Analysis Server Benchmark Scenarios

This document explains the synthetic scenarios in `pkg/analysis_server/tool/benchmark_tools/`: what real IDE or CLI behavior each one models, who is affected, and how its numbers relate to real repositories. Synthetic benchmarks are easy to dismiss as contrived, or to over-optimize, unless their inputs are tied to real workflows.

## Warm startup of a multi-package workspace with IDE excludes

`single_benchmarks/warm_startup_multi_package_with_ide_excludes.dart`

```bash
out/ReleaseX64/dart-sdk/bin/dart \
  pkg/analysis_server/tool/benchmark_tools/single_benchmarks/warm_startup_multi_package_with_ide_excludes.dart
```

It accepts only `--dart=<path>` and `--json`; the scenarios and the sweep are fixed in code, so every run produces the same comparable report.

### What it simulates

A pub workspace with 25, 50, or 100 packages, 50 small Dart libraries per package, one shared `.dart_tool/package_config.json`, opened as a single included root. For each package count, three scenarios run AOT `dart language-server` with a persistent disk cache (`--cache`):

- `legacy_3p_excludes`: `--protocol=analyzer`, 3 excludes per package (`<package>/.dart_tool`, `<package>/.pub`, `<package>/build`) sent in `analysis.setAnalysisRoots`. This is IntelliJ and Android Studio today.
- `lsp_3p_excludes`: `--protocol=lsp`, the same excludes sent as `analysisExcludedFolders` in the `workspace/configuration` response. VS Code sends none by default (Dart-Code 3.147), so this models users who configured excludes, and a possible future IntelliJ client that uses LSP.
- `lsp_no_excludes`: `--protocol=lsp`, no excludes. This is the control, and the default for VS Code.

Each scenario first runs a cold analysis to fill the cache, then 3 fresh server processes against the filled cache. The measured time is from sending `analysis.setAnalysisRoots` (legacy) or `initialized` (LSP) until analysis finishes, so it includes root discovery, file listing, and watcher setup, but not process launch.

The workspace root path is padded to 64 characters, and the report prints the actual length. The server compares paths character by character, so without padding the result would depend on the temp directory: on one Linux machine, a 128-character common prefix of the package paths instead of an 80-character one raised the exclude overhead at 100 packages from 1,059 ms to 1,533 ms.

### Why these inputs happen

- IntelliJ and Android Studio run the analysis server with the legacy protocol, and bridge LSP features in process ([`lsp/ABOUT.md`](https://github.com/flutter/dart-intellij-third-party/blob/75ae85549a97ead55e9496255eba8af803991308/third_party/src/main/java/com/jetbrains/lang/dart/lsp/ABOUT.md)). On project open, `DartStartupActivity` finds every `pubspec.yaml` in the project and excludes `.dart_tool`, `.pub`, and `build` next to it ([`DartStartupActivity.kt#L166-L180`](https://github.com/flutter/dart-intellij-third-party/blob/75ae85549a97ead55e9496255eba8af803991308/third_party/src/main/java/com/jetbrains/lang/dart/DartStartupActivity.kt#L166-L180), [`#L246-L247`](https://github.com/flutter/dart-intellij-third-party/blob/75ae85549a97ead55e9496255eba8af803991308/third_party/src/main/java/com/jetbrains/lang/dart/DartStartupActivity.kt#L246-L247)). `DartServerRootsHandler` sends every module content root as `included`, and every excluded folder of it, except `packages`, as `excluded` ([`DartServerRootsHandler.java#L88-L101`](https://github.com/flutter/dart-intellij-third-party/blob/75ae85549a97ead55e9496255eba8af803991308/third_party/src/main/java/com/jetbrains/lang/dart/analyzer/DartServerRootsHandler.java#L88-L101)).
- With LSP, `LspAnalysisServer` applies each relative entry of `dart.analysisExcludedFolders` to every workspace folder, so the number of excluded paths is the number of entries times the number of workspace folders. Both protocols pass the included and excluded paths to the same `AbstractNotificationManager` and `ContextManager`.

The server checks every analyzed file against every included and excluded root, in `AbstractNotificationManager._isIncluded` and `ContextRootImpl._isExcluded`, and against every package of the package config, in `Packages.packageForPath`. Each check scans the paths character by character, so the cost of the root checks is proportional to `fileCount * (includedCount + excludedCount) * pathLength`. Here the number of files and the number of excludes both grow with the number of packages, so the cost grows quadratically.

### Who is affected

- Affected: IntelliJ and Android Studio users with a multi-package repository in one window (pub workspaces, melos monorepos, Flutter plugins with `example/` and subpackages, multi-module projects), and VS Code users with many workspace folders or with `dart.analysisExcludedFolders`.
- Not meaningfully affected: one package opened alone (1 included root, at most 3 excludes). There, `isWithin` is about 2–3% of warm startup (about 60 ms for `pkg/analyzer` on an Apple M4 Pro).

### Metrics

- Primary: warm initial analysis time, median of 3 runs, for each scenario and package count.
- Headline: the exclude overhead, the warm median of a scenario with excludes minus that of `lsp_no_excludes`, printed as a separate table. Fixes should bring it close to zero at every package count. If it grows with the package count again, that is a regression. A change that speeds up every file, with or without excludes, also speeds up the control, so the overhead does not show it; compare the warm medians too.

The generated libraries are tiny, so reading, linking, and diagnostics cost much less than in real code. Relative speedups here are therefore much larger than in real repositories. Report the absolute milliseconds saved, and check the real impact on a real repository, as in the calibration below.

### Real-world calibration

The Dart SDK repository, opened in IntelliJ, sends 32 included and 292 excluded roots (96 packages times `.dart_tool`, `.pub`, and `build`, plus 4 others); 6,618 files are analyzed, and the package config has 190 packages. Replaying that `analysis.setAnalysisRoots` payload against AOT `dart language-server --protocol=analyzer` with a filled cache (commit `256206b002e`, 2026-11-20, macOS, Apple M4 Pro):

- Warm startup: median 6,320 ms (runs: 6,706, 6,306, 6,320 ms).
- In a separate run under the sampling profiler (250 µs period), `isWithin` takes about 24% of CPU (about 1.5 s of the 6.3 s), two thirds of it in `AbstractNotificationManager._isIncluded`.
- Control: `pkg/analyzer` alone (1,625 files, no excludes) has a warm median of 1,984 ms, of which `isWithin` is about 3% (about 60 ms). Adding 496 excludes raises the median to 2,250 ms and `isWithin` to about 18%.

### Baseline before the optimizations

Linux x64, AMD Ryzen 9 PRO 8945HS, 2026-11-21, server from an SDK built at `51133fc5559` (2026-11-18), workspace root path length 64.

| Scenario | Packages | Files | Excluded | Cold | Warm runs (ms) | Warm median |
|---|---:|---:|---:|---:|---|---:|
| legacy_3p_excludes | 25 | 1250 | 75 | 1025 ms | 262, 261, 264 | **262 ms** |
| lsp_3p_excludes | 25 | 1250 | 75 | 1073 ms | 251, 248, 253 | **251 ms** |
| lsp_no_excludes | 25 | 1250 | 0 | 993 ms | 182, 183, 183 | **183 ms** |
| legacy_3p_excludes | 50 | 2500 | 150 | 2098 ms | 675, 659, 653 | **659 ms** |
| lsp_3p_excludes | 50 | 2500 | 150 | 2059 ms | 627, 621, 620 | **621 ms** |
| lsp_no_excludes | 50 | 2500 | 0 | 1823 ms | 367, 369, 367 | **367 ms** |
| legacy_3p_excludes | 100 | 5000 | 300 | 4759 ms | 1786, 1780, 1805 | **1786 ms** |
| lsp_3p_excludes | 100 | 5000 | 300 | 4623 ms | 1751, 1741, 1771 | **1751 ms** |
| lsp_no_excludes | 100 | 5000 | 0 | 3624 ms | 727, 707, 719 | **719 ms** |

Exclude overhead:

| Packages | legacy_3p_excludes | lsp_3p_excludes |
|---:|---:|---:|
| 25 | +79 ms | +68 ms |
| 50 | +292 ms | +254 ms |
| 100 | +1067 ms | +1032 ms |

Each doubling of the package count multiplies the overhead by about 3.7–4.1, consistent with quadratic growth. At 100 packages, the excludes take 59% of the warm startup. With a 48-character `TMPDIR`, the overhead at 100 packages was +1073 ms and +1019 ms, so the padding works.

### Optimizations

Each entry is measured against its parent commit, on the machine of the baseline above (product AOT, mean of 2 interleaved rounds). Profiles are of the whole server process, from launch to exit, all threads, in the 3 warm runs of `lsp_3p_excludes` at 100 packages (non-product AOT, `perf record -e instructions:u -c 1000000 -g`, mean of the 3 runs). A row "with callees" counts every sample that has that code anywhere on its stack, including inlined frames. With smaller sampling periods the kernel throttles sampling, and the profile undercounts by up to 3 times; with this one, the totals match `perf stat` within 1%. Without `perf`, the non-product server's warm medians are within 1% of the product ones, so the profiles represent the product build.

#### [CL 580541](https://dart-review.googlesource.com/c/sdk/+/580541): Cache `AbstractNotificationManager._isIncluded` per file path

`_isIncluded` ran for every analysis result, twice for the first result for each file. Its result depends only on the path and the analysis roots, so it is now cached per path, and the cache is cleared when the roots change.

Warm medians:

| Packages | legacy_3p_excludes | lsp_3p_excludes | lsp_no_excludes |
|---:|---:|---:|---:|
| 25 | 266 → 241 ms | 252 → 226 ms | 184 → 184 ms |
| 50 | 651 → 561 ms | 625 → 533 ms | 367 → 369 ms |
| 100 | 1779 → 1437 ms | 1758 → 1381 ms | 713 → 710 ms |

Exclude overhead:

| Packages | legacy_3p_excludes | lsp_3p_excludes |
|---:|---:|---:|
| 25 | 82 → 57 ms | 68 → 42 ms |
| 50 | 285 → 193 ms | 258 → 165 ms |
| 100 | 1066 → 728 ms | 1045 → 672 ms |

Profile:

| | Before | After | Change |
|---|---:|---:|---:|
| All server instructions | 29.73G | 21.73G | −27% |
| `AbstractNotificationManager._isIncluded`, with callees | 16.21G (54.5%) | 8.08G (37.2%) | −50% |
| `ContextRootImpl._isExcluded`, with callees | 6.37G (21.4%) | 6.51G (30.0%) | unchanged |
| `package:path` code, with callees | 22.67G (76.2%) | 14.71G (67.7%) | −35% |

After this change, `isWithin` reached from `_isIncluded` (36.8%, once per file, but still over all included and excluded paths) and in `ContextRootImpl._isExcluded` (23.4%) is most of the remaining path cost.

#### [CL 580600](https://dart-review.googlesource.com/c/sdk/+/580600): Scan names under the root once in `ContextRootImpl._isExcluded`

Files and folders whose name, or the name of an ancestor under the context root, starts with `.` are excluded. This was checked by walking the ancestors with `Folder.contains`, `Context.basename`, and `Context.dirname`, each parsing the whole path, for every file, with or without excludes; now the names after the root are scanned once.

Warm medians:

| Packages | legacy_3p_excludes | lsp_3p_excludes | lsp_no_excludes |
|---:|---:|---:|---:|
| 25 | 241 → 226 ms | 226 → 213 ms | 183 → 170 ms |
| 50 | 554 → 534 ms | 529 → 508 ms | 364 → 339 ms |
| 100 | 1420 → 1388 ms | 1383 → 1331 ms | 708 → 685 ms |

Exclude overhead:

| Packages | legacy_3p_excludes | lsp_3p_excludes |
|---:|---:|---:|
| 25 | 59 → 56 ms | 43 → 43 ms |
| 50 | 190 → 195 ms | 165 → 170 ms |
| 100 | 713 → 703 ms | 676 → 646 ms |

The overhead does not change, because the check runs for every file in every scenario, including `lsp_no_excludes`.

Profile:

| | Before | After | Change |
|---|---:|---:|---:|
| All server instructions | 21.73G | 20.70G | −5% |
| `ContextRootImpl._isExcluded`, with callees | 6.51G (30.0%) | 5.51G (26.6%) | −15% |
| Ancestor walk in `_isExcluded` (`Context.basename`, `Context.dirname`, `Folder.contains`) | 0.98G (4.5%) | none | |
| `ContextRootImpl._hasDotNameUnderRoot`, with callees | none | 0.013G (0.06%) | |
| Fallback walk of the ancestors | none | 0 samples | |
| `package:path` code, with callees | 14.71G (67.7%) | 13.89G (67.1%) | −6% |

The check matters more for `dart analyze` of one large package with a filled cache, where everything else is cached, and the paths are long and deep. A second `dart analyze` of the `stable_analysis` tarball (a separate cache for each build, 7 interleaved rounds, product AOT) went from 7.72G to 6.69G instructions (−13%), and from 673 to 622 ms wall time (−8%). Its profile (non-product AOT, all processes, sampled every 200,000 instructions, which this workload allows without throttling):

| | Before | After | Change |
|---|---:|---:|---:|
| All instructions | 10.01G | 9.22G | −8% |
| `ContextRootImpl._isExcluded`, with callees | 0.958G (9.6%) | 0.010G (0.1%) | −99% |
| `ContextRootImpl._hasDotNameUnderRoot`, with callees | none | 0.008G (0.1%) | |
| `package:path` code, with callees | 1.375G (13.7%) | 0.437G (4.7%) | −68% |

#### [CL 580660](https://dart-review.googlesource.com/c/sdk/+/580660): Look up the ancestors of a path in `AbstractNotificationManager._isIncluded`

`_isIncluded` checked each file against every included and excluded path with `Context.isWithin` and `Context.equals`. Now a new `PathSubtreeSet` looks up the file and those of its ancestors that have the length of a root in a `PathSet` of `package:path`, so the cost no longer depends on the number of excludes.

Warm medians:

| Packages | legacy_3p_excludes | lsp_3p_excludes | lsp_no_excludes |
|---:|---:|---:|---:|
| 25 | 230 → 208 ms | 214 → 193 ms | 174 → 174 ms |
| 50 | 536 → 440 ms | 511 → 418 ms | 344 → 352 ms |
| 100 | 1386 → 1008 ms | 1337 → 950 ms | 690 → 694 ms |

Exclude overhead:

| Packages | legacy_3p_excludes | lsp_3p_excludes |
|---:|---:|---:|
| 25 | 56 → 34 ms | 41 → 18 ms |
| 50 | 192 → 89 ms | 167 → 67 ms |
| 100 | 696 → 314 ms | 647 → 257 ms |

Profile:

| | Before | After | Change |
|---|---:|---:|---:|
| All server instructions | 20.71G | 12.69G | −39% |
| `AbstractNotificationManager._isIncluded`, with callees | 8.08G (39.0%) | 0.061G (0.5%) | −99% |
| `PathSubtreeSet.containsSelfOrAncestor`, with callees | none | 0.056G (0.4%) | |
| `ContextRootImpl._isExcluded`, with callees | 5.47G (26.4%) | 5.55G (43.7%) | unchanged |
| `package:path` code, with callees | 13.87G (67.0%) | 6.00G (47.3%) | −57% |

After this change, `isWithin` in `ContextRootImpl._isExcluded` (41.9%) is most of the remaining exclude overhead.

### Limitations

- It covers excludes sent by the IDE, not `analyzer: exclude:` globs in `analysis_options.yaml`, which go through `ContextRootImpl.excludedGlobs`.
- It uses one included root, because many separately watched roots on macOS occasionally add 1,000 ms retries (`TimerUtils::Sleep(1000)` in `runtime/bin/file_system_watcher_macos.cc`). Real IntelliJ workspaces often send many included roots, and in `_isIncluded` each included root costs about as much as an excluded one, so this underestimates them.
- The excluded folders do not exist on disk; the server still records and checks them, but skips no files while listing.
- In a profile of the warm runs, `Packages.packageForPath` gets no samples, while `_PhysicalFolder.contains`, mostly reached from it, is about 5% in the Dart SDK calibration, so this benchmark does not show that cost.
