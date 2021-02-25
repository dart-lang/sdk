// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regenerates the static error test markers inside static error tests based
/// on the actual errors reported by analyzer and CFE.
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart' as pkg_file;
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import 'package:test_runner/src/command_output.dart';
import 'package:test_runner/src/path.dart';
import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/test_file.dart';
import 'package:test_runner/src/update_errors.dart';

const _usage =
    "Usage: dart update_static_error_tests.dart [flags...] <path glob>";

final _dartPath = _findBinary("dart", "exe");
final _analyzerPath = _findBinary("dartanalyzer", "bat");
final _dart2jsPath = _findBinary("dart2js", "bat");

Future<void> main(List<String> args) async {
  var sources = ErrorSource.all.map((e) => e.marker).toList();

  var parser = ArgParser();

  parser.addFlag("help", abbr: "h");

  parser.addFlag("dry-run",
      abbr: "n",
      help: "Print result but do not overwrite any files.",
      negatable: false);

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

  parser.addSeparator("Other flags:");
  parser.addFlag("null-safety",
      help: "Enable the 'non-nullable' experiment.", negatable: false);

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
  var nullSafety = results["null-safety"] as bool;

  var removeSources = <ErrorSource>{};
  var insertSources = <ErrorSource>{};

  for (var source in results["remove"] as List<String>) {
    removeSources.add(ErrorSource.find(source));
  }

  for (var source in results["insert"] as List<String>) {
    insertSources.add(ErrorSource.find(source));
  }

  for (var source in results["update"] as List<String>) {
    removeSources.add(ErrorSource.find(source));
    insertSources.add(ErrorSource.find(source));
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

  if (results.rest.length != 1) {
    _usageError(
        parser, "Must provide a file path or glob for which tests to update.");
  }

  var result = results.rest.single;

  // Allow tests to be specified without the extension for compatibility with
  // the regular test runner syntax.
  if (!result.endsWith(".dart")) {
    result += ".dart";
  }

  // Allow tests to be specified either relative to the "tests" directory
  // or relative to the current directory.
  var root = result.startsWith("tests") ? "." : "tests";
  var glob = Glob(result, recursive: true);
  for (var entry in glob.listSync(root: root)) {
    if (!entry.path.endsWith(".dart")) continue;

    if (entry is pkg_file.File) {
      await _processFile(entry,
          dryRun: dryRun,
          remove: removeSources,
          insert: insertSources,
          nullSafety: nullSafety);
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

Future<void> _processFile(File file,
    {bool dryRun,
    Set<ErrorSource> remove,
    Set<ErrorSource> insert,
    bool nullSafety}) async {
  stdout.write("${file.path}...");
  var source = file.readAsStringSync();
  var testFile = TestFile.parse(Path("."), file.absolute.path, source);

  var experiments = [
    if (nullSafety) "non-nullable",
    if (testFile.experiments.isNotEmpty) ...testFile.experiments
  ];

  var options = [
    ...testFile.sharedOptions,
    if (experiments.isNotEmpty) "--enable-experiment=${experiments.join(',')}"
  ];

  var errors = <StaticError>[];
  if (insert.contains(ErrorSource.analyzer)) {
    stdout.write("\r${file.path} (Running analyzer...)");
    var fileErrors = await runAnalyzer(file.absolute.path, options);
    if (fileErrors == null) {
      print("Error: failed to update ${file.path}");
    } else {
      errors.addAll(fileErrors);
    }
  }

  // If we're inserting web errors, we also need to gather the CFE errors to
  // tell which web errors are web-specific.
  List<StaticError> cfeErrors;
  if (insert.contains(ErrorSource.cfe) || insert.contains(ErrorSource.web)) {
    // Clear the previous line.
    stdout.write("\r${file.path}                      ");
    stdout.write("\r${file.path} (Running CFE...)");
    cfeErrors = await runCfe(file.absolute.path, options);
    if (cfeErrors == null) {
      print("Error: failed to update ${file.path}");
    } else if (insert.contains(ErrorSource.cfe)) {
      errors.addAll(cfeErrors);
    }
  }

  if (insert.contains(ErrorSource.web)) {
    // Clear the previous line.
    stdout.write("\r${file.path}                      ");
    stdout.write("\r${file.path} (Running dart2js...)");
    var fileErrors = await runDart2js(file.absolute.path, options, cfeErrors);
    if (fileErrors == null) {
      print("Error: failed to update ${file.path}");
    } else {
      errors.addAll(fileErrors);
    }
  }

  errors = StaticError.simplify(errors);

  var result = updateErrorExpectations(source, errors, remove: remove);

  stdout.writeln("\r${file.path} (Updated with ${errors.length} errors)");

  if (dryRun) {
    print(result);
  } else {
    await file.writeAsString(result);
  }
}

/// Invoke analyzer on [path] and gather all static errors it reports.
Future<List<StaticError>> runAnalyzer(String path, List<String> options) async {
  // TODO(rnystrom): Running the analyzer command line each time is very slow.
  // Either import the analyzer as a library, or at least invoke it in a batch
  // mode.
  var result = await Process.run(_analyzerPath, [
    ...options,
    "--format=machine",
    path,
  ]);

  // Analyzer returns 3 when it detects errors, 2 when it detects
  // warnings and --fatal-warnings is enabled, 1 when it detects
  // hints and --fatal-hints or --fatal-infos are enabled.
  if (result.exitCode < 0 || result.exitCode > 3) {
    print("Analyzer run failed: ${result.stdout}\n${result.stderr}");
    return null;
  }

  var errors = <StaticError>[];
  var warnings = <StaticError>[];
  AnalysisCommandOutput.parseErrors(result.stderr as String, errors, warnings);
  return [...errors, ...warnings];
}

/// Invoke CFE on [path] and gather all static errors it reports.
Future<List<StaticError>> runCfe(String path, List<String> options) async {
  // TODO(rnystrom): Running the CFE command line each time is slow and wastes
  // time generating code, which we don't care about. Import it as a library or
  // at least run it in batch mode.
  var result = await Process.run(_dartPath, [
    "pkg/front_end/tool/_fasta/compile.dart",
    ...options,
    "--verify",
    "-o",
    "dev:null", // Output is only created for file URIs.
    path,
  ]);

  // Running the above command may generate a dill file next to the test, which
  // we don't want, so delete it if present.
  var file = File("$path.dill");
  if (await file.exists()) {
    await file.delete();
  }
  if (result.exitCode != 0) {
    print("CFE run failed: ${result.stdout}\n${result.stderr}");
    return null;
  }
  var errors = <StaticError>[];
  var warnings = <StaticError>[];
  FastaCommandOutput.parseErrors(result.stdout as String, errors, warnings);
  return [...errors, ...warnings];
}

/// Invoke dart2js on [path] and gather all static errors it reports.
Future<List<StaticError>> runDart2js(
    String path, List<String> options, List<StaticError> cfeErrors) async {
  var result = await Process.run(_dart2jsPath, [
    ...options,
    "-o",
    "dev:null", // Output is only created for file URIs.
    path,
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
          dart2jsError.errorFor(ErrorSource.web) ==
              cfeError.errorFor(ErrorSource.cfe);
    });
  });

  return errors;
}

/// Find the most recently-built binary [name] in any of the build directories.
String _findBinary(String name, String windowsExtension) {
  var binary = Platform.isWindows ? "$name.$windowsExtension" : name;

  String newestPath;
  DateTime newestTime;

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
