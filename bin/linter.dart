// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:args/args.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/formatter.dart';
import 'package:linter/src/rules.dart';

Future main(List<String> args) async {
  await runLinter(args, new LinterOptions());
}

const processFileFailedExitCode = 65;

const unableToProcessExitCode = 64;

String getRoot(List<String> paths) =>
    paths.length == 1 && new Directory(paths[0]).existsSync() ? paths[0] : null;

bool isLinterErrorCode(int code) =>
    code == unableToProcessExitCode || code == processFileFailedExitCode;

void printUsage(ArgParser parser, IOSink out, [String error]) {
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

Future runLinter(List<String> args, LinterOptions initialLintOptions) async {
  // Force the rule registry to be populated.
  registerLintRules();

  var parser = new ArgParser(allowTrailingOptions: true);

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
        defaultsTo: false,
        negatable: false)
    ..addFlag('strong', help: 'Use strong-mode analyzer.')
    ..addOption('config', abbr: 'c', help: 'Use configuration from this file.')
    ..addOption('dart-sdk', help: 'Custom path to a Dart SDK.')
    ..addOption('rules',
        help: 'A list of lint rules to run. For example: '
            'avoid_as,annotate_overrides',
        allowMultiple: true)
    ..addOption('packages',
        help: 'Path to the package resolution configuration file, which\n'
            'supplies a mapping of package names to paths.  This option\n'
            'cannot be used with --package-root.')
    ..addOption('package-root',
        abbr: 'p', help: 'Custom package root. (Discouraged.)');

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, errorSink, err.message);
    exitCode = unableToProcessExitCode;
    return;
  }

  if (options['help']) {
    printUsage(parser, outSink);
    return;
  }

  if (options.rest.isEmpty) {
    printUsage(parser, errorSink,
        'Please provide at least one file or directory to lint.');
    exitCode = unableToProcessExitCode;
    return;
  }

  var lintOptions = initialLintOptions;

  var configFile = options['config'];
  if (configFile != null) {
    var config = new LintConfig.parse(readFile(configFile));
    lintOptions.configure(config);
  }

  var lints = options['rules'];
  if (lints != null && !lints.isEmpty) {
    var rules = <LintRule>[];
    for (var lint in lints) {
      var rule = Registry.ruleRegistry[lint];
      if (rule == null) {
        errorSink.write('Unrecognized lint rule: $lint');
        exit(unableToProcessExitCode);
      }
      rules.add(rule);
    }

    lintOptions.enabledLints = rules;
  }

  var customSdk = options['dart-sdk'];
  if (customSdk != null) {
    lintOptions.dartSdkPath = customSdk;
  }

  var strongMode = options['strong'];
  if (strongMode != null) lintOptions.strongMode = strongMode;

  var customPackageRoot = options['package-root'];
  if (customPackageRoot != null) {
    lintOptions.packageRootPath = customPackageRoot;
  }

  var packageConfigFile = options['packages'];

  if (customPackageRoot != null && packageConfigFile != null) {
    errorSink.write("Cannot specify both '--package-root' and '--packages'.");
    exitCode = unableToProcessExitCode;
    return;
  }

  var stats = options['stats'];
  var benchmark = options['benchmark'];
  if (stats || benchmark) {
    lintOptions.enableTiming = true;
  }

  lintOptions
    ..packageConfigPath = packageConfigFile
    ..resourceProvider = PhysicalResourceProvider.INSTANCE;

  List<File> filesToLint = [];
  for (var path in options.rest) {
    filesToLint.addAll(collectFiles(path));
  }

  if (benchmark) {
    await writeBenchmarks(outSink, filesToLint, lintOptions);
    return;
  }

  final linter = new DartLinter(lintOptions);

  try {
    final timer = new Stopwatch()..start();
    List<AnalysisErrorInfo> errors = await linter.lintFiles(filesToLint);
    timer.stop();

    if (errors.length > 0) {
      exitCode = _maxSeverity(errors, lintOptions.filter);
    }

    var commonRoot = getRoot(options.rest);

    new ReportFormatter(errors, lintOptions.filter, outSink,
        elapsedMs: timer.elapsedMilliseconds,
        fileCount: linter.numSourcesAnalyzed,
        fileRoot: commonRoot,
        showStatistics: stats,
        machineOutput: options['machine'],
        quiet: options['quiet'])
      ..write();
  } catch (err, stack) {
    errorSink.writeln('''An error occurred while linting
  Please report it at: github.com/dart-lang/linter/issues
$err
$stack''');
  }
}

Iterable<AnalysisError> _filtered(
        List<AnalysisError> errors, LintFilter filter) =>
    (filter == null)
        ? errors
        : errors.where((AnalysisError e) => !filter.filter(e));

int _maxSeverity(List<AnalysisErrorInfo> errors, LintFilter filter) {
  int max = 0;
  for (AnalysisErrorInfo info in errors) {
    _filtered(info.errors, filter).forEach((AnalysisError e) {
      max = math.max(max, e.errorCode.errorSeverity.ordinal);
    });
  }
  return max;
}
