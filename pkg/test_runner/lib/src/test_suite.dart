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
import 'test_file.dart';
import 'testing_servers.dart';
import 'utils.dart';

typedef TestCaseEvent = void Function(TestCase testCase);

typedef CreateTest = void Function(Path filePath, Path originTestPath,
    {bool hasSyntaxError,
    bool hasCompileError,
    bool hasRuntimeError,
    bool hasStaticWarning,
    String multitestKey});

typedef VoidFunction = void Function();

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
  Map<String, String> _environmentOverrides;

  TestSuite(this.configuration, this.suiteName, this.statusFilePaths) {
    _environmentOverrides = {
      'DART_CONFIGURATION': configuration.configurationDirectory,
      if (Platform.isWindows) 'DART_SUPPRESS_WER': '1',
      if (Platform.isWindows && configuration.copyCoreDumps)
        'DART_CRASHPAD_HANDLER':
            Uri.base.resolve(buildDir + '/crashpad_handler.exe').toFilePath(),
      if (configuration.chromePath != null)
        'CHROME_PATH': Uri.base.resolve(configuration.chromePath).toFilePath(),
      if (configuration.firefoxPath != null)
        'FIREFOX_PATH':
            Uri.base.resolve(configuration.firefoxPath).toFilePath(),
    };
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

  /// Calls [onTest] with each [TestCase] produced by the suite for the
  /// current configuration.
  ///
  /// The [testCache] argument provides a persistent store that can be used to
  /// cache information about the test suite, so that directories do not need
  /// to be listed each time.
  void findTestCases(
      TestCaseEvent onTest, Map<String, List<TestFile>> testCache);

  /// Creates a [TestCase] and passes it to [onTest] if there is a relevant
  /// test to run for [testFile] in the current configuration.
  ///
  /// This handles skips, shards, selector matching, and updating the
  /// [SummaryReport].
  void _addTestCase(TestFile testFile, String fullName, List<Command> commands,
      Set<Expectation> expectations, TestCaseEvent onTest) {
    var displayName = '$suiteName/$fullName';

    if (!_isRelevantTest(testFile, displayName, expectations)) return;

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

    var testCase = TestCase(displayName, commands, configuration, expectations,
        testFile: testFile);

    // Update Summary report.
    if (configuration.printReport) {
      summaryReport.add(testCase);
    }

    if (!_shouldSkipTest(expectations)) {
      onTest(testCase);
    }
  }

  /// Whether it is meaningful to run [testFile] with [expectations] under the
  /// current configuration.
  ///
  /// Does not take skips into account, but does "skip" tests for other
  /// fundamental reasons.
  bool _isRelevantTest(
      TestFile testFile, String displayName, Set<Expectation> expectations) {
    // Test if the selector includes this test.
    var pattern = configuration.selectors[suiteName];
    if (!pattern.hasMatch(displayName)) {
      return false;
    }

    if (configuration.testList != null &&
        !configuration.testList.contains(displayName)) {
      return false;
    }

    // Handle sharding based on the original test path. All multitests of a
    // given original test belong to the same shard.
    if (configuration.shardCount > 1 &&
        testFile.shardHash % configuration.shardCount !=
            configuration.shard - 1) {
      return false;
    }

    if (configuration.hotReload || configuration.hotReloadRollback) {
      // Handle reload special cases.
      if (expectations.contains(Expectation.compileTimeError) ||
          testFile.hasCompileError) {
        // Running a test that expects a compilation error with hot reloading
        // is redundant with a regular run of the test.
        return false;
      }
    }

    // Normal runtime tests are always run.
    if (testFile.isRuntimeTest) return true;

    // Tests of web-specific static errors are run on web compilers.
    if (testFile.isWebStaticErrorTest &&
        (configuration.compiler == Compiler.dart2js ||
            configuration.compiler == Compiler.dartdevc)) {
      return true;
    }

    // Other static error tests are run on front-end-only configurations.
    return configuration.compiler == Compiler.dart2analyzer ||
        configuration.compiler == Compiler.fasta;
  }

  /// Whether a test with [expectations] should be skipped under the current
  /// configuration.
  bool _shouldSkipTest(Set<Expectation> expectations) {
    if (expectations.contains(Expectation.skip) ||
        expectations.contains(Expectation.skipByDesign) ||
        expectations.contains(Expectation.skipSlow)) {
      return true;
    }

    if (configuration.fastTestsOnly &&
        (expectations.contains(Expectation.slow) ||
            expectations.contains(Expectation.skipSlow) ||
            expectations.contains(Expectation.timeout) ||
            expectations.contains(Expectation.dartkTimeout))) {
      return true;
    }

    return false;
  }

  String createGeneratedTestDirectoryHelper(
      String name, String dirname, Path testPath) {
    var relative = testPath.relativeTo(Repository.dir);
    relative = relative.directoryPath.append(relative.filenameWithoutExtension);
    var testUniqueName = TestUtils.getShortName(relative.toString());

    var generatedTestPath = Path(buildDir)
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
    var minified = configuration.isMinified ? '-minified' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}-${configuration.runtime.name}"
        "$checked$minified$sdk";
    return createGeneratedTestDirectoryHelper("tests", dirName, testPath);
  }

  String createCompilationOutputDirectory(Path testPath) {
    var checked = configuration.isChecked ? '-checked' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var csp = configuration.isCsp ? '-csp' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}"
        "$checked$minified$csp$sdk";
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

  void findTestCases(TestCaseEvent onTest, Map testCache) {
    var statusFiles =
        statusFilePaths.map((statusFile) => "$dartDir/$statusFile").toList();
    var expectations = ExpectationSet.read(statusFiles, configuration);

    try {
      for (var test in _listTests(hostRunnerPath)) {
        _addTest(expectations, test, onTest);
      }
    } catch (error, s) {
      print("Fatal error occurred: $error");
      print(s);
      exit(1);
    }
  }

  void _addTest(
      ExpectationSet testExpectations, VMUnitTest test, TestCaseEvent onTest) {
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
    var filename = configuration.architecture == Architecture.x64
        ? '$buildDir/gen/kernel-service.dart.snapshot'
        : '$buildDir/gen/kernel_service.dill';
    var dfePath = Path(filename).absolute.toNativePath();
    var args = [
      // '--dfe' has to be the first argument for run_vm_test to pick it up.
      '--dfe=$dfePath',
      if (expectations.contains(Expectation.crash)) '--suppress-core-dump',
      if (configuration.experiments.isNotEmpty)
        '--enable-experiment=${configuration.experiments.join(",")}',
      ...configuration.standardOptions,
      ...configuration.vmOptions,
      test.name
    ];

    var command = ProcessCommand(
        'run_vm_unittest', targetRunnerPath, args, environmentOverrides);
    _addTestCase(testFile, fullName, [command], expectations, onTest);
  }

  Iterable<VMUnitTest> _listTests(String runnerPath) {
    var result = Process.runSync(runnerPath, ["--list"]);
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

/// A specialized [TestSuite] that runs tests written in C to unit test
/// the standalone (non-DartVM) C/C++ code.
///
/// The tests are compiled into an executable for all [targetAbis] by the
/// build step.
/// An executable lists its tests when run with the --list command line flag.
/// Individual tests are run by specifying them on the command line.
class FfiTestSuite extends TestSuite {
  Map<String, String> runnerPaths;
  final String dartDir;

  static const targetAbis = [
    "arm64_android",
    "arm64_ios",
    "arm64_linux",
    "arm64_macos",
    "arm_android",
    "arm_ios",
    "arm_linux",
    "ia32_android",
    "ia32_linux",
    "ia32_win",
    "x64_ios",
    "x64_linux",
    "x64_macos",
    "x64_win",
  ];

  FfiTestSuite(TestConfiguration configuration)
      : dartDir = Repository.dir.toNativePath(),
        super(configuration, "ffi_unit", []) {
    final binarySuffix = Platform.operatingSystem == 'windows' ? '.exe' : '';

    // For running the tests we use multiple binaries, one for each target ABI.
    runnerPaths = Map.fromIterables(
        targetAbis,
        targetAbis.map((String config) =>
            '$buildDir/run_ffi_unit_tests_$config$binarySuffix'));
  }

  void findTestCases(TestCaseEvent onTest, Map testCache) {
    final statusFiles =
        statusFilePaths.map((statusFile) => "$dartDir/$statusFile").toList();
    final expectations = ExpectationSet.read(statusFiles, configuration);

    runnerPaths.forEach((runnerName, runnerPath) {
      try {
        for (final test in _listTests(runnerName, runnerPath)) {
          _addTest(expectations, test, onTest);
        }
      } catch (error, s) {
        print(
            "Fatal error occurred while parsing tests from $runnerName: $error");
        print(s);
        exit(1);
      }
    });
  }

  void _addTest(
      ExpectationSet testExpectations, FfiUnitTest test, TestCaseEvent onTest) {
    final fullName = '${test.runnerName}/${test.name}';
    var expectations = testExpectations.expectations(fullName);

    // Get the expectation from the test itself.
    final testExpectation = Expectation.find(test.expectation);

    // Update the legacy status-file based expectations to include
    // [testExpectation].
    if (testExpectation != Expectation.pass) {
      expectations = {...expectations, testExpectation};
      expectations.remove(Expectation.pass);
    }

    // Update the new workflow based expectations to include [testExpectation].
    final testFile = TestFile.vmUnitTest(
        hasSyntaxError: false,
        hasCompileError: testExpectation == Expectation.compileTimeError,
        hasRuntimeError: testExpectation == Expectation.runtimeError,
        hasStaticWarning: false,
        hasCrash: testExpectation == Expectation.crash);

    final args = [
      // This test has no VM, but pipe through vmOptions as test options.
      // Passing `--vm-options=--update` will update all test expectations.
      ...configuration.vmOptions,
      test.name,
    ];
    final command = ProcessCommand(
        'run_ffi_unit_test', test.runnerPath, args, environmentOverrides);

    _addTestCase(testFile, fullName, [command], expectations, onTest);
  }

  Iterable<FfiUnitTest> _listTests(String runnerName, String runnerPath) {
    final result = Process.runSync(runnerPath, ["--list"]);
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
      assert(parts.length == 2);
      return FfiUnitTest(runnerName, runnerPath, parts[0], parts[1]);
    });
  }
}

