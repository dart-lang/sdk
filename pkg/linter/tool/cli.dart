// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/extensions.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/test_utilities/analyzer_utils.dart';
import 'package:linter/src/test_utilities/formatter.dart';
import 'package:linter/src/test_utilities/test_linter.dart';

import 'util/score_utils.dart';

/// Starts linting from the command-line.
Future<void> main(List<String> args) async {
  await runLinter(args);
}

const unableToProcessExitCode = 64;

String? getRoot(List<String> paths) =>
    paths.length == 1 && Directory(paths.first).existsSync()
        ? paths.first
        : null;

void printUsage(ArgParser parser, IOSink out, [String? error]) {
  var message = 'Lints Dart source files and pubspecs.';
  if (error != null) {
    message = error;
  }

  out.writeln('''$message
Usage: linter <file>
${parser.usage}

For more information, see https://github.com/dart-lang/linter
''');
}

// TODO(pq): consider using `dart analyze` where possible
// see: https://github.com/dart-lang/linter/pull/2537
Future<void> runLinter(List<String> args) async {
  // Force the rule registry to be populated.
  registerLintRules();

  var parser = ArgParser();
  parser
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information.')
    ..addFlag('stats',
        abbr: 's', negatable: false, help: 'Show lint statistics.')
    ..addFlag('benchmark', negatable: false, help: 'Show lint benchmarks.')
    ..addFlag('visit-transitive-closure',
        help: 'Visit the transitive closure of imported/exported libraries.')
    ..addFlag('quiet', abbr: 'q', help: "Don't show individual lint errors.")
    ..addFlag('machine',
        help: 'Print results in a format suitable for parsing.',
        negatable: false)
    ..addOption('config', abbr: 'c', help: 'Use configuration from this file.')
    ..addOption('dart-sdk', help: 'Custom path to a Dart SDK.')
    ..addMultiOption('rules',
        help: 'A list of lint rules to run. For example: '
            'annotate_overrides, avoid_catching_errors');

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, errorSink, err.message);
    exitCode = unableToProcessExitCode;
    return;
  }

  if (options['help'] as bool) {
    printUsage(parser, outSink);
    return;
  }

  if (options.rest.isEmpty) {
    printUsage(parser, errorSink,
        'Please provide at least one file or directory to lint.');
    exitCode = unableToProcessExitCode;
    return;
  }

  var configFile = options['config'];
  var ruleNames = options['rules'];

  LinterOptions linterOptions;
  if (configFile is String) {
    var config = LintConfig.parse(readFile(configFile));
    var enabledRules = Registry.ruleRegistry.where((LintRule rule) =>
        !config.ruleConfigs.any((rc) => rc.disables(rule.name)));
    var filter = _FileGlobFilter(config.fileIncludes, config.fileExcludes);
    linterOptions = LinterOptions(enabledRules: enabledRules, filter: filter);
  } else if (ruleNames is Iterable<String> && ruleNames.isNotEmpty) {
    var rules = <LintRule>[];
    for (var ruleName in ruleNames) {
      var rule = Registry.ruleRegistry[ruleName];
      if (rule == null) {
        errorSink.write('Unrecognized lint rule: $ruleName');
        exit(unableToProcessExitCode);
      }
      rules.add(rule);
    }
    linterOptions = LinterOptions(enabledRules: rules);
  } else {
    linterOptions = LinterOptions();
  }

  var customSdk = options['dart-sdk'];
  if (customSdk is String) {
    linterOptions.dartSdkPath = customSdk;
  }

  var stats = options['stats'] as bool;
  var benchmark = options['benchmark'] as bool;
  if (stats || benchmark) {
    linterOptions.enableTiming = true;
  }

  var filesToLint = [
    for (var path in options.rest)
      ...collectFiles(path)
          .map((file) => file.path.toAbsoluteNormalizedPath())
          .map(File.new),
  ];

  if (benchmark) {
    await writeBenchmarks(outSink, filesToLint, linterOptions);
    return;
  }

  var linter = TestLinter(linterOptions);

  try {
    var timer = Stopwatch()..start();
    var errors = await lintFiles(linter, filesToLint);
    timer.stop();

    var commonRoot = getRoot(options.rest);
    var machine = options['machine'] ?? false;
    var quiet = options['quiet'] ?? false;
    ReportFormatter(
      errors,
      linterOptions.filter,
      outSink,
      elapsedMs: timer.elapsedMilliseconds,
      fileCount: linter.numSourcesAnalyzed,
      fileRoot: commonRoot,
      showStatistics: stats,
      machineOutput: machine as bool,
      quiet: quiet as bool,
    ).write();
    // ignore: avoid_catches_without_on_clauses
  } catch (err, stack) {
    errorSink.writeln('''An error occurred while linting
  Please report it at: github.com/dart-lang/linter/issues
$err
$stack''');
  }
}

Future<void> writeBenchmarks(
    IOSink out, List<File> filesToLint, LinterOptions linterOptions) async {
  var timings = <String, int>{};
  for (var i = 0; i < benchmarkRuns; ++i) {
    await lintFiles(TestLinter(linterOptions), filesToLint);
    lintRuleTimers.timers.forEach((n, t) {
      var timing = t.elapsedMilliseconds;
      var previous = timings[n];
      if (previous == null) {
        timings[n] = timing;
      } else {
        timings[n] = min(previous, timing);
      }
    });
  }

  var coreRuleset = await coreRules;
  var recommendedRuleset = await recommendedRules;
  var flutterRuleset = await flutterRules;

  var stats = timings.keys.map((t) {
    var sets = <String>[];
    if (coreRuleset.contains(t)) {
      sets.add('core');
    }
    if (recommendedRuleset.contains(t)) {
      sets.add('recommended');
    }
    if (flutterRuleset.contains(t)) {
      sets.add('flutter');
    }

    var details = sets.isEmpty ? '' : " [${sets.join(', ')}]";
    return Stat('$t$details', timings[t] ?? 0);
  }).toList();
  out.writeTimings(stats, 0);
}

class _FileGlobFilter extends LintFilter {
  final List<Glob> includes;
  final List<Glob> excludes;

  _FileGlobFilter(Iterable<String> includeGlobs, Iterable<String> excludeGlobs)
      : includes = includeGlobs.map(Glob.new).toList(),
        excludes = excludeGlobs.map(Glob.new).toList();

  @override
  bool filter(AnalysisError lint) =>
      // TODO(srawlins): specify order.
      excludes.any((glob) => glob.matches(lint.source.fullName)) &&
      !includes.any((glob) => glob.matches(lint.source.fullName));
}
