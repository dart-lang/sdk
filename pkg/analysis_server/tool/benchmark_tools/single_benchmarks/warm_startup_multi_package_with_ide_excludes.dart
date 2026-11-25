// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../language_server_benchmark.dart';

/// Warm startup (pre-filled disk cache) of a multi-package workspace with many
/// IDE-provided excluded folders.
///
/// Run with no benchmark-specific flags (accepts `--dart=<path>` and `--json`):
/// ```
/// out/ReleaseX64/dart-sdk/bin/dart \
///   pkg/analysis_server/tool/benchmark_tools/single_benchmarks/warm_startup_multi_package_with_ide_excludes.dart
/// ```
///
/// See `SCENARIOS.md` in `tool/benchmark_tools/` for rationale, real-world
/// calibration, and caveats.
Future<void> main(List<String> args) async {
  var jsonOutput = args.contains('--json');
  var rows = <_ResultRow>[];
  var workspacePathLength = 0;

  for (var packageCount in _packageCounts) {
    var totalFiles = packageCount * _filesPerPackage;
    var tmpDir = Directory.systemTemp.createTempSync('das_');
    try {
      var workspaceDir = _createWorkspaceDirectory(tmpDir);
      workspacePathLength = workspaceDir.path.length;

      var workspace = _createWorkspace(
        workspaceDir.uri,
        packageCount: packageCount,
        filesPerPackage: _filesPerPackage,
      );

      for (var scenario in _scenarios) {
        var excludedRoots = scenario.includePerPackageExcludes
            ? workspace.perPackageExcludes
            : const <Uri>[];
        var cacheDir = Directory.fromUri(
          tmpDir.uri.resolve('cache_${scenario.name}/'),
        )..createSync(recursive: true);

        // Phase 1: Cold fill of the persistent disk cache.
        var coldDuration = await _runOnce(
          args,
          rootUri: workspace.workspaceUri,
          excludedRootUris: excludedRoots,
          cacheFolder: cacheDir.uri,
          protocol: scenario.protocol,
        );

        // Phase 2: Measured warm runs against the filled disk cache.
        var warmDurations = <Duration>[];
        for (var i = 0; i < _warmRuns; i++) {
          warmDurations.add(
            await _runOnce(
              args,
              rootUri: workspace.workspaceUri,
              excludedRootUris: excludedRoots,
              cacheFolder: cacheDir.uri,
              protocol: scenario.protocol,
            ),
          );
        }

        var sortedWarm = [...warmDurations]..sort();
        var medianWarm = sortedWarm[sortedWarm.length ~/ 2];

        var row = _ResultRow(
          scenario: scenario.name,
          protocol: scenario.protocol,
          packages: packageCount,
          files: totalFiles,
          included: 1,
          excluded: excludedRoots.length,
          cold: coldDuration,
          warmRuns: warmDurations,
          warmMedian: medianWarm,
        );
        rows.add(row);

        if (!jsonOutput) {
          var warmList = warmDurations
              .map((d) => '${d.inMilliseconds}ms')
              .join(', ');
          print(
            '${scenario.name} | packages=$packageCount files=$totalFiles '
            'excluded=${excludedRoots.length} | '
            'cold=${coldDuration.inMilliseconds}ms | '
            'warm=[$warmList] -> median=${medianWarm.inMilliseconds}ms',
          );
        }
      }
    } finally {
      try {
        tmpDir.deleteSync(recursive: true);
      } catch (_) {
        sleep(const Duration(milliseconds: 50));
        try {
          tmpDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  if (jsonOutput) {
    print(
      const JsonEncoder.withIndent('  ').convert({
        'benchmark': 'warm_startup_multi_package_with_ide_excludes',
        'workspacePathLength': workspacePathLength,
        'results': [for (var row in rows) row.toJson()],
      }),
    );
    return;
  }

  print('');
  print('Scenarios:');
  for (var s in _scenarios) {
    print('  - ${s.name}: ${s.description}');
  }
  print('');
  print(
    'Workspace root path length: $workspacePathLength '
    '(target $_workspacePathLength)',
  );
  print('');
  print(
    '| Scenario | Packages | Files | Excluded | Cold | Warm runs (ms) | Warm median |',
  );
  print('|---|---:|---:|---:|---:|---|---:|');
  for (var row in rows) {
    var warmList = row.warmRuns.map((d) => '${d.inMilliseconds}').join(', ');
    print(
      '| ${row.scenario} | ${row.packages} | ${row.files} | ${row.excluded} | '
      '${row.cold.inMilliseconds} ms | $warmList | '
      '**${row.warmMedian.inMilliseconds} ms** |',
    );
  }

  _printExcludeOverhead(rows);
}

/// Number of Dart libraries generated per package.
const _filesPerPackage = 50;

/// Package counts swept for every scenario, each package has
/// [_filesPerPackage] Dart files.
const _packageCounts = [25, 50, 100];

/// Fixed scenarios executed by this benchmark.
///
/// All scenarios use a single workspace root (`included = 1`) rather than
/// one included root per package to avoid macOS FSEvents 1000ms retry jitter
/// (`TimerUtils::Sleep(1000)` in `runtime/bin/file_system_watcher_macos.cc`).
///
/// For each protocol, the scenario without excludes is the control, see
/// [_printExcludeOverhead].
const _scenarios = [
  _Scenario(
    name: 'legacy_3p_excludes',
    description: 'IntelliJ / Android Studio today (3 excludes per package)',
    protocol: _Protocol.legacy,
    includePerPackageExcludes: true,
  ),
  _Scenario(
    name: 'legacy_no_excludes',
    description: 'Legacy control (0 excludes)',
    protocol: _Protocol.legacy,
    includePerPackageExcludes: false,
  ),
  _Scenario(
    name: 'lsp_3p_excludes',
    description: 'LSP with analysisExcludedFolders / future pure-LSP IntelliJ',
    protocol: _Protocol.lsp,
    includePerPackageExcludes: true,
  ),
  _Scenario(
    name: 'lsp_no_excludes',
    description:
        'Default VS Code control (0 excludes; isolates package lookup)',
    protocol: _Protocol.lsp,
    includePerPackageExcludes: false,
  ),
];

/// Number of measured warm runs against a pre-filled disk cache.
const _warmRuns = 3;

/// The length of the workspace root path.
///
/// Path checks in the server compare paths character by character, so their
/// cost grows with the length of the paths. The root is padded to this
/// length, so that results do not depend on the temp directory of the
/// machine, and so that the paths are about as long as in a deeply nested
/// real repository.
const _workspacePathLength = 64;

_WorkspaceSpec _createWorkspace(
  Uri workspaceUri, {
  required int packageCount,
  required int filesPerPackage,
}) {
  var packageEntries = <Map<String, Object?>>[];
  var workspaceMembers = <String>[];
  var perPackageExcludes = <Uri>[];

  for (var p = 0; p < packageCount; p++) {
    var pkgName = 'pkg_${p.toString().padLeft(3, '0')}';
    var relPath = 'pkgs/$pkgName';
    workspaceMembers.add(relPath);

    var pkgUri = workspaceUri.resolve('$relPath/');
    var libUri = pkgUri.resolve('lib/');
    Directory.fromUri(libUri).createSync(recursive: true);

    File.fromUri(pkgUri.resolve('pubspec.yaml')).writeAsStringSync('''
name: $pkgName
environment:
  sdk: ^3.10.0
resolution: workspace
''');

    for (var f = 0; f < filesPerPackage; f++) {
      var fileName = 'file_${f.toString().padLeft(3, '0')}.dart';
      var buf = StringBuffer();
      if (f > 0) {
        var prevFile = 'file_${(f - 1).toString().padLeft(3, '0')}.dart';
        buf.writeln("import '$prevFile';");
      } else if (p > 0) {
        buf.writeln("import 'package:pkg_000/file_000.dart';");
      }
      buf.writeln('''

class C_${p}_$f {
  final int value;
  const C_${p}_$f(this.value);
  int compute(int x) => value + x + ${f > 0 ? 'const C_${p}_${f - 1}($f).value' : (p > 0 ? 'const C_0_0(0).value' : '1')};
}
''');
      File.fromUri(libUri.resolve(fileName)).writeAsStringSync(buf.toString());
    }

    // Standard per-package excludes added by IntelliJ's DartStartupActivity.kt.
    perPackageExcludes.add(pkgUri.resolve('.dart_tool/'));
    perPackageExcludes.add(pkgUri.resolve('.pub/'));
    perPackageExcludes.add(pkgUri.resolve('build/'));

    packageEntries.add({
      'name': pkgName,
      'rootUri': '../$relPath',
      'packageUri': 'lib/',
      'languageVersion': '3.10',
    });
  }

  var rootPubspec = StringBuffer('''
name: synthetic_workspace
environment:
  sdk: ^3.10.0
workspace:
''');
  for (var member in workspaceMembers) {
    rootPubspec.writeln('  - $member');
  }
  File.fromUri(workspaceUri.resolve('pubspec.yaml'))
      .writeAsStringSync(rootPubspec.toString());

  var dartToolDir = Directory.fromUri(workspaceUri.resolve('.dart_tool/'))
    ..createSync(recursive: true);
  File.fromUri(dartToolDir.uri.resolve('package_config.json'))
      .writeAsStringSync(
        const JsonEncoder.withIndent('  ')
            .convert({'configVersion': 2, 'packages': packageEntries}),
      );

  return _WorkspaceSpec(
    workspaceUri: workspaceUri,
    perPackageExcludes: perPackageExcludes,
  );
}

/// Creates the workspace root in [tmpDir], padded to [_workspacePathLength].
///
/// If [tmpDir] is too long, the root is longer than [_workspacePathLength],
/// and the actual length is reported with the results.
Directory _createWorkspaceDirectory(Directory tmpDir) {
  var nameLength = _workspacePathLength - tmpDir.path.length - 1;
  var name = 'w' * (nameLength < 1 ? 1 : nameLength);
  return Directory('${tmpDir.path}${Platform.pathSeparator}$name')
    ..createSync();
}

/// Prints the warm median of each scenario with excludes minus the warm
/// median of the scenario without excludes with the same protocol, for each
/// package count.
///
/// This is the cost of the IDE excludes, the headline number of the
/// benchmark. The protocols differ in costs that do not depend on the
/// excludes, so each scenario is compared with its own protocol.
void _printExcludeOverhead(List<_ResultRow> rows) {
  var withExcludes = _scenarios.where((s) => s.includePerPackageExcludes);

  _Scenario controlFor(_Scenario scenario) {
    return _scenarios.singleWhere(
      (s) => s.protocol == scenario.protocol && !s.includePerPackageExcludes,
    );
  }

  print('');
  print(
    'Exclude overhead (warm median minus the scenario without excludes '
    'with the same protocol):',
  );
  print('');
  print('| Packages | ${withExcludes.map((s) => s.name).join(' | ')} |');
  print('|---:|${'---:|' * withExcludes.length}');
  for (var packageCount in _packageCounts) {
    int warmMedianMs(_Scenario scenario) {
      return rows
          .singleWhere(
            (row) =>
                row.packages == packageCount && row.scenario == scenario.name,
          )
          .warmMedian
          .inMilliseconds;
    }

    var cells = withExcludes.map((s) {
      var overheadMs = warmMedianMs(s) - warmMedianMs(controlFor(s));
      return '${overheadMs >= 0 ? '+' : ''}$overheadMs ms';
    });
    print('| $packageCount | ${cells.join(' | ')} |');
  }
}

Future<Duration> _runOnce(
  List<String> args, {
  required Uri rootUri,
  required List<Uri> excludedRootUris,
  required Uri cacheFolder,
  required _Protocol protocol,
}) async {
  var benchmark = _WarmStartupMultiPackageWithIdeExcludesBenchmark(
    args,
    rootUri: rootUri,
    excludedRootUris: excludedRootUris,
    cacheFolder: cacheFolder,
    useLspProtocol: protocol == _Protocol.lsp,
  )..verbosity = -1;

  try {
    await benchmark.run();
    var duration = benchmark.initialAnalysisDuration;
    if (duration == null) {
      throw StateError('Initial analysis duration was not recorded.');
    }
    return duration;
  } finally {
    await benchmark.shutdown();
  }
}

enum _Protocol { legacy, lsp }

class _ResultRow {
  final String scenario;
  final _Protocol protocol;
  final int packages;
  final int files;
  final int included;
  final int excluded;
  final Duration cold;
  final List<Duration> warmRuns;
  final Duration warmMedian;

  new({
    required this.scenario,
    required this.protocol,
    required this.packages,
    required this.files,
    required this.included,
    required this.excluded,
    required this.cold,
    required this.warmRuns,
    required this.warmMedian,
  });

  Map<String, Object?> toJson() => {
    'scenario': scenario,
    'protocol': protocol.name,
    'packages': packages,
    'files': files,
    'included': included,
    'excluded': excluded,
    'coldMs': cold.inMilliseconds,
    'warmRunsMs': [for (var d in warmRuns) d.inMilliseconds],
    'warmMedianMs': warmMedian.inMilliseconds,
  };
}

class _Scenario {
  final String name;
  final String description;
  final _Protocol protocol;
  final bool includePerPackageExcludes;

  const new({
    required this.name,
    required this.description,
    required this.protocol,
    required this.includePerPackageExcludes,
  });
}

class _WarmStartupMultiPackageWithIdeExcludesBenchmark
    extends DartLanguageServerBenchmark {
  @override
  final Uri rootUri;

  @override
  final List<Uri> excludedRootUris;

  @override
  final Uri cacheFolder;

  new(
    super.args, {
    required this.rootUri,
    required this.excludedRootUris,
    required this.cacheFolder,
    required super.useLspProtocol,
  });

  @override
  int? get diagnosticPort => null;

  @override
  LaunchFrom get launchFrom => LaunchFrom.dart;

  @override
  Future<void> afterInitialization() async {
    // Nothing to do after initial analysis completes.
  }
}

class _WorkspaceSpec {
  final Uri workspaceUri;
  final List<Uri> perPackageExcludes;

  new({required this.workspaceUri, required this.perPackageExcludes});
}
