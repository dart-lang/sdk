// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Classes and methods for enumerating and preparing tests.
 *
 * This library includes:
 *
 * - Creating tests by listing all the Dart files in certain directories,
 *   and creating [TestCase]s for those files that meet the relevant criteria.
 * - Preparing tests, including copying files and frameworks to temporary
 *   directories, and computing the command line and arguments to be run.
 */
library test_suite;

import "dart:async";
import "dart:io";
import "drt_updater.dart";
import "multitest.dart";
import "status_file_parser.dart";
import "test_runner.dart";
import "utils.dart";
import "http_server.dart" show PREFIX_BUILDDIR, PREFIX_DARTDIR;

import "compiler_configuration.dart" show
    CommandArtifact,
    CompilerConfiguration;

import "runtime_configuration.dart" show
    RuntimeConfiguration;

part "browser_test.dart";


RegExp multiHtmlTestGroupRegExp = new RegExp(r"\s*[^/]\s*group\('[^,']*");
RegExp multiHtmlTestRegExp = new RegExp(r"useHtmlIndividualConfiguration()");
// Require at least one non-space character before '///'
RegExp multiTestRegExp = new RegExp(r"\S *"
                                    r"/// \w+:(.*)");

/**
 * A simple function that tests [arg] and returns `true` or `false`.
 */
typedef bool Predicate<T>(T arg);

typedef void CreateTest(Path filePath,
                        bool hasCompileError,
                        bool hasRuntimeError,
                        {bool isNegativeIfChecked,
                         bool hasCompileErrorIfChecked,
                         bool hasStaticWarning,
                         String multitestKey,
                         Path originTestPath});

typedef void VoidFunction();

/**
 * Calls [function] asynchronously. Returns a future that completes with the
 * result of the function. If the function is `null`, returns a future that
 * completes immediately with `null`.
 */
Future asynchronously(function()) {
  if (function == null) return new Future.value(null);

  var completer = new Completer();
  Timer.run(() => completer.complete(function()));

  return completer.future;
}

