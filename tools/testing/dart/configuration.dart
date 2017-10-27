// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
class Configuration {
  Configuration(
      {this.architecture,
      this.compiler,
      this.mode,
      this.progress,
      this.runtime,
      this.system,
      this.selectors,
      this.appendLogs,
      this.batch,
      this.batchDart2JS,
      this.copyCoreDumps,
      this.hotReload,
      this.hotReloadRollback,
      this.isChecked,
      this.isStrong,
      this.isHostChecked,
      this.isCsp,
      this.isMinified,
      this.isVerbose,
      this.listTests,
      this.listStatusFiles,
      this.previewDart2,
      this.printTiming,
      this.printReport,
      this.reportInJson,
      this.resetBrowser,
      this.skipCompilation,
      this.useBlobs,
      this.useSdk,
      this.useFastStartup,
      this.useEnableAsserts,
      this.useDart2JSWithKernel,
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
      int timeout,
      this.shardCount,
      this.shard,
      this.stepName,
      this.testServerPort,
      this.testServerCrossOriginPort,
      this.testDriverErrorPort,
      this.localIP,
      this.dart2jsOptions,
      this.vmOptions,
      String packages,
      this.packageRoot,
      this.suiteDirectory,
      this.builderTag,
      this.outputDirectory,
      this.reproducingArguments})
      : _packages = packages,
        _timeout = timeout;

  final Architecture architecture;
  final Compiler compiler;
  final Mode mode;
  final Progress progress;
  final Runtime runtime;
  final System system;

  final Map<String, RegExp> selectors;

  // Boolean flags.

  final bool appendLogs;
  final bool batch;
  final bool batchDart2JS;
  final bool copyCoreDumps;
  final bool hotReload;
  final bool hotReloadRollback;
  final bool isChecked;
  final bool isStrong;
  final bool isHostChecked;
  final bool isCsp;
  final bool isMinified;
  final bool isVerbose;
  final bool listTests;
  final bool listStatusFiles;
  final bool previewDart2;
  final bool printTiming;
  final bool printReport;
  final bool reportInJson;
  final bool resetBrowser;
  final bool skipCompilation;
  final bool useBlobs;
  final bool useSdk;
  final bool useFastStartup;
  final bool useEnableAsserts;
  final bool useDart2JSWithKernel;
  final bool writeDebugLog;
  final bool writeTestOutcomeLog;
  final bool writeResultLog;

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
  final List<String> vmOptions;

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
  final String builderTag;
  final List<String> reproducingArguments;

  TestingServers _servers;
  TestingServers get servers {
    if (_servers == null) {
      throw new StateError("Servers have not been started yet.");
    }
    return _servers;
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

  int _timeout;
  int get timeout {
    if (_timeout == null) {
      var isReload = hotReload || hotReloadRollback;

      var compilerMulitiplier = compilerConfiguration.timeoutMultiplier;
      var runtimeMultiplier = runtimeConfiguration.timeoutMultiplier(
          mode: mode,
          isChecked: isChecked,
          isReload: isReload,
          arch: architecture);

      _timeout = 60 * compilerMulitiplier * runtimeMultiplier;
    }

    return _timeout;
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
        _windowsSdkPath = JSON.decode(text)['win_sdk'] as String;
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
      case Runtime.drt:
        location = drtPath;
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
        System.windows: 'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe',
        System.linux: 'firefox',
        System.macos: '/Applications/Firefox.app/Contents/MacOS/firefox'
      },
      Runtime.chrome: const {
        System.windows:
            'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
        System.macos:
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        System.linux: 'google-chrome'
      },
      Runtime.safari: const {
        System.macos: '/Applications/Safari.app/Contents/MacOS/Safari'
      },
      Runtime.safariMobileSim: const {
        System.macos: '/Applications/Xcode.app/Contents/Developer/Platforms/'
            'iPhoneSimulator.platform/Developer/Applications/'
            'iPhone Simulator.app/Contents/MacOS/iPhone Simulator'
      },
      Runtime.ie9: const {
        System.windows: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      },
      Runtime.ie10: const {
        System.windows: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
      },
      Runtime.ie11: const {
        System.windows: 'C:\\Program Files\\Internet Explorer\\iexplore.exe'
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

    if (compiler == Compiler.dartdevc && !isStrong) {
      isValid = false;
      print("--compiler dartdevc requires --strong");
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

    var arch = architecture.name.toUpperCase();
    var normal = '$modeName$os$arch';
    var cross = '$modeName${os}X$arch';
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
        'strong': isStrong,
        'host_checked': isHostChecked,
        'minified': isMinified,
        'csp': isCsp,
        'system': system.name,
        'vm_options': vmOptions,
        'use_sdk': useSdk,
        'builder_tag': builderTag,
        'fast_startup': useFastStartup,
        'timeout': timeout,
        'preview_dart_2': previewDart2,
        'dart2js_with_kernel': useDart2JSWithKernel,
        'enable_asserts': useEnableAsserts,
        'hot_reload': hotReload,
        'hot_reload_rollback': hotReloadRollback,
        'batch': batch,
        'batch_dart2js': batchDart2JS,
        'reset_browser_configuration': resetBrowser,
        'selectors': selectors.keys.toList()
      };
    }
    return _summaryMap;
  }
}

