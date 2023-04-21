// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regenerates the static error test markers inside static error tests based
/// on the actual errors reported by analyzer and CFE.
import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:test_runner/src/command_output.dart';
import 'package:test_runner/src/feature.dart' show Feature;
import 'package:test_runner/src/path.dart';
import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/test_file.dart';
import 'package:test_runner/src/update_errors.dart';

const _usage =
    "Usage: dart update_static_error_tests.dart [flags...] <path glob>";

final _dartPath = _findBinary("dart", "exe");
final _analyzerPath = p.join('pkg', 'analyzer_cli', 'bin', 'analyzer.dart');

Future<void> main(List<String> args) async {
  var sources = ErrorSource.all.map((e) => e.marker).toList();

  var parser = ArgParser();

  parser.addFlag("help", abbr: "h");

  parser.addFlag("dry-run",
      abbr: "n",
      help: "Print result but do not overwrite any files.",
      negatable: false);
  parser.addFlag("context",
      abbr: "c", help: "Include context messages in output.");

  parser.addSeparator("What operations to perform:");
  parser.addFlag("remove-all",
      abbr: "r",
      help: "Remove all existing error expectations.",
      negatable: false);
  parser.addMultiOption("remove",
      help: "Remove error expectations for given front ends.",
      allowed: sources);
  parser.addFlag("insert-all",
      abbr: "i",
      help: "Insert error expectations for all front ends.",
      negatable: false);
  parser.addMultiOption("insert",
      help: "Insert error expectations from given front ends.",
      allowed: sources);
  parser.addFlag("update-all",
      abbr: "u",
      help: "Replace error expectations for all front ends.",
      negatable: false);
  parser.addMultiOption("update",
      help: "Update error expectations for given front ends.",
      allowed: sources);

  var results = parser.parse(args);

  if (results["help"] as bool) {
    print("Regenerates the test markers inside static error tests.");
    print("");
    print(_usage);
    print("");
    print(parser.usage);
    exit(0);
  }

  var dryRun = results["dry-run"] as bool;

  var includeContext = results["context"] as bool;

  var removeSources = <ErrorSource>{};
  var insertSources = <ErrorSource>{};

  for (var source in results["remove"] as List<String>) {
    removeSources.add(ErrorSource.find(source)!);
  }

  for (var source in results["insert"] as List<String>) {
    insertSources.add(ErrorSource.find(source)!);
  }

  for (var source in results["update"] as List<String>) {
    removeSources.add(ErrorSource.find(source)!);
    insertSources.add(ErrorSource.find(source)!);
  }

  if (results["remove-all"] as bool) {
    removeSources.addAll(ErrorSource.all);
  }

  if (results["insert-all"] as bool) {
    insertSources.addAll(ErrorSource.all);
  }

  if (results["update-all"] as bool) {
    removeSources.addAll(ErrorSource.all);
    insertSources.addAll(ErrorSource.all);
  }

  if (removeSources.isEmpty && insertSources.isEmpty) {
    _usageError(
        parser, "Must provide at least one flag for an operation to perform.");
  }

  var processedFiles = 0;
  var skippedMultitests = <String>[];

  for (var result in results.rest) {
    // Allow tests to be specified without the extension for compatibility with
    // the regular test runner syntax.
    if (!result.endsWith(".dart")) {
      result += ".dart";
    }

    // Allow tests to be specified either relative to the "tests" directory
    // or relative to the current directory.
    var root = result.startsWith("tests") ? "." : "tests";
    var glob = Glob(result, recursive: true);
    for (var entry in glob
        .listSync(root: root)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))) {
      var processed = await _processFile(
        entry,
        dryRun: dryRun,
        includeContext: includeContext,
        remove: removeSources,
        insert: insertSources,
      );

      if (processed) {
        processedFiles++;
      } else {
        skippedMultitests.add(entry.path);
      }
    }
  }

  if (skippedMultitests.isNotEmpty) {
    // If no files were successfully processed, then the user is only pointing
    // it at multitests and made a mistake.
    if (processedFiles == 0) {
      stderr.writeln("Error: This tool doesn't support updating static errors "
          "in multitests. Couldn't update:");
    } else {
      stderr.writeln("Did not update the following multitests:");
    }

    for (var multitest in skippedMultitests) {
      stderr.writeln(p.normalize(multitest));
    }
  }
}

void _usageError(ArgParser parser, String message) {
  stderr.writeln(message);
  stderr.writeln();
  stderr.writeln(_usage);
  stderr.writeln(parser.usage);
  exit(64);
}

