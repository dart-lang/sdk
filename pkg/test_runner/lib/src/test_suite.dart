// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes and methods for enumerating and preparing tests.
///
/// This library includes:
///
/// - Creating tests by listing all the Dart files in certain directories,
///   and creating [TestCase]s for those files that meet the relevant criteria.
/// - Preparing tests, including copying files and frameworks to temporary
///   directories, and computing the command line and arguments to be run.
import 'dart:async';
import 'dart:io';
import 'dart:math';

import "package:status_file/expectation.dart";

import 'browser.dart';
import 'command.dart';
import 'configuration.dart';
import 'expectation_set.dart';
import 'multitest.dart';
import 'path.dart';
import 'repository.dart';
import 'summary_report.dart';
import 'test_case.dart';
import 'test_configurations.dart';
import 'test_file.dart';
import 'testing_servers.dart';
import 'utils.dart';

typedef TestCaseEvent = void Function(TestCase testCase);

/// A simple function that tests [arg] and returns `true` or `false`.
typedef Predicate<T> = bool Function(T arg);

typedef CreateTest = void Function(Path filePath, Path originTestPath,
    {bool hasSyntaxError,
    bool hasCompileError,
    bool hasRuntimeError,
    bool hasStaticWarning,
    String multitestKey});

typedef VoidFunction = void Function();

/// Calls [function] asynchronously. Returns a future that completes with the
/// result of the function. If the function is `null`, returns a future that
/// completes immediately with `null`.
Future asynchronously<T>(T function()) {
  if (function == null) return Future<T>.value(null);

  var completer = Completer<T>();
  Timer.run(() => completer.complete(function()));

  return completer.future;
}

/// A completer that waits until all added [Future]s complete.
// TODO(rnystrom): Copied from web_components. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup {
  static const _finished = -1;
  int _pending = 0;
  final Completer<List> _completer = Completer();
  final List<Future> futures = [];
  bool wasCompleted = false;

  /// Wait for [task] to complete (assuming this barrier has not already been
  /// marked as completed, otherwise you'll get an exception indicating that a
  /// future has already been completed).
  void add(Future task) {
    if (_pending == _finished) {
      throw Exception("FutureFutureAlreadyCompleteException");
    }
    _pending++;
    var handledTaskFuture = task.catchError((e, StackTrace s) {
      if (!wasCompleted) {
        _completer.completeError(e, s);
        wasCompleted = true;
      }
    }).then((_) {
      _pending--;
      if (_pending == 0) {
        _pending = _finished;
        if (!wasCompleted) {
          _completer.complete(futures);
          wasCompleted = true;
        }
      }
    });
    futures.add(handledTaskFuture);
  }

  Future<List> get future => _completer.future;
}

/// A TestSuite represents a collection of tests.  It creates a [TestCase]
/// object for each test to be run, and passes the test cases to a callback.
///
/// Most TestSuites represent a directory or directory tree containing tests,
/// and a status file containing the expected results when these tests are run.
abstract class TestSuite {
  final TestConfiguration configuration;
  final String suiteName;
  final List<String> statusFilePaths;

  /// This function is set by subclasses before enqueueing starts.
  Function doTest;
  Map<String, String> _environmentOverrides;

  TestSuite(this.configuration, this.suiteName, this.statusFilePaths) {
    _environmentOverrides = {
      'DART_CONFIGURATION': configuration.configurationDirectory,
    };
    if (Platform.isWindows) {
      _environmentOverrides['DART_SUPPRESS_WER'] = '1';
      if (configuration.copyCoreDumps) {
        _environmentOverrides['DART_CRASHPAD_HANDLER'] =
            Path(buildDir + '/crashpad_handler.exe').absolute.toNativePath();
      }
    }
  }

  Map<String, String> get environmentOverrides => _environmentOverrides;

  /// The output directory for this suite's configuration.
  String get buildDir => configuration.buildDirectory;

  /// The path to the compiler for this suite's configuration. Returns `null` if
  /// no compiler should be used.
  String get compilerPath {
    var compilerConfiguration = configuration.compilerConfiguration;
    if (!compilerConfiguration.hasCompiler) return null;
    var name = compilerConfiguration.computeCompilerPath();

    // TODO(ahe): Only validate this once, in test_options.dart.
    TestUtils.ensureExists(name, configuration);
    return name;
  }