class Architecture {
  static const ia32 = const Architecture._('ia32');
  static const x64 = const Architecture._('x64');
  static const arm = const Architecture._('arm');
  static const armv6 = const Architecture._('armv6');
  static const armv5te = const Architecture._('armv5te');
  static const arm64 = const Architecture._('arm64');
  static const simarm = const Architecture._('simarm');
  static const simarmv6 = const Architecture._('simarmv6');
  static const simarmv5te = const Architecture._('simarmv5te');
  static const simarm64 = const Architecture._('simarm64');
  static const simdbc = const Architecture._('simdbc');
  static const simdbc64 = const Architecture._('simdbc64');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Architecture>.fromIterable([
    ia32,
    x64,
    arm,
    armv6,
    armv5te,
    arm64,
    simarm,
    simarmv6,
    simarmv5te,
    simarm64,
    simdbc,
    simdbc64
  ], key: (architecture) => (architecture as Architecture).name);

  static Architecture find(String name) {
    var architecture = _all[name];
    if (architecture != null) return architecture;

    throw new ArgumentError('Unknown architecture "$name".');
  }

  final String name;

  const Architecture._(this.name);

  String toString() => "Architecture($name)";
}

class Compiler {
  static const none = const Compiler._('none');
  static const precompiler = const Compiler._('precompiler');
  static const dart2js = const Compiler._('dart2js');
  static const dart2analyzer = const Compiler._('dart2analyzer');
  static const dartdevc = const Compiler._('dartdevc');
  static const dartdevk = const Compiler._('dartdevk');
  static const appJit = const Compiler._('app_jit');
  static const dartk = const Compiler._('dartk');
  static const dartkp = const Compiler._('dartkp');
  static const specParser = const Compiler._('spec_parser');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Compiler>.fromIterable([
    none,
    precompiler,
    dart2js,
    dart2analyzer,
    dartdevc,
    dartdevk,
    appJit,
    dartk,
    dartkp,
    specParser,
  ], key: (compiler) => (compiler as Compiler).name);

  static Compiler find(String name) {
    var compiler = _all[name];
    if (compiler != null) return compiler;

    throw new ArgumentError('Unknown compiler "$name".');
  }

  final String name;

  const Compiler._(this.name);

  /// Gets the runtimes this compiler can target.
  List<Runtime> get supportedRuntimes {
    switch (this) {
      case Compiler.dart2js:
        // Note: by adding 'none' as a configuration, if the user
        // runs test.py -c dart2js -r drt,none the dart2js_none and
        // dart2js_drt will be duplicating work. If later we don't need 'none'
        // with dart2js, we should remove it from here.
        return const [
          Runtime.d8,
          Runtime.jsshell,
          Runtime.drt,
          Runtime.none,
          Runtime.firefox,
          Runtime.chrome,
          Runtime.safari,
          Runtime.ie9,
          Runtime.ie10,
          Runtime.ie11,
          Runtime.opera,
          Runtime.chromeOnAndroid,
          Runtime.safariMobileSim
        ];

      case Compiler.dartdevc:
      case Compiler.dartdevk:
        // TODO(rnystrom): Expand to support other JS execution environments
        // (other browsers, d8) when tested and working.
        return const [
          Runtime.none,
          Runtime.drt,
          Runtime.chrome,
        ];

      case Compiler.dart2analyzer:
        return const [Runtime.none];
      case Compiler.appJit:
      case Compiler.dartk:
        return const [Runtime.vm, Runtime.selfCheck];
      case Compiler.precompiler:
      case Compiler.dartkp:
        return const [Runtime.dartPrecompiled];
      case Compiler.specParser:
        return const [Runtime.none];
      case Compiler.none:
        return const [
          Runtime.vm,
          Runtime.flutter,
          Runtime.drt,
          Runtime.contentShellOnAndroid
        ];
    }

    throw "unreachable";
  }

  /// The preferred runtime to use with this compiler if no other runtime is
  /// specified.
  Runtime get defaultRuntime {
    switch (this) {
      case Compiler.dart2js:
        return Runtime.d8;
      case Compiler.dartdevc:
      case Compiler.dartdevk:
        return Runtime.chrome;
      case Compiler.dart2analyzer:
        return Runtime.none;
      case Compiler.appJit:
      case Compiler.dartk:
        return Runtime.vm;
      case Compiler.precompiler:
      case Compiler.dartkp:
        return Runtime.dartPrecompiled;
      case Compiler.specParser:
        return Runtime.none;
      case Compiler.none:
        return Runtime.vm;
    }

    throw "unreachable";
  }