Future<bool> _processFile(File file,
    {required bool dryRun,
    required bool includeContext,
    required Set<ErrorSource> remove,
    required Set<ErrorSource> insert}) async {
  var source = file.readAsStringSync();
  var testFile = TestFile.parse(Path("."), file.absolute.path, source);

  // Don't process multitests. The multitest file isn't necessarily a valid or
  // meaningful Dart file that can be processed by front ends. To process them,
  // we'd have to split the multitest, run each separate file on the front ends,
  // and then try to merge the results back together.
  //
  // In practice, a test should either be a multitest or a static error test,
  // but not both.
  if (testFile.isMultitest) return false;

  stdout.write("${file.path}...");

  var experiments = [
    if (testFile.experiments.isNotEmpty) ...testFile.experiments
  ];

  var options = [
    ...testFile.sharedOptions,
    if (experiments.isNotEmpty) "--enable-experiment=${experiments.join(',')}"
  ];

  var errors = <StaticError>[];
  if (insert.contains(ErrorSource.analyzer)) {
    stdout.write("\r${file.path} (Running analyzer...)");
    errors.addAll(await runAnalyzer(file, options));
  }

  // If we're inserting web errors, we also need to gather the CFE errors to
  // tell which web errors are web-specific.
  final cfeErrors = <StaticError>[];
  if (insert.contains(ErrorSource.cfe) || insert.contains(ErrorSource.web)) {
    var cfeOptions = [
      if (testFile.requirements.contains(Feature.nnbdWeak)) "--nnbd-weak",
      if (testFile.requirements.contains(Feature.nnbdStrong)) "--nnbd-strong",
      ...options
    ];
    // Clear the previous line.
    stdout.write("\r${file.path}                      ");
    stdout.write("\r${file.path} (Running CFE...)");
    cfeErrors.addAll(await runCfe(file, cfeOptions));
    if (insert.contains(ErrorSource.cfe)) {
      errors.addAll(cfeErrors);
    }
  }

  if (insert.contains(ErrorSource.web)) {
    // Clear the previous line.
    stdout.write("\r${file.path}                      ");
    stdout.write("\r${file.path} (Running dart2js...)");
    errors.addAll(await runDart2js(file, options, cfeErrors));
  }

  var result = updateErrorExpectations(source, errors,
      remove: remove, includeContext: includeContext);

  stdout.writeln("\r${file.path} (Updated with ${errors.length} errors)");

  if (dryRun) {
    print(result);
  } else {
    await file.writeAsString(result);
  }

  return true;
}

/// Invoke analyzer on [file] and gather all static errors it reports.
Future<List<StaticError>> runAnalyzer(File file, List<String> options) async {
  // TODO(rnystrom): Running the analyzer command line each time is very slow.
  // Either import the analyzer as a library, or at least invoke it in a batch
  // mode.
  var result = await Process.run(_dartPath, [
    _analyzerPath,
    ...options,
    "--format=json",
    file.absolute.path,
  ]);

  // Analyzer returns 3 when it detects errors, 2 when it detects
  // warnings and --fatal-warnings is enabled, 1 when it detects
  // hints and --fatal-hints or --fatal-infos are enabled.
  if (result.exitCode < 0 || result.exitCode > 3) {
    print("Analyzer run failed: ${result.stdout}\n${result.stderr}");
    print("Error: failed to update ${file.path}");
    return const [];
  }

  var errors = <StaticError>[];
  var warnings = <StaticError>[];
  AnalysisCommandOutput.parseErrors(result.stdout as String, errors, warnings);
  return [...errors, ...warnings];
}

/// Invoke CFE on [file] and gather all static errors it reports.
Future<List<StaticError>> runCfe(File file, List<String> options) async {
  // TODO(rnystrom): Running the CFE command line each time is slow and wastes
  // time generating code, which we don't care about. Import it as a library or
  // at least run it in batch mode.
  var result = await Process.run(_dartPath, [
    "pkg/front_end/tool/_fasta/compile.dart",
    ...options,
    "--verify",
    "-o",
    "dev:null", // Output is only created for file URIs.
    file.absolute.path,
  ]);

  // Running the above command may generate a dill file next to the test, which
  // we don't want, so delete it if present.
  var dill = File("${file.absolute.path}.dill");
  if (await dill.exists()) {
    await dill.delete();
  }
  if (result.exitCode != 0) {
    print("CFE run failed: ${result.stdout}\n${result.stderr}");
    print("Error: failed to update ${file.path}");
    return const [];
  }
  var errors = <StaticError>[];
  var warnings = <StaticError>[];
  FastaCommandOutput.parseErrors(result.stdout as String, errors, warnings);
  return [...errors, ...warnings];
}

/// Invoke dart2js on [file] and gather all static errors it reports.
Future<List<StaticError>> runDart2js(
    File file, List<String> options, List<StaticError> cfeErrors) async {
  var result = await Process.run(_dartPath, [
    'compile',
    'js',
    ...options,
    "-o",
    "dev:null", // Output is only created for file URIs.
    file.absolute.path,
  ]);

  var errors = <StaticError>[];
  Dart2jsCompilerCommandOutput.parseErrors(result.stdout as String, errors);

  // We only want the web-specific errors from dart2js, so filter out any errors
  // that are also reported by the CFE.
  errors.removeWhere((dart2jsError) {
    return cfeErrors.any((cfeError) {
      return dart2jsError.line == cfeError.line &&
          dart2jsError.column == cfeError.column &&
          dart2jsError.length == cfeError.length &&
          dart2jsError.message == cfeError.message;
    });
  });

  return errors;
}

/// Find the most recently-built binary [name] in any of the build directories.
String _findBinary(String name, String windowsExtension) {
  var binary = Platform.isWindows ? "$name.$windowsExtension" : name;

  String? newestPath;
  DateTime? newestTime;

  var buildDirectory = Directory(Platform.isMacOS ? "xcodebuild" : "out");
  if (buildDirectory.existsSync()) {
    for (var config in buildDirectory.listSync()) {
      var path = p.join(config.path, "dart-sdk", "bin", binary);
      var file = File(path);
      if (!file.existsSync()) continue;
      var modified = file.lastModifiedSync();

      if (newestTime == null || modified.isAfter(newestTime)) {
        newestPath = path;
        newestTime = modified;
      }
    }
  }

  if (newestPath == null) {
    // Clear the current line since we're in the middle of a progress line.
    print("");
    print("Could not find a built SDK with a $binary to run.");
    print("Make sure to build the Dart SDK before running this tool.");
    exit(1);
  }

  return newestPath;
}
