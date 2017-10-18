// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Code from tools/testing/dart/configuration.dart
// TODO(mkroghj) add package with all settings, such as these
// and also information about test-suites

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
  ], key: (architecture) => architecture.name);

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
    appJit,
    dartk,
    dartkp,
    specParser
  ], key: (Compiler compiler) => compiler.name);

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

      case Compiler.dart2js:
      case Compiler.dartdevc:
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

  String toString() => "Compiler($name)";
}

class Mode {
  static const debug = const Mode._('debug');
  static const product = const Mode._('product');
  static const release = const Mode._('release');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Mode>.fromIterable(
      [debug, product, release],
      key: (Mode mode) => mode.name);

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
      key: (Progress progress) => progress.name);

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
  ], key: (Runtime runtime) => runtime.name);

  static Runtime find(String name) {
    // Allow "ff" as a synonym for Firefox.
    if (name == "ff") return firefox;

    var runtime = _all[name];
    if (runtime != null) return runtime;

    throw new ArgumentError('Unknown runtime "$name".');
  }

  final String name;

  const Runtime._(this.name);

  factory Runtime.fromName(name) {
    return _all[name];
  }

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
      key: (System system) => system.name);

  static System find(String name) {
    var system = _all[name];
    if (system != null) return system;

    throw new ArgumentError('Unknown operating system "$name".');
  }

  final String name;

  const System._(this.name);

  String toString() => "System($name)";
}
