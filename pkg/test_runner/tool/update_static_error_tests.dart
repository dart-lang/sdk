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
import 'package:collection/collection.dart';
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

final dartPath = _findBinary("dart", "exe");

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

  var analyzerErrors = const <TestFile, List<StaticError>>{};
  var cfeErrors = const <TestFile, List<StaticError>>{};
  var webErrors = const <TestFile, List<StaticError>>{};

  if (insertSources.contains(ErrorSource.analyzer)) {
    analyzerErrors = await _runAnalyzer(testFiles);
  }

  // If we're inserting web errors, we also need to gather the CFE errors to
  // tell which web errors are web-specific.
  if (insertSources.contains(ErrorSource.cfe) ||
      insertSources.contains(ErrorSource.web)) {
    cfeErrors = await _runCfe(testFiles);
  }

  if (insertSources.contains(ErrorSource.web)) {
    webErrors = await _runDart2js(testFiles, cfeErrors);
  }

  print('Updating test files...');
  for (var testFile in testFiles) {
    _updateErrors(
        testFile,
        [
          if (insertSources.contains(ErrorSource.analyzer))
            ...?analyzerErrors[testFile],
          if (insertSources.contains(ErrorSource.cfe)) ...?cfeErrors[testFile],
          if (insertSources.contains(ErrorSource.web)) ...?webErrors[testFile],
        ],
        remove: removeSources,
        includeContext: includeContext,
        dryRun: dryRun);
  }
}

