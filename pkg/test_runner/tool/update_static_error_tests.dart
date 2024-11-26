// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regenerates the static error test markers inside static error tests based
/// on the actual errors reported by analyzer and CFE.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
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

/// Maps a set of enabled experiments (stored as a sorted comma-separated list
/// of experiment names) to an [AnalysisContextCollection] for analyzing files
/// with those experiments enabled.
final Map<String, AnalysisContextCollection> _analysisContextCollections = {};

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
  parser.addFlag("only-static-error-tests",
      abbr: "o",
      help: "Skips files that don't already have static error expectations.",
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
  var onlyStaticErrorTests = results["only-static-error-tests"] as bool;

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

  var testFiles =
      _listFiles(results.rest, onlyStaticErrorTests: onlyStaticErrorTests);

  for (var testFile in testFiles) {
    await _processFile(testFiles, testFile,
        dryRun: dryRun,
        includeContext: includeContext,
        remove: removeSources,
        insert: insertSources);
  }

  for (var MapEntry(key: experiments, value: contextCollection)
      in _analysisContextCollections.entries) {
    if (experiments.isEmpty) {
      print('Shutting down analyzer...');
    } else {
      print('Shutting down analyzer for experiments "$experiments"...');
    }

    await contextCollection.dispose();
  }
}

/// Find all of the files that match [pathGlobs], load corresponding [TestFile]s
/// and return all tests that should be updated.
///
/// Omits multitests since those don't support being used as static error tests.
/// Omits any [TestFile] that doesn't already contain a static error test
/// expectation if [onlyStaticErrorTests] is `true`.
List<TestFile> _listFiles(List<String> pathGlobs,
    {required bool onlyStaticErrorTests}) {
  print('Listing files...');
  var testFiles = <TestFile>[];
  for (var pathGlob in pathGlobs) {
    // Allow tests to be specified without the extension for compatibility with
    // the regular test runner syntax.
    if (!pathGlob.endsWith(".dart")) pathGlob += ".dart";

    // Allow tests to be specified either relative to the "tests" directory
    // or relative to the current directory.
    var root = pathGlob.startsWith("tests") ? "." : "tests";

    for (var file in Glob(pathGlob, recursive: true).listSync(root: root)) {
      if (file is! File) continue;

      if (!file.path.endsWith(".dart")) continue;

      // Canonicalize the path in the same way StaticError does, so it matches.
      var f = p.relative(file.path, from: Directory.current.path);
      var testFile = TestFile.read(Path("."), f);

      if (testFile.isMultitest) {
        print("Skip ${testFile.path} since this tool can't update multitests.");
        continue;
      }

      if (onlyStaticErrorTests && testFile.expectedErrors.isEmpty) {
        print("Skip ${testFile.path} since it isn't a static error test.");
        continue;
      }

      testFiles.add(testFile);
    }
  }

  return testFiles;
}

/// Lazily creates an analysis context collection that analyze files with the
/// given set of [experiments].
AnalysisContextCollection _analyzerCollectionForExperiments(
    List<TestFile> testFiles, List<String> experiments) {
  var sorted = experiments.toList()..sort();
  var experimentsKey = sorted.join(',');

  var collection = _analysisContextCollections[experimentsKey];
  if (collection != null) return collection;

  if (experiments.isNotEmpty) {
    print('\nInitializing analyzer for experiments "$experimentsKey"...');
  } else {
    print('\nInitializing analyzer...');
  }

  var paths = [
    for (var testFile in testFiles)
      p.normalize(testFile.path.absolute.toNativePath())
  ];

  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  // If there are experiments, then synthesize an analysis options file in the
  // root directory that enables the experiments for all of the tests.
  if (experiments.isNotEmpty) {
    var options = StringBuffer();
    options.writeln('analyzer:');
    options.writeln('  enable-experiment:');
    for (var experiment in experiments) {
      options.writeln('    - $experiment');
    }

    resourceProvider =
        OverlayResourceProvider(PhysicalResourceProvider.INSTANCE)
          ..setOverlay(
              Path('tests/analysis_options.yaml').absolute.toNativePath(),
              content: options.toString(),
              modificationStamp: 0);
  }

  return _analysisContextCollections[experimentsKey] =
      AnalysisContextCollection(
          includedPaths: paths, resourceProvider: resourceProvider);
}

void _usageError(ArgParser parser, String message) {
  stderr.writeln(message);
  stderr.writeln();
  stderr.writeln(_usage);
  stderr.writeln(parser.usage);
  exit(64);
}

