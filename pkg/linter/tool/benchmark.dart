// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/src/lint/analysis_rule_timers.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:args/args.dart';
import 'package:linter/src/extensions.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/test_utilities/analysis_error_info.dart';
import 'package:linter/src/test_utilities/linter_options.dart';
import 'package:linter/src/test_utilities/test_linter.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'lint_sets.dart';

/// Benchmarks lint rules.
Future<void> main(List<String> args) async {
  await runLinter(args);
}

// Number of times to perform linting to get stable benchmarks.
const benchmarkRuns = 10;

const loggedAnalyzerErrorExitCode = 63;

const unableToProcessExitCode = 64;

/// Collect all lintable files, recursively, under this [entityPath] root,
/// ignoring links.
Iterable<File> collectFiles(String entityPath) {
  var files = <File>[];

  var file = File(entityPath);
  if (file.existsSync()) {
    files.add(file);
  } else {
    var directory = Directory(entityPath);
    if (directory.existsSync()) {
      for (var entry in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        var relative = path.relative(entry.path, from: directory.path);

        if (entry is File && entry.path.isLintable && !relative.isInHiddenDir) {
          files.add(entry);
        }
      }
    }
  }

  return files;
}

Future<void> lintFiles(TestLinter linter, List<File> filesToLint) async {
  // Setup an error watcher to track whether an error was logged to stderr so
  // we can set the exit code accordingly.
  var errorWatcher = _ErrorWatchingSink(errorSink);
  errorSink = errorWatcher;
  var errors = await linter.lintFiles(filesToLint);
  if (errorWatcher.encounteredError) {
    exitCode = loggedAnalyzerErrorExitCode;
  } else if (errors.isNotEmpty) {
    exitCode = _maxSeverity(errors);
  }
}

void printUsage(ArgParser parser, StringSink out, [String? error]) {
  var message = 'Benchmark lint rules.';
  if (error != null) {
    message = error;
  }

  out.writeln('''$message
Usage: benchmark.dart <file>
${parser.usage}
''');
}

Future<void> runLinter(List<String> args) async {
  registerLintRules();

  var parser = ArgParser();
  parser
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    )
    ..addOption('config', abbr: 'c', help: 'Use configuration from this file.')
    ..addOption('dart-sdk', help: 'Custom path to a Dart SDK.')
    ..addMultiOption(
      'rules',
      help:
          'A list of lint rules to run. For example: '
          'annotate_overrides, avoid_catching_errors',
    );

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

  var paths = options.rest;
  if (paths.isEmpty) {
    printUsage(
      parser,
      errorSink,
      'Please provide at least one file or directory to lint.',
    );
    exitCode = unableToProcessExitCode;
    return;
  }

  var configFile = options['config'];
  var ruleNames = options['rules'];

  LinterOptions linterOptions;
  if (configFile is String) {
    var optionsContent = readFile(configFile);
    var options = loadYamlNode(optionsContent) as YamlMap;
    var ruleConfigs = parseLinterSection(options)!.values;
    var enabledRules = Registry.ruleRegistry.where(
      (rule) => !ruleConfigs.any((rc) => rc.disables(rule.name)),
    );

    linterOptions = LinterOptions(enabledRules: enabledRules);
  } else if (ruleNames is Iterable<String> && ruleNames.isNotEmpty) {
    var rules = <AbstractAnalysisRule>[];
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

  linterOptions.enableTiming = true;

  var filesToLint = [
    for (var path in paths)
      ...collectFiles(
        path,
      ).map((file) => file.path.toAbsoluteNormalizedPath()).map(File.new),
  ];

  await writeBenchmarks(outSink, filesToLint, linterOptions);
}

Future<void> writeBenchmarks(
  StringSink out,
  List<File> filesToLint,
  LinterOptions linterOptions,
) async {
  var timings = <String, int>{};
  for (var i = 0; i < benchmarkRuns; ++i) {
    await lintFiles(TestLinter(linterOptions), filesToLint);
    analysisRuleTimers.timers.forEach((n, t) {
      var timing = t.elapsedMilliseconds;
      var previous = timings[n];
      timings[n] = previous == null ? timing : math.min(previous, timing);
    });
  }

  var coreRuleset = await dartCoreLints;
  var recommendedRuleset = await dartRecommendedLints;
  var flutterRuleset = await flutterUserLints;

  var stats =
      timings.keys.map((t) {
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

int _maxSeverity(List<DiagnosticInfo> infos) {
  var filteredErrors = infos.expand((i) => i.diagnostics);
  return filteredErrors.fold(
    0,
    (value, e) => math.max(value, e.diagnosticCode.severity.ordinal),
  );
}

class Stat implements Comparable<Stat> {
  final String name;
  final int elapsed;

  Stat(this.name, this.elapsed);

  @override
  int compareTo(Stat other) => other.elapsed - elapsed;
}

class _ErrorWatchingSink implements StringSink {
  bool encounteredError = false;

  final StringSink delegate;

  _ErrorWatchingSink(this.delegate);

  @override
  void write(Object? obj) => delegate.write(obj);

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      delegate.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => delegate.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) {
    // 'Exception while using a Visitor to visit ...' (
    if (obj.toString().startsWith('Exception')) {
      encounteredError = true;
    }
    delegate.writeln(obj);
  }
}

extension on String {
  /// Whether this path is a hidden directory.
  bool get isInHiddenDir =>
      path.split(this).any((part) => part.startsWith('.'));

  /// Whether this path is a Dart file or a Pubspec file.
  bool get isLintable =>
      endsWith('.dart') || path.basename(this) == file_paths.pubspecYaml;
}

extension on StringSink {
  void writeTimings(List<Stat> timings, int summaryLength) {
    var names = timings.map((s) => s.name).toList();

    var longestName = names.fold<int>(
      0,
      (prev, element) => math.max(prev, element.length),
    );
    var longestTime = 8;
    var tableWidth = math.max(summaryLength, longestName + longestTime);
    var pad = tableWidth - longestName;
    var line = ''.padLeft(tableWidth, '-');

    writeln();
    writeln(line);
    writeln('${'Timings'.padRight(longestName)}${'ms'.padLeft(pad)}');
    writeln(line);
    var totalTime = 0;

    timings.sort();
    for (var stat in timings) {
      totalTime += stat.elapsed;
      writeln(
        '${stat.name.padRight(longestName)}${stat.elapsed.toString().padLeft(pad)}',
      );
    }

    writeln(line);
    writeln(
      '${'Total'.padRight(longestName)}${totalTime.toString().padLeft(pad)}',
    );
    writeln(line);
  }
}