  /// Call the callback function onTest with a [TestCase] argument for each
  /// test in the suite.  When all tests have been processed, call [onDone].
  ///
  /// The [testCache] argument provides a persistent store that can be used to
  /// cache information about the test suite, so that directories do not need
  /// to be listed each time.
  Future forEachTest(
      TestCaseEvent onTest, Map<String, List<TestFile>> testCache,
      [VoidFunction onDone]);

  /// This function is called for every TestCase of this test suite. It:
  ///
  /// - Handles sharding.
  /// - Updates [SummaryReport].
  /// - Handle skip markers.
  /// - Tests if the selector matches.
  ///
  /// and enqueue the test if necessary.
  void enqueueNewTestCase(TestFile testFile, String fullName,
      List<Command> commands, Set<Expectation> expectations) {
    var displayName = '$suiteName/$fullName';

    // If the test is not going to be run at all, then a RuntimeError,
    // MissingRuntimeError or Timeout will never occur.
    // Instead, treat that as Pass.
    if (configuration.runtime == Runtime.none) {
      expectations = expectations.toSet();
      expectations.remove(Expectation.runtimeError);
      expectations.remove(Expectation.ok);
      expectations.remove(Expectation.missingRuntimeError);
      expectations.remove(Expectation.timeout);
      if (expectations.isEmpty) expectations.add(Expectation.pass);
    }

    var negative = testFile != null && isNegative(testFile);
    var testCase = TestCase(displayName, commands, configuration, expectations,
        testFile: testFile);
    if (negative &&
        configuration.runtimeConfiguration.shouldSkipNegativeTests) {
      return;
    }

    // Handle sharding based on the original test path (i.e. all multitests
    // of a given original test belong to the same shard)
    if (configuration.shardCount > 1 &&
        testCase.hash % configuration.shardCount != configuration.shard - 1) {
      return;
    }

    // Test if the selector includes this test.
    var pattern = configuration.selectors[suiteName];
    if (!pattern.hasMatch(displayName)) {
      return;
    }
    if (configuration.testList != null &&
        !configuration.testList.contains(displayName)) {
      return;
    }

    if (configuration.hotReload || configuration.hotReloadRollback) {
      // Handle reload special cases.
      if (expectations.contains(Expectation.compileTimeError) ||
          testCase.hasCompileError) {
        // Running a test that expects a compilation error with hot reloading
        // is redundant with a regular run of the test.
        return;
      }
    }

    // Update Summary report.
    if (configuration.printReport) {
      summaryReport.add(testCase);
    }

    // Handle skipped tests.
    if (expectations.contains(Expectation.skip) ||
        expectations.contains(Expectation.skipByDesign) ||
        expectations.contains(Expectation.skipSlow)) {
      return;
    }

    if (configuration.fastTestsOnly &&
        (expectations.contains(Expectation.slow) ||
            expectations.contains(Expectation.skipSlow) ||
            expectations.contains(Expectation.timeout) ||
            expectations.contains(Expectation.dartkTimeout))) {
      return;
    }

    doTest(testCase);
  }

  bool isNegative(TestFile testFile) =>
      testFile.hasCompileError ||
      testFile.hasRuntimeError && configuration.runtime != Runtime.none;

  String createGeneratedTestDirectoryHelper(
      String name, String dirname, Path testPath) {
    Path relative = testPath.relativeTo(Repository.dir);
    relative = relative.directoryPath.append(relative.filenameWithoutExtension);
    String testUniqueName = TestUtils.getShortName(relative.toString());

    Path generatedTestPath = Path(buildDir)
        .append('generated_$name')
        .append(dirname)
        .append(testUniqueName);

    TestUtils.mkdirRecursive(Path('.'), generatedTestPath);
    return File(generatedTestPath.toNativePath())
        .absolute
        .path
        .replaceAll('\\', '/');
  }

  /// Create a directories for generated assets (tests, html files,
  /// pubspec checkouts ...).
  String createOutputDirectory(Path testPath) {
    var checked = configuration.isChecked ? '-checked' : '';
    var legacy = configuration.noPreviewDart2 ? '-legacy' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}-${configuration.runtime.name}"
        "$checked$legacy$minified$sdk";
    return createGeneratedTestDirectoryHelper("tests", dirName, testPath);
  }

  String createCompilationOutputDirectory(Path testPath) {
    var checked = configuration.isChecked ? '-checked' : '';
    var legacy = configuration.noPreviewDart2 ? '-legacy' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var csp = configuration.isCsp ? '-csp' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}"
        "$checked$legacy$minified$csp$sdk";
    return createGeneratedTestDirectoryHelper(
        "compilations", dirName, testPath);
  }

  String createPubspecCheckoutDirectory(Path directoryOfPubspecYaml) {
    var sdk = configuration.useSdk ? 'sdk' : '';
    return createGeneratedTestDirectoryHelper(
        "pubspec_checkouts", sdk, directoryOfPubspecYaml);
  }

  String createPubPackageBuildsDirectory(Path directoryOfPubspecYaml) {
    return createGeneratedTestDirectoryHelper(
        "pub_package_builds", 'public_packages', directoryOfPubspecYaml);
  }
}

