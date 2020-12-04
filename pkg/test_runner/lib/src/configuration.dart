// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:smith/smith.dart';

import 'compiler_configuration.dart';
import 'feature.dart';
import 'path.dart';
import 'repository.dart';
import 'runtime_configuration.dart';
import 'testing_servers.dart';

export 'package:smith/smith.dart';

/// All of the contextual information to determine how a test suite should be
/// run.
///
/// Includes the compiler used to compile the code, the runtime the result is
/// executed on, etc.
class TestConfiguration {
  TestConfiguration(
      {this.configuration,
      this.progress,
      this.selectors,
      this.build,
      this.testList,
      this.repeat,
      this.batch,
      this.batchDart2JS,
      this.copyCoreDumps,
      this.rr,
      this.isVerbose,
      this.listTests,
      this.listStatusFiles,
      this.cleanExit,
      this.silentFailures,
      this.printTiming,
      this.printReport,
      this.reportFailures,
      this.reportInJson,
      this.resetBrowser,
      this.skipCompilation,
      this.writeDebugLog,
      this.writeResults,
      this.writeLogs,
      this.drtPath,
      this.chromePath,
      this.safariPath,
      this.firefoxPath,
      this.dartPath,
      this.dartPrecompiledPath,
      this.genSnapshotPath,
      this.taskCount,
      this.shardCount,
      this.shard,
      this.stepName,
      this.testServerPort,
      this.testServerCrossOriginPort,
      this.testDriverErrorPort,
      this.localIP,
      this.keepGeneratedFiles,
      this.sharedOptions,
      String packages,
      this.suiteDirectory,
      this.outputDirectory,
      this.reproducingArguments,
      this.fastTestsOnly,
      this.printPassingStdout})
      : _packages = packages;

  final Map<String, RegExp> selectors;
  final Progress progress;
  // The test configuration read from the -n option and the test matrix
  // or else computed from the test options.
  final Configuration configuration;

  // Boolean flags.

  final bool batch;
  final bool batchDart2JS;
  final bool build;
  final bool copyCoreDumps;
  final bool rr;
  final bool fastTestsOnly;
  final bool isVerbose;
  final bool listTests;
  final bool listStatusFiles;
  final bool cleanExit;
  final bool silentFailures;
  final bool printTiming;
  final bool printReport;
  final bool reportFailures;
  final bool reportInJson;
  final bool resetBrowser;
  final bool skipCompilation;
  final bool writeDebugLog;
  final bool writeResults;
  final bool writeLogs;
  final bool printPassingStdout;

  Architecture get architecture => configuration.architecture;
  Compiler get compiler => configuration.compiler;
  Mode get mode => configuration.mode;
  Runtime get runtime => configuration.runtime;
  System get system => configuration.system;
  NnbdMode get nnbdMode => configuration.nnbdMode;
  Sanitizer get sanitizer => configuration.sanitizer;

  // Boolean getters
  bool get hotReload => configuration.useHotReload;
  bool get hotReloadRollback => configuration.useHotReloadRollback;
  bool get isChecked => configuration.isChecked;
  bool get isHostChecked => configuration.isHostChecked;
  bool get isCsp => configuration.isCsp;
  bool get isMinified => configuration.isMinified;
  bool get useAnalyzerCfe => configuration.useAnalyzerCfe;
  bool get useAnalyzerFastaParser => configuration.useAnalyzerFastaParser;
  bool get useElf => configuration.useElf;
  bool get useSdk => configuration.useSdk;
  bool get enableAsserts => configuration.enableAsserts;
  bool get useQemu => configuration.useQemu;

  // Various file paths.

  final String drtPath;
  final String chromePath;
  final String safariPath;
  final String firefoxPath;
  final String dartPath;
  final String dartPrecompiledPath;
  final String genSnapshotPath;
  final List<String> testList;

  final int taskCount;
  final int shardCount;
  final int shard;
  final int repeat;
  final String stepName;

  final int testServerPort;
  final int testServerCrossOriginPort;
  final int testDriverErrorPort;
  final String localIP;
  final bool keepGeneratedFiles;

  /// Extra dart2js options passed to the testing script.
  List<String> get dart2jsOptions => configuration.dart2jsOptions;

  /// Extra gen_kernel options passed to the testing script.
  List<String> get genKernelOptions => configuration.genKernelOptions;

  /// Extra VM options passed to the testing script.
  List<String> get vmOptions => configuration.vmOptions;

  /// The names of the experiments to enable while running tests.
  ///
  /// A test may *require* an experiment to always be enabled by containing a
  /// comment like:
  ///
  ///     // SharedOptions=--enable-experiment=extension-methods
  ///
  /// Enabling an experiment here in the configuration allows running the same
  /// test both with an experiment on and off.
  List<String> get experiments => configuration.experiments;

  /// Extra general options passed to the testing script.
  final List<String> sharedOptions;

