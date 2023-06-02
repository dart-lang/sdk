// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:native_assets_cli/native_assets_cli.dart' show CCompilerConfig;
import 'package:smith/configuration.dart';
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
      {required this.configuration,
      this.progress = Progress.compact,
      this.selectors = const {},
      this.build = false,
      this.testList = const [],
      this.repeat = 1,
      this.batch = false,
      this.copyCoreDumps = false,
      this.rr = false,
      this.isVerbose = false,
      this.listTests = false,
      this.listStatusFiles = false,
      this.cleanExit = false,
      this.silentFailures = false,
      this.printTiming = false,
      this.printReport = false,
      this.reportFailures = false,
      this.reportInJson = false,
      this.resetBrowser = false,
      this.writeDebugLog = false,
      this.writeResults = false,
      this.writeLogs = false,
      this.drtPath,
      this.chromePath,
      this.safariPath,
      this.firefoxPath,
      this.dartPath,
      this.dartPrecompiledPath,
      this.genSnapshotPath,
      this.taskCount = 1,
      this.shardCount = 1,
      this.shard = 1,
      this.stepName,
      this.testServerPort = 0,
      this.testServerCrossOriginPort = 0,
      this.testDriverErrorPort = 0,
      this.localIP = '0.0.0.0',
      this.keepGeneratedFiles = false,
      this.sharedOptions = const [],
      String? packages,
      this.serviceResponseSizesDirectory,
      this.suiteDirectory,
      required this.outputDirectory,
      required this.reproducingArguments,
      this.fastTestsOnly = false,
      this.printPassingStdout = false})
      : packages = packages ??
            Repository.uri
                .resolve('.dart_tool/package_config.json')
                .toFilePath();

  final Map<String, RegExp?> selectors;
  final Progress progress;
  // The test configuration read from the -n option and the test matrix
  // or else computed from the test options.
  final Configuration configuration;

  // Boolean flags.

  final bool batch;
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
  bool get isSimulator => architecture.isSimulator;
  bool get useAnalyzerCfe => configuration.useAnalyzerCfe;
  bool get useAnalyzerFastaParser => configuration.useAnalyzerFastaParser;
  bool get useElf => configuration.useElf;
  bool get useSdk => configuration.useSdk;
  bool get enableAsserts => configuration.enableAsserts;
  bool get useQemu => configuration.useQemu;

  // Various file paths.

  final String? drtPath;
  final String? chromePath;
  final String? safariPath;
  final String? firefoxPath;
  final String? dartPath;
  final String? dartPrecompiledPath;
  final String? genSnapshotPath;
  final List<String>? testList;

  final int taskCount;
  final int shardCount;
  final int shard;
  final int repeat;
  final String? stepName;

  final int testServerPort;
  final int testServerCrossOriginPort;
  final int testDriverErrorPort;
  final String localIP;
  final bool keepGeneratedFiles;

  /// Extra dart2js options passed to the testing script.
  List<String> get dart2jsOptions => configuration.dart2jsOptions;

  /// Extra ddc options passed to the testing script.
  List<String> get ddcOptions => configuration.ddcOptions;

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

  final String packages;

  final String? serviceResponseSizesDirectory;
  final String outputDirectory;
  final String? suiteDirectory;
  String get babel => configuration.babel;
  String get builderTag => configuration.builderTag;
  final List<String> reproducingArguments;

  TestingServers? _servers;

  TestingServers get servers {
    return _servers ?? (throw StateError("Servers have not been started yet."));
  }

  /// Returns true if this configuration uses the new front end (fasta)
  /// as the first stage of compilation.
  bool get usesFasta {
    var fastaCompilers = const [
      Compiler.appJitk,
      Compiler.ddc,
      Compiler.dartk,
      Compiler.dartkp,
      Compiler.fasta,
      Compiler.dart2js,
      Compiler.dart2wasm,
    ];
    return fastaCompilers.contains(compiler);
  }

  /// The base directory named for this configuration, like:
  ///
  ///     ReleaseX64
  String? _configurationDirectory;

  String get configurationDirectory {
    // Lazy initialize and cache since it requires hitting the file system.
    return _configurationDirectory ??= _calculateDirectory();
  }

  /// The build directory path for this configuration, like:
  ///
  ///     build/ReleaseX64
  String get buildDirectory => system.outputDirectory + configurationDirectory;

  int? _timeout;

  // TODO(whesse): Put non-default timeouts explicitly in configs, not this.
  /// Calculates a default timeout based on the compiler and runtime used,
  /// and the mode, architecture, etc.
  int get timeout {
    if (_timeout == null) {
      if (configuration.timeout > 0) {
        _timeout = configuration.timeout;
      } else {
        var isReload = hotReload || hotReloadRollback;

        var compilerMultiplier = compilerConfiguration.timeoutMultiplier;
        var runtimeMultiplier = runtimeConfiguration.timeoutMultiplier(
            mode: mode,
            isChecked: isChecked,
            isReload: isReload,
            arch: architecture);

        _timeout = 60 * compilerMultiplier * runtimeMultiplier;
      }
    }

    return _timeout!;
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

  late final String? windowsSdkPath = () {
    if (!Platform.isWindows) {
      throw StateError(
          "Should not use windowsSdkPath when not running on Windows.");
    }

    // When running tests on Windows, use cdb from depot_tools to dump
    // stack traces of tests timing out.
    try {
      var path = Path("build/win_toolchain.json").toNativePath();
      var text = File(path).readAsStringSync();
      return jsonDecode(text)['win_sdk'] as String;
    } catch (_) {
      // Ignore errors here. If win_sdk is not found, stack trace dumping
      // for timeouts won't work.
    }
  }();

  late final Map<String, String> nativeCompilerEnvironmentVariables = () {
    String unparseKey(String key) => key.replaceAll('.', '__').toUpperCase();
    final arKey = unparseKey(CCompilerConfig.arConfigKeyFull);
    final ccKey = unparseKey(CCompilerConfig.ccConfigKeyFull);
    final ldKey = unparseKey(CCompilerConfig.ldConfigKeyFull);
    final envScriptKey = unparseKey(CCompilerConfig.envScriptConfigKeyFull);
    final envScriptArgsKey =
        unparseKey(CCompilerConfig.envScriptArgsConfigKeyFull);

    if (Platform.isWindows) {
      // Use MSVC from Depot Tools instead. When using clang from DEPS, we still
      // need to pass the right INCLUDE / LIB environment variables. So we might
      // as well use the MSVC instead.
      final windowsSdkPath_ = windowsSdkPath;
      if (windowsSdkPath_ == null) {
        return <String, String>{};
      }
      final windowsSdk = Uri.directory(windowsSdkPath_);
      final vsPath = windowsSdk.resolve('../../');
      final msvcPaths = vsPath.resolve('VC/Tools/MSVC/');
      final msvcPath = Directory.fromUri(msvcPaths)
          .listSync()
          .firstWhere((element) => element.path != '.' && element.path != '..')
          .uri;
      const targetFolderName = {
        Abi.windowsX64: 'x64',
        Abi.windowsIA32: 'ia32',
        Abi.windowsArm64: 'arm64',
      };
      const envScriptArgument = {
        Abi.windowsX64: '/x64',
        Abi.windowsIA32: '/x86',
        Abi.windowsArm64: '/arm64',
      };
      final binDir =
          msvcPath.resolve('bin/Hostx64/${targetFolderName[Abi.current()]!}/');
      final toolchainEnvScript = windowsSdk.resolve('bin/SetEnv.cmd');
      return {
        arKey: binDir.resolve('lib.exe').toFilePath(),
        ccKey: binDir.resolve('cl.exe').toFilePath(),
        ldKey: binDir.resolve('link.exe').toFilePath(),
        envScriptKey: toolchainEnvScript.toFilePath(),
        envScriptArgsKey: envScriptArgument[Abi.current()]!,
      };
    }

    if (Platform.isMacOS) {
      // Use XCode instead, it has the right sysroot by default.
      return <String, String>{};
    }

    assert(Platform.isLinux);
    // Keep consistent with DEPS.
    const clangHostFolderName = {
      Abi.linuxArm64: 'linux-arm64',
      Abi.linuxX64: 'linux-x64',
    };
    final hostFolderName = clangHostFolderName[Abi.current()]!;
    final clangBin =
        Directory.current.uri.resolve('buildtools/$hostFolderName/clang/bin/');
    return {
      arKey: clangBin.resolve('llvm-ar').toFilePath(),
      ccKey: clangBin.resolve('clang').toFilePath(),
      ldKey: clangBin.resolve('ld.lld').toFilePath(),
    };
  }();

  /// Gets the local file path to the browser executable for this configuration.
  late final String browserLocation = () {
    // If the user has explicitly configured a browser path, use it.
    String? location;
    switch (runtime) {
      case Runtime.chrome:
        location = chromePath;
        break;
      case Runtime.firefox:
        location = firefoxPath;
        break;
    }

    if (location != null) return location;

    const locations = {
      Runtime.firefox: {
        System.win: 'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe',
        System.linux: '/usr/bin/firefox',
        System.mac: '/Applications/Firefox.app/Contents/MacOS/firefox'
      },
      Runtime.chrome: {
        System.win:
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
        System.mac:
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        System.linux: '/usr/bin/google-chrome'
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

    location = locations[runtime]![System.find(Platform.operatingSystem)];

    if (location == null) {
      throw "${runtime.name} is not supported on ${Platform.operatingSystem}";
    }

    return location;
  }();

  RuntimeConfiguration? _runtimeConfiguration;

  RuntimeConfiguration get runtimeConfiguration =>
      _runtimeConfiguration ??= RuntimeConfiguration(this);

  CompilerConfiguration? _compilerConfiguration;

  CompilerConfiguration get compilerConfiguration =>
      _compilerConfiguration ??= CompilerConfiguration(this);

  /// The set of [Feature]s supported by this configuration.
  late final Set<Feature> supportedFeatures = compiler == Compiler.dart2analyzer
      // The analyzer should parse all tests.
      ? {...Feature.all}
      : {
          // TODO(rnystrom): Define more features for things like "dart:io", separate
          // int/double representation, etc.
          if (NnbdMode.legacy == configuration.nnbdMode)
            Feature.nnbdLegacy
          else
            Feature.nnbd,
          if (NnbdMode.weak == configuration.nnbdMode) Feature.nnbdWeak,
          if (NnbdMode.strong == configuration.nnbdMode) Feature.nnbdStrong,
        };

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
            architecture == Architecture.arm64 ||
            architecture == Architecture.arm64c)) {
      print("Warning: Android only supports the following "
          "architectures: ia32/x64/arm/arm64/arm64c/arm_x64.");
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
    _servers?.stopServers();
  }

  /// Returns the correct configuration directory (the last component of the
  /// output directory path) for regular dart checkouts.
  ///
  /// We allow our code to have been cross compiled, i.e., that there is an X
  /// in front of the arch. We don't allow both a cross compiled and a normal
  /// version to be present (except if you specifically pass in the
  /// build-directory).
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

  @override
  String toString() => "Progress($name)";
}