/// A specialized [TestSuite] that runs tests written in C to unit test
/// the Dart virtual machine and its API.
///
/// The tests are compiled into a monolithic executable by the build step.
/// The executable lists its tests when run with the --list command line flag.
/// Individual tests are run by specifying them on the command line.
class VMTestSuite extends TestSuite {
  String targetRunnerPath;
  String hostRunnerPath;
  final String dartDir;

  VMTestSuite(TestConfiguration configuration)
      : dartDir = Repository.dir.toNativePath(),
        super(configuration, "vm", ["runtime/tests/vm/vm.status"]) {
    var binarySuffix = Platform.operatingSystem == 'windows' ? '.exe' : '';

    // For running the tests we use the given '$runnerName' binary
    targetRunnerPath = '$buildDir/run_vm_tests$binarySuffix';

    // For listing the tests we use the '$runnerName.host' binary if it exists
    // and use '$runnerName' if it doesn't.
    var hostBinary = '$targetRunnerPath.host$binarySuffix';
    if (File(hostBinary).existsSync()) {
      hostRunnerPath = hostBinary;
    } else {
      hostRunnerPath = targetRunnerPath;
    }
  }

  Future<Null> forEachTest(TestCaseEvent onTest, Map testCache,
      [VoidFunction onDone]) async {
    doTest = onTest;

    var statusFiles =
        statusFilePaths.map((statusFile) => "$dartDir/$statusFile").toList();
    var expectations = ExpectationSet.read(statusFiles, configuration);

    try {
      for (VMUnitTest test in await _listTests(hostRunnerPath)) {
        _addTest(expectations, test);
      }

      doTest = null;
      if (onDone != null) onDone();
    } catch (error, s) {
      print("Fatal error occured: $error");
      print(s);
      exit(1);
    }
  }

  void _addTest(ExpectationSet testExpectations, VMUnitTest test) {
    var fullName = 'cc/${test.name}';
    var expectations = testExpectations.expectations(fullName);

    // Get the expectation from the cc/ test itself.
    var testExpectation = Expectation.find(test.expectation);

    // Update the legacy status-file based expectations to include
    // [testExpectation].
    if (testExpectation != Expectation.pass) {
      expectations = Set<Expectation>.from(expectations)..add(testExpectation);
      expectations.removeWhere((e) => e == Expectation.pass);
    }

    // Update the new workflow based expectations to include [testExpectation].
    var testFile = TestFile.vmUnitTest(
        hasSyntaxError: false,
        hasCompileError: testExpectation == Expectation.compileTimeError,
        hasRuntimeError: testExpectation == Expectation.runtimeError,
        hasStaticWarning: false,
        hasCrash: testExpectation == Expectation.crash);

    var args = configuration.standardOptions.toList();
    if (configuration.compilerConfiguration.previewDart2) {
      var filename = configuration.architecture == Architecture.x64
          ? '$buildDir/gen/kernel-service.dart.snapshot'
          : '$buildDir/gen/kernel_service.dill';
      var dfePath = Path(filename).absolute.toNativePath();
      // '--dfe' has to be the first argument for run_vm_test to pick it up.
      args.insert(0, '--dfe=$dfePath');
      args.addAll(configuration.vmOptions);
    }
    if (expectations.contains(Expectation.crash)) {
      args.insert(0, '--suppress-core-dump');
    }

    args.add(test.name);

    var command = Command.process(
        'run_vm_unittest', targetRunnerPath, args, environmentOverrides);
    enqueueNewTestCase(testFile, fullName, [command], expectations);
  }

  Future<Iterable<VMUnitTest>> _listTests(String runnerPath) async {
    var result = await Process.run(runnerPath, ["--list"]);
    if (result.exitCode != 0) {
      throw "Failed to list tests: '$runnerPath --list'. "
          "Process exited with ${result.exitCode}";
    }

    return (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((name) => name.isNotEmpty)
        .map((String line) {
      final parts = line.split(' ');
      return VMUnitTest(parts[0].trim(), parts.skip(1).single);
    });
  }
}

class VMUnitTest {
  final String name;
  final String expectation;