  String _packages;

  String get packages {
    // If the .packages file path wasn't given, find it.
    _packages ??= Repository.uri.resolve('.packages').toFilePath();

    return _packages;
  }

  final String outputDirectory;
  final String suiteDirectory;
  String get babel => configuration.babel;
  String get builderTag => configuration.builderTag;
  final List<String> reproducingArguments;

  TestingServers _servers;

  TestingServers get servers {
    if (_servers == null) {
      throw StateError("Servers have not been started yet.");
    }
    return _servers;
  }

  /// Returns true if this configuration uses the new front end (fasta)
  /// as the first stage of compilation.
  bool get usesFasta {
    var fastaCompilers = const [
      Compiler.appJitk,
      Compiler.dartdevk,
      Compiler.dartk,
      Compiler.dartkp,
      Compiler.fasta,
      Compiler.dart2js,
    ];
    return fastaCompilers.contains(compiler);
  }

  /// The base directory named for this configuration, like:
  ///
  ///     ReleaseX64
  String _configurationDirectory;

  String get configurationDirectory {
    // Lazy initialize and cache since it requires hitting the file system.
    return _configurationDirectory ??= _calculateDirectory();
  }

  /// The build directory path for this configuration, like:
  ///
  ///     build/ReleaseX64
  String get buildDirectory => system.outputDirectory + configurationDirectory;

  int _timeout;

  // TODO(whesse): Put non-default timeouts explicitly in configs, not this.
  /// Calculates a default timeout based on the compiler and runtime used,
  /// and the mode, architecture, etc.
  int get timeout {
    if (_timeout == null) {
      if (configuration.timeout > 0) {
        _timeout = configuration.timeout;
      } else {
        var isReload = hotReload || hotReloadRollback;

        var compilerMulitiplier = compilerConfiguration.timeoutMultiplier;
        var runtimeMultiplier = runtimeConfiguration.timeoutMultiplier(
            mode: mode,
            isChecked: isChecked,
            isReload: isReload,
            arch: architecture);

        _timeout = 60 * compilerMulitiplier * runtimeMultiplier;
      }
    }

    return _timeout;
  }

  List<String> get standardOptions {
    if (compiler != Compiler.dart2js) {
      return const ["--ignore-unrecognized-flags"];
    }

    var args = ['--test-mode'];

    if (isMinified) args.add("--minify");
    if (isCsp) args.add("--csp");
    if (enableAsserts) args.add("--enable-asserts");
    return args;
  }

  String _windowsSdkPath;

  String get windowsSdkPath {
    if (!Platform.isWindows) {
      throw StateError(
          "Should not use windowsSdkPath when not running on Windows.");
    }

    if (_windowsSdkPath == null) {
      // When running tests on Windows, use cdb from depot_tools to dump
      // stack traces of tests timing out.
      try {
        var path = Path("build/win_toolchain.json").toNativePath();
        var text = File(path).readAsStringSync();
        _windowsSdkPath = jsonDecode(text)['win_sdk'] as String;
      } on dynamic {
        // Ignore errors here. If win_sdk is not found, stack trace dumping
        // for timeouts won't work.
      }
    }

    return _windowsSdkPath;
  }

  /// Gets the local file path to the browser executable for this configuration.
  String get browserLocation {
    // If the user has explicitly configured a browser path, use it.
    String location;
    switch (runtime) {
      case Runtime.chrome:
        location = chromePath;
        break;
      case Runtime.firefox:
        location = firefoxPath;
        break;
      case Runtime.safari:
        location = safariPath;
        break;
    }

    if (location != null) return location;

    const locations = {
      Runtime.firefox: {
        System.win: 'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe',
        System.linux: 'firefox',
        System.mac: '/Applications/Firefox.app/Contents/MacOS/firefox'
      },
      Runtime.chrome: {
        System.win:
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
        System.mac:
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        System.linux: 'google-chrome'
      },
      Runtime.safari: {
        System.mac: '/Applications/Safari.app/Contents/MacOS/Safari'
      },
      Runtime.ie9: {
        System.win: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      },
      Runtime.ie10: {
        System.win: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      },
      Runtime.ie11: {
        System.win: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      }
    };

    location = locations[runtime][System.find(Platform.operatingSystem)];

    if (location == null) {
      throw "${runtime.name} is not supported on ${Platform.operatingSystem}";
    }

    return location;
  }

  RuntimeConfiguration _runtimeConfiguration;

  RuntimeConfiguration get runtimeConfiguration =>
      _runtimeConfiguration ??= RuntimeConfiguration(this);

  CompilerConfiguration _compilerConfiguration;

  CompilerConfiguration get compilerConfiguration =>
      _compilerConfiguration ??= CompilerConfiguration(this);

  Set<Feature> _supportedFeatures;