class FfiUnitTest {
  final String runnerName;
  final String runnerPath;
  final String name;
  final String expectation;

  FfiUnitTest(this.runnerName, this.runnerPath, this.name, this.expectation);
}

/// A standard [TestSuite] implementation that searches for tests in a
/// directory, and creates [TestCase]s that compile and/or run them.
class StandardTestSuite extends TestSuite {
  final Path suiteDir;
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
      for (var s in configuration.testList) {
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

  /// Creates a test suite whose file organization matches an expected
  /// structure. To use this, your suite should look like:
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
  ///     StandardTestSuite.forDirectory(configuration, 'path/to/mytestsuite');
  ///
  /// instead of having to create a custom [StandardTestSuite] subclass. In
  /// particular, if you add 'path/to/mytestsuite' to `testSuiteDirectories`
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

  void findTestCases(
      TestCaseEvent onTest, Map<String, List<TestFile>> testCache) {
    var expectations = _readExpectations();

    // Check if we have already found the test files for this suite.
    var testFiles = testCache[suiteName];
    if (testFiles == null) {
      testFiles = [...findTests()];
      testCache[suiteName] = testFiles;
    }

    // Produce test cases for each test file.
    for (var testFile in testFiles) {
      _testCasesFromTestFile(testFile, expectations, onTest);
    }
  }

  /// Walks the file system to find all test files relevant to this test suite.
  Iterable<TestFile> findTests() {
    var dir = Directory(suiteDir.toNativePath());
    if (!dir.existsSync()) {
      print('Directory containing tests missing: ${suiteDir.toNativePath()}');
      return const [];
    }

    return _searchDirectory(dir);
  }

  /// Reads the status files and completes with the parsed expectations.
  ExpectationSet _readExpectations() {
    var statusFiles = <String>[];
    for (var relativePath in statusFilePaths) {
      var file = File(dartDir.append(relativePath).toNativePath());
      if (!file.existsSync()) continue;
      statusFiles.add(file.path);
    }

    return ExpectationSet.read(statusFiles, configuration);
  }

  /// Looks for test files in [directory].
  Iterable<TestFile> _searchDirectory(Directory directory) sync* {
    for (var entry in directory.listSync(recursive: listRecursively)) {
      if (entry is File) yield* _processFile(entry.path);
    }
  }

  /// Gets the set of [TestFile]s based on the source file at [filePath].
  ///
  /// This may produce zero [TestFile]s if [filePath] isn't a test. It may
  /// produce more than one if the file is a multitest.
  Iterable<TestFile> _processFile(String filePath) sync* {
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
      for (var test in splitMultitest(testFile, buildDir, suiteDir,
          hotReload:
              configuration.hotReload || configuration.hotReloadRollback)) {
        yield test;
      }
    } else {
      yield testFile;
    }
  }