  VMUnitTest(this.name, this.expectation);
}

/// A standard [TestSuite] implementation that searches for tests in a
/// directory, and creates [TestCase]s that compile and/or run them.
class StandardTestSuite extends TestSuite {
  final Path suiteDir;
  ExpectationSet testExpectations;
  List<TestFile> cachedTests;
  final Path dartDir;
  final bool listRecursively;
  final List<String> extraVmOptions;
  List<Uri> _dart2JsBootstrapDependencies;
  Set<String> _testListPossibleFilenames;
  RegExp _selectorFilenameRegExp;

  StandardTestSuite(TestConfiguration configuration, String suiteName,
      Path suiteDirectory, List<String> statusFilePaths,
      {bool recursive = false})
      : dartDir = Repository.dir,
        listRecursively = recursive,
        suiteDir = Repository.dir.join(suiteDirectory),
        extraVmOptions = configuration.vmOptions,
        super(configuration, suiteName, statusFilePaths) {
    // Initialize _dart2JsBootstrapDependencies.
    if (!configuration.useSdk) {
      _dart2JsBootstrapDependencies = [];
    } else {
      _dart2JsBootstrapDependencies = [
        Uri.base
            .resolveUri(Uri.directory(buildDir))
            .resolve('dart-sdk/bin/snapshots/dart2js.dart.snapshot')
      ];
    }

    // Initialize _testListPossibleFilenames.
    if (configuration.testList != null) {
      _testListPossibleFilenames = <String>{};
      for (String s in configuration.testList) {
        if (s.startsWith("$suiteName/")) {
          s = s.substring(s.indexOf('/') + 1);
          _testListPossibleFilenames
              .add(suiteDir.append('$s.dart').toNativePath());
          // If the test is a multitest, the filename doesn't include the label.
          // Also if it has multiple VMOptions.  If both, remove two labels.
          for (var i = 0; i < 2; i++) {
            // Twice.
            if (s.lastIndexOf('/') != -1) {
              s = s.substring(0, s.lastIndexOf('/'));
              _testListPossibleFilenames
                  .add(suiteDir.append('$s.dart').toNativePath());
            }
          }
        }
      }
    }

    // Initialize _selectorFilenameRegExp.
    var pattern = configuration.selectors[suiteName].pattern;
    if (pattern.contains("/")) {
      var lastPart = pattern.substring(pattern.lastIndexOf("/") + 1);
      // If the selector is a multitest name ending in a number or 'none'
      // we also accept test file names that don't contain that last part.
      if (int.tryParse(lastPart) != null || lastPart == "none") {
        pattern = pattern.substring(0, pattern.lastIndexOf("/"));
      }
    }
    _selectorFilenameRegExp = RegExp(pattern);
  }

  /// Creates a test suite whose file organization matches an expected structure.
  /// To use this, your suite should look like:
  ///
  ///     dart/
  ///       path/
  ///         to/
  ///           mytestsuite/
  ///             mytestsuite.status
  ///             example1_test.dart
  ///             example2_test.dart
  ///             example3_test.dart
  ///
  /// The important parts:
  ///
  /// * The leaf directory name is the name of your test suite.
  /// * The status file uses the same name.
  /// * Test files are directly in that directory and end in "_test.dart".
  ///
  /// If you follow that convention, then you can construct one of these like:
  ///
  /// new StandardTestSuite.forDirectory(configuration, 'path/to/mytestsuite');
  ///
  /// instead of having to create a custom [StandardTestSuite] subclass. In
  /// particular, if you add 'path/to/mytestsuite' to [TEST_SUITE_DIRECTORIES]
  /// in test.dart, this will all be set up for you.
  factory StandardTestSuite.forDirectory(
      TestConfiguration configuration, Path directory) {
    var name = directory.filename;
    var status_paths = [
      '$directory/$name.status',
      '$directory/.status',
      '$directory/${name}_app_jit.status',
      '$directory/${name}_analyzer.status',
      '$directory/${name}_analyzer2.status',
      '$directory/${name}_dart2js.status',
      '$directory/${name}_dartdevc.status',
      '$directory/${name}_kernel.status',
      '$directory/${name}_precompiled.status',
      '$directory/${name}_spec_parser.status',
      '$directory/${name}_vm.status',
    ];

    return StandardTestSuite(configuration, name, directory, status_paths,
        recursive: true);
  }

  List<Uri> get dart2JsBootstrapDependencies => _dart2JsBootstrapDependencies;

