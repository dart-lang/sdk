// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:path/path.dart' as pkg_path;

import '../../test/util/diff.dart' as diff;
import 'ab_mutate/engine.dart';
import 'ab_mutate/models.dart';
import 'ab_mutate/mutations.dart';
import 'ab_mutate/mutations/kinds.dart';
import 'ab_mutate/util.dart';

void main(List<String> args) async {
  linter.registerLintRules();

  var options = _parseOptions(args);
  if (options == null) {
    io.exit(2);
  }

  await MutationRunner(options).run();
}

Options? _parseOptions(List<String> args) {
  var allKindIds = MutationKind.values.map((k) => k.id).toList();
  var defaultKindIds = [
    MutationKind.removeLastFormalParameter,
    MutationKind.renameLocalVariable,
    MutationKind.toggleReturnTypeNullability,
  ].map((k) => k.id);
  var parser = ArgParser()
    ..addOption('repo', help: 'Path to repository root', mandatory: true)
    ..addOption(
      'mutate-dirs',
      help: 'Comma-separated dirs (relative to repo) to choose mutation sites',
      mandatory: true,
    )
    ..addOption(
      'diagnostic-dirs',
      help: 'Comma-separated dirs (relative to repo) to compute diagnostics',
      mandatory: true,
    )
    ..addMultiOption(
      'kinds',
      help: 'Allowed: ${allKindIds.join(', ')} (subset ok)',
      allowed: allKindIds,
      defaultsTo: defaultKindIds,
    )
    ..addOption(
      'per-kind',
      help: 'Upper bound of successful applied mutations per kind (per chain)',
      defaultsTo: '3',
    )
    ..addOption(
      'chains',
      help: 'How many chains to run (each starts from baseline)',
      defaultsTo: '5',
    )
    ..addOption(
      'max-steps-per-chain',
      help: 'Hard cap on steps within a chain',
      defaultsTo: '6',
    )
    ..addOption('seed', help: 'RNG seed (int)', defaultsTo: '1')
    ..addOption(
      'max-diagnostics',
      help:
          'Absolute cap of diagnostics (if unset, derived from baseline per run)',
      defaultsTo: '',
    )
    ..addOption('out', help: 'Output directory', mandatory: true);

  late ArgResults opts;
  try {
    opts = parser.parse(args);
  } catch (e) {
    print(parser.usage);
    return null;
  }

  var repo = pkg_path.normalize(pkg_path.absolute(opts['repo'] as String));
  var outDir = pkg_path.normalize(pkg_path.absolute(opts['out'] as String));
  io.Directory(outDir).createSync(recursive: true);

  var mutateDirs = splitCsv(
    opts['mutate-dirs'] as String,
  ).map((d) => pkg_path.join(repo, d)).toList();
  var diagDirs = splitCsv(
    opts['diagnostic-dirs'] as String,
  ).map((d) => pkg_path.join(repo, d)).toList();

  var kindIds = (opts['kinds'] as List<String>).toSet();
  var kinds = kindIds.map((id) => MutationKind.byId[id]).nonNulls.toList();
  if (kinds.isEmpty) {
    io.stderr.writeln(
      'No valid kinds specified. Allowed: ${allKindIds.join(', ')}',
    );
    return null;
  }

  var perKindCap = int.parse(opts['per-kind'] as String);
  var chains = int.parse(opts['chains'] as String);
  var maxStepsPerChain = int.parse(opts['max-steps-per-chain'] as String);
  var seed = int.parse(opts['seed'] as String);
  var explicitMaxDiagnostics =
      (opts['max-diagnostics'] as String).trim().isEmpty
      ? null
      : int.parse(opts['max-diagnostics'] as String);

  return Options(
    repo: repo,
    outDir: outDir,
    mutateDirs: mutateDirs,
    diagnosticDirs: diagDirs,
    kinds: kinds,
    perKindCap: perKindCap,
    chains: chains,
    maxStepsPerChain: maxStepsPerChain,
    seed: seed,
    explicitMaxDiagnostics: explicitMaxDiagnostics,
  );
}