  /// Calls [onTest] with every [TestCase] that should be produced from
  /// [testFile].
  ///
  /// This will generally be one or no tests if the test should be skipped but
  /// may be more if [testFile] is a browser multitest or has multiple VM
  /// options.
  void _testCasesFromTestFile(
      TestFile testFile, ExpectationSet expectations, TestCaseEvent onTest) {
    // The configuration must support everything the test needs.
    if (!configuration.supportedFeatures.containsAll(testFile.requirements)) {
      return;
    }

    var expectationSet = expectations.expectations(testFile.name);
    if (configuration.compilerConfiguration.hasCompiler &&
        (testFile.hasCompileError || !testFile.isRuntimeTest)) {
      // If a compile-time error is expected, and we're testing a
      // compiler, we never need to attempt to run the program (in a
      // browser or otherwise).
      _enqueueStandardTest(testFile, expectationSet, onTest);
    } else if (configuration.runtime.isBrowser) {
      _enqueueBrowserTest(testFile, expectationSet, onTest);
    } else if (suiteName == 'service' || suiteName == 'service_2') {
      _enqueueServiceTest(testFile, expectationSet, onTest);
    } else {
      _enqueueStandardTest(testFile, expectationSet, onTest);
    }
  }

  void _enqueueStandardTest(
      TestFile testFile, Set<Expectation> expectations, TestCaseEvent onTest) {
    var commonArguments = _commonArgumentsFromFile(testFile);

    var vmOptionsList = getVmOptions(testFile);
    assert(vmOptionsList.isNotEmpty);

    for (var vmOptionsVariant = 0;
        vmOptionsVariant < vmOptionsList.length;
        vmOptionsVariant++) {
      var vmOptions = [
        ...vmOptionsList[vmOptionsVariant],
        ...extraVmOptions,
      ];
      var isCrashExpected = expectations.contains(Expectation.crash);
      var commands = _makeCommands(testFile, vmOptionsVariant, vmOptions,
          commonArguments, isCrashExpected);
      var variantTestName = testFile.name;
      if (vmOptionsList.length > 1) {
        variantTestName = "${testFile.name}/$vmOptionsVariant";
      }

      _addTestCase(testFile, variantTestName, commands, expectations, onTest);
    }
  }