  /// The default implementation assumes a file is a test if
  /// it ends in "_test.dart".
  bool isTestFile(String filename) => filename.endsWith("_test.dart");

  List<String> additionalOptions(Path filePath) => [];

  Future forEachTest(
      TestCaseEvent onTest, Map<String, List<TestFile>> testCache,
      [VoidFunction onDone]) async {
    doTest = onTest;
    testExpectations = readExpectations();

    // Check if we have already found and generated the tests for this suite.
    if (!testCache.containsKey(suiteName)) {
      cachedTests = testCache[suiteName] = <TestFile>[];
      await enqueueTests();
    } else {
      for (var testFile in testCache[suiteName]) {
        enqueueTestCaseFromTestFile(testFile);
      }
    }
    testExpectations = null;
    cachedTests = null;
    doTest = null;
    if (onDone != null) onDone();
  }

  /// Reads the status files and completes with the parsed expectations.
  ExpectationSet readExpectations() {
    var statusFiles = statusFilePaths.where((String statusFilePath) {
      var file = File(dartDir.append(statusFilePath).toNativePath());
      return file.existsSync();
    }).map((statusFilePath) {
      return dartDir.append(statusFilePath).toNativePath();
    }).toList();

    return ExpectationSet.read(statusFiles, configuration);
  }

  Future enqueueTests() {
    Directory dir = Directory(suiteDir.toNativePath());
    return dir.exists().then((exists) {
      if (!exists) {
        print('Directory containing tests missing: ${suiteDir.toNativePath()}');
        return Future.value(null);
      } else {
        var group = FutureGroup();
        enqueueDirectory(dir, group);
        return group.future;
      }
    });
  }

  void enqueueDirectory(Directory dir, FutureGroup group) {
    var lister = dir
        .list(recursive: listRecursively)
        .where((fse) => fse is File)
        .forEach((FileSystemEntity entity) {
      enqueueFile((entity as File).path, group);
    });
    group.add(lister);
  }

  void enqueueFile(String filePath, FutureGroup group) {
    // This is an optimization to avoid scanning and generating extra tests.
    // The definitive check against configuration.testList is performed in
    // TestSuite.enqueueNewTestCase().
    if (_testListPossibleFilenames?.contains(filePath) == false) return;

    // Note: have to use Path instead of a filename for matching because
    // on Windows we need to convert backward slashes to forward slashes.
    // Our display test names (and filters) are given using forward slashes
    // while filenames on Windows use backwards slashes.
    if (!_selectorFilenameRegExp.hasMatch(Path(filePath).toString())) return;

    if (!isTestFile(filePath)) return;

    var testFile = TestFile.read(suiteDir, filePath);

    if (testFile.isMultitest) {
      group.add(splitMultitest(testFile, buildDir, suiteDir,
              hotReload:
                  configuration.hotReload || configuration.hotReloadRollback)
          .then((splitTests) {
        for (var test in splitTests) {
          cachedTests.add(test);
          enqueueTestCaseFromTestFile(test);
        }
      }));
    } else {
      cachedTests.add(testFile);
      enqueueTestCaseFromTestFile(testFile);
    }
  }

  void enqueueTestCaseFromTestFile(TestFile testFile) {
    // Static error tests are currently skipped on every implementation except
    // analyzer and Fasta.
    // TODO(rnystrom): Should other configurations that use CFE support static
    // error tests?
    // TODO(rnystrom): Skipping this here is a little unusual because most
    // skips are handled in enqueueStandardTest(). However, if the configuration
    // is running on browser, calling enqueueStandardTest() will try to create
    // a set of commands which ultimately causes an exception in
    // DummyRuntimeConfiguration. This avoids that.
    if (testFile.isStaticErrorTest &&
        configuration.compiler != Compiler.dart2analyzer &&
        configuration.compiler != Compiler.fasta) {
      return;
    }

    if (configuration.compilerConfiguration.hasCompiler &&
        (testFile.hasCompileError || testFile.isStaticErrorTest)) {
      // If a compile-time error is expected, and we're testing a
      // compiler, we never need to attempt to run the program (in a
      // browser or otherwise).
      enqueueStandardTest(testFile);
    } else if (configuration.runtime.isBrowser) {
      var expectationsMap = <String, Set<Expectation>>{};

      if (testFile.isMultiHtmlTest) {
        // A browser multi-test has multiple expectations for one test file.
        // Find all the different sub-test expectations for one entire test
        // file.
        var subtestNames = testFile.subtestNames;
        expectationsMap = <String, Set<Expectation>>{};
        for (var subtest in subtestNames) {
          expectationsMap[subtest] =
              testExpectations.expectations('${testFile.name}/$subtest');
        }
      } else {
        expectationsMap[testFile.name] =
            testExpectations.expectations(testFile.name);
      }

      _enqueueBrowserTest(testFile, expectationsMap);
    } else {
      enqueueStandardTest(testFile);
    }
  }