List<String> _testFileOptions(TestFile testFile, {bool cfe = false}) {
  return [
    ...testFile.sharedOptions,
    if (testFile.experiments.isNotEmpty)
      "--enable-experiment=${testFile.experiments.join(',')}",
    if (cfe) ...[
      if (testFile.requirements.contains(Feature.nnbdWeak)) "--nnbd-weak",
      if (testFile.requirements.contains(Feature.nnbdStrong)) "--nnbd-strong",
    ]
  ];
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

void _usageError(ArgParser parser, String message) {
  stderr.writeln(message);
  stderr.writeln();
  stderr.writeln(_usage);
  stderr.writeln(parser.usage);
  exit(64);
}

/// Run analyzer on [allTestFiles] and return the errors for each file.
Future<Map<TestFile, List<StaticError>>> _runAnalyzer(
    List<TestFile> allTestFiles) async {
  // For performance, we want to analyze multiple tests using the same analysis
  // context collection. But a context collection only works with a single set
  // of experiment flags, so group the tests by their experiments.
  var testsByExperiments =
      EqualityMap<List<String>, List<TestFile>>(const ListEquality());
  for (var testFile in allTestFiles) {
    var experiments = testFile.experiments.toList()..sort();
    testsByExperiments.putIfAbsent(experiments, () => []).add(testFile);
  }

  var errors = <TestFile, List<StaticError>>{};
  for (var experiments in testsByExperiments.keys) {
    var testFiles = testsByExperiments[experiments]!;

    ResourceProvider resourceProvider;
    if (experiments.isEmpty) {
      print('Running analyzer on ${_plural(testFiles, 'file')}...');
      resourceProvider = PhysicalResourceProvider.INSTANCE;
    } else {
      print('Running analyzer on ${_plural(testFiles, 'file')} '
          'with experiments "${experiments.join(', ')}"...');

      // If there are experiments, then synthesize an analysis options file in the
      // root directory that enables the experiments for all of the tests.
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

    var paths = [
      for (var testFile in testFiles)
        p.normalize(testFile.path.absolute.toNativePath())
    ];

    var contextCollection = AnalysisContextCollection(
        includedPaths: paths, resourceProvider: resourceProvider);

    for (var testFile in testFiles) {
      errors[testFile] = await _runAnalyzerOnFile(contextCollection, testFile);
    }

    await contextCollection.dispose();
  }

  return errors;
}

/// Analyze [testFile] using [contextCollection] and return the list of reported
/// errors.
Future<List<StaticError>> _runAnalyzerOnFile(
    AnalysisContextCollection contextCollection, TestFile testFile) async {
  var absolutePath = testFile.path.absolute.toNativePath();

  var context = contextCollection.contextFor(absolutePath);
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

/// Invoke CFE on all [allTestFiles] and gather the static errors it reports.
Future<Map<TestFile, List<StaticError>>> _runCfe(
    List<TestFile> allTestFiles) async {
  // For performance, we want to run CFE on batches of files, but we can't use
  // the same invocation for files with different options, so group by options
  // first.
  var testsByOptions =
      EqualityMap<List<String>, List<TestFile>>(const ListEquality());
  for (var testFile in allTestFiles) {
    var options = _testFileOptions(testFile, cfe: true)..sort();
    testsByOptions.putIfAbsent(options, () => []).add(testFile);
  }

  var errors = <TestFile, List<StaticError>>{};

  for (var options in testsByOptions.keys) {
    var testFiles = testsByOptions[options]!;

    if (options.isEmpty) {
      print('Running CFE on ${_plural(testFiles, 'file')}...');
    } else {
      print('Running CFE on ${_plural(testFiles, 'file')} '
          'with options "${options.join(', ')}"...');
    }

    var absolutePaths = [
      for (var testFile in testFiles)
        File(testFile.path.toNativePath()).absolute.path,
    ];

    var result = await Process.run(dartPath, [
      'pkg/front_end/tool/compile.dart',
      ...options,
      '--packages=.dart_tool/package_config.json',
      '--verify',
      '-o',
      'dev:null', // Output is only created for file URIs.
      ...absolutePaths,
    ]);

    // Running the above command may generate dill files next to the tests,
    // which we don't want, so delete them if present.
    for (var absolutePath in absolutePaths) {
      var dill = File("$absolutePath.dill");
      if (await dill.exists()) {
        await dill.delete();
      }
    }

    if (result.exitCode != 0) {
      print("CFE run failed: ${result.stdout}\n${result.stderr}");
      exit(1);
    }

    var parsedErrors = <StaticError>[];
    FastaCommandOutput.parseErrors(
        result.stdout as String, parsedErrors, parsedErrors);
    for (var error in parsedErrors) {
      var testFile =
          testFiles.firstWhere((test) => test.path.toString() == error.path);
      errors.putIfAbsent(testFile, () => []).add(error);
    }
  }

  return errors;
}

Future<Map<TestFile, List<StaticError>>> _runDart2js(List<TestFile> testFiles,
    Map<TestFile, List<StaticError>> cfeErrors) async {
  var errors = <TestFile, List<StaticError>>{};
  for (var testFile in testFiles) {
    print('Running dart2js on ${testFile.path}...');
    errors[testFile] = await _runDart2jsOnFile(
        testFile, cfeErrors[testFile] ?? const <StaticError>[]);
  }

  return errors;
}

/// Invoke dart2js on [testFile] and gather all static errors it reports.
Future<List<StaticError>> _runDart2jsOnFile(
    TestFile testFile, List<StaticError> cfeErrors) async {
  var result = await Process.run(dartPath, [
    'compile',
    'js',
    ..._testFileOptions(testFile),
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

/// Update the static error expectations in [testFile].
///
/// Adds [errors] to the file and removes any existing errors that are in from
/// the sources in [remove].
///
/// If [includeContext] is `true`, then includes context messages in the
/// resulting test. If [dryRun] is `false`, then writes the result to disk.
/// Otherwise, prints the resulting test file.
void _updateErrors(TestFile testFile, List<StaticError> errors,
    {required Set<ErrorSource> remove,
    required bool includeContext,
    required bool dryRun}) {
  // Error expectations can be in imported libraries or part files. Iterate
  // over the set of paths that is the main file path plus all paths mentioned
  // in expectations, updating them.
  var paths = {testFile.path.toString(), for (var error in errors) error.path};

  for (var path in paths) {
    var file = File(path);
    var pathErrors = errors.where((e) => e.path == path).toList();
    var result = updateErrorExpectations(
        path, file.readAsStringSync(), pathErrors,
        remove: remove, includeContext: includeContext);

    if (dryRun) {
      print(result);
    } else {
      file.writeAsString(result);
      print('- $path (${_plural(pathErrors, 'error')})');
    }
  }
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

/// Returns a string with the number of [things] followed by [noun], pluralized
/// as needed.
String _plural(List<Object?> things, String noun) {
  if (things.length == 1) return '1 $noun';
  return '${things.length} ${noun}s';
}