  void _enqueueServiceTest(
      TestFile testFile, Set<Expectation> expectations, TestCaseEvent onTest) {
    var commonArguments = _commonArgumentsFromFile(testFile);

    var vmOptionsList = getVmOptions(testFile);
    assert(vmOptionsList.isNotEmpty);

    var emitDdsTest = false;
    for (var i = 0; i < 2; ++i) {
      for (var vmOptionsVariant = 0;
          vmOptionsVariant < vmOptionsList.length;
          vmOptionsVariant++) {
        var vmOptions = [
          ...vmOptionsList[vmOptionsVariant],
          ...extraVmOptions,
          if (emitDdsTest) '-DUSE_DDS=true',
        ];
        var isCrashExpected = expectations.contains(Expectation.crash);
        var commands = _makeCommands(
            testFile,
            vmOptionsVariant + (vmOptionsList.length * i),
            vmOptions,
            commonArguments,
            isCrashExpected);
        var variantTestName =
            testFile.name + '/${emitDdsTest ? 'dds' : 'service'}';
        if (vmOptionsList.length > 1) {
          variantTestName = "${variantTestName}_$vmOptionsVariant";
        }

        _addTestCase(testFile, variantTestName, commands, expectations, onTest);
      }
      emitDdsTest = true;
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
          testFile, vmOptions, args);
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
        File('$tempDir/$name').createSync(recursive: true);
        File(fromPath.toNativePath()).copySync('$tempDir/$name');
      }
    }

    var compilationArtifact = compilerConfiguration.computeCompilationArtifact(
        tempDir, compileTimeArguments, environmentOverrides);
    if (!configuration.skipCompilation) {
      commands.addAll(compilationArtifact.commands);
    }

    if ((testFile.hasCompileError || testFile.isStaticErrorTest) &&
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

    print("Cannot create URL for path $file. Not in build or dart directory.");
    exit(1);
  }

  String _uriForBrowserTest(String pathComponent) {
    // Note: If we run test.py with the "--list" option, no http servers
    // will be started. So we return a dummy url instead.
    if (configuration.listTests) {
      return Uri.parse('http://listing_the_tests_only').toString();
    }

    var serverPort = configuration.servers.port;
    var crossOriginPort = configuration.servers.crossOriginPort;
    var parameters = {'crossOriginPort': crossOriginPort.toString()};
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
  void _enqueueBrowserTest(
      TestFile testFile, Set<Expectation> expectations, TestCaseEvent onTest) {
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
        var packageRoot = packagesArgument(configuration.packages);
        packageRoot =
            packageRoot == null ? nameNoExt : packageRoot.split("=").last;
        var nameFromModuleRoot =
            testFile.path.relativeTo(Path(packageRoot).directoryPath);
        var nameFromModuleRootNoExt =
            "${nameFromModuleRoot.directoryPath}/$nameNoExt";
        var jsDir =
            Path(compilationTempDir).relativeTo(Repository.dir).toString();
        var nullAssertions =
            testFile.sharedOptions.contains('--null-assertions');
        var weakNullSafetyErrors =
            testFile.ddcOptions.contains('--weak-null-safety-errors');
        content = dartdevcHtml(
            nameNoExt,
            nameFromModuleRootNoExt,
            jsDir,
            configuration.compiler,
            configuration.nnbdMode,
            nullAssertions,
            weakNullSafetyErrors);
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

    var args = configuration.compilerConfiguration
        .computeCompilerArguments(testFile, null, commonArguments);
    var compilation = configuration.compilerConfiguration
        .computeCompilationArtifact(outputDir, args, environmentOverrides);
    commands.addAll(compilation.commands);

    _enqueueSingleBrowserTest(
        commands, testFile, testFile.name, expectations, htmlPath, onTest);
  }

  // TODO: Merge with above.
  /// Enqueues a single browser test, or a single subtest of an HTML multitest.
  void _enqueueSingleBrowserTest(
      List<Command> commands,
      TestFile testFile,
      String testName,
      Set<Expectation> expectations,
      String htmlPath,
      TestCaseEvent onTest) {
    // Construct the command that executes the browser test.
    commands = commands.toList();

    var fullHtmlPath =
        _uriForBrowserTest(_createUrlPathFromFile(Path(htmlPath)));
    commands.add(BrowserTestCommand(fullHtmlPath, configuration));

    var fullName = testName;
    _addTestCase(testFile, fullName, commands, expectations, onTest);
  }

  List<String> _commonArgumentsFromFile(TestFile testFile) {
    var args = configuration.standardOptions.toList();

    var packages = packagesArgument(testFile.packages);
    if (packages != null) {
      args.add(packages);
    }
    args.addAll(additionalOptions(testFile.path));
    if (configuration.compiler == Compiler.dart2analyzer) {
      args.add('--format=machine');
      args.add('--no-hints');
    }

    args.add(testFile.path.toNativePath());

    return args;
  }

  String packagesArgument(String packages) {
    // If this test is inside a package, we will check if there is a
    // pubspec.yaml file and if so, create a custom package root for it.
    if (packages == null && configuration.packages != null) {
      packages = Path(configuration.packages).toNativePath();
    }

    if (packages == 'none') {
      return null;
    } else if (packages != null) {
      return '--packages=$packages';
    } else {
      return null;
    }
  }

  List<List<String>> getVmOptions(TestFile testFile) {
    const compilers = [
      Compiler.none,
      Compiler.dartk,
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
class PackageTestSuite extends StandardTestSuite {
  PackageTestSuite(TestConfiguration configuration, Path directoryPath)
      : super(configuration, directoryPath.filename, directoryPath,
            ["$directoryPath/.status"],
            recursive: true);

  void _enqueueBrowserTest(
      TestFile testFile, Set<Expectation> expectations, TestCaseEvent onTest) {
    var dir = testFile.path.directoryPath;
    var nameNoExt = testFile.path.filenameWithoutExtension;
    var customHtmlPath = dir.append('$nameNoExt.html');
    var customHtml = File(customHtmlPath.toNativePath());
    if (!customHtml.existsSync()) {
      super._enqueueBrowserTest(testFile, expectations, onTest);
    } else {
      var fullPath = _createUrlPathFromFile(customHtmlPath);
      var command = BrowserTestCommand(fullPath, configuration);
      _addTestCase(testFile, testFile.name, [command], expectations, onTest);
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

  Iterable<TestFile> findTests() {
    var dir = Directory(suiteDir.append('lib').toNativePath());
    if (dir.existsSync()) {
      return _searchDirectory(dir);
    }

    return const [];
  }

  bool isTestFile(String filename) {
    // NOTE: We exclude tests and patch files for now.
    return filename.endsWith(".dart") &&
        !filename.endsWith("_test.dart") &&
        !filename.contains("_internal/js_runtime/lib");
  }
}