  void enqueueStandardTest(TestFile testFile) {
    var commonArguments = _commonArgumentsFromFile(testFile);

    var vmOptionsList = getVmOptions(testFile);
    assert(!vmOptionsList.isEmpty);

    for (var vmOptionsVariant = 0;
        vmOptionsVariant < vmOptionsList.length;
        vmOptionsVariant++) {
      var vmOptions = vmOptionsList[vmOptionsVariant];
      var allVmOptions = vmOptions;
      if (!extraVmOptions.isEmpty) {
        allVmOptions = vmOptions.toList()..addAll(extraVmOptions);
      }

      var expectations = testExpectations.expectations(testFile.name);
      var isCrashExpected = expectations.contains(Expectation.crash);
      var commands = _makeCommands(testFile, vmOptionsVariant, allVmOptions,
          commonArguments, isCrashExpected);
      var variantTestName = testFile.name;
      if (vmOptionsList.length > 1) {
        variantTestName = "${testFile.name}/$vmOptionsVariant";
      }

      enqueueNewTestCase(testFile, variantTestName, commands, expectations);
    }
  }

  List<Command> _makeCommands(TestFile testFile, int vmOptionsVariant,
      List<String> vmOptions, List<String> args, bool isCrashExpected) {
    var commands = <Command>[];
    var compilerConfiguration = configuration.compilerConfiguration;

    var compileTimeArguments = <String>[];
    String tempDir;
    if (compilerConfiguration.hasCompiler) {
      compileTimeArguments = compilerConfiguration.computeCompilerArguments(
          vmOptions,
          testFile.sharedOptions,
          testFile.dartOptions,
          testFile.dart2jsOptions,
          testFile.ddcOptions,
          args);
      // Avoid doing this for analyzer.
      var path = testFile.path;
      if (vmOptionsVariant != 0) {
        // Ensure a unique directory for each test case.
        path = path.join(Path(vmOptionsVariant.toString()));
      }
      tempDir = createCompilationOutputDirectory(path);

      for (var name in testFile.otherResources) {
        var namePath = Path(name);
        var fromPath = testFile.path.directoryPath.join(namePath);
        File('$tempDir/$name').parent.createSync(recursive: true);
        File(fromPath.toNativePath()).copySync('$tempDir/$name');
      }
    }

    var compilationArtifact = compilerConfiguration.computeCompilationArtifact(
        tempDir, compileTimeArguments, environmentOverrides);
    if (!configuration.skipCompilation) {
      commands.addAll(compilationArtifact.commands);
    }

    if (testFile.hasCompileError &&
        compilerConfiguration.hasCompiler &&
        !compilerConfiguration.runRuntimeDespiteMissingCompileTimeError) {
      // Do not attempt to run the compiled result. A compilation
      // error should be reported by the compilation command.
      return commands;
    }

    vmOptions = vmOptions
        .map((s) =>
            s.replaceAll("__RANDOM__", "${Random().nextInt(0x7fffffff)}"))
        .toList();

    var runtimeArguments = compilerConfiguration.computeRuntimeArguments(
        configuration.runtimeConfiguration,
        testFile,
        vmOptions,
        args,
        compilationArtifact);

    var environment = {...environmentOverrides, ...?testFile.environment};

    return commands
      ..addAll(configuration.runtimeConfiguration.computeRuntimeCommands(
          compilationArtifact,
          runtimeArguments,
          environment,
          testFile.sharedObjects,
          isCrashExpected));
  }

  /// Takes a [file], which is either located in the dart or in the build
  /// directory, and returns a String representing the relative path to either
  /// the dart or the build directory.
  ///
  /// Thus, the returned [String] will be the path component of the URL
  /// corresponding to [file] (the HTTP server serves files relative to the
  /// dart/build directories).
  String _createUrlPathFromFile(Path file) {
    file = file.absolute;

    var relativeBuildDir = Path(configuration.buildDirectory);
    var buildDir = relativeBuildDir.absolute;
    var dartDir = Repository.dir.absolute;

    var fileString = file.toString();
    if (fileString.startsWith(buildDir.toString())) {
      var fileRelativeToBuildDir = file.relativeTo(buildDir);
      return "/$prefixBuildDir/$fileRelativeToBuildDir";
    } else if (fileString.startsWith(dartDir.toString())) {
      var fileRelativeToDartDir = file.relativeTo(dartDir);
      return "/$prefixDartDir/$fileRelativeToDartDir";
    }

    // Unreachable.
    print("Cannot create URL for path $file. Not in build or dart directory.");
    exit(1);
    return null;
  }

