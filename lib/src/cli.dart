// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/lint/config.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/io.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart'; // ignore: implementation_imports
import 'package:args/args.dart';

import 'analyzer.dart';
import 'formatter.dart';
import 'rules.dart';

const processFileFailedExitCode = 65;

const unableToProcessExitCode = 64;
String getRoot(List<String> paths) =>
    paths.length == 1 && Directory(paths[0]).existsSync() ? paths[0] : null;

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

/// Start linting from the command-line.
Future run(List<String> args) async {
  await runLinter(args, LinterOptions());
}

Future runLinter(List<String> args, LinterOptions initialLintOptions) async {
  // Force the rule registry to be populated.
  registerLintRules();

  var parser = ArgParser(allowTrailingOptions: true);

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
    ..addMultiOption('rules',
        help: 'A list of lint rules to run. For example: '
            'avoid_as,annotate_overrides')
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

  var lintOptions = initialLintOptions;

  var configFile = options['config'];
  if (configFile is String) {
    var config = LintConfig.parse(readFile(configFile));
    lintOptions.configure(config);
  }

  var lints = options['rules'];
  if (lints is Iterable<String> && lints.isNotEmpty) {
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
  if (customSdk is String) {
    lintOptions.dartSdkPath = customSdk;
  }

  var strongMode = options['strong'];
  if (strongMode is bool) {
    lintOptions.strongMode = strongMode;
  }

  var customPackageRoot = options['package-root'];
  if (customPackageRoot is String) {
    lintOptions.packageRootPath = customPackageRoot;
  }

  var packageConfigFile = options['packages'] as String;

  if (customPackageRoot != null && packageConfigFile != null) {
    errorSink.write("Cannot specify both '--package-root' and '--packages'.");
    exitCode = unableToProcessExitCode;
    return;
  }

  var stats = options['stats'] as bool;
  var benchmark = options['benchmark'] as bool;
  if (stats || benchmark) {
    lintOptions.enableTiming = true;
  }

  lintOptions
    ..packageConfigPath = packageConfigFile
    ..resourceProvider = PhysicalResourceProvider.INSTANCE;

  final filesToLint = <File>[];
  for (var path in options.rest) {
    filesToLint.addAll(collectFiles(path));
  }

  if (benchmark) {
    await writeBenchmarks(outSink, filesToLint, lintOptions);
    return;
  }

  final linter = DartLinter(lintOptions);

  try {
    final timer = Stopwatch()..start();
    final errors = await lintFiles(linter, filesToLint);
    timer.stop();

    var commonRoot = getRoot(options.rest);
    ReportFormatter(errors, lintOptions.filter, outSink,
        elapsedMs: timer.elapsedMilliseconds,
        fileCount: linter.numSourcesAnalyzed,
        fileRoot: commonRoot,
        showStatistics: stats,
        machineOutput: options['machine'] as bool,
        quiet: options['quiet'] as bool)
      ..write();
    // ignore: avoid_catches_without_on_clauses
  } catch (err, stack) {
    errorSink.writeln('''An error occurred while linting
  Please report it at: github.com/dart-lang/linter/issues
$err
$stack''');
  }
}