class MutationRunner {
  final Options options;

  late final OverlayResourceProvider overlay;
  late final List<String> mutateFiles;
  late final List<String> diagFiles;
  late final String runRoot;
  late final Map<String, String> baselineMap;

  late final bool baselineEqual;
  late final int baseTotal;
  late final int maxDiagnostics;

  final List<Map<String, Object?>> runSummary = [];
  late final Map<MutationKind, int> perKindUsedRun;

  MutationRunner(this.options) {
    perKindUsedRun = {for (var k in options.kinds) k: 0};
  }

  Future<void> run() async {
    if (!await _setupAndBaseline()) {
      // Baseline diverged, summary already written.
      print(
        'Baseline A vs B differ; aborting run. '
        'See baseline_diverge_details.json.',
      );
      return;
    }

    await _runChains();

    _writeRunSummary();

    print('Done. Output in: $runRoot');
  }

  Future<List<HarnessDiagnostic>?> _collectAndHandleErrors(
    ABEngine engine,
    String stateDir,
    String label,
  ) async {
    try {
      return await collectAllDiagnostics(engine, diagFiles);
    } catch (e, st) {
      io.File(pkg_path.join(stateDir, 'exception_$label.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('$e\n$st');
      return null;
    }
  }

  Future<bool> _establishBaseline() async {
    var baselineDir = pkg_path.join(runRoot, 'baseline');
    io.Directory(baselineDir).createSync(recursive: true);

    var aBaseline = ABEngine(
      overlay: overlay,
      roots: [options.repo],
      label: 'A-baseline',
      rebuildEveryStep: true,
      withFineDependencies: false,
    );
    var bBaseline = ABEngine(
      overlay: overlay,
      roots: [options.repo],
      label: 'B-baseline',
      rebuildEveryStep: false,
      withFineDependencies: true,
    );

    var baselineA = await collectAllDiagnostics(aBaseline, diagFiles);
    var baselineB = await collectAllDiagnostics(bBaseline, diagFiles);

    writeJson(
      pkg_path.join(baselineDir, 'diagnostics_A.json'),
      baselineA.map((e) => e.toJson(options.repo)).toList(),
    );
    writeJson(
      pkg_path.join(baselineDir, 'diagnostics_B.json'),
      baselineB.map((e) => e.toJson(options.repo)).toList(),
    );

    aBaseline.writePerformanceTo(
      pkg_path.join(baselineDir, 'performance_A.txt'),
    );
    bBaseline.writePerformanceTo(
      pkg_path.join(baselineDir, 'performance_B.txt'),
    );

    var keysA0 = baselineA.map((e) => e.key()).toList()..sort();
    var keysB0 = baselineB.map((e) => e.key()).toList()..sort();
    var equal = const ListEquality<String>().equals(keysA0, keysB0);
    writeJson(pkg_path.join(baselineDir, 'baseline_compare_A_vs_B.json'), {
      'equal': equal,
    });

    if (!equal) {
      _writeBaselineDivergenceDetails(baselineA, baselineB);
      _writeRunSummary(baselineDiverged: true);
      return false;
    }

    baselineEqual = true;
    baseTotal = (baselineA.length >= baselineB.length)
        ? baselineA.length
        : baselineB.length;
    var derivedCap = ((baseTotal + 50) >= ((baseTotal * 1.20).ceil()))
        ? (baseTotal + 50)
        : ((baseTotal * 1.20).ceil());
    maxDiagnostics = options.explicitMaxDiagnostics ?? derivedCap;

    return true;
  }

  Future<void> _runChain(int chainIdx, String chainsDir) async {
    var currentContent = Map<String, String>.from(baselineMap);

    // Reset overlays to baseline so each chain is independent.
    for (var f in currentContent.keys) {
      overlay.removeOverlay(f);
    }
    for (var e in currentContent.entries) {
      overlay.setOverlay(e.key, content: e.value, modificationStamp: 0);
    }

    var chainRoot = pkg_path.join(
      chainsDir,
      chainIdx.toString().padLeft(4, '0'),
    );
    io.Directory(
      pkg_path.join(chainRoot, 'states'),
    ).createSync(recursive: true);

    var aEngine = ABEngine(
      overlay: overlay,
      roots: [options.repo],
      label: 'A',
      rebuildEveryStep: false,
      withFineDependencies: false,
    );
    var bEngine = ABEngine(
      overlay: overlay,
      roots: [options.repo],
      label: 'B',
      rebuildEveryStep: false,
      withFineDependencies: true,
    );

    // Warm-up, so that the first mutation is incremental.
    await collectAllDiagnostics(aEngine, diagFiles);
    await collectAllDiagnostics(bEngine, diagFiles);
    aEngine.resetPerformance();
    bEngine.resetPerformance();

    var selector = SiteSelector(overlay, [options.repo]);
    var perKindUsed = {for (var k in options.kinds) k: 0};

    var step = 0;
    var endReason = 'max_steps_reached';
    var chainSummary = <Map<String, Object?>>[];

    while (step < options.maxStepsPerChain) {
      var exhaustedKinds = <MutationKind>{};
      MutationResult? mutationResult;
      Mutation? mutation;
      var kindAttempt = 0;

      while (true) {
        var applicableKinds = options.kinds.where((k) {
          return perKindUsed[k]! < options.perKindCap &&
              !exhaustedKinds.contains(k);
        }).toList();
        if (applicableKinds.isEmpty) {
          endReason = 'no_applicable_kinds';
          break;
        }

        var kindIdx = pickIndex(applicableKinds.length, [
          options.seed,
          chainIdx,
          step + 1,
          'pick-kind',
          kindAttempt,
        ]);
        kindAttempt++;
        var selectedKind = applicableKinds[kindIdx];

        const maxFileTrials = 32;
        var applied = false;

        for (var fileAttempt = 0; fileAttempt < maxFileTrials; fileAttempt++) {
          var fileIdx = pickIndex(mutateFiles.length, [
            options.seed,
            chainIdx,
            step + 1,
            'pick-file',
            selectedKind.id,
            fileAttempt,
          ]);
          var filePath = mutateFiles[fileIdx];
          var before = currentContent[filePath]!;

          var compilationUnit = (selectedKind.selector == SelectorMode.resolved)
              ? await selector.resolvedUnit(filePath)
              : selector.parsedUnit(filePath);
          if (compilationUnit == null) continue;

          var mutations = discoverMutationsFor(
            selectedKind,
            filePath,
            compilationUnit,
          );
          if (mutations.isEmpty) continue;

          var siteIdx = pickIndex(mutations.length, [
            options.seed,
            chainIdx,
            step + 1,
            'pick-site',
            selectedKind.id,
            fileAttempt,
          ]);
          mutation = mutations[siteIdx];

          mutationResult = mutation.apply(compilationUnit, before);
          applied = true;
          break;
        }

        if (applied) break;
        exhaustedKinds.add(selectedKind);
      }

      if (mutationResult == null) break;

      var filePath = mutation!.path;
      var before = currentContent[filePath]!;
      var after = applyEdit(before, mutationResult.edit);
      currentContent[filePath] = after;
      overlay.setOverlay(
        filePath,
        content: after,
        modificationStamp: DateTime.now().millisecondsSinceEpoch,
      );

      await aEngine.notifyChange(filePath);
      await bEngine.notifyChange(filePath);
      await selector.notifyChange(filePath);

      var stateId =
          '${(step + 1).toString().padLeft(4, '0')}-${mutation.kind.id}';
      var stateDir = pkg_path.join(chainRoot, 'states', stateId);
      io.Directory(stateDir).createSync(recursive: true);

      writeJson(pkg_path.join(stateDir, 'mutation.json'), {
        'seed': options.seed,
        'chain': chainIdx,
        'step': step + 1,
        'kind': mutation.kind.id,
        'file': pkg_path.relative(filePath, from: options.repo),
        'selection': mutation.selectionJson(options.repo),
        'selector_mode': mutation.kind.selector.name,
        'edit': mutationResult.edit.toJson(),
        'notes': mutationResult.notes,
      });

      _writeStepOutputs(stateDir, filePath, before, after);

      var stopwatch = Stopwatch()..start();
      var diagsA = await _collectAndHandleErrors(aEngine, stateDir, 'A');
      var aTimeMs = stopwatch.elapsedMilliseconds;

      stopwatch.reset();
      var diagsB = await _collectAndHandleErrors(bEngine, stateDir, 'B');
      var bTimeMs = stopwatch.elapsedMilliseconds;

      if (diagsA == null || diagsB == null) {
        endReason = 'exception';
        chainSummary.add({
          'state': stateId,
          'kind': mutation.kind.id,
          'file': pkg_path.relative(filePath, from: options.repo),
          'equal': false,
          'A_time_ms': 0,
          'B_time_ms': 0,
          'A_total': 0,
          'B_total': 0,
          'exception_file': diagsA == null
              ? 'exception_A.txt'
              : 'exception_B.txt',
        });
        break;
      }

      var normA = diagsA.map((e) => e.toJson(options.repo)).toList();
      var normB = diagsB.map((e) => e.toJson(options.repo)).toList();
      writeJson(pkg_path.join(stateDir, 'diagnostics_A.json'), normA);
      writeJson(pkg_path.join(stateDir, 'diagnostics_B.json'), normB);

      var keysA = diagsA.map((e) => e.key()).toList()..sort();
      var keysB = diagsB.map((e) => e.key()).toList()..sort();
      var eq = const ListEquality<String>().equals(keysA, keysB);
      writeJson(pkg_path.join(stateDir, 'compare_A_vs_B.json'), {'equal': eq});

      var aTotal = diagsA.length;
      var bTotal = diagsB.length;
      writeJson(pkg_path.join(stateDir, 'metrics_A.json'), {
        'engine': 'A',
        'timing_ms': aTimeMs,
        'total_diagnostics': aTotal,
      });
      writeJson(pkg_path.join(stateDir, 'metrics_B.json'), {
        'engine': 'B',
        'timing_ms': bTimeMs,
        'total_diagnostics': bTotal,
      });

      aEngine.writePerformanceTo(pkg_path.join(stateDir, 'performance_A.txt'));
      bEngine.writePerformanceTo(pkg_path.join(stateDir, 'performance_B.txt'));

      chainSummary.add({
        'state': stateId,
        'kind': mutation.kind.id,
        'file': pkg_path.relative(filePath, from: options.repo),
        'equal': eq,
        'A_time_ms': aTimeMs,
        'B_time_ms': bTimeMs,
        'A_total': aTotal,
        'B_total': bTotal,
      });

      if (!eq) {
        _writeDivergenceDetails(
          stateDir,
          diagsA,
          diagsB,
          keysA,
          keysB,
          chainIdx: chainIdx,
          step: step + 1,
          mut: mutation,
          filePath: filePath,
          res: mutationResult,
        );
        endReason = 'diverged';
        break;
      }

      perKindUsed[mutation.kind] = perKindUsed[mutation.kind]! + 1;
      step++;

      var maxTotal = (aTotal >= bTotal) ? aTotal : bTotal;
      if (maxTotal > maxDiagnostics) {
        endReason = 'max_diagnostics_exceeded';
        break;
      }
    }

    writeJson(pkg_path.join(chainRoot, 'chain_summary.json'), {
      'chain': chainIdx,
      'end_reason': endReason,
      'steps': chainSummary,
      'per_kind_used': {for (var e in perKindUsed.entries) e.key.id: e.value},
    });

    for (var k in options.kinds) {
      perKindUsedRun[k] = perKindUsedRun[k]! + perKindUsed[k]!;
    }

    runSummary.add({
      'chain': chainIdx,
      'end_reason': endReason,
      'steps': chainSummary.length,
      'p50_speedup': medianSpeedup(chainSummary.map(speedup).toList()),
      'p90_speedup': p90Speedup(chainSummary.map(speedup).toList()),
    });
  }

  Future<void> _runChains() async {
    var chainsDir = pkg_path.join(runRoot, 'chains');
    io.Directory(chainsDir).createSync();

    for (var chainIdx = 1; chainIdx <= options.chains; chainIdx++) {
      await _runChain(chainIdx, chainsDir);
    }
  }

  Future<bool> _setupAndBaseline() async {
    var physical = PhysicalResourceProvider.INSTANCE;
    overlay = OverlayResourceProvider(physical);

    mutateFiles = discoverDartFiles(options.mutateDirs, options.repo);
    diagFiles = discoverDartFiles(options.diagnosticDirs, options.repo);

    if (mutateFiles.isEmpty) {
      io.stderr.writeln('No Dart files found under mutate-dirs.');
      io.exit(2);
    }
    if (diagFiles.isEmpty) {
      io.stderr.writeln('No Dart files found under diagnostic-dirs.');
      io.exit(2);
    }

    var runId = timestampId();
    runRoot = pkg_path.join(options.outDir, 'run-$runId-seed${options.seed}');
    io.Directory(runRoot).createSync(recursive: true);

    _writeManifest();
    _snapshotBaselineFiles();

    return await _establishBaseline();
  }

  void _snapshotBaselineFiles() {
    baselineMap = <String, String>{};
    for (var path in {...mutateFiles, ...diagFiles}) {
      var content = io.File(path).readAsStringSync();
      baselineMap[path] = content;
    }
    var filesJson = baselineMap.entries.map((entry) {
      return {
        'path': pkg_path.relative(entry.key, from: options.repo),
        'sha256': sha256.convert(utf8.encode(entry.value)).toString(),
      };
    }).toList();
    writeJson(pkg_path.join(runRoot, 'files.json'), filesJson);
  }

  void _writeBaselineDivergenceDetails(
    List<HarnessDiagnostic> baselineA,
    List<HarnessDiagnostic> baselineB,
  ) {
    var baselineDir = pkg_path.join(runRoot, 'baseline');
    var baselineKeysA = baselineA.map((e) => e.key()).toList()..sort();
    var baselineKeysB = baselineB.map((e) => e.key()).toList()..sort();
    var setA = baselineKeysA.toSet();
    var setB = baselineKeysB.toSet();
    var onlyA = setA.difference(setB);
    var onlyB = setB.difference(setA);
    var byCode = <String, Map<String, int>>{};

    void tally(List<HarnessDiagnostic> src, Set<String> keys, String bucket) {
      for (var d in src) {
        var k = d.key();
        if (!keys.contains(k)) continue;
        var m = byCode.putIfAbsent(
          d.code,
          () => {'only_in_A': 0, 'only_in_B': 0},
        );
        m[bucket] = (m[bucket] ?? 0) + 1;
      }
    }

    tally(baselineA, onlyA, 'only_in_A');
    tally(baselineB, onlyB, 'only_in_B');
    writeJson(pkg_path.join(baselineDir, 'baseline_diverge_details.json'), {
      'A_total': baselineA.length,
      'B_total': baselineB.length,
      'only_in_A_count': onlyA.length,
      'only_in_B_count': onlyB.length,
      'by_code': byCode,
    });
  }

  void _writeDivergenceDetails(
    String stateDir,
    List<HarnessDiagnostic> diagsA,
    List<HarnessDiagnostic> diagsB,
    List<String> keysA,
    List<String> keysB, {
    required int chainIdx,
    required int step,
    required Mutation mut,
    required String filePath,
    required MutationResult res,
  }) {
    var setA = keysA.toSet();
    var setB = keysB.toSet();
    var onlyA = setA.difference(setB);
    var onlyB = setB.difference(setA);

    List<Map<String, Object?>> summarize(
      List<HarnessDiagnostic> src,
      Set<String> keys,
    ) {
      var out = <Map<String, Object?>>[];
      for (var d in src) {
        if (!keys.contains(d.key())) continue;
        out.add({
          'file': pkg_path.relative(d.path, from: options.repo),
          'code': d.code,
          'severity': d.severity,
          'offset': d.offset,
          'length': d.length,
        });
      }
      return out;
    }

    var onlyInA = summarize(diagsA, onlyA);
    var onlyInB = summarize(diagsB, onlyB);

    var byCode = <String, Map<String, int>>{};
    void tally(List<Map<String, Object?>> list, String bucket) {
      for (var m in list) {
        var code = m['code'] as String;
        var b = byCode.putIfAbsent(
          code,
          () => {'only_in_A': 0, 'only_in_B': 0},
        );
        b[bucket] = (b[bucket] ?? 0) + 1;
      }
    }

    tally(onlyInA, 'only_in_A');
    tally(onlyInB, 'only_in_B');

    var details = {
      'seed': options.seed,
      'chain': chainIdx,
      'step': step,
      'kind': mut.kind.id,
      'file': pkg_path.relative(filePath, from: options.repo),
      'selector_mode': mut.kind.selector.name,
      'edit': res.edit.toJson(),
      'notes': res.notes,
      'A_total': diagsA.length,
      'B_total': diagsB.length,
      'only_in_A_count': onlyInA.length,
      'only_in_B_count': onlyInB.length,
      'only_in_A': onlyInA,
      'only_in_B': onlyInB,
      'by_code': byCode,
    };
    writeJson(pkg_path.join(stateDir, 'diverge_details.json'), details);
  }

  void _writeManifest() {
    var manifest = {
      'repo': options.repo,
      'mutateDirs': options.mutateDirs
          .map((d) => pkg_path.relative(d, from: options.repo))
          .toList(),
      'diagnosticDirs': options.diagnosticDirs
          .map((d) => pkg_path.relative(d, from: options.repo))
          .toList(),
      'kinds': options.kinds.map((k) => k.id).toList(),
      'perKind': options.perKindCap,
      'chains': options.chains,
      'maxStepsPerChain': options.maxStepsPerChain,
      'seed': options.seed,
      'out': options.outDir,
      'toolVersion': 3, // on-demand site discovery + changeFile notifications
    };
    writeJson(pkg_path.join(runRoot, 'manifest.json'), manifest);
  }

  void _writeRunSummary({bool baselineDiverged = false}) {
    if (baselineDiverged) {
      writeJson(pkg_path.join(runRoot, 'run_summary.json'), {
        'baseline_equal': false,
        'baseline_total': 0,
        'max_diagnostics_cap': (options.explicitMaxDiagnostics ?? 0),
        'per_kind_final': {for (var k in options.kinds) k.id: 0},
        'chains': <Object>[],
        'end_reason': 'baseline_diverged',
      });
      return;
    }

    writeJson(pkg_path.join(runRoot, 'run_summary.json'), {
      'baseline_equal': baselineEqual,
      'baseline_total': baseTotal,
      'max_diagnostics_cap': maxDiagnostics,
      'per_kind_final': {
        for (var e in perKindUsedRun.entries) e.key.id: e.value,
      },
      'chains': runSummary,
    });
  }

  void _writeStepOutputs(
    String stateDir,
    String filePath,
    String before,
    String after,
  ) {
    io.File(pkg_path.join(stateDir, 'before.dart')).writeAsStringSync(before);
    io.File(pkg_path.join(stateDir, 'after.dart')).writeAsStringSync(after);

    var relPath = pkg_path.relative(filePath, from: options.repo);
    var lines = diff.generateFocusedDiff(before, after);
    var header = ['--- a/$relPath', '+++ b/$relPath'];
    var patch = '${(header + lines).join('\n')}\n';

    io.File(pkg_path.join(stateDir, 'patch.diff')).writeAsStringSync(patch);
  }
}

class Options {
  final String repo;
  final String outDir;
  final List<String> mutateDirs;
  final List<String> diagnosticDirs;
  final List<MutationKind> kinds;
  final int perKindCap;
  final int chains;
  final int maxStepsPerChain;
  final int seed;
  final int? explicitMaxDiagnostics;

  Options({
    required this.repo,
    required this.outDir,
    required this.mutateDirs,
    required this.diagnosticDirs,
    required this.kinds,
    required this.perKindCap,
    required this.chains,
    required this.maxStepsPerChain,
    required this.seed,
    required this.explicitMaxDiagnostics,
  });
}