  /// The set of [Feature]s supported by this configuration.
  Set<Feature> get supportedFeatures {
    if (_supportedFeatures != null) return _supportedFeatures;

    _supportedFeatures = {};
    switch (nnbdMode) {
      case NnbdMode.legacy:
        _supportedFeatures.add(Feature.nnbdLegacy);
        break;
      case NnbdMode.weak:
        _supportedFeatures.add(Feature.nnbd);
        _supportedFeatures.add(Feature.nnbdWeak);
        break;
      case NnbdMode.strong:
        _supportedFeatures.add(Feature.nnbd);
        _supportedFeatures.add(Feature.nnbdStrong);
        break;
    }

    // TODO(rnystrom): Define more features for things like "dart:io", separate
    // int/double representation, etc.

    return _supportedFeatures;
  }

  /// Determines if this configuration has a compatible compiler and runtime
  /// and other valid fields.
  ///
  /// Prints a warning if the configuration isn't valid. Returns whether or not
  /// it is.
  bool validate() {
    var isValid = true;
    var validRuntimes = compiler.supportedRuntimes;

    if (!validRuntimes.contains(runtime)) {
      print("Warning: combination of compiler '${compiler.name}' and "
          "runtime '${runtime.name}' is invalid. Skipping this combination.");
      isValid = false;
    }

    if (runtime.isIE &&
        Platform.operatingSystem != 'windows' &&
        !listStatusFiles &&
        !listTests) {
      print("Warning: cannot run Internet Explorer on non-Windows operating"
          " system.");
      isValid = false;
    }

    if (architecture == Architecture.ia32 && compiler == Compiler.dartkp) {
      print("Warning: IA32 does not support AOT mode.");
      isValid = false;
    }

    if (system == System.android &&
        !(architecture == Architecture.ia32 ||
            architecture == Architecture.x64 ||
            architecture == Architecture.arm ||
            architecture == Architecture.arm_x64 ||
            architecture == Architecture.arm64)) {
      print("Warning: Android only supports the following "
          "architectures: ia32/x64/arm/arm64/arm_x64.");
      isValid = false;
    }

    if (shard < 1 || shard > shardCount) {
      print("Error: shard index is $shard out of $shardCount shards");
      isValid = false;
    }

    return isValid;
  }

  /// Starts global HTTP servers that serve the entire dart repo.
  ///
  /// The HTTP server is available on `window.location.port`, and a second
  /// server for cross-domain tests can be found by calling
  /// `getCrossOriginPortNumber()`.
  Future startServers() {
    _servers = TestingServers(buildDirectory, isCsp, runtime, null, packages);
    var future = servers.startServers(localIP,
        port: testServerPort, crossOriginPort: testServerCrossOriginPort);

    if (isVerbose) {
      future = future.then((_) {
        print('Started HttpServers: ${servers.commandLine}');
      });
    }

    return future;
  }

  void stopServers() {
    if (_servers != null) _servers.stopServers();
  }

  /// Returns the correct configuration directory (the last component of the
  /// output directory path) for regular dart checkouts.
  ///
  /// We allow our code to have been cross compiled, i.e., that there is an X
  /// in front of the arch. We don't allow both a cross compiled and a normal
  /// version to be present (except if you specifically pass in the
  /// build_directory).
  String _calculateDirectory() {
    // Capitalize the mode name.
    var result =
        mode.name.substring(0, 1).toUpperCase() + mode.name.substring(1);

    if (system == System.android) result += "Android";
    if (system == System.fuchsia) result += "Fuchsia";

    if (sanitizer != Sanitizer.none) {
      result += sanitizer.name.toUpperCase();
    }

    var arch = architecture.name.toUpperCase();
    var normal = '$result$arch';
    var cross = '${result}X$arch';

    var outDir = system.outputDirectory;
    var normalDir = Directory(Path('$outDir$normal').toNativePath());
    var crossDir = Directory(Path('$outDir$cross').toNativePath());

    if (normalDir.existsSync() && crossDir.existsSync()) {
      throw "You can't have both $normalDir and $crossDir. We don't know which"
          " binary to use.";
    }

    return crossDir.existsSync() ? cross : normal;
  }
}

class Progress {
  static const compact = Progress._('compact');
  static const color = Progress._('color');
  static const line = Progress._('line');
  static const verbose = Progress._('verbose');
  static const silent = Progress._('silent');
  static const status = Progress._('status');
  static const buildbot = Progress._('buildbot');

  static final List<String> names = _all.keys.toList();

  static final _all = Map<String, Progress>.fromIterable(
      [compact, color, line, verbose, silent, status, buildbot],
      key: (progress) => (progress as Progress).name);

  static Progress find(String name) {
    var progress = _all[name];
    if (progress != null) return progress;

    throw ArgumentError('Unknown progress type "$name".');
  }

  final String name;

  const Progress._(this.name);

  String toString() => "Progress($name)";
}