/** A completer that waits until all added [Future]s complete. */
// TODO(rnystrom): Copied from web_components. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup {
  static const _FINISHED = -1;
  int _pending = 0;
  Completer<List> _completer = new Completer<List>();
  final List<Future> futures = <Future>[];
  bool wasCompleted = false;

  /**
   * Wait for [task] to complete (assuming this barrier has not already been
   * marked as completed, otherwise you'll get an exception indicating that a
   * future has already been completed).
   */
  void add(Future task) {
    if (_pending == _FINISHED) {
      throw new Exception("FutureFutureAlreadyCompleteException");
    }
    _pending++;
    var handledTaskFuture = task.catchError((e) {
      if (!wasCompleted) {
        _completer.completeError(e);
        wasCompleted = true;
      }
    }).then((_) {
      _pending--;
      if (_pending == 0) {
        _pending = _FINISHED;
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

/**
 * A TestSuite represents a collection of tests.  It creates a [TestCase]
 * object for each test to be run, and passes the test cases to a callback.
 *
 * Most TestSuites represent a directory or directory tree containing tests,
 * and a status file containing the expected results when these tests are run.
 */
abstract class TestSuite {
  final Map configuration;
  final String suiteName;
  // This function is set by subclasses before enqueueing starts.
  Function doTest;


  TestSuite(this.configuration, this.suiteName);

  Map<String, String> get environmentOverrides {
    return {
      'DART_CONFIGURATION' : TestUtils.configurationDir(configuration),
    };
  }

  /**
   * Whether or not binaries should be found in the root build directory or
   * in the built SDK.
   */
  bool get useSdk {
    // The pub suite always uses the SDK.
    // TODO(rnystrom): Eventually, all test suites should run out of the SDK
    // and this check should go away.
    // TODO(ahe): This check is broken for several reasons:
    // First, it is not true that all tests should be running out of the
    // SDK. It is absolutely critical to VM development that you can test the
    // VM without building the SDK.
    // Second, it is convenient for dart2js developers to run tests without
    // rebuilding the SDK, and similarly, it should be convenient for pub
    // developers.
    // Third, even if pub can only run from the SDK directory, this is the
    // wrong place to work around that problem. Instead, test_options.dart
    // should have been modified so that configuration['use_sdk'] is always
    // true when testing pub. Attempting to override the value here is brittle
    // because we read configuration['use_sdk'] directly in many places without
    // using this getter.
    if (suiteName == 'pub') return true;

    return configuration['use_sdk'];
  }

  /**
   * The output directory for this suite's configuration.
   */
  String get buildDir => TestUtils.buildDir(configuration);

  /**
   * The path to the compiler for this suite's configuration. Returns `null` if
   * no compiler should be used.
   */
  String get compilerPath {
    var compilerConfiguration = new CompilerConfiguration(configuration);
    if (!compilerConfiguration.hasCompiler) return null;
    String name = compilerConfiguration.computeCompilerPath(buildDir);
    // TODO(ahe): Only validate this once, in test_options.dart.
    TestUtils.ensureExists(name, configuration);
    return name;
  }

  String get pubPath {
    var prefix = 'sdk/bin/';
    if (configuration['use_sdk']) {
      prefix = '$buildDir/dart-sdk/bin/';
    }
    String suffix = getExecutableSuffix('pub');
    var name = '${prefix}pub$suffix';
    TestUtils.ensureExists(name, configuration);
    return name;
  }

  /// Returns the name of the Dart VM executable.
  String get dartVmBinaryFileName {
    // Controlled by user with the option "--dart".
    String dartExecutable = configuration['dart'];

    if (dartExecutable == '') {
      String suffix = executableBinarySuffix;
      dartExecutable = useSdk
          ? '$buildDir/dart-sdk/bin/dart$suffix'
          : '$buildDir/dart$suffix';
    }

    TestUtils.ensureExists(dartExecutable, configuration);
    return dartExecutable;
  }

  String get d8FileName {
    var suffix = getExecutableSuffix('d8');
    var d8Dir = TestUtils.dartDir.append('third_party/d8');
    var d8Path = d8Dir.append('${Platform.operatingSystem}/d8$suffix');
    var d8 = d8Path.toNativePath();
    TestUtils.ensureExists(d8, configuration);
    return d8;
  }

  String get jsShellFileName {
    var executableSuffix = getExecutableSuffix('jsshell');
    var executable = 'jsshell$executableSuffix';
    var jsshellDir = '${TestUtils.dartDir}/tools/testing/bin';
    return '$jsshellDir/$executable';
  }

  /**
   * The file extension (if any) that should be added to the given executable
   * name for the current platform.
   */
  // TODO(ahe): Get rid of this. Use executableBinarySuffix instead.
  String getExecutableSuffix(String executable) {
    if (Platform.operatingSystem == 'windows') {
      if (executable == 'd8' || executable == 'vm' || executable == 'none') {
        return '.exe';
      } else {
        return '.bat';
      }
    }
    return '';
  }

  String get executableBinarySuffix => Platform.isWindows ? '.exe' : '';

  /**
   * Call the callback function onTest with a [TestCase] argument for each
   * test in the suite.  When all tests have been processed, call [onDone].
   *
   * The [testCache] argument provides a persistent store that can be used to
   * cache information about the test suite, so that directories do not need
   * to be listed each time.
   */
  void forEachTest(TestCaseEvent onTest, Map testCache, [VoidFunction onDone]);

  // This function will be called for every TestCase of this test suite.
  // It will
  //  - handle sharding
  //  - update SummaryReport
  //  - handle SKIP/SKIP_BY_DESIGN markers
  //  - test if the selector matches
  // and will enqueue the test (if necessary).
  void enqueueNewTestCase(TestCase testCase) {
    var expectations = testCase.expectedOutcomes;

    // Handle sharding based on the original test path (i.e. all multitests
    // of a given original test belong to the same shard)
    int shards = configuration['shards'];
    if (shards > 1 && testCase.hash % shards != configuration['shard'] - 1) {
      return;
    }
    // Test if the selector includes this test.
    RegExp pattern = configuration['selectors'][suiteName];
    if (!pattern.hasMatch(testCase.displayName)) {
      return;
    }

    // Update Summary report
    if (configuration['report']) {
      SummaryReport.add(expectations);
      if (testCase.expectCompileError &&
          TestUtils.isBrowserRuntime(configuration['runtime']) &&
          new CompilerConfiguration(configuration).hasCompiler) {
        SummaryReport.addCompileErrorSkipTest();
        return;
      }
    }

    // Handle skipped tests
    if (expectations.contains(Expectation.SKIP) ||
        expectations.contains(Expectation.SKIP_BY_DESIGN)) {
      return;
    }

    doTest(testCase);
  }

  String createGeneratedTestDirectoryHelper(
      String name, String dirname, Path testPath, String optionsName) {
    Path relative = testPath.relativeTo(TestUtils.dartDir);
    relative = relative.directoryPath.append(relative.filenameWithoutExtension);
    String testUniqueName = TestUtils.getShortName(relative.toString());
    if (!optionsName.isEmpty) {
      testUniqueName = '$testUniqueName-$optionsName';
    }

    Path generatedTestPath = new Path(buildDir)
        .append('generated_$name')
        .append(dirname)
        .append(testUniqueName);

    TestUtils.mkdirRecursive(new Path('.'), generatedTestPath);
    return new File(generatedTestPath.toNativePath()).absolute.path
        .replaceAll('\\', '/');
  }

  String buildTestCaseDisplayName(Path suiteDir,
                                  Path originTestPath,
                                  {String multitestName: ""}) {
    Path testNamePath = originTestPath.relativeTo(suiteDir);
    var directory = testNamePath.directoryPath;
    var filenameWithoutExt = testNamePath.filenameWithoutExtension;

    String concat(String base, String part) {
      if (base == "") return part;
      if (part == "") return base;
      return "$base/$part";
    }

    var testName = "$directory";
    testName = concat(testName, "$filenameWithoutExt");
    testName = concat(testName, multitestName);
    return testName;
  }

  /**
   * Create a directories for generated assets (tests, html files,
   * pubspec checkouts ...).
   */

  String createOutputDirectory(Path testPath, String optionsName) {
    var checked = configuration['checked'] ? '-checked' : '';
    var minified = configuration['minified'] ? '-minified' : '';
    var sdk = configuration['use_sdk'] ? '-sdk' : '';
    var packages = configuration['use_public_packages']
        ? '-public_packages' : '';
    var dirName = "${configuration['compiler']}-${configuration['runtime']}"
                  "$checked$minified$packages$sdk";
    return createGeneratedTestDirectoryHelper(
        "tests", dirName, testPath, optionsName);
  }

  String createCompilationOutputDirectory(Path testPath) {
    var checked = configuration['checked'] ? '-checked' : '';
    var minified = configuration['minified'] ? '-minified' : '';
    var csp = configuration['csp'] ? '-csp' : '';
    var sdk = configuration['use_sdk'] ? '-sdk' : '';
    var packages = configuration['use_public_packages']
        ? '-public_packages' : '';
    var dirName = "${configuration['compiler']}"
                  "$checked$minified$csp$packages$sdk";
    return createGeneratedTestDirectoryHelper(
        "compilations", dirName, testPath, "");
  }

  String createPubspecCheckoutDirectory(Path directoryOfPubspecYaml) {
    var relativeDir = directoryOfPubspecYaml.relativeTo(TestUtils.dartDir);
    var sdk = configuration['use_sdk'] ? '-sdk' : '';
    var pkg = configuration['use_public_packages']
        ? 'public_packages' : 'repo_packages';
    return createGeneratedTestDirectoryHelper(
        "pubspec_checkouts", '$pkg$sdk', directoryOfPubspecYaml, "");
  }

  String createPubPackageBuildsDirectory(Path directoryOfPubspecYaml) {
    var relativeDir = directoryOfPubspecYaml.relativeTo(TestUtils.dartDir);
    var pkg = configuration['use_public_packages']
        ? 'public_packages' : 'repo_packages';
    return createGeneratedTestDirectoryHelper(
        "pub_package_builds", pkg, directoryOfPubspecYaml, "");
  }

  /**
   * Helper function for discovering the packages in the dart repository.
   */
  Future<List> listDir(Path path, Function isValid) {
    return new Directory(path.toNativePath())
    .list(recursive: false)
    .where((fse) => fse is Directory)
    .map((Directory directory) {
      var fullPath = directory.absolute.path;
      var packageName = new Path(fullPath).filename;
      if (isValid(packageName)) {
        return [packageName, path.append(packageName).toNativePath()];
      }
      return null;
    })
    .where((name) => name != null)
    .toList();
  }

  Future<Map> discoverPackagesInRepository() {
    /*
     * Layout of packages inside the dart repository:
     *  dart/
     *      pkg/PACKAGE_NAME
     *      pkg/third_party/PACKAGE_NAME
     *      third_party/pkg/PACKAGE_NAME
     *      runtime/bin/vmservice/PACKAGE_NAME
     */

    // Directories containing "-" are not valid pub packages and we therefore
    // do not include them in the list of packages.
    isValid(packageName) =>
        packageName != 'third_party' && !packageName.contains('-');

    var dartDir = TestUtils.dartDir;
    var futures = [
      listDir(dartDir.append('pkg'), isValid),
      listDir(dartDir.append('pkg').append('third_party'), isValid),
      listDir(dartDir.append('third_party').append('pkg'), isValid),
      listDir(dartDir.append('runtime').append('bin').append('vmservice'),
              isValid),
    ];
    return Future.wait(futures).then((results) {
      var packageDirectories = {};
      for (var result in results) {
        for (var packageTuple in result) {
          String packageName = packageTuple[0];
          String fullPath = packageTuple[1];
          String yamlFile =
              new Path(fullPath).append('pubspec.yaml').toNativePath();
          if (new File(yamlFile).existsSync()) {
            packageDirectories[packageName] = fullPath;
          }
        }
      }
      return packageDirectories;
    });
  }

  Future<Map> discoverSamplesInRepository() {
    /*
     * Layout of samples inside the dart repository:
     *  dart/
     *      samples/SAMPLE_NAME
     *      samples/third_party/SAMPLE_NAME
     */

    isValid(packageName) => packageName != 'third_party';

    var dartDir = TestUtils.dartDir;
    var futures = [
      listDir(dartDir.append('samples'), isValid),
      listDir(dartDir.append('samples').append('third_party'), isValid),
    ];
    return Future.wait(futures).then((results) {
      var packageDirectories = {};
      for (var result in results) {
        for (var packageTuple in result) {
          String packageName = packageTuple[0];
          String fullPath = packageTuple[1];
          packageDirectories[packageName] = fullPath;
        }
      }
      return packageDirectories;
    });
  }

  /**
   * Helper function for building dependency_overrides for pubspec.yaml files.
   */
  Map buildPubspecDependencyOverrides(Map packageDirectories) {
    Map overrides = {};
    packageDirectories.forEach((String packageName, String fullPath) {
      overrides[packageName] = { 'path' : fullPath };
    });
    return overrides;
  }

}


Future<Iterable<String>> ccTestLister(String runnerPath) {
  return Process.run(runnerPath, ["--list"]).then((ProcessResult result) {
    if (result.exitCode != 0) {
      throw "Failed to list tests: '$runnerPath --list'. "
            "Process exited with ${result.exitCode}";
    }
    return result.stdout
      .split('\n')
      .map((line) => line.trim())
      .where((name) => name.length > 0);
  });
}


/**
 * A specialized [TestSuite] that runs tests written in C to unit test
 * the Dart virtual machine and its API.
 *
 * The tests are compiled into a monolithic executable by the build step.
 * The executable lists its tests when run with the --list command line flag.
 * Individual tests are run by specifying them on the command line.
 */
class CCTestSuite extends TestSuite {
  final String testPrefix;
  String targetRunnerPath;
  String hostRunnerPath;
  final String dartDir;
  List<String> statusFilePaths;

  CCTestSuite(Map configuration,
              String suiteName,
              String runnerName,
              this.statusFilePaths,
              {this.testPrefix: ''})
      : super(configuration, suiteName),
        dartDir = TestUtils.dartDir.toNativePath() {
    // For running the tests we use the given '$runnerName' binary
    targetRunnerPath = '$buildDir/$runnerName';

    // For listing the tests we use the '$runnerName.host' binary if it exists
    // and use '$runnerName' if it doesn't.
    var binarySuffix = Platform.operatingSystem == 'windows' ? '.exe' : '';
    var hostBinary = '$targetRunnerPath.host$binarySuffix';
    if (new File(hostBinary).existsSync()) {
      hostRunnerPath = hostBinary;
    } else {
      hostRunnerPath = targetRunnerPath;
    }
  }

  void testNameHandler(TestExpectations testExpectations, String testName) {
    // Only run the tests that match the pattern. Use the name
    // "suiteName/testName" for cc tests.
    String constructedName = '$suiteName/$testPrefix$testName';

    var expectations = testExpectations.expectations(
        '$testPrefix$testName');

    var args = TestUtils.standardOptions(configuration);
    args.add(testName);

    var command = CommandBuilder.instance.getProcessCommand(
        'run_vm_unittest', targetRunnerPath, args, environmentOverrides);
    enqueueNewTestCase(
        new TestCase(constructedName, [command], configuration, expectations));
  }

  void forEachTest(Function onTest, Map testCache, [VoidFunction onDone]) {
    doTest = onTest;
    var statusFiles =
        statusFilePaths.map((statusFile) => "$dartDir/$statusFile").toList();

    ReadTestExpectations(statusFiles, configuration)
        .then((TestExpectations expectations) {
      ccTestLister(hostRunnerPath).then((Iterable<String> names) {
        names.forEach((testName) => testNameHandler(expectations, testName));
        doTest = null;
        if (onDone != null) onDone();
      }).catchError((error) {
        print("Fatal error occured: $error");
        exit(1);
      });
    });
  }
}


class TestInformation {
  Path originTestPath;
  Path filePath;
  Map optionsFromFile;
  bool hasCompileError;
  bool hasRuntimeError;
  bool isNegativeIfChecked;
  bool hasCompileErrorIfChecked;
  bool hasStaticWarning;
  String multitestKey;

  TestInformation(this.filePath, this.optionsFromFile,
                  this.hasCompileError, this.hasRuntimeError,
                  this.isNegativeIfChecked, this.hasCompileErrorIfChecked,
                  this.hasStaticWarning,
                  {this.multitestKey, this.originTestPath}) {
    assert(filePath.isAbsolute);
    if (originTestPath == null) originTestPath = filePath;
  }
}

/**
 * A standard [TestSuite] implementation that searches for tests in a
 * directory, and creates [TestCase]s that compile and/or run them.
 */
class StandardTestSuite extends TestSuite {
  final Path suiteDir;
  final List<String> statusFilePaths;
  TestExpectations testExpectations;
  List<TestInformation> cachedTests;
  final Path dartDir;
  Predicate<String> isTestFilePredicate;
  final bool listRecursively;
  final extraVmOptions;

  StandardTestSuite(Map configuration,
                    String suiteName,
                    Path suiteDirectory,
                    this.statusFilePaths,
                    {this.isTestFilePredicate,
                    bool recursive: false})
  : super(configuration, suiteName),
    dartDir = TestUtils.dartDir,
    listRecursively = recursive,
    suiteDir = TestUtils.dartDir.join(suiteDirectory),
    extraVmOptions = TestUtils.getExtraVmOptions(configuration);

  /**
   * Creates a test suite whose file organization matches an expected structure.
   * To use this, your suite should look like:
   *
   *     dart/
   *       path/
   *         to/
   *           mytestsuite/
   *             mytestsuite.status
   *             example1_test.dart
   *             example2_test.dart
   *             example3_test.dart
   *
   * The important parts:
   *
   * * The leaf directory name is the name of your test suite.
   * * The status file uses the same name.
   * * Test files are directly in that directory and end in "_test.dart".
   *
   * If you follow that convention, then you can construct one of these like:
   *
   * new StandardTestSuite.forDirectory(configuration, 'path/to/mytestsuite');
   *
   * instead of having to create a custom [StandardTestSuite] subclass. In
   * particular, if you add 'path/to/mytestsuite' to [TEST_SUITE_DIRECTORIES]
   * in test.dart, this will all be set up for you.
   *
   * The [StandardTestSuite] also optionally takes a list of servers that have
   * been started up by the test harness, to be used by browser tests.
   */
  factory StandardTestSuite.forDirectory(Map configuration, Path directory) {
    final name = directory.filename;

    var status_paths = ['$directory/$name.status',
                        '$directory/.status',
                        '$directory/${name}_dart2js.status',
                        '$directory/${name}_analyzer.status',
                        '$directory/${name}_analyzer2.status'];

    return new StandardTestSuite(configuration,
        name, directory,
        status_paths,
        isTestFilePredicate: (filename) => filename.endsWith('_test.dart'),
        recursive: true);
  }

  List<Uri> get dart2JsBootstrapDependencies {
    if (!useSdk) return [];

    var snapshotPath = TestUtils.absolutePath(new Path(buildDir).join(
        new Path('dart-sdk/bin/snapshots/'
                 'utils_wrapper.dart.snapshot'))).toString();
    return [new Uri(scheme: 'file', path: snapshotPath)];
  }

  /**
   * The default implementation assumes a file is a test if
   * it ends in "Test.dart".
   */
  bool isTestFile(String filename) {
    // Use the specified predicate, if provided.
    if (isTestFilePredicate != null) return isTestFilePredicate(filename);

    return filename.endsWith("Test.dart");
  }

  List<String> additionalOptions(Path filePath) => [];

  Map<String, String> localPackageDirectories;

  void forEachTest(Function onTest, Map testCache, [VoidFunction onDone]) {
    discoverPackagesInRepository().then((Map packageDirectories) {
      localPackageDirectories = packageDirectories;
      return updateDartium();
    }).then((_) {
      doTest = onTest;

      return readExpectations();
    }).then((expectations) {
      testExpectations = expectations;

      // Checked if we have already found and generated the tests for
      // this suite.
      if (!testCache.containsKey(suiteName)) {
        cachedTests = testCache[suiteName] = [];
        return enqueueTests();
      } else {
        // We rely on enqueueing completing asynchronously.
        return asynchronously(() {
          for (var info in testCache[suiteName]) {
            enqueueTestCaseFromTestInformation(info);
          }
        });
      }
    }).then((_) {
      testExpectations = null;
      cachedTests = null;
      doTest = null;
      if (onDone != null) onDone();
    });
  }

  /**
   * If Content shell/Dartium is required, and not yet updated, waits for
   * the update then completes. Otherwise completes immediately.
   */
  Future updateDartium() {
    var completer = new Completer();
    var updater = runtimeUpdater(configuration);
    if (updater == null || updater.updated) {
      return new Future.value(null);
    }

    assert(updater.isActive);
    updater.onUpdated.add(() => completer.complete(null));

    return completer.future;
  }

  /**
   * Reads the status files and completes with the parsed expectations.
   */
  Future<TestExpectations> readExpectations() {
    var statusFiles = statusFilePaths.where((String statusFilePath) {
      var file = new File(dartDir.append(statusFilePath).toNativePath());
      return file.existsSync();
    }).map((statusFilePath) {
      return dartDir.append(statusFilePath).toNativePath();
    }).toList();

    return ReadTestExpectations(statusFiles, configuration);
  }

  Future enqueueTests() {
    Directory dir = new Directory(suiteDir.toNativePath());
    return dir.exists().then((exists) {
      if (!exists) {
        print('Directory containing tests missing: ${suiteDir.toNativePath()}');
        return new Future.value(null);
      } else {
        var group = new FutureGroup();
        enqueueDirectory(dir, group);
        return group.future;
      }
    });
  }

  void enqueueDirectory(Directory dir, FutureGroup group) {
    var listCompleter = new Completer();
    group.add(listCompleter.future);

    var lister = dir.list(recursive: listRecursively)
        .listen((FileSystemEntity fse) {
          if (fse is File) enqueueFile(fse.path, group);
        },
        onDone: listCompleter.complete);
  }

  void enqueueFile(String filename, FutureGroup group) {
    if (!isTestFile(filename)) return;
    Path filePath = new Path(filename);

    // Only run the tests that match the pattern.
    if (filePath.filename.endsWith('test_config.dart')) return;

    var optionsFromFile = readOptionsFromFile(filePath);
    CreateTest createTestCase = makeTestCaseCreator(optionsFromFile);

    if (optionsFromFile['isMultitest']) {
      group.add(doMultitest(filePath, buildDir, suiteDir, createTestCase));
    } else {
      createTestCase(filePath,
                     optionsFromFile['hasCompileError'],
                     optionsFromFile['hasRuntimeError'],
                     hasStaticWarning: optionsFromFile['hasStaticWarning']);
    }
  }

  static Path _findPubspecYamlFile(Path filePath) {
    final existsCache = TestUtils.existsCache;

    Path root = TestUtils.dartDir;
    assert ("$filePath".startsWith("$root"));

    // We start with the parent directory of [filePath] and go up until
    // the root directory (excluding the root).
    List<String> segments =
        filePath.directoryPath.relativeTo(root).segments();
    while (segments.length > 0) {
      var pubspecYamlPath =
          new Path(segments.join('/')).append('pubspec.yaml');
      if (existsCache.doesFileExist(pubspecYamlPath.toNativePath())) {
        return root.join(pubspecYamlPath);
      }
      segments.removeLast();
    }
    return null;
  }

  void enqueueTestCaseFromTestInformation(TestInformation info) {
    var filePath = info.filePath;
    var optionsFromFile = info.optionsFromFile;

    Map buildSpecialPackageRoot(Path pubspecYamlFile) {
      var commands = <Command>[];
      var packageDir = pubspecYamlFile.directoryPath;
      var packageName = packageDir.filename;

      var checkoutDirectory =
          createPubspecCheckoutDirectory(packageDir);
      var modifiedYamlFile = new Path(checkoutDirectory).append("pubspec.yaml");
      var pubCacheDirectory = new Path(checkoutDirectory).append("pub-cache");
      var newPackageRoot = new Path(checkoutDirectory).append("packages");

      // Remove the old packages directory, so we can do a clean 'pub get'.
      var newPackagesDirectory = new Directory(newPackageRoot.toNativePath());
      if (newPackagesDirectory.existsSync()) {
        newPackagesDirectory.deleteSync(recursive: true);
      }

      // NOTE: We make a link in the package-root to [packageName], since
      // 'pub get' doesn't create the link to the package containing
      // pubspec.yaml if there is no lib directory.
      var packageLink = newPackageRoot.append(packageName);
      var packageLinkTarget = packageDir.append('lib');

      // NOTE: We make a link in the package-root to pkg/expect, since
      // 'package:expect' is not available on pub.dartlang.org!
      var expectLink = newPackageRoot.append('expect');
      var expectLinkTarget = TestUtils.dartDir
          .append('pkg').append('expect').append('lib');

      // Generate dependency overrides if we use repository packages.
      var packageDirectories = {};
      if (configuration['use_repository_packages']) {
        packageDirectories = new Map.from(localPackageDirectories);
        // Do not create an dependency override for the package itself.
        if (packageDirectories.containsKey(packageName)) {
          packageDirectories.remove(packageName);
        }
      }
      var overrides = buildPubspecDependencyOverrides(packageDirectories);

      commands.add(CommandBuilder.instance.getModifyPubspecCommand(
          pubspecYamlFile.toNativePath(), overrides,
          destinationFile: modifiedYamlFile.toNativePath()));
      commands.add(CommandBuilder.instance.getPubCommand(
          "get", pubPath, checkoutDirectory, pubCacheDirectory.toNativePath()));
      if (new Directory(packageLinkTarget.toNativePath()).existsSync()) {
        commands.add(CommandBuilder.instance.getMakeSymlinkCommand(
            packageLink.toNativePath(), packageLinkTarget.toNativePath()));
      }
      commands.add(CommandBuilder.instance.getMakeSymlinkCommand(
          expectLink.toNativePath(), expectLinkTarget.toNativePath()));

      return {
        'commands' : commands,
        'package-root' : newPackageRoot,
      };
    }

    // If this test is inside a package, we will check if there is a
    // pubspec.yaml file and if so, create a custom package root for it.
    List<Command> baseCommands = <Command>[];
    Path packageRoot;
    if (configuration['use_repository_packages'] ||
        configuration['use_public_packages']) {
        Path pubspecYamlFile = _findPubspecYamlFile(filePath);
        if (pubspecYamlFile != null) {
          var result = buildSpecialPackageRoot(pubspecYamlFile);
          baseCommands.addAll(result['commands']);
          packageRoot = result['package-root'];
          if (optionsFromFile['packageRoot'] == null ||
              optionsFromFile['packageRoot'] == "") {
            optionsFromFile['packageRoot'] = packageRoot.toNativePath();
          }
      }
    }
    String testName = buildTestCaseDisplayName(suiteDir, info.originTestPath,
        multitestName: optionsFromFile['isMultitest'] ? info.multitestKey : "");

    Set<Expectation> expectations = testExpectations.expectations(testName);
    if (new CompilerConfiguration(configuration).hasCompiler &&
        expectCompileError(info)) {
      // If a compile-time error is expected, and we're testing a
      // compiler, we never need to attempt to run the program (in a
      // browser or otherwise).
      enqueueStandardTest(baseCommands, info, testName, expectations);
    } else if (TestUtils.isBrowserRuntime(configuration['runtime'])) {
      if (info.optionsFromFile['isMultiHtmlTest']) {
        // A browser multi-test has multiple expectations for one test file.
        // Find all the different sub-test expecations for one entire test file.
        List<String> subtestNames = info.optionsFromFile['subtestNames'];
        Map<String, Set<Expectation>> multiHtmlTestExpectations = {};
        for (String name in subtestNames) {
          String fullTestName = '$testName/$name';
          multiHtmlTestExpectations[fullTestName] =
              testExpectations.expectations(fullTestName);
        }
        enqueueBrowserTest(baseCommands, packageRoot, info, testName,
            multiHtmlTestExpectations);
      } else {
        enqueueBrowserTest(
            baseCommands, packageRoot, info, testName, expectations);
      }
    } else {
      enqueueStandardTest(
          baseCommands, info, testName, expectations);
    }
  }

  void enqueueStandardTest(List<Command> baseCommands,
                           TestInformation info,
                           String testName,
                           Set<Expectation> expectations) {
    var commonArguments = commonArgumentsFromFile(info.filePath,
                                                  info.optionsFromFile);

    List<List<String>> vmOptionsList = getVmOptions(info.optionsFromFile);
    assert(!vmOptionsList.isEmpty);

    for (var vmOptions in vmOptionsList) {
      var allVmOptions = vmOptions;
      if (!extraVmOptions.isEmpty) {
        allVmOptions = new List.from(vmOptions)..addAll(extraVmOptions);
      }

      var commands = []..addAll(baseCommands);
      commands.addAll(makeCommands(info, allVmOptions, commonArguments));
      enqueueNewTestCase(
          new TestCase('$suiteName/$testName',
                       commands,
                       configuration,
                       expectations,
                       isNegative: isNegative(info),
                       info: info));
    }
  }

  bool expectCompileError(TestInformation info) {
    return info.hasCompileError ||
        (configuration['checked'] && info.hasCompileErrorIfChecked);
  }

  bool isNegative(TestInformation info) {
    bool negative = expectCompileError(info) ||
        (configuration['checked'] && info.isNegativeIfChecked);
    if (info.hasRuntimeError && hasRuntime) {
      negative = true;
    }
    return negative;
  }

  List<Command> makeCommands(TestInformation info, var vmOptions, var args) {
    List<Command> commands = <Command>[];
    CompilerConfiguration compilerConfiguration =
        new CompilerConfiguration(configuration);
    List<String> sharedOptions = info.optionsFromFile['sharedOptions'];

    List<String> compileTimeArguments = <String>[];
    String tempDir;
    if (compilerConfiguration.hasCompiler) {
      compileTimeArguments
          ..addAll(args)
          ..addAll(sharedOptions);
      // Avoid doing this for analyzer.
      tempDir = createCompilationOutputDirectory(info.filePath);
    }

    CommandArtifact compilationArtifact =
        compilerConfiguration.computeCompilationArtifact(
            buildDir,
            tempDir,
            CommandBuilder.instance,
            compileTimeArguments,
            environmentOverrides);
    commands.addAll(compilationArtifact.commands);

    if (expectCompileError(info) && compilerConfiguration.hasCompiler) {
      // Do not attempt to run the compiled result. A compilation
      // error should be reported by the compilation command.
      return commands;
    }

    RuntimeConfiguration runtimeConfiguration =
        new RuntimeConfiguration(configuration);
    List<String> runtimeArguments =
        compilerConfiguration.computeRuntimeArguments(
            runtimeConfiguration,
            buildDir,
            info,
            vmOptions, sharedOptions, args,
            compilationArtifact);

    return commands
        ..addAll(
            runtimeConfiguration.computeRuntimeCommands(
                this,
                CommandBuilder.instance,
                compilationArtifact,
                runtimeArguments,
                environmentOverrides));
  }

  CreateTest makeTestCaseCreator(Map optionsFromFile) {
    return (Path filePath,
            bool hasCompileError,
            bool hasRuntimeError,
            {bool isNegativeIfChecked: false,
             bool hasCompileErrorIfChecked: false,
             bool hasStaticWarning: false,
             String multitestKey,
             Path originTestPath}) {
      // Cache the test information for each test case.
      var info = new TestInformation(filePath,
                                     optionsFromFile,
                                     hasCompileError,
                                     hasRuntimeError,
                                     isNegativeIfChecked,
                                     hasCompileErrorIfChecked,
                                     hasStaticWarning,
                                     multitestKey: multitestKey,
                                     originTestPath: originTestPath);
      cachedTests.add(info);
      enqueueTestCaseFromTestInformation(info);
    };
  }

  /**
   * _createUrlPathFromFile takes a [file], which is either located in the dart
   * or in the build directory, and will return a String representing
   * the relative path to either the dart or the build directory.
   * Thus, the returned [String] will be the path component of the URL
   * corresponding to [file] (the http server serves files relative to the
   * dart/build directories).
   */
  String _createUrlPathFromFile(Path file) {
    file = TestUtils.absolutePath(file);

    var relativeBuildDir = new Path(TestUtils.buildDir(configuration));
    var buildDir = TestUtils.absolutePath(relativeBuildDir);
    var dartDir = TestUtils.absolutePath(TestUtils.dartDir);

    var fileString = file.toString();
    if (fileString.startsWith(buildDir.toString())) {
      var fileRelativeToBuildDir = file.relativeTo(buildDir);
      return "/$PREFIX_BUILDDIR/$fileRelativeToBuildDir";
    } else if (fileString.startsWith(dartDir.toString())) {
      var fileRelativeToDartDir = file.relativeTo(dartDir);
      return "/$PREFIX_DARTDIR/$fileRelativeToDartDir";
    }
    // Unreachable
    print("Cannot create URL for path $file. Not in build or dart directory.");
    exit(1);
  }

  String _getUriForBrowserTest(TestInformation info,
                            String pathComponent,
                            subtestNames,
                            subtestIndex) {
    // Note: If we run test.py with the "--list" option, no http servers
    // will be started. So we use PORT/CROSS_ORIGIN_PORT instead of real ports.
    var serverPort = "PORT";
    var crossOriginPort = "CROSS_ORIGIN_PORT";
    if (!configuration['list']) {
      assert(configuration.containsKey('_servers_'));
      serverPort = configuration['_servers_'].port;
      crossOriginPort = configuration['_servers_'].crossOriginPort;
    }

    var localIp = configuration['local_ip'];
    var url= 'http://$localIp:$serverPort$pathComponent'
        '?crossOriginPort=$crossOriginPort';
    if (info.optionsFromFile['isMultiHtmlTest'] && subtestNames.length > 0) {
      url= '${url}&group=${subtestNames[subtestIndex]}';
    }
    return url;
  }

  void _createWrapperFile(String dartWrapperFilename,
                          Path localDartLibraryFilename) {
    File file = new File(dartWrapperFilename);
    RandomAccessFile dartWrapper = file.openSync(mode: FileMode.WRITE);

    var usePackageImport = localDartLibraryFilename.segments().contains("pkg");
    var libraryPathComponent = _createUrlPathFromFile(localDartLibraryFilename);
    var generatedSource = dartTestWrapper(libraryPathComponent);
    dartWrapper.writeStringSync(generatedSource);
    dartWrapper.closeSync();
  }

  /**
   * The [StandardTestSuite] has support for tests that
   * compile a test from Dart to JavaScript, and then run the resulting
   * JavaScript.  This function creates a working directory to hold the
   * JavaScript version of the test, and copies the appropriate framework
   * files to that directory.  It creates a [BrowserTestCase], which has
   * two sequential steps to be run by the [ProcessQueue] when the test is
   * executed: a compilation step and an execution step, both with the
   * appropriate executable and arguments. The [expectations] object can be
   * either a Set<String> if the test is a regular test, or a Map<String
   * subTestName, Set<String>> if we are running a browser multi-test (one
   * compilation and many browser runs).
   */
  void enqueueBrowserTest(List<Command> baseCommands,
                          Path packageRoot,
                          TestInformation info,
                          String testName,
                          expectations) {
    // TODO(Issue 14651): If we're on dartium, we need to pass [packageRoot]
    // on to the browser (it may be test specific).

    // TODO(kustermann/ricow): This method should be refactored.
    Map optionsFromFile = info.optionsFromFile;
    Path filePath = info.filePath;
    String filename = filePath.toString();

    final String compiler = configuration['compiler'];
    final String runtime = configuration['runtime'];

    for (var vmOptions in getVmOptions(optionsFromFile)) {
      // Create a unique temporary directory for each set of vmOptions.
      // TODO(dart:429): Replace separate replaceAlls with a RegExp when
      // replaceAll(RegExp, String) is implemented.
      String optionsName = '';
      if (getVmOptions(optionsFromFile).length > 1) {
          optionsName = vmOptions.join('-').replaceAll('-','')
                                           .replaceAll('=','')
                                           .replaceAll('/','');
      }
      final String compilationTempDir =
          createCompilationOutputDirectory(info.filePath);
      final String tempDir = createOutputDirectory(info.filePath, optionsName);

      String dartWrapperFilename = '$tempDir/test.dart';
      String compiledDartWrapperFilename = '$compilationTempDir/test.js';

      String content = null;
      Path dir = filePath.directoryPath;
      String nameNoExt = filePath.filenameWithoutExtension;

      Path pngPath = dir.append('$nameNoExt.png');
      Path txtPath = dir.append('$nameNoExt.txt');
      String customHtmlPath = dir.append('$nameNoExt.html').toNativePath();
      File customHtml = new File(customHtmlPath);

      // Construct the command(s) that compile all the inputs needed by the
      // browser test. For running Dart in DRT, this will be noop commands.
      List<Command> commands = []..addAll(baseCommands);

      // Use existing HTML document if available.
      String htmlPath;
      if (customHtml.existsSync()) {
        // If necessary, run the Polymer deploy steps.
        // TODO(jmesserly): this should be generalized for any tests that
        // require Pub deploy, not just polymer.
        if (customHtml.readAsStringSync().contains('<!--polymer-test')) {
          if (compiler != 'none') {
            commands.add(_polymerDeployCommand(
                customHtmlPath, tempDir, optionsFromFile));

            Path pubspecYamlFile = _findPubspecYamlFile(filePath);
            Path homeDir = pubspecYamlFile == null ? dir :
                pubspecYamlFile.directoryPath;
            htmlPath = '$tempDir/${dir.relativeTo(homeDir)}/$nameNoExt.html';
            dartWrapperFilename = '${htmlPath}_bootstrap.dart';
            compiledDartWrapperFilename = '$dartWrapperFilename.js';
          } else {
            htmlPath = customHtmlPath;
          }
        } else {
          htmlPath = '$tempDir/test.html';
          dartWrapperFilename = filePath.toNativePath();

          var htmlContents = customHtml.readAsStringSync();
          if (compiler == 'none') {
            htmlContents = htmlContents.replaceAll('%TEST_SCRIPTS%',
              '<script type="application/dart" '
              'src="${_createUrlPathFromFile(filePath)}"></script>\n'
              '<script type="text/javascript" '
                  'src="/packages/browser/dart.js"></script>');
          } else {
            compiledDartWrapperFilename = '$tempDir/$nameNoExt.js';
            var jsFile = '$nameNoExt.js';
            htmlContents = htmlContents.replaceAll('%TEST_SCRIPTS%',
              '<script src="$jsFile"></script>');
          }
          new File(htmlPath).writeAsStringSync(htmlContents);
        }
      } else {
        htmlPath = '$tempDir/test.html';
        if (configuration['compiler'] != 'dart2js') {
          // test.dart will import the dart test.
          _createWrapperFile(dartWrapperFilename, filePath);
        } else {
          dartWrapperFilename = filename;
        }

        // Create the HTML file for the test.
        RandomAccessFile htmlTest =
            new File(htmlPath).openSync(mode: FileMode.WRITE);

        String scriptPath = dartWrapperFilename;
        if (compiler != 'none') {
          scriptPath = compiledDartWrapperFilename;
        }
        scriptPath = _createUrlPathFromFile(new Path(scriptPath));

        content =
            getHtmlContents(filename, scriptType, new Path("$scriptPath"));
        htmlTest.writeStringSync(content);
        htmlTest.closeSync();
      }

      if (compiler != 'none') {
        commands.add(_compileCommand(
            dartWrapperFilename, compiledDartWrapperFilename,
            compiler, tempDir, vmOptions, optionsFromFile));
      }

      // some tests require compiling multiple input scripts.
      List<String> otherScripts = optionsFromFile['otherScripts'];
      for (String name in otherScripts) {
        Path namePath = new Path(name);
        String fileName = namePath.filename;
        Path fromPath = filePath.directoryPath.join(namePath);
        if (compiler != 'none') {
          assert(namePath.extension == 'dart');
          commands.add(_compileCommand(
              fromPath.toNativePath(), '$tempDir/$fileName.js',
              compiler, tempDir, vmOptions, optionsFromFile));
        }
        if (compiler == 'none') {
          // For the tests that require multiple input scripts but are not
          // compiled, move the input scripts over with the script so they can
          // be accessed.
          String result = new File(fromPath.toNativePath()).readAsStringSync();
          new File('$tempDir/$fileName').writeAsStringSync(result);
        }
      }


      // Variables for browser multi-tests.
      List<String> subtestNames = info.optionsFromFile['subtestNames'];
      int subtestIndex = 0;
      // Construct the command that executes the browser test
      do {
        List<Command> commandSet = new List<Command>.from(commands);

        var htmlPath_subtest = _createUrlPathFromFile(new Path(htmlPath));
        var fullHtmlPath = _getUriForBrowserTest(info, htmlPath_subtest,
                                                 subtestNames, subtestIndex);

        List<String> args = <String>[];

        if (runtime == "drt") {
          var dartFlags = [];
          var contentShellOptions = [];

          contentShellOptions.add('--no-timeout');
          contentShellOptions.add('--dump-render-tree');

          if (compiler == 'none' || compiler == 'dart2dart') {
            dartFlags.add('--ignore-unrecognized-flags');
            if (configuration["checked"]) {
              dartFlags.add('--enable_asserts');
              dartFlags.add("--enable_type_checks");
            }
            dartFlags.addAll(vmOptions);
          }

          commandSet.add(CommandBuilder.instance.getContentShellCommand(
              contentShellFilename, fullHtmlPath, contentShellOptions,
              dartFlags, environmentOverrides));
        } else {
          commandSet.add(CommandBuilder.instance.getBrowserTestCommand(
              runtime, fullHtmlPath, checkedMode: configuration['checked']));
        }

        // Create BrowserTestCase and queue it.
        String testDisplayName = '$suiteName/$testName';
        var testCase;
        if (info.optionsFromFile['isMultiHtmlTest']) {
          testDisplayName = '$testDisplayName/${subtestNames[subtestIndex]}';
          testCase = new BrowserTestCase(testDisplayName,
              commandSet, configuration,
              expectations['$testName/${subtestNames[subtestIndex]}'],
              info, isNegative(info), fullHtmlPath);
        } else {
          testCase = new BrowserTestCase(testDisplayName,
              commandSet, configuration, expectations,
              info, isNegative(info), fullHtmlPath);
        }

        enqueueNewTestCase(testCase);
        subtestIndex++;
      } while(subtestIndex < subtestNames.length);
    }
  }

  /** Helper to create a compilation command for a single input file. */
  Command _compileCommand(String inputFile, String outputFile,
      String compiler, String dir, vmOptions, optionsFromFile) {
    assert (['dart2js', 'dart2dart'].contains(compiler));
    String executable = compilerPath;
    List<String> args = TestUtils.standardOptions(configuration);
    String packageRoot =
      packageRootArgument(optionsFromFile['packageRoot']);
    if (packageRoot != null) {
      args.add(packageRoot);
    }
    args.add('--out=$outputFile');
    if (configuration['csp']) args.add('--csp');
    args.add(inputFile);
    args.addAll(optionsFromFile['sharedOptions']);
    if (executable.endsWith('.dart')) {
      // Run the compiler script via the Dart VM.
      args.insert(0, executable);
      executable = dartVmBinaryFileName;
    }
    return CommandBuilder.instance.getCompilationCommand(
        compiler, outputFile, !useSdk,
        dart2JsBootstrapDependencies, compilerPath, args, environmentOverrides);
  }

  /** Helper to create a Polymer deploy command for a single HTML file. */
  Command _polymerDeployCommand(String inputFile, String outputDir,
      optionsFromFile) {
    List<String> args = [];
    String packageRoot = packageRootArgument(optionsFromFile['packageRoot']);
    if (packageRoot != null) args.add(packageRoot);
    args..add('package:polymer/deploy.dart')
        ..add('--test')..add(inputFile)
        ..add('--out')..add(outputDir)
        ..add('--file-filter')..add('.svn');
    if (configuration['csp']) args.add('--csp');

    return CommandBuilder.instance.getProcessCommand(
        'polymer_deploy', dartVmBinaryFileName, args, environmentOverrides);
  }

  String get scriptType {
    switch (configuration['compiler']) {
      case 'none':
      case 'dart2dart':
        return 'application/dart';
      case 'dart2js':
      case 'dartanalyzer':
      case 'dart2analyzer':
        return 'text/javascript';
      default:
        print('Non-web runtime, so no scriptType for: '
                    '${configuration["compiler"]}');
        exit(1);
        return null;
    }
  }

  bool get hasRuntime {
    switch(configuration['runtime']) {
      case 'none':
        return false;
      default:
        return true;
    }
  }

  String get contentShellFilename {
    if (configuration['drt'] != '') {
      return configuration['drt'];
    }
    if (Platform.operatingSystem == 'macos') {
      final path = dartDir.append(
          '/client/tests/drt/Content Shell.app/Contents/MacOS/Content Shell');
      return path.toNativePath();
    }
    return dartDir.append('client/tests/drt/content_shell').toNativePath();
  }

  List<String> commonArgumentsFromFile(Path filePath, Map optionsFromFile) {
    List args = TestUtils.standardOptions(configuration);

    String packageRoot = packageRootArgument(optionsFromFile['packageRoot']);
    if (packageRoot != null) {
      args.add(packageRoot);
    }
    args.addAll(additionalOptions(filePath));
    if (configuration['analyzer']) {
      args.add('--machine');
      args.add('--no-hints');
    }

    if ((configuration["compiler"] == "dartanalyzer" ||
        configuration["compiler"] == "dart2analyzer") &&
        (filePath.filename.contains("dart2js") ||
        filePath.directoryPath.segments().last.contains('html_common'))) {
      args.add("--use-dart2js-libraries");
    }

    bool isMultitest = optionsFromFile["isMultitest"];
    List<String> dartOptions = optionsFromFile["dartOptions"];

    assert(!isMultitest || dartOptions == null);
    if (dartOptions == null) {
      args.add(filePath.toNativePath());
    } else {
      var executable_name = dartOptions[0];
      // TODO(ager): Get rid of this hack when the runtime checkout goes away.
      var file = new File(executable_name);
      if (!file.existsSync()) {
        executable_name = '../$executable_name';
        assert(new File(executable_name).existsSync());
        dartOptions[0] = executable_name;
      }
      args.addAll(dartOptions);
    }

    return args;
  }

  String packageRoot(String packageRootFromFile) {
    if (packageRootFromFile == "none") {
      return null;
    }
    String packageRoot = packageRootFromFile;
    if (packageRootFromFile == null) {
      packageRoot = "$buildDir/packages/";
    }
    return packageRoot;
  }

  String packageRootArgument(String packageRootFromFile) {
    var packageRootPath = packageRoot(packageRootFromFile);
    if (packageRootPath == null) {
      return null;
    }
    return "--package-root=$packageRootPath";
  }

  /**
   * Special options for individual tests are currently specified in various
   * ways: with comments directly in test files, by using certain imports, or by
   * creating additional files in the test directories.
   *
   * Here is a list of options that are used by 'test.dart' today:
   *   - Flags can be passed to the vm or dartium process that runs the test by
   *   adding a comment to the test file:
   *
   *     // VMOptions=--flag1 --flag2
   *
   *   - Flags can be passed to dart2js, dart2dart or vm by adding a comment
   *   to the test file:
   *
   *     // SharedOptions=--flag1 --flag2
   *
   *   - Flags can be passed to the dart script that contains the test also
   *   using comments, as follows:
   *
   *     // DartOptions=--flag1 --flag2
   *
   *   - For tests that depend on compiling other files with dart2js (e.g.
   *   isolate tests that use multiple source scripts), you can specify
   *   additional files to compile using a comment too, as follows:
   *
   *     // OtherScripts=file1.dart file2.dart
   *
   *   - You can indicate whether a test is treated as a web-only test by
   *   using an explicit import to a part of the the dart:html library:
   *
   *     import 'dart:html';
   *     import 'dart:web_audio';
   *     import 'dart:indexed_db';
   *     import 'dart:svg';
   *     import 'dart:web_sql';
   *
   *   Most tests are not web tests, but can (and will be) wrapped within
   *   another script file to test them also on browser environments (e.g.
   *   language and corelib tests are run this way). We deduce that if this
   *   import is specified, the test was intended to be a web test and no
   *   wrapping is necessary.
   *
   *   - You can convert DRT web-tests into layout-web-tests by specifying a
   *   test expectation file. An expectation file is located in the same
   *   location as the test, it has the same file name, except for the extension
   *   (which can be either .txt or .png).
   *
   *   When there are no expectation files, 'test.dart' assumes tests fail if
   *   the process return a non-zero exit code (in the case of web tests, we
   *   check for PASS/FAIL indications in the test output).
   *
   *   When there is an expectation file, tests are run differently: the test
   *   code is run to the end of the event loop and 'test.dart' takes a snapshot
   *   of what is rendered in the page at that moment. This snapshot is
   *   represented either in text form, if the expectation ends in .txt, or as
   *   an image, if the expectation ends in .png. 'test.dart' will compare the
   *   snapshot to the expectation file. When tests fail, 'test.dart' saves the
   *   new snapshot into a file so it can be visualized or copied over.
   *   Expectations can be recorded for the first time by creating an empty file
   *   with the right name (touch test_name_test.png), running the test, and
   *   executing the copy command printed by the test script.
   *
   * This method is static as the map is cached and shared amongst
   * configurations, so it may not use [configuration].
   */
  Map readOptionsFromFile(Path filePath) {
    if (filePath.segments().contains('co19')) {
      return readOptionsFromCo19File(filePath);
    }
    RegExp testOptionsRegExp = new RegExp(r"// VMOptions=(.*)");
    RegExp sharedOptionsRegExp = new RegExp(r"// SharedOptions=(.*)");
    RegExp dartOptionsRegExp = new RegExp(r"// DartOptions=(.*)");
    RegExp otherScriptsRegExp = new RegExp(r"// OtherScripts=(.*)");
    RegExp packageRootRegExp = new RegExp(r"// PackageRoot=(.*)");
    RegExp isolateStubsRegExp = new RegExp(r"// IsolateStubs=(.*)");
    // TODO(gram) Clean these up once the old directives are not supported.
    RegExp domImportRegExp =
        new RegExp(r"^[#]?import.*dart:(html|web_audio|indexed_db|svg|web_sql)",
        multiLine: true);

    var bytes = new File(filePath.toNativePath()).readAsBytesSync();
    String contents = decodeUtf8(bytes);
    bytes = null;

    // Find the options in the file.
    List<List> result = new List<List>();
    List<String> dartOptions;
    List<String> sharedOptions;
    String packageRoot;

    Iterable<Match> matches = testOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      result.add(match[1].split(' ').where((e) => e != '').toList());
    }
    if (result.isEmpty) result.add([]);

    matches = dartOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      if (dartOptions != null) {
        throw new Exception(
            'More than one "// DartOptions=" line in test $filePath');
      }
      dartOptions = match[1].split(' ').where((e) => e != '').toList();
    }

    matches = sharedOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      if (sharedOptions != null) {
        throw new Exception(
            'More than one "// SharedOptions=" line in test $filePath');
      }
      sharedOptions = match[1].split(' ').where((e) => e != '').toList();
    }

    matches = packageRootRegExp.allMatches(contents);
    for (var match in matches) {
      if (packageRoot != null) {
        throw new Exception(
            'More than one "// PackageRoot=" line in test $filePath');
      }
      packageRoot = match[1];
      if (packageRoot != 'none') {
        // PackageRoot=none means that no package-root option should be given.
        packageRoot = '${filePath.directoryPath.join(new Path(packageRoot))}';
      }
    }

    List<String> otherScripts = new List<String>();
    matches = otherScriptsRegExp.allMatches(contents);
    for (var match in matches) {
      otherScripts.addAll(match[1].split(' ').where((e) => e != '').toList());
    }

    bool isMultitest = multiTestRegExp.hasMatch(contents);
    bool isMultiHtmlTest = multiHtmlTestRegExp.hasMatch(contents);
    Match isolateMatch = isolateStubsRegExp.firstMatch(contents);
    String isolateStubs = isolateMatch != null ? isolateMatch[1] : '';
    bool containsDomImport = domImportRegExp.hasMatch(contents);

    List<String> subtestNames = [];
    Iterator matchesIter =
        multiHtmlTestGroupRegExp.allMatches(contents).iterator;
    while(matchesIter.moveNext() && isMultiHtmlTest) {
      String fullMatch = matchesIter.current.group(0);
      subtestNames.add(fullMatch.substring(fullMatch.indexOf("'") + 1));
    }

    return { "vmOptions": result,
             "sharedOptions": sharedOptions == null ? [] : sharedOptions,
             "dartOptions": dartOptions,
             "packageRoot": packageRoot,
             "hasCompileError": false,
             "hasRuntimeError": false,
             "hasStaticWarning" : false,
             "otherScripts": otherScripts,
             "isMultitest": isMultitest,
             "isMultiHtmlTest": isMultiHtmlTest,
             "subtestNames": subtestNames,
             "isolateStubs": isolateStubs,
             "containsDomImport": containsDomImport };
  }

  List<List<String>> getVmOptions(Map optionsFromFile) {
    var COMPILERS = const ['none', 'dart2dart'];
    var RUNTIMES = const ['none', 'vm', 'drt', 'dartium',
                          'ContentShellOnAndroid', 'DartiumOnAndroid'];
    var needsVmOptions = COMPILERS.contains(configuration['compiler']) &&
                         RUNTIMES.contains(configuration['runtime']);
    if (!needsVmOptions) return [[]];
    final vmOptions = optionsFromFile['vmOptions'];
    if (configuration['compiler'] != 'dart2dart') return vmOptions;
    // Temporary workaround for race in test suite: tests with different
    // vm options are still compiled into the same output file which
    // may lead to reads from empty files.
    return [vmOptions[0]];
  }

  /**
   * Read options from a co19 test file.
   *
   * The reason this is different from [readOptionsFromFile] is that
   * co19 is developed based on a contract which defines certain test
   * tags. These tags may appear unused, but should not be removed
   * without consulting with the co19 team.
   *
   * Also, [readOptionsFromFile] recognizes a number of additional
   * tags that are not appropriate for use in general tests of
   * conformance to the Dart language. Any Dart implementation must
   * pass the co19 test suite as is, and not require extra flags,
   * environment variables, configuration files, etc.
   */
  Map readOptionsFromCo19File(Path filePath) {
    String contents = decodeUtf8(new File(filePath.toNativePath())
        .readAsBytesSync());

    bool hasCompileError = contents.contains("@compile-error");
    bool hasRuntimeError = contents.contains("@runtime-error");
    bool hasStaticWarning = contents.contains("@static-warning");
    bool isMultitest = multiTestRegExp.hasMatch(contents);

    return {
      "vmOptions": <List>[[]],
      "sharedOptions": <String>[],
      "dartOptions": null,
      "packageRoot": null,
      "hasCompileError": hasCompileError,
      "hasRuntimeError": hasRuntimeError,
      "hasStaticWarning" : hasStaticWarning,
      "otherScripts": <String>[],
      "isMultitest": isMultitest,
      "isMultiHtmlTest": false,
      "subtestNames": <String>[],
      "isolateStubs": '',
      "containsDomImport": false,
    };
  }
}


/// A DartcCompilationTestSuite will run dartc on all of the tests.
///
/// Usually, the result of a dartc run is determined by the output of
/// dartc in connection with annotations in the test file.
class DartcCompilationTestSuite extends StandardTestSuite {
  List<String> _testDirs;

  DartcCompilationTestSuite(Map configuration,
                            String suiteName,
                            String directoryPath,
                            List<String> this._testDirs,
                            List<String> expectations)
      : super(configuration,
              suiteName,
              new Path(directoryPath),
              expectations);

  List<String> additionalOptions(Path filePath) {
    return ['--fatal-warnings', '--fatal-type-errors'];
  }

  Future enqueueTests() {
    var group = new FutureGroup();

    for (String testDir in _testDirs) {
      Directory dir = new Directory(suiteDir.append(testDir).toNativePath());
      if (dir.existsSync()) {
        enqueueDirectory(dir, group);
      }
    }

    return group.future;
  }
}

class AnalyzeLibraryTestSuite extends DartcCompilationTestSuite {
  AnalyzeLibraryTestSuite(Map configuration)
      : super(configuration,
              'analyze_library',
              'sdk',
              ['lib'],
              ['tests/lib/analyzer/analyze_library.status']);

  List<String> additionalOptions(Path filePath, {bool showSdkWarnings}) {
    var options = super.additionalOptions(filePath);
    // NOTE: This flag has been deprecated.
    options.add('--show-sdk-warnings');
    return options;
  }

  bool isTestFile(String filename) {
    var sep = Platform.pathSeparator;
    // NOTE: We exclude tests and patch files for now.
    return filename.endsWith(".dart") &&
        !filename.endsWith("_test.dart") &&
        !filename.contains("_internal/lib");
  }

  bool get listRecursively => true;
}

class PkgBuildTestSuite extends TestSuite {
  final String statusFilePath;

  PkgBuildTestSuite(Map configuration, String suiteName, this.statusFilePath)
      : super(configuration, suiteName) {
    assert(configuration['use_sdk']);;
  }

  void forEachTest(void onTest(TestCase testCase), _, [void onDone()]) {
    bool fileExists(Path path) => new File(path.toNativePath()).existsSync();

    bool dirExists(Path path)
        => new Directory(path.toNativePath()).existsSync();

    enqueueTestCases(Map<String, String> localPackageDirectories,
                     Map<String, String> localSampleDirectories,
                     TestExpectations testExpectations) {
      enqueueTestCase(String packageName, String directory) {
        var absoluteDirectoryPath = new Path(directory);

        // Early return if this package is not using pub.
        if (!fileExists(absoluteDirectoryPath.append('pubspec.yaml'))) {
          return;
        }

        var directoryPath =
            absoluteDirectoryPath.relativeTo(TestUtils.dartDir);
        var testName = "$directoryPath";
        var displayName = '$suiteName/$testName';
        var packageName = directoryPath.filename;

        // Collect necessary paths for pubspec.yaml overrides, pub-cache, ...
        var checkoutDir =
            createPubPackageBuildsDirectory(absoluteDirectoryPath);
        var cacheDir = new Path(checkoutDir).append("pub-cache").toNativePath();
        var pubspecYamlFile =
            new Path(checkoutDir).append('pubspec.yaml').toNativePath();

        var packageDirectories = {};
        if (!configuration['use_public_packages']) {
          packageDirectories = new Map.from(localPackageDirectories);
          if (packageDirectories.containsKey(packageName)) {
            packageDirectories.remove(packageName);
          }
        }
        var dependencyOverrides =
            buildPubspecDependencyOverrides(packageDirectories);

        // Build all commands
        var commands = new List<Command>();
        commands.add(
            CommandBuilder.instance.getCopyCommand(directory, checkoutDir));
        commands.add(CommandBuilder.instance.getModifyPubspecCommand(
            pubspecYamlFile, dependencyOverrides));
        commands.add(CommandBuilder.instance.getPubCommand(
            "get", pubPath, checkoutDir, cacheDir));

        bool containsWebDirectory = dirExists(directoryPath.append('web'));
        bool containsBuildDartFile =
            fileExists(directoryPath.append('build.dart'));
        if (containsBuildDartFile) {
          var dartBinary = new File(dartVmBinaryFileName).absolute.path;

          commands.add(CommandBuilder.instance.getProcessCommand(
              "custom_build", dartBinary, ['build.dart'],
              {'PUB_CACHE': cacheDir}, checkoutDir));

          // We only try to deploy the application if it's a webapp.
          if (containsWebDirectory) {
            commands.add(CommandBuilder.instance.getProcessCommand(
                 "custom_deploy", dartBinary, ['build.dart', '--deploy'],
                 {'PUB_CACHE': cacheDir}, checkoutDir));
          }
        } else if (containsWebDirectory)  {
          commands.add(CommandBuilder.instance.getPubCommand(
             "build", pubPath, checkoutDir, cacheDir));
        }

        // Enqueue TestCase
        var testCase = new TestCase(displayName,
            commands, configuration, testExpectations.expectations(testName));
        enqueueNewTestCase(testCase);
      }

      localPackageDirectories.forEach(enqueueTestCase);
      localSampleDirectories.forEach(enqueueTestCase);

      doTest = null;
      // Notify we're done
      if (onDone != null) onDone();
    }

    doTest = onTest;
    Map<String, String> _localPackageDirectories;
    Map<String, String> _localSampleDirectories;
    List<String> statusFiles = [
        TestUtils.dartDir.join(new Path(statusFilePath)).toNativePath()];
    ReadTestExpectations(statusFiles, configuration).then((expectations) {
      Future.wait([discoverPackagesInRepository(),
                   discoverSamplesInRepository()]).then((List results) {
        Map packageDirectories = results[0];
        Map sampleDirectories = results[1];
        enqueueTestCases(packageDirectories, sampleDirectories, expectations);
      });
    });
  }
}


class LastModifiedCache {
  Map<String, DateTime> _cache = <String, DateTime>{};

  /**
   * Returns the last modified date of the given [uri].
   *
   * The return value will be cached for future queries. If [uri] is a local
   * file, it's last modified [Date] will be returned. If the file does not
   * exist, null will be returned instead.
   * In case [uri] is not a local file, this method will always return
   * the current date.
   */
  DateTime getLastModified(Uri uri) {
    if (uri.scheme == "file") {
      if (_cache.containsKey(uri.path)) {
        return _cache[uri.path];
      }
      var file = new File(new Path(uri.path).toNativePath());
      _cache[uri.path] = file.existsSync() ? file.lastModifiedSync() : null;
      return _cache[uri.path];
    }
    return new DateTime.now();
  }
}

class ExistsCache {
  Map<String, bool> _cache = <String, bool>{};

  /**
   * Returns true if the file in [path] exists, false otherwise.
   *
   * The information will be cached.
   */
  bool doesFileExist(String path) {
    if (!_cache.containsKey(path)) {
      _cache[path] = new File(path).existsSync();
    }
    return _cache[path];
  }
}

class TestUtils {
  /**
   * Any script using TestUtils must set dartDirUri to a file:// URI
   * pointing to the root of the Dart checkout.
   */
  static setDartDirUri(uri) {
    dartDirUri = uri;
    dartDir = new Path(uri.toFilePath());
  }
  static Uri dartDirUri;
  static Path dartDir;
  static LastModifiedCache lastModifiedCache = new LastModifiedCache();
  static ExistsCache existsCache = new ExistsCache();
  static Path currentWorkingDirectory =
      new Path(Directory.current.path);

  /**
   * Creates a directory using a [relativePath] to an existing
   * [base] directory if that [relativePath] does not already exist.
   */
  static Directory mkdirRecursive(Path base, Path relativePath) {
    if (relativePath.isAbsolute) {
      base = new Path('/');
    }
    Directory dir = new Directory(base.toNativePath());
    assert(dir.existsSync());
    var segments = relativePath.segments();
    for (String segment in segments) {
      base = base.append(segment);
      if (base.toString() == "/$segment" &&
          segment.length == 2 &&
          segment.endsWith(':')) {
        // Skip the directory creation for a path like "/E:".
        continue;
      }
      dir = new Directory(base.toNativePath());
      if (!dir.existsSync()) {
        dir.createSync();
      }
      assert(dir.existsSync());
    }
    return dir;
  }

  /**
   * Copy a [source] file to a new place.
   * Assumes that the directory for [dest] already exists.
   */
  static Future copyFile(Path source, Path dest) {
    return new File(source.toNativePath()).openRead()
        .pipe(new File(dest.toNativePath()).openWrite());
  }

  static Future copyDirectory(String source, String dest) {
    source = new Path(source).toNativePath();
    dest = new Path(dest).toNativePath();

    var executable = 'cp';
    var args = ['-Rp', source, dest];
    if (Platform.operatingSystem == 'windows') {
      executable = 'xcopy';
      args = [source, dest, '/e', '/i'];
    }
    return Process.run(executable, args).then((ProcessResult result) {
      if (result.exitCode != 0) {
        throw new Exception("Failed to execute '$executable "
            "${args.join(' ')}'.");
      }
    });
  }

  static Future deleteDirectory(String path) {
    // We are seeing issues with long path names on windows when
    // deleting them. Use the system tools to delete our long paths.
    // See issue 16264.
    if (Platform.operatingSystem == 'windows') {
      var native_path = new Path(path).toNativePath();
      // Running this in a shell sucks, but rmdir is not part of the standard
      // path.
      return Process.run('rmdir', ['/s', '/q', native_path], runInShell: true)
        .then((ProcessResult result) {
          if (result.exitCode != 0) {
            throw new Exception('Can\'t delete path $native_path. '
                                'This path might be too long');
          }  
        });
    } else {
      var dir = new Directory(path);
      return dir.delete(recursive: true);
    }
  }

  static Path debugLogfile() {
    return new Path(".debug.log");
  }

  static String flakyFileName() {
    // If a flaky test did fail, infos about it (i.e. test name, stdin, stdout)
    // will be written to this file. This is useful for the debugging of
    // flaky tests.
    // When running on a built bot, the file can be made visible in the
    // waterfall UI.
    return ".flaky.log";
  }

  static String testOutcomeFileName() {
    // If test.py was invoked with '--write-test-outcome-log it will write
    // test outcomes to this file.
    return ".test-outcome.log";
  }

  static void ensureExists(String filename, Map configuration) {
    if (!configuration['list'] && !existsCache.doesFileExist(filename)) {
      throw "'$filename' does not exist";
    }
  }

  static Path absolutePath(Path path) {
    if (!path.isAbsolute) {
      return currentWorkingDirectory.join(path);
    }
    return path;
  }

  static String outputDir(Map configuration) {
    var result = '';
    var system = configuration['system'];
    if (system == 'linux') {
      result = 'out/';
    } else if (system == 'macos') {
      result = 'xcodebuild/';
    } else if (system == 'windows') {
      result = 'build/';
    }
    return result;
  }

  static List<String> standardOptions(Map configuration) {
    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add('--enable_asserts');
      args.add("--enable_type_checks");
    }
    String compiler = configuration["compiler"];
    if (compiler == "dart2js" || compiler == "dart2dart") {
      args = [];
      if (configuration["checked"]) {
        args.add('--enable-checked-mode');
      }
      // args.add("--verbose");
      if (!isBrowserRuntime(configuration['runtime'])) {
        args.add("--allow-mock-compilation");
        args.add("--categories=all");
      }
    }
    if ((compiler == "dart2js" || compiler == "dart2dart") &&
        configuration["minified"]) {
      args.add("--minify");
    }
    if (compiler == "dartanalyzer" || compiler == "dart2analyzer") {
      args.add("--show-package-warnings");
      args.add("--enable-async");
    }
    return args;
  }

  static bool isBrowserRuntime(String runtime) {
    const BROWSERS = const [
      'drt',
      'dartium',
      'ie9',
      'ie10',
      'ie11',
      'safari',
      'opera',
      'chrome',
      'ff',
      'chromeOnAndroid',
      'safarimobilesim',
      'ContentShellOnAndroid',
      'DartiumOnAndroid'
    ];
    return BROWSERS.contains(runtime);
  }

  static bool isJsCommandLineRuntime(String runtime) =>
      const ['d8', 'jsshell'].contains(runtime);

  static bool isCommandLineAnalyzer(String compiler) =>
      compiler == 'dartanalyzer' || compiler == 'dart2analyzer';

  static String buildDir(Map configuration) {
    // FIXME(kustermann,ricow): Our code assumes that the returned 'buildDir'
    // is relative to the current working directory.
    // Thus, if we pass in an absolute path (e.g. '--build-directory=/tmp/out')
    // we get into trouble.
    if (configuration['build_directory'] != '') {
      return configuration['build_directory'];
    }

    return "${outputDir(configuration)}${configurationDir(configuration)}";
  }

  static getValidOutputDir(Map configuration, String mode, String arch) {
    // We allow our code to have been cross compiled, i.e., that there
    // is an X in front of the arch. We don't allow both a cross compiled
    // and a normal version to be present (except if you specifically pass
    // in the build_directory).
    var normal = '$mode$arch';
    var cross = '${mode}X$arch';
    var outDir = outputDir(configuration);
    var normalDir = new Directory(new Path('$outDir$normal').toNativePath());
    var crossDir = new Directory(new Path('$outDir$cross').toNativePath());
    if (normalDir.existsSync() && crossDir.existsSync()) {
      throw "You can't have both $normalDir and $crossDir, we don't know which"
            " binary to use";
    }
    if (crossDir.existsSync()) {
      return cross;
    }
    return normal;
  }

  static String configurationDir(Map configuration) {
    // For regular dart checkouts, the configDir by default is mode+arch.
    // For Dartium, the configDir by default is mode (as defined by the Chrome
    // build setup). We can detect this because in the dartium checkout, the
    // "output" directory is a sibling of the dart directory instead of a child.
    var mode = (configuration['mode'] == 'debug') ? 'Debug' : 'Release';
    var arch = configuration['arch'].toUpperCase();
    if (currentWorkingDirectory != dartDir) {
      return getValidOutputDir(configuration, mode, arch);
    } else {
      return mode;
    }
  }

  /**
   * Returns the path to the dart binary checked into the repo, used for
   * bootstrapping test.dart.
   */
  static Path get dartTestExecutable {
    var path = '$dartDir/tools/testing/bin/'
        '${Platform.operatingSystem}/dart';
    if (Platform.operatingSystem == 'windows') {
      path = '$path.exe';
    }
    return new Path(path);
  }

  /**
   * Gets extra options under [key] passed to the testing script.
   */
  static List<String> getExtraOptions(Map configuration, String key) {
    if (configuration[key] == null) return <String>[];
    return configuration[key]
        .split(" ")
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /**
   * Gets extra vm options passed to the testing script.
   */
  static List<String> getExtraVmOptions(Map configuration) =>
      getExtraOptions(configuration, 'vm_options');

  static String getShortName(String path) {
    final PATH_REPLACEMENTS = const {
      "pkg_polymer_e2e_test_bad_import_test": "polymer_bi",
      "pkg_polymer_e2e_test_canonicalization_test": "polymer_c16n",
      "pkg_polymer_e2e_test_experimental_boot_test": "polymer_boot",
      "pkg_polymer_e2e_test_good_import_test": "polymer_gi",
      "tests_co19_src_Language_12_Expressions_14_Function_Invocation_":
          "co19_fn_invoke_",
      "tests_co19_src_LayoutTests_fast_css_getComputedStyle_getComputedStyle-":
          "co19_css_getComputedStyle_",
      "tests_co19_src_LayoutTests_fast_dom_Document_CaretRangeFromPoint_"
          "caretRangeFromPoint-": "co19_caretrangefrompoint_",
      "tests_co19_src_LayoutTests_fast_dom_Document_CaretRangeFromPoint_"
          "hittest-relative-to-viewport_": "co19_caretrange_hittest_",
      "tests_co19_src_LayoutTests_fast_dom_HTMLLinkElement_link-onerror-"
          "stylesheet-with-": "co19_dom_link-",
      "tests_co19_src_LayoutTests_fast_dom_": "co19_dom",
      "tests_co19_src_LayoutTests_fast_canvas_webgl": "co19_canvas_webgl",
      "tests_co19_src_LibTest_core_AbstractClassInstantiationError_"
          "AbstractClassInstantiationError_": "co19_abstract_class_",
      "tests_co19_src_LibTest_core_IntegerDivisionByZeroException_"
          "IntegerDivisionByZeroException_": "co19_division_by_zero",
      "tests_co19_src_WebPlatformTest_html_dom_documents_dom-tree-accessors_":
          "co19_dom_accessors_",
      "tests_co19_src_WebPlatformTest_html_semantics_embedded-content_"
          "media-elements_": "co19_media_elements",
      "tests_co19_src_WebPlatformTest_html_semantics_": "co19_semantics_",

      "tests_co19_src_WebPlatformTest_html-templates_additions-to-"
          "the-steps-to-clone-a-node_": "co19_htmltemplates_clone_",
      "tests_co19_src_WebPlatformTest_html-templates_definitions_"
          "template-contents-owner": "co19_htmltemplates_contents",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_additions-to-": "co19_htmltemplates_add_",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_appending-to-a-template_": "co19_htmltemplates_append_",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_clearing-the-stack-back-to-a-given-context_":
          "co19_htmltemplates_clearstack_",
      "tests_co19_src_WebPlatformTest_html-templates_parsing-html-"
          "templates_creating-an-element-for-the-token_":
          "co19_htmltemplates_create_",
      "tests_co19_src_WebPlatformTest_html-templates_template-element"
          "_template-": "co19_htmltemplates_element-",
      "tests_co19_src_WebPlatformTest_html-templates_": "co19_htmltemplate_",

      "tests_co19_src_WebPlatformTest_shadow-dom_shadow-trees_":
          "co19_shadow-trees_",
      "tests_co19_src_WebPlatformTest_shadow-dom_elements-and-dom-objects_":
          "co19_shadowdom_",
      "tests_co19_src_WebPlatformTest_shadow-dom_html-elements-in-"
          "shadow-trees_": "co19_shadow_html_",
      "tests_co19_src_WebPlatformTest_html_webappapis_system-state-and-"
          "capabilities_the-navigator-object": "co19_webappapis_navigator_",
      "tests_co19_src_WebPlatformTest_DOMEvents_approved_": "co19_dom_approved_"
    };

    // Some tests are already in [build_dir]/generated_tests.
    String GEN_TESTS = 'generated_tests/';
    if (path.contains(GEN_TESTS)) {
      int index = path.indexOf(GEN_TESTS) + GEN_TESTS.length;
      path = 'multitest/${path.substring(index)}';
    }
    path = path.replaceAll('/', '_');
    final int WINDOWS_SHORTEN_PATH_LIMIT = 58;
    if (Platform.operatingSystem == 'windows' &&
        path.length > WINDOWS_SHORTEN_PATH_LIMIT) {
      for (var key in PATH_REPLACEMENTS.keys) {
        if (path.startsWith(key)) {
          path = path.replaceFirst(key, PATH_REPLACEMENTS[key]);
          break;
        }
      }
    }
    return path;
  }
}

class SummaryReport {
  static int total = 0;
  static int skipped = 0;
  static int skippedByDesign = 0;
  static int noCrash = 0;
  static int pass = 0;
  static int failOk = 0;
  static int fail = 0;
  static int crash = 0;
  static int timeout = 0;
  static int compileErrorSkip = 0;

  static void add(Set<Expectation> expectations) {
    bool containsFail = expectations.any(
        (expectation) => expectation.canBeOutcomeOf(Expectation.FAIL));
    ++total;
    if (expectations.contains(Expectation.SKIP)) {
      ++skipped;
    } else if (expectations.contains(Expectation.SKIP_BY_DESIGN)) {
      ++skipped;
      ++skippedByDesign;
    } else {
      // Counts the number of flaky tests.
      if (expectations.contains(Expectation.PASS) &&
          containsFail &&
          !expectations.contains(Expectation.CRASH) &&
          !expectations.contains(Expectation.OK)) {
        ++noCrash;
      }
      if (expectations.contains(Expectation.PASS) && expectations.length == 1) {
        ++pass;
      }
      if (expectations.containsAll([Expectation.FAIL, Expectation.OK]) &&
          expectations.length == 2) {
        ++failOk;
      }
      if (containsFail && expectations.length == 1) {
        ++fail;
      }
      if (expectations.contains(Expectation.CRASH) &&
          expectations.length == 1) {
        ++crash;
      }
      if (expectations.contains(Expectation.TIMEOUT)) {
        ++timeout;
      }
    }
  }

  static void addCompileErrorSkipTest() {
    total++;
    compileErrorSkip++;
  }

  static void printReport() {
    if (total == 0) return;
    String report = """Total: $total tests
 * $skipped tests will be skipped ($skippedByDesign skipped by design)
 * $noCrash tests are expected to be flaky but not crash
 * $pass tests are expected to pass
 * $failOk tests are expected to fail that we won't fix
 * $fail tests are expected to fail that we should fix
 * $crash tests are expected to crash that we should fix
 * $timeout tests are allowed to timeout
 * $compileErrorSkip tests are skipped on browsers due to compile-time error
""";
    print(report);
  }
}