  String toString() => "Compiler($name)";
}

class Mode {
  static const debug = const Mode._('debug');
  static const product = const Mode._('product');
  static const release = const Mode._('release');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Mode>.fromIterable(
      [debug, product, release],
      key: (mode) => (mode as Mode).name);

  static Mode find(String name) {
    var mode = _all[name];
    if (mode != null) return mode;

    throw new ArgumentError('Unknown mode "$name".');
  }

  final String name;

  const Mode._(this.name);

  bool get isDebug => this == debug;

  String toString() => "Mode($name)";
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

class Runtime {
  static const vm = const Runtime._('vm');
  static const flutter = const Runtime._('flutter');
  static const dartPrecompiled = const Runtime._('dart_precompiled');
  static const d8 = const Runtime._('d8');
  static const jsshell = const Runtime._('jsshell');
  static const drt = const Runtime._('drt');
  static const firefox = const Runtime._('firefox');
  static const chrome = const Runtime._('chrome');
  static const safari = const Runtime._('safari');
  static const ie9 = const Runtime._('ie9');
  static const ie10 = const Runtime._('ie10');
  static const ie11 = const Runtime._('ie11');
  static const opera = const Runtime._('opera');
  static const chromeOnAndroid = const Runtime._('chromeOnAndroid');
  static const safariMobileSim = const Runtime._('safarimobilesim');
  static const contentShellOnAndroid = const Runtime._('ContentShellOnAndroid');
  static const selfCheck = const Runtime._('self_check');
  static const none = const Runtime._('none');

  static final List<String> names = _all.keys.toList()..add("ff");

  static final _all = new Map<String, Runtime>.fromIterable([
    vm,
    flutter,
    dartPrecompiled,
    d8,
    jsshell,
    drt,
    firefox,
    chrome,
    safari,
    ie9,
    ie10,
    ie11,
    opera,
    chromeOnAndroid,
    safariMobileSim,
    contentShellOnAndroid,
    selfCheck,
    none
  ], key: (runtime) => (runtime as Runtime).name);

  static Runtime find(String name) {
    // Allow "ff" as a synonym for Firefox.
    if (name == "ff") return firefox;

    var runtime = _all[name];
    if (runtime != null) return runtime;

    throw new ArgumentError('Unknown runtime "$name".');
  }

  final String name;

  const Runtime._(this.name);

  bool get isBrowser => const [
        drt,
        ie9,
        ie10,
        ie11,
        safari,
        opera,
        chrome,
        firefox,
        chromeOnAndroid,
        safariMobileSim,
        contentShellOnAndroid
      ].contains(this);

  bool get isIE => name.startsWith("ie");
  bool get isSafari => name.startsWith("safari");

  /// Whether this runtime is a command-line JavaScript environment.
  bool get isJSCommandLine => const [d8, jsshell].contains(this);

  /// If the runtime doesn't support `Window.open`, we use iframes instead.
  bool get requiresIFrame => !const [ie11, ie10].contains(this);

  /// The preferred compiler to use with this runtime if no other compiler is
  /// specified.
  Compiler get defaultCompiler {
    switch (this) {
      case vm:
      case flutter:
      case drt:
        return Compiler.none;

      case dartPrecompiled:
        return Compiler.precompiler;

      case d8:
      case jsshell:
      case firefox:
      case chrome:
      case safari:
      case ie9:
      case ie10:
      case ie11:
      case opera:
      case chromeOnAndroid:
      case safariMobileSim:
      case contentShellOnAndroid:
        return Compiler.dart2js;

      case selfCheck:
        return Compiler.dartk;

      case none:
        // If we aren't running it, we probably just want to analyze it.
        return Compiler.dart2analyzer;
    }

    throw "unreachable";
  }

  String toString() => "Runtime($name)";
}

class System {
  static const android = const System._('android');
  static const fuchsia = const System._('fuchsia');
  static const linux = const System._('linux');
  static const macos = const System._('macos');
  static const windows = const System._('windows');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, System>.fromIterable(
      [android, fuchsia, linux, macos, windows],
      key: (system) => (system as System).name);

  static System find(String name) {
    var system = _all[name];
    if (system != null) return system;

    throw new ArgumentError('Unknown operating system "$name".');
  }

  final String name;

  const System._(this.name);

  /// The root directory name for build outputs on this system.
  String get outputDirectory {
    switch (this) {
      case android:
      case fuchsia:
      case linux:
      case windows:
        return 'out/';

      case macos:
        return 'xcodebuild/';
    }

    throw "unreachable";
  }

  String toString() => "System($name)";
}