Future<bool> _processFile(List<TestFile> allTestFiles, TestFile testFile,
    {required bool dryRun,
    required bool includeContext,
    required Set<ErrorSource> remove,
    required Set<ErrorSource> insert}) async {
  stdout.write("${testFile.path}...");

  var options = [
    ...testFile.sharedOptions,
    if (testFile.experiments.isNotEmpty)
      "--enable-experiment=${testFile.experiments.join(',')}"
  ];

  var errors = <StaticError>[];
  if (insert.contains(ErrorSource.analyzer)) {
    stdout.write("\r${testFile.path} (Running analyzer...)");
    errors.addAll(await runAnalyzerLibrary(allTestFiles, testFile));
  }

  // If we're inserting web errors, we also need to gather the CFE errors to
  // tell which web errors are web-specific.
  var cfeErrors = <StaticError>[];
  if (insert.contains(ErrorSource.cfe) || insert.contains(ErrorSource.web)) {
    var cfeOptions = [
      if (testFile.requirements.contains(Feature.nnbdWeak)) "--nnbd-weak",
      if (testFile.requirements.contains(Feature.nnbdStrong)) "--nnbd-strong",
      ...options
    ];

    // Clear the previous line.
    stdout.write("\r${testFile.path}                      ");
    stdout.write("\r${testFile.path} (Running CFE...)");
    cfeErrors
        .addAll(await runCfe(File(testFile.path.toNativePath()), cfeOptions));
    if (insert.contains(ErrorSource.cfe)) {
      errors.addAll(cfeErrors);
    }
  }

  if (insert.contains(ErrorSource.web)) {
    // Clear the previous line.
    stdout.write("\r${testFile.path}                      ");
    stdout.write("\r${testFile.path} (Running dart2js...)");
    errors.addAll(await runDart2js(testFile, options, cfeErrors));
  }

  // Error expectations can be in imported or part files: iterate over the set
  // of paths that is the main file path plus all paths mentioned in
  // expectations, updating them.
  for (var path in {testFile.path.toString(), ...errors.map((e) => e.path)}) {
    var file = File(path);
    var pathErrors = errors.where((e) => e.path == path).toList();
    var result = updateErrorExpectations(
        path, file.readAsStringSync(), pathErrors,
        remove: remove, includeContext: includeContext);

    stdout.writeln("\r$path (Updated with ${pathErrors.length} errors)");

    if (dryRun) {
      print(result);
    } else {
      file.writeAsString(result);
    }
  }

  return true;
}

// TODO(rnystrom): This is 100x slower than [runAnalyzerLibrary()]. It's no
// longer used by the static error updater, but convert_multitest.dart still
// uses it.
/// Invoke analyzer on [file] and gather all static errors it reports.
Future<List<StaticError>> runAnalyzerCli(
    File file, List<String> options) async {
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

/// Analyze [testFile] and return the list of reported errors.
///
/// This will lazily created an [AnalysisContextCollection] if this is the first
/// file being analyzed for a given set of experiment flags.
Future<List<StaticError>> runAnalyzerLibrary(
    List<TestFile> allTestFiles, TestFile testFile) async {
  var absolutePath = testFile.path.absolute.toNativePath();

  var context =
      _analyzerCollectionForExperiments(allTestFiles, testFile.experiments)
          .contextFor(absolutePath);
  var errorsResult = await context.currentSession.getErrors(absolutePath);

  // Convert the analyzer errors to test_runner [StaticErrors].
  var errors = <StaticError>[];
  if (errorsResult is ErrorsResult) {
    for (var diagnostic in errorsResult.errors) {
      switch (diagnostic.severity) {
        case Severity.error:
        case Severity.warning
            when AnalyzerError.isValidatedWarning(diagnostic.errorCode.name):
          errors.add(
              _convertAnalysisError(context, errorsResult.path, diagnostic));
        default:
          // Ignore todos and other harmless warnings like unused variables
          // which the tests are riddled with but we don't want to bother
          // validating.
          break;
      }
    }
  }

  return errors;
}

/// Convert an [AnalysisError] from the analyzer package to the test runner's
/// [StaticError] type.
StaticError _convertAnalysisError(AnalysisContext analysisContext,
    String containingFile, AnalysisError error) {
  var fileResult =
      analysisContext.currentSession.getFile(containingFile) as FileResult;
  var errorLocation = fileResult.lineInfo.getLocation(error.offset);

  var staticError = StaticError(ErrorSource.analyzer,
      '${error.errorCode.type.name}.${error.errorCode.name}',
      path: containingFile,
      line: errorLocation.lineNumber,
      column: errorLocation.columnNumber,
      length: error.length);

  for (var context in error.contextMessages) {
    var contextFileResult =
        analysisContext.currentSession.getFile(context.filePath) as FileResult;
    var contextLocation =
        contextFileResult.lineInfo.getLocation(context.offset);

    staticError.contextMessages.add(StaticError(
        ErrorSource.context, context.messageText(includeUrl: true),
        path: context.filePath,
        line: contextLocation.lineNumber,
        column: contextLocation.columnNumber,
        length: context.length));
  }

  return staticError;
}

/// Invoke CFE on [file] and gather all static errors it reports.
Future<List<StaticError>> runCfe(File file, List<String> options) async {
  var absolutePath = file.absolute.path;
  // TODO(rnystrom): Running the CFE command line each time is slow and wastes
  // time generating code, which we don't care about. Import it as a library or
  // at least run it in batch mode.
  var result = await Process.run(_dartPath, [
    "pkg/front_end/tool/compile.dart",
    ...options,
    "--verify",
    "-o",
    "dev:null", // Output is only created for file URIs.
    absolutePath,
  ]);

  // Running the above command may generate a dill file next to the test, which
  // we don't want, so delete it if present.
  var dill = File("$absolutePath.dill");
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

/// Invoke dart2js on [testFile] and gather all static errors it reports.
Future<List<StaticError>> runDart2js(TestFile testFile, List<String> options,
    List<StaticError> cfeErrors) async {
  var result = await Process.run(_dartPath, [
    'compile',
    'js',
    ...options,
    "-o",
    "dev:null", // Output is only created for file URIs.
    testFile.path.absolute.toNativePath(),
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