  String _uriForBrowserTest(String pathComponent, [String subtestName]) {
    // Note: If we run test.py with the "--list" option, no http servers
    // will be started. So we return a dummy url instead.
    if (configuration.listTests) {
      return Uri.parse('http://listing_the_tests_only').toString();
    }

    var serverPort = configuration.servers.port;
    var crossOriginPort = configuration.servers.crossOriginPort;
    var parameters = {'crossOriginPort': crossOriginPort.toString()};
    if (subtestName != null) {
      parameters['group'] = subtestName;
    }
    return Uri(
            scheme: 'http',
            host: configuration.localIP,
            port: serverPort,
            path: pathComponent,
            queryParameters: parameters)
        .toString();
  }

  /// Enqueues a test that runs in a browser.
  ///
  /// Creates a [Command] that compiles the test to JavaScript and writes that
  /// in a generated output directory. Any additional framework and HTML files
  /// are put there too. Then adds another [Command] the spawn the browser and
  /// run the test.
  ///
  /// In order to handle browser multitests, [expectations] is a map of subtest
  /// names to expectation sets. If the test is not a multitest, the map has
  /// a single key, `testFile.name`.
  void _enqueueBrowserTest(
      TestFile testFile, Map<String, Set<Expectation>> expectations) {
    var tempDir = createOutputDirectory(testFile.path);
    var compilationTempDir = createCompilationOutputDirectory(testFile.path);
    var nameNoExt = testFile.path.filenameWithoutExtension;
    var outputDir = compilationTempDir;

    var commonArguments = _commonArgumentsFromFile(testFile);

    // Use existing HTML document if available.
    String content;
    var customHtml = File(
        testFile.path.directoryPath.append('$nameNoExt.html').toNativePath());
    if (customHtml.existsSync()) {
      outputDir = tempDir;
      content = customHtml.readAsStringSync().replaceAll(
          '%TEST_SCRIPTS%', '<script src="$nameNoExt.js"></script>');
    } else {
      // Synthesize an HTML file for the test.
      if (configuration.compiler == Compiler.dart2js) {
        var scriptPath =
            _createUrlPathFromFile(Path('$compilationTempDir/$nameNoExt.js'));
        content = dart2jsHtml(testFile.path.toNativePath(), scriptPath);
      } else {
        var jsDir =
            Path(compilationTempDir).relativeTo(Repository.dir).toString();
        content = dartdevcHtml(nameNoExt, jsDir, configuration.compiler);
      }
    }

    var htmlPath = '$tempDir/test.html';
    File(htmlPath).writeAsStringSync(content);

    // Construct the command(s) that compile all the inputs needed by the
    // browser test.
    var commands = <Command>[];
    const supportedCompilers = {
      Compiler.dart2js,
      Compiler.dartdevc,
      Compiler.dartdevk
    };
    assert(supportedCompilers.contains(configuration.compiler));

    var args = configuration.compilerConfiguration.computeCompilerArguments(
        null,
        testFile.sharedOptions,
        null,
        testFile.dart2jsOptions,
        testFile.ddcOptions,
        commonArguments);
    var compilation = configuration.compilerConfiguration
        .computeCompilationArtifact(outputDir, args, environmentOverrides);
    commands.addAll(compilation.commands);

    if (testFile.isMultiHtmlTest) {
      // Variables for browser multi-tests.
      var subtestNames = testFile.subtestNames;
      for (var subtestName in subtestNames) {
        _enqueueSingleBrowserTest(
            commands,
            testFile,
            '${testFile.name}/$subtestName',
            subtestName,
            expectations[subtestName],
            htmlPath);
      }
    } else {
      _enqueueSingleBrowserTest(commands, testFile, testFile.name, null,
          expectations[testFile.name], htmlPath);
    }
  }

  /// Enqueues a single browser test, or a single subtest of an HTML multitest.
  void _enqueueSingleBrowserTest(
      List<Command> commands,
      TestFile testFile,
      String testName,
      String subtestName,
      Set<Expectation> expectations,
      String htmlPath) {
    // Construct the command that executes the browser test.
    commands = commands.toList();

    var htmlPathSubtest = _createUrlPathFromFile(Path(htmlPath));
    var fullHtmlPath = _uriForBrowserTest(htmlPathSubtest, subtestName);

    commands.add(Command.browserTest(fullHtmlPath, configuration,
        retry: !isNegative(testFile)));

    var fullName = testName;
    if (subtestName != null) fullName += "/$subtestName";
    enqueueNewTestCase(testFile, fullName, commands, expectations);
  }

