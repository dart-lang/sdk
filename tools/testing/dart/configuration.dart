// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:smith/smith.dart';
export 'package:smith/smith.dart';

import 'compiler_configuration.dart';
import 'http_server.dart';
import 'path.dart';
import 'repository.dart';
import 'runtime_configuration.dart';

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
      this.appendLogs,
      this.batch,
      this.batchDart2JS,
      this.copyCoreDumps,
      this.isVerbose,
      this.listTests,
      this.listStatusFiles,
      this.printTiming,
      this.printReport,
      this.reportInJson,
      this.resetBrowser,
      this.skipCompilation,
      this.useKernelBytecode,
      this.writeDebugLog,
      this.writeTestOutcomeLog,
      this.writeResultLog,
      this.drtPath,
      this.chromePath,
      this.safariPath,
      this.firefoxPath,
      this.dartPath,
      this.dartPrecompiledPath,
      this.flutterPath,
      this.taskCount,
      this.shardCount,
      this.shard,
      this.stepName,
      this.testServerPort,
      this.testServerCrossOriginPort,
      this.testDriverErrorPort,
      this.localIP,
      this.dart2jsOptions,
      String packages,
      this.packageRoot,
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

  final bool appendLogs;
  final bool batch;
  final bool batchDart2JS;
  final bool copyCoreDumps;
  final bool fastTestsOnly;
  final bool isVerbose;
  final bool listTests;
  final bool listStatusFiles;
  final bool printTiming;
  final bool printReport;
  final bool reportInJson;
  final bool resetBrowser;
  final bool skipCompilation;
  final bool useKernelBytecode;
  final bool writeDebugLog;
  final bool writeTestOutcomeLog;
  final bool writeResultLog;
  final bool printPassingStdout;

  Architecture get architecture => configuration.architecture;
  Compiler get compiler => configuration.compiler;
  Mode get mode => configuration.mode;
  Runtime get runtime => configuration.runtime;
  System get system => configuration.system;

  // Boolean getters
  bool get hotReload => configuration.useHotReload;
  bool get hotReloadRollback => configuration.useHotReloadRollback;
  bool get isChecked => configuration.isChecked;
  bool get isHostChecked => configuration.isHostChecked;
  bool get isCsp => configuration.isCsp;
  bool get isMinified => configuration.isMinified;
  bool get noPreviewDart2 => !configuration.previewDart2;
  bool get useAnalyzerCfe => configuration.useAnalyzerCfe;
  bool get useAnalyzerFastaParser => configuration.useAnalyzerFastaParser;
  bool get useBlobs => configuration.useBlobs;
  bool get useSdk => configuration.useSdk;
  bool get useFastStartup => configuration.useFastStartup;
  bool get useEnableAsserts => configuration.enableAsserts;
  bool get useDart2JSWithKernel => configuration.useDart2JSWithKernel;
  bool get useDart2JSOldFrontend => configuration.useDart2JSOldFrontEnd;

  // Various file paths.

  final String drtPath;
  final String chromePath;
  final String safariPath;
  final String firefoxPath;
  final String dartPath;
  final String dartPrecompiledPath;
  final String flutterPath;

  final int taskCount;
  final int shardCount;
  final int shard;
  final String stepName;

  final int testServerPort;
  final int testServerCrossOriginPort;
  final int testDriverErrorPort;
  final String localIP;

  /// Extra dart2js options passed to the testing script.
  final List<String> dart2jsOptions;

  /// Extra VM options passed to the testing script.
  List<String> get vmOptions => configuration.vmOptions;

  String _packages;

  String get packages {
    // If the .packages file path wasn't given, find it.
    if (packageRoot == null && _packages == null) {
      _packages = Repository.uri.resolve('.packages').toFilePath();
    }

    return _packages;
  }

  final String outputDirectory;
  final String packageRoot;
  final String suiteDirectory;
  String get builderTag => configuration.builderTag;
  final List<String> reproducingArguments;

  TestingServers _servers;

  TestingServers get servers {
    if (_servers == null) {
      throw new StateError("Servers have not been started yet.");
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
      Compiler.dartkb,
      Compiler.dartkp,
      Compiler.fasta,
    ];
    return fastaCompilers.contains(compiler) ||
        (compiler == Compiler.dart2js && !useDart2JSOldFrontend) ||
        (compiler == Compiler.dart2analyzer &&
            (builderTag == 'analyzer_use_fasta' || useAnalyzerCfe));
  }

  /// The base directory named for this configuration, like:
  ///
  ///     none_vm_release_x64
  String _configurationDirectory;

  String get configurationDirectory {
    // Lazy initialize and cache since it requires hitting the file system.
    if (_configurationDirectory == null) {
      _configurationDirectory = _calculateDirectory();
    }

    return _configurationDirectory;
  }

  /// The build directory path for this configuration, like:
  ///
  ///     build/none_vm_release_x64
  String get buildDirectory => system.outputDirectory + configurationDirectory;

  // TODO(whesse): Put non-default timeouts explicitly in configs, not this.
  /// Calculates a default timeout based on the compiler and runtime used,
  /// and the mode, architecture, etc.
  int get timeout {
    if (configuration.timeout == null) {
      var isReload = hotReload || hotReloadRollback;

      var compilerMulitiplier = compilerConfiguration.timeoutMultiplier;
      var runtimeMultiplier = runtimeConfiguration.timeoutMultiplier(
          mode: mode,
          isChecked: isChecked,
          isReload: isReload,
          arch: architecture);

      configuration.timeout = 60 * compilerMulitiplier * runtimeMultiplier;
    }

    return configuration.timeout;
  }

  List<String> get standardOptions {
    if (compiler != Compiler.dart2js) {
      return const ["--ignore-unrecognized-flags"];
    }

    var args = ['--generate-code-with-compile-time-errors', '--test-mode'];
    if (isChecked) args.add('--enable-checked-mode');

    if (!runtime.isBrowser) {
      args.add("--allow-mock-compilation");
      args.add("--categories=all");
    }

    if (isMinified) args.add("--minify");
    if (isCsp) args.add("--csp");
    if (useFastStartup) args.add("--fast-startup");
    if (useEnableAsserts) args.add("--enable-asserts");
    if (useDart2JSWithKernel) args.add("--use-kernel");
    if (useDart2JSOldFrontend) args.add("--use-old-frontend");
    return args;
  }

  String _windowsSdkPath;

  String get windowsSdkPath {
    if (!Platform.isWindows) {
      throw new StateError(
          "Should not use windowsSdkPath when not running on Windows.");
    }

    if (_windowsSdkPath == null) {
      // When running tests on Windows, use cdb from depot_tools to dump
      // stack traces of tests timing out.
      try {
        var path = new Path("build/win_toolchain.json").toNativePath();
        var text = new File(path).readAsStringSync();
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
      case Runtime.flutter:
        location = flutterPath;
        break;
      case Runtime.safari:
        location = safariPath;
        break;
    }

    if (location != null) return location;

    const locations = const {
      Runtime.firefox: const {
        System.win: 'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe',
        System.linux: 'firefox',
        System.mac: '/Applications/Firefox.app/Contents/MacOS/firefox'
      },
      Runtime.chrome: const {
        System.win:
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
        System.mac:
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        System.linux: 'google-chrome'
      },
      Runtime.safari: const {
        System.mac: '/Applications/Safari.app/Contents/MacOS/Safari'
      },
      Runtime.ie9: const {
        System.win: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      },
      Runtime.ie10: const {
        System.win: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      },
      Runtime.ie11: const {
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
      _runtimeConfiguration ??= new RuntimeConfiguration(this);

  CompilerConfiguration _compilerConfiguration;

  CompilerConfiguration get compilerConfiguration =>
      _compilerConfiguration ??= new CompilerConfiguration(this);

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

    if (shard < 1 || shard > shardCount) {
      print("Error: shard index is $shard out of $shardCount shards");
      isValid = false;
    }

    if (runtime == Runtime.flutter && flutterPath == null) {
      print("-rflutter requires the flutter engine executable to "
          "be specified using --flutter");
      isValid = false;
    }

    if (runtime == Runtime.flutter && architecture != Architecture.x64) {
      isValid = false;
      print("-rflutter is applicable only for --arch=x64");
    }

    return isValid;
  }

  /// Starts global HTTP servers that serve the entire dart repo.
  ///
  /// The HTTP server is available on `window.location.port`, and a second
  /// server for cross-domain tests can be found by calling
  /// `getCrossOriginPortNumber()`.
  Future startServers() {
    _servers = new TestingServers(
        buildDirectory, isCsp, runtime, null, packageRoot, packages);
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
    var modeName =
        mode.name.substring(0, 1).toUpperCase() + mode.name.substring(1);

    var os = '';
    if (system == System.android) os = "Android";

    var kbc = useKernelBytecode ? 'KBC' : '';
    var arch = architecture.name.toUpperCase();
    var normal = '$modeName$os$arch$kbc';
    var cross = '$modeName${os}X$arch$kbc';
    var outDir = system.outputDirectory;
    var normalDir = new Directory(new Path('$outDir$normal').toNativePath());
    var crossDir = new Directory(new Path('$outDir$cross').toNativePath());

    if (normalDir.existsSync() && crossDir.existsSync()) {
      throw "You can't have both $normalDir and $crossDir. We don't know which"
          " binary to use.";
    }

    if (crossDir.existsSync()) return cross;

    return normal;
  }

  Map _summaryMap;

  /// [toSummaryMap] returns a map of configurations important to the running
  /// of a test. Flags and properties used for output are not included.
  /// The summary map can be used to serialize to json for test-output logging.
  Map toSummaryMap() {
    if (_summaryMap == null) {
      _summaryMap = {
        'mode': mode.name,
        'arch': architecture.name,
        'compiler': compiler.name,
        'runtime': runtime.name,
        'checked': isChecked,
        'host_checked': isHostChecked,
        'minified': isMinified,
        'csp': isCsp,
        'system': system.name,
        'vm_options': vmOptions,
        'fasta': usesFasta,
        'use_sdk': useSdk,
        'builder_tag': builderTag,
        'fast_startup': useFastStartup,
        'timeout': timeout,
        'no_preview_dart_2': noPreviewDart2,
        'use_cfe': useAnalyzerCfe,
        'analyzer_use_fasta_parser': useAnalyzerFastaParser,
        'dart2js_with_kernel': useDart2JSWithKernel,
        'dart2js_old_frontend': useDart2JSOldFrontend,
        'enable_asserts': useEnableAsserts,
        'hot_reload': hotReload,
        'hot_reload_rollback': hotReloadRollback,
        'batch': batch,
        'batch_dart2js': batchDart2JS,
        'reset_browser_configuration': resetBrowser,
        'selectors': selectors.keys.toList(),
        'use_kernel_bytecode': useKernelBytecode,
      };
    }
    return _summaryMap;
  }
}

class Progress {
  static const compact = const Progress._('compact');
  static const color = const Progress._('color');
  static const line = const Progress._('line');
  static const verbose = const Progress._('verbose');
  static const silent = const Progress._('silent');
  static const status = const Progress._('status');
  static const buildbot = const Progress._('buildbot');
  static const diff = const Progress._('diff');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Progress>.fromIterable(
      [compact, color, line, verbose, silent, status, buildbot, diff],
      key: (progress) => (progress as Progress).name);

  static Progress find(String name) {
    var progress = _all[name];
    if (progress != null) return progress;

    throw new ArgumentError('Unknown progress type "$name".');
  }

  final String name;

  const Progress._(this.name);

  String toString() => "Progress($name)";
}