  List<String> _commonArgumentsFromFile(TestFile testFile) {
    var args = configuration.standardOptions.toList();

    var packages = packagesArgument(testFile.packageRoot, testFile.packages);
    if (packages != null) {
      args.add(packages);
    }
    args.addAll(additionalOptions(testFile.path));
    if (configuration.compiler == Compiler.dart2analyzer) {
      args.add('--format=machine');
      args.add('--no-hints');

      if (testFile.path.filename.contains("dart2js") ||
          testFile.path.directoryPath.segments().last.contains('html_common')) {
        args.add("--use-dart2js-libraries");
      }
    }

    args.add(testFile.path.toNativePath());

    return args;
  }

  String packagesArgument(String packageRoot, String packages) {
    // If this test is inside a package, we will check if there is a
    // pubspec.yaml file and if so, create a custom package root for it.
    if (packageRoot == null && packages == null) {
      if (configuration.packageRoot != null) {
        packageRoot = Path(configuration.packageRoot).toNativePath();
      }

      if (configuration.packages != null) {
        packages = Path(configuration.packages).toNativePath();
      }
    }

    if (packageRoot == 'none' || packages == 'none') {
      return null;
    } else if (packages != null) {
      return '--packages=$packages';
    } else if (packageRoot != null) {
      return '--package-root=$packageRoot';
    } else {
      return null;
    }
  }

  List<List<String>> getVmOptions(TestFile testFile) {
    const compilers = [
      Compiler.none,
      Compiler.dartk,
      Compiler.dartkb,
      Compiler.dartkp,
      Compiler.appJitk,
    ];

    const runtimes = [Runtime.none, Runtime.dartPrecompiled, Runtime.vm];

    var needsVmOptions = compilers.contains(configuration.compiler) &&
        runtimes.contains(configuration.runtime);
    if (!needsVmOptions) return [[]];
    return testFile.vmOptions;
  }
}

/// Used for testing packages in one-off settings, i.e., we pass in the actual
/// directory that we want to test.
class PKGTestSuite extends StandardTestSuite {
  PKGTestSuite(TestConfiguration configuration, Path directoryPath)
      : super(configuration, directoryPath.filename, directoryPath,
            ["$directoryPath/.status"],
            recursive: true);

  void _enqueueBrowserTest(
      TestFile testFile, Map<String, Set<Expectation>> expectations) {
    var dir = testFile.path.directoryPath;
    var nameNoExt = testFile.path.filenameWithoutExtension;
    var customHtmlPath = dir.append('$nameNoExt.html');
    var customHtml = File(customHtmlPath.toNativePath());
    if (!customHtml.existsSync()) {
      super._enqueueBrowserTest(testFile, expectations);
    } else {
      var fullPath = _createUrlPathFromFile(customHtmlPath);
      var command = Command.browserTest(fullPath, configuration,
          retry: !isNegative(testFile));
      enqueueNewTestCase(
          testFile, testFile.name, [command], expectations[testFile.name]);
    }
  }
}

class AnalyzeLibraryTestSuite extends StandardTestSuite {
  static Path _libraryPath(TestConfiguration configuration) =>
      Path(configuration.useSdk
          ? '${configuration.buildDirectory}/dart-sdk'
          : 'sdk');

  bool get listRecursively => true;

  AnalyzeLibraryTestSuite(TestConfiguration configuration)
      : super(configuration, 'analyze_library', _libraryPath(configuration),
            ['tests/lib_2/analyzer/analyze_library.status']);

  List<String> additionalOptions(Path filePath, {bool showSdkWarnings}) =>
      const ['--fatal-warnings', '--fatal-type-errors', '--sdk-warnings'];

  Future enqueueTests() {
    var group = FutureGroup();

    var dir = Directory(suiteDir.append('lib').toNativePath());
    if (dir.existsSync()) {
      enqueueDirectory(dir, group);
    }

    return group.future;
  }

  bool isTestFile(String filename) {
    // NOTE: We exclude tests and patch files for now.
    return filename.endsWith(".dart") &&
        !filename.endsWith("_test.dart") &&
        !filename.contains("_internal/js_runtime/lib");
  }
}
