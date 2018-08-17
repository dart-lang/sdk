// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

// TODO(rnystrom): Differences from test.dart's version:
// - Remove special handling for "ff" as firefox.
// - "windows" -> "win".
// - "macos" -> "mac".
// - toString() on enum classes is just name.
// - builderTag defaults to empty string, not null.
// Need to migrate test.dart to not expect the above before it can use this.

// READ ME! If you add a new field to this, make sure to add it to
// [parse()], [optionsEqual()], [hashCode], and [toString()]. A good check is to
// comment out an existing field and see what breaks. Every error is a place
// where you will need to add code for your new field.

/// A set of options that affects how a Dart SDK test is run in a way that may
/// affect its outcome.
///
/// This includes options like "compiler" and "runtime" which fundamentally
/// decide how a test is executed. Options are tracked because a single test
/// may have different outcomes for different configurations. For example, it
/// may currently pass on the VM but not dart2js or vice versa.
///
/// Options that affect how a test can be run but don't affect its outcome are
/// *not* stored here. Things like how test results are displayed, where logs
/// are written, etc. live outside of this.
class Configuration {
  /// Expands a configuration name "[template]" all using [optionsJson] to a
  /// list of configurations.
  ///
  /// A template is a configuration name that contains zero or more
  /// parenthesized sections. Within the parentheses are a series of options
  /// separated by pipes. For example:
  ///
  ///     strong-fasta-(linux|mac|win)-(debug|release)
  ///
  /// Text outside of parenthesized groups is treated literally. Each
  /// parenthesized section expands to a configuration for each of the options
  /// separated by pipes. If a template contains multiple parenthesized
  /// sections, configurations are created for all combinations of them. The
  /// above template expands to:
  ///
  ///     strong-fasta-linux-debug
  ///     strong-fasta-linux-release
  ///     strong-fasta-mac-debug
  ///     strong-fasta-mac-release
  ///     strong-fasta-win-debug
  ///     strong-fasta-win-release
  ///
  /// After expansion, the resulting strings (and [optionsJson]) are passed to
  /// [parse()] to convert each one to a full configuration.
  static List<Configuration> expandTemplate(
      String template, Map<String, dynamic> optionsJson) {
    if (template.isEmpty) throw FormatException("Template must not be empty.");

    var sections = <List<String>>[];
    var start = 0;
    while (start < template.length) {
      var openParen = template.indexOf("(", start);

      if (openParen == -1) {
        // Add the last literal section.
        sections.add([template.substring(start, template.length)]);
        break;
      }

      var closeParen = template.indexOf(")", openParen);
      if (closeParen == -1) {
        throw FormatException('Missing ")" in name template "$template".');
      }

      // Add the literal part before the next "(".
      sections.add([template.substring(start, openParen)]);

      // Add the options within the parentheses.
      sections.add(template.substring(openParen + 1, closeParen).split("|"));

      // Continue past the ")".
      start = closeParen + 1;
    }

    var result = <Configuration>[];

    // Walk through every combination of every section.
    iterateSection(String prefix, int section) {
      // If we pinned all the sections, parse it.
      if (section >= sections.length) {
        try {
          result.add(Configuration.parse(prefix, optionsJson));
        } on FormatException catch (ex) {
          throw FormatException(
              'Could not parse expanded configuration "$prefix" from template '
              '"$template":\n${ex.message}');
        }
        return;
      }

      for (var i = 0; i < sections[section].length; i++) {
        iterateSection(prefix + sections[section][i], section + 1);
      }
    }

    iterateSection("", 0);

    return result;
  }

  /// Parse a single configuration with [name] with additional options defined
  /// in [optionsJson].
  ///
  /// The name should be a series of words separated by hyphens. Any word that
  /// matches the name of an [Architecture], [Compiler], [Mode], [Runtime], or
  /// [System] sets that option in the resulting configuration. Those options
  /// may also be specified in the JSON map.
  ///
  /// Additional Boolean and string options are defined in the map. The key
  /// names match the corresponding command-line option names, using kebab-case.
  static Configuration parse(String name, Map<String, dynamic> optionsJson) {
    if (name.isEmpty) throw FormatException("Name must not be empty.");

    // Infer option values from the words in the configuration name.
    var words = name.split("-").toSet();
    var optionsCopy = new Map.of(optionsJson);

    T enumOption<T extends NamedEnum>(
        String option, List<String> allowed, T Function(String) parse) {
      // Look up the value from the words in the name.
      T fromName;
      for (var value in allowed) {
        // Don't treat "none" as matchable since it's ambiguous as to whether
        // it refers to compiler or runtime.
        if (value == "none") continue;

        if (words.contains(value)) {
          if (fromName != null) {
            throw FormatException(
                'Found multiple values for $option ("$fromName" and "$value"), '
                'in configuration name.');
          }
          fromName = parse(value);
        }
      }

      // Look up the value from the options.
      T fromOption;
      if (optionsCopy.containsKey(option)) {
        fromOption = parse(optionsCopy[option] as String);
        optionsCopy.remove(option);
      }

      if (fromName != null && fromOption != null) {
        if (fromName == fromOption) {
          throw FormatException(
              'Redundant $option in configuration name "$fromName" and options.');
        } else {
          throw FormatException(
              'Found $option "$fromOption" in options and "$fromName" in '
              'configuration name.');
        }
      }

      return fromName ?? fromOption;
    }

    bool boolOption(String option) {
      if (!optionsCopy.containsKey(option)) return null;

      var value = optionsCopy.remove(option);
      if (value == null) throw FormatException('Option "$option" was null.');
      if (value is! bool) {
        throw FormatException('Option "$option" had value "$value", which is '
            'not a bool.');
      }
      return value as bool;
    }

    int intOption(String option) {
      if (!optionsCopy.containsKey(option)) return null;

      var value = optionsCopy.remove(option);
      if (value == null) throw FormatException('Option "$option" was null.');
      if (value is! int) {
        throw FormatException('Option "$option" had value "$value", which is '
            'not an int.');
      }
      return value as int;
    }

    String stringOption(String option) {
      if (!optionsCopy.containsKey(option)) return null;

      var value = optionsCopy.remove(option);
      if (value == null) throw FormatException('Option "$option" was null.');
      if (value is! String) {
        throw FormatException('Option "$option" had value "$value", which is '
            'not a string.');
      }
      return value as String;
    }

    List<String> stringListOption(String option) {
      if (!optionsCopy.containsKey(option)) return null;

      var value = optionsCopy.remove(option);
      if (value == null) throw FormatException('Option "$option" was null.');
      if (value is! List) {
        throw FormatException('Option "$option" had value "$value", which is '
            'not a List.');
      }
      return new List<String>.from(value as List);
    }

    // Extract options from the name and map.
    var architecture =
        enumOption("architecture", Architecture.names, Architecture.find);
    var compiler = enumOption("compiler", Compiler.names, Compiler.find);
    var mode = enumOption("mode", Mode.names, Mode.find);
    var runtime = enumOption("runtime", Runtime.names, Runtime.find);
    var system = enumOption("system", System.names, System.find);

    // Fill in any missing values using defaults when possible.
    architecture ??= Architecture.x64;
    system ??= System.host;

    // Infer from compiler from runtime or vice versa.
    if (compiler == null) {
      if (runtime == null) {
        throw FormatException(
            'Must specify at least one of compiler or runtime in options or '
            'configuration name.');
      } else {
        compiler = runtime.defaultCompiler;
      }
    } else {
      if (runtime == null) {
        runtime = compiler.defaultRuntime;
      } else {
        // Do nothing, specified both.
      }
    }

    // Infer the mode from the compiler.
    mode ??= compiler.defaultMode;

    var configuration = Configuration(
        name, architecture, compiler, mode, runtime, system,
        builderTag: stringOption("builder-tag"),
        vmOptions: stringListOption("vm-options"),
        timeout: intOption("timeout"),
        enableAsserts: boolOption("enable-asserts"),
        isChecked: boolOption("checked"),
        isCsp: boolOption("csp"),
        isHostChecked: boolOption("host-checked"),
        isMinified: boolOption("minified"),
        previewDart2: boolOption("preview-dart-2"),
        useAnalyzerCfe: boolOption("use-cfe"),
        useAnalyzerFastaParser: boolOption("analyzer-use-fasta-parser"),
        useBlobs: boolOption("use-blobs"),
        useDart2JSWithKernel: boolOption("dart2js-with-kernel"),
        useDart2JSOldFrontEnd: boolOption("dart2js-old-frontend"),
        useFastStartup: boolOption("fast-startup"),
        useHotReload: boolOption("hot-reload"),
        useHotReloadRollback: boolOption("hot-reload-rollback"),
        useSdk: boolOption("use-sdk"));

    // Should have consumed the whole map.
    if (optionsCopy.isNotEmpty) {
      throw new FormatException('Unknown option "${optionsCopy.keys.first}".');
    }

    return configuration;
  }

  final String name;

  final Architecture architecture;

  final Compiler compiler;

  final Mode mode;

  final Runtime runtime;

  final System system;

  final String builderTag;

  final List<String> vmOptions;

  int timeout;

  final bool enableAsserts;

  // TODO(rnystrom): Remove this when Dart 1.0 is no longer supported.
  final bool isChecked;

  final bool isCsp;

  // TODO(rnystrom): Remove this when Dart 1.0 is no longer supported.
  final bool isHostChecked;

  final bool isMinified;

  // TODO(rnystrom): Remove this when Dart 1.0 is no longer supported.
  final bool previewDart2;

  // TODO(whesse): Remove these when only fasta front end is in analyzer.
  final bool useAnalyzerCfe;
  final bool useAnalyzerFastaParser;

  // TODO(rnystrom): What is this?
  final bool useBlobs;

  // TODO(rnystrom): Remove these when Dart 1.0 is no longer supported.
  final bool useDart2JSWithKernel;
  final bool useDart2JSOldFrontEnd;

  final bool useFastStartup;

  final bool useHotReload;
  final bool useHotReloadRollback;

  final bool useSdk;

  Configuration(this.name, this.architecture, this.compiler, this.mode,
      this.runtime, this.system,
      {String builderTag,
      List<String> vmOptions,
      int timeout,
      bool enableAsserts,
      bool isChecked,
      bool isCsp,
      bool isHostChecked,
      bool isMinified,
      bool previewDart2,
      bool useAnalyzerCfe,
      bool useAnalyzerFastaParser,
      bool useBlobs,
      bool useDart2JSWithKernel,
      bool useDart2JSOldFrontEnd,
      bool useFastStartup,
      bool useHotReload,
      bool useHotReloadRollback,
      bool useSdk})
      : builderTag = builderTag ?? "",
        vmOptions = vmOptions ?? <String>[],
        timeout = timeout,
        enableAsserts = enableAsserts ?? false,
        isChecked = isChecked ?? false,
        isCsp = isCsp ?? false,
        isHostChecked = isHostChecked ?? false,
        isMinified = isMinified ?? false,
        previewDart2 = previewDart2 ?? true,
        useAnalyzerCfe = useAnalyzerCfe ?? false,
        useAnalyzerFastaParser = useAnalyzerFastaParser ?? false,
        useBlobs = useBlobs ?? false,
        useDart2JSWithKernel = useDart2JSWithKernel ?? false,
        useDart2JSOldFrontEnd = useDart2JSOldFrontEnd ?? false,
        useFastStartup = useFastStartup ?? false,
        useHotReload = useHotReload ?? false,
        useHotReloadRollback = useHotReloadRollback ?? false,
        useSdk = useSdk ?? false;

  /// Returns `true` if this configuration's options all have the same values
  /// as [other].
  bool optionsEqual(Configuration other) =>
      architecture == other.architecture &&
      compiler == other.compiler &&
      mode == other.mode &&
      runtime == other.runtime &&
      system == other.system &&
      builderTag == other.builderTag &&
      vmOptions.join(" & ") == other.vmOptions.join(" & ") &&
      timeout == other.timeout &&
      enableAsserts == other.enableAsserts &&
      isChecked == other.isChecked &&
      isCsp == other.isCsp &&
      isHostChecked == other.isHostChecked &&
      isMinified == other.isMinified &&
      previewDart2 == other.previewDart2 &&
      useAnalyzerCfe == other.useAnalyzerCfe &&
      useAnalyzerFastaParser == other.useAnalyzerFastaParser &&
      useBlobs == other.useBlobs &&
      useDart2JSWithKernel == other.useDart2JSWithKernel &&
      useDart2JSOldFrontEnd == other.useDart2JSOldFrontEnd &&
      useFastStartup == other.useFastStartup &&
      useHotReload == other.useHotReload &&
      useHotReloadRollback == other.useHotReloadRollback &&
      useSdk == other.useSdk;

  bool operator ==(Object other) =>
      other is Configuration && name == other.name && optionsEqual(other);

  int get hashCode =>
      name.hashCode ^
      architecture.hashCode ^
      compiler.hashCode ^
      mode.hashCode ^
      runtime.hashCode ^
      system.hashCode ^
      builderTag.hashCode ^
      vmOptions.join(" & ").hashCode ^
      timeout.hashCode ^
      (enableAsserts ? 1 : 0) ^
      (isChecked ? 2 : 0) ^
      (isCsp ? 4 : 0) ^
      (isHostChecked ? 8 : 0) ^
      (isMinified ? 16 : 0) ^
      (previewDart2 ? 32 : 0) ^
      (useAnalyzerCfe ? 64 : 0) ^
      (useAnalyzerFastaParser ? 128 : 0) ^
      (useBlobs ? 256 : 0) ^
      (useDart2JSWithKernel ? 512 : 0) ^
      (useDart2JSOldFrontEnd ? 1024 : 0) ^
      (useFastStartup ? 2048 : 0) ^
      (useHotReload ? 4096 : 0) ^
      (useHotReloadRollback ? 8192 : 0) ^
      (useSdk ? 16384 : 0);

  String toString() {
    var buffer = new StringBuffer();
    buffer.write(name);
    buffer.write("(");

    var fields = <String>[];
    fields.add("architecture: $architecture");
    fields.add("compiler: $compiler");
    fields.add("mode: $mode");
    fields.add("runtime: $runtime");
    fields.add("system: $system");

    if (builderTag != "") fields.add("builder-tag: $builderTag");
    if (vmOptions != "") fields.add("vm-options: [${vmOptions.join(", ")}]");
    if (timeout != 0) fields.add("timeout: $timeout");
    if (enableAsserts) fields.add("enable-asserts");
    if (isChecked) fields.add("checked");
    if (isCsp) fields.add("csp");
    if (isHostChecked) fields.add("host-checked");
    if (isMinified) fields.add("minified");
    if (previewDart2) fields.add("preview-dart-2");
    if (useAnalyzerCfe) fields.add("use-cfe");
    if (useAnalyzerFastaParser) fields.add("analyzer-use-fasta-parser");
    if (useBlobs) fields.add("use-blobs");
    if (useDart2JSWithKernel) fields.add("dart2js-with-kernel");
    if (useDart2JSOldFrontEnd) fields.add("dart2js-old-frontend");
    if (useFastStartup) fields.add("fast-startup");
    if (useHotReload) fields.add("hot-reload");
    if (useHotReloadRollback) fields.add("hot-reload-rollback");
    if (useSdk) fields.add("use-sdk");

    buffer.write(fields.join(", "));
    buffer.write(")");
    return buffer.toString();
  }

  String visualCompare(Configuration other) {
    var buffer = new StringBuffer();
    buffer.writeln(name);
    buffer.writeln(other.name);

    var fields = <String>[];
    fields.add("architecture: $architecture ${other.architecture}");
    fields.add("compiler: $compiler ${other.compiler}");
    fields.add("mode: $mode ${other.mode}");
    fields.add("runtime: $runtime ${other.runtime}");
    fields.add("system: $system ${other.system}");

    if (builderTag != "" || other.builderTag != "") {
      var tag = builderTag == "" ? "(none)" : builderTag;
      var otherTag = other.builderTag == "" ? "(none)" : other.builderTag;
      fields.add("builder-tag: $tag $otherTag");
    }
    if (vmOptions != "" || other.vmOptions != "") {
      var tag = "[${vmOptions.join(", ")}]";
      var otherTag = "[${other.vmOptions.join(", ")}]";
      fields.add("vm-options: $tag $otherTag");
    }
    fields.add("timeout: $timeout ${other.timeout}");
    if (enableAsserts || other.enableAsserts) {
      fields.add("enable-asserts $enableAsserts ${other.enableAsserts}");
    }
    if (isChecked || other.isChecked) {
      fields.add("checked $isChecked ${other.isChecked}");
    }
    if (isCsp || other.isCsp) {
      fields.add("csp $isCsp ${other.isCsp}");
    }
    if (isHostChecked || other.isHostChecked) {
      fields.add("isHostChecked $isHostChecked ${other.isHostChecked}");
    }
    if (isMinified || other.isMinified) {
      fields.add("isMinified $isMinified ${other.isMinified}");
    }
    if (previewDart2 || other.previewDart2) {
      fields.add("previewDart2 $previewDart2 ${other.previewDart2}");
    }
    if (useAnalyzerCfe || other.useAnalyzerCfe) {
      fields.add("useAnalyzerCfe $useAnalyzerCfe ${other.useAnalyzerCfe}");
    }
    if (useAnalyzerFastaParser || other.useAnalyzerFastaParser) {
      fields.add("useAnalyzerFastaParser "
          "$useAnalyzerFastaParser ${other.useAnalyzerFastaParser}");
    }
    if (useBlobs || other.useBlobs) {
      fields.add("useBlobs $useBlobs ${other.useBlobs}");
    }
    if (useDart2JSWithKernel || other.useDart2JSWithKernel) {
      fields.add("useDart2JSWithKernel "
          "$useDart2JSWithKernel ${other.useDart2JSWithKernel}");
    }
    if (useDart2JSOldFrontEnd || other.useDart2JSOldFrontEnd) {
      fields.add("useDart2JSOldFrontEnd "
          "$useDart2JSOldFrontEnd ${other.useDart2JSOldFrontEnd}");
    }
    if (useFastStartup || other.useFastStartup) {
      fields.add("useFastStartup $useFastStartup ${other.useFastStartup}");
    }
    if (useHotReload || other.useHotReload) {
      fields.add("useHotReload $useHotReload ${other.useHotReload}");
    }
    if (isHostChecked) {
      fields.add("host-checked $isHostChecked ${other.isHostChecked}");
    }
    if (useHotReloadRollback || other.useHotReloadRollback) {
      fields.add("useHotReloadRollback"
          " $useHotReloadRollback ${other.useHotReloadRollback}");
    }
    if (useSdk || other.useSdk) {
      fields.add("useSdk $useSdk ${other.useSdk}");
    }

    buffer.write(fields.join("\n   "));
    buffer.write("\n");
    return buffer.toString();
  }
}

class Architecture extends NamedEnum {
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

  const Architecture._(String name) : super(name);
}

class Compiler extends NamedEnum {
  static const none = const Compiler._('none');
  static const precompiler = const Compiler._('precompiler');
  static const dart2js = const Compiler._('dart2js');
  static const dart2analyzer = const Compiler._('dart2analyzer');
  static const dartdevc = const Compiler._('dartdevc');
  static const dartdevk = const Compiler._('dartdevk');
  static const appJit = const Compiler._('app_jit');
  static const appJitk = const Compiler._('app_jitk');
  static const dartk = const Compiler._('dartk');
  static const dartkp = const Compiler._('dartkp');
  static const dartkb = const Compiler._('dartkb');
  static const specParser = const Compiler._('spec_parser');
  static const fasta = const Compiler._('fasta');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Compiler>.fromIterable([
    none,
    precompiler,
    dart2js,
    dart2analyzer,
    dartdevc,
    dartdevk,
    appJit,
    appJitk,
    dartk,
    dartkp,
    dartkb,
    specParser,
    fasta,
  ], key: (compiler) => (compiler as Compiler).name);

  static Compiler find(String name) {
    var compiler = _all[name];
    if (compiler != null) return compiler;

    throw new ArgumentError('Unknown compiler "$name".');
  }

  const Compiler._(String name) : super(name);

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
          Runtime.none,
          Runtime.firefox,
          Runtime.chrome,
          Runtime.safari,
          Runtime.ie9,
          Runtime.ie10,
          Runtime.ie11,
          Runtime.edge,
          Runtime.chromeOnAndroid,
        ];

      case Compiler.dartdevc:
      case Compiler.dartdevk:
        // TODO(rnystrom): Expand to support other JS execution environments
        // (other browsers, d8) when tested and working.
        return const [
          Runtime.none,
          Runtime.chrome,
        ];

      case Compiler.dart2analyzer:
        return const [Runtime.none];
      case Compiler.appJit:
      case Compiler.appJitk:
      case Compiler.dartk:
      case Compiler.dartkb:
        return const [Runtime.vm, Runtime.selfCheck];
      case Compiler.precompiler:
      case Compiler.dartkp:
        return const [Runtime.dartPrecompiled];
      case Compiler.specParser:
        return const [Runtime.none];
      case Compiler.fasta:
        return const [Runtime.none];
      case Compiler.none:
        return const [Runtime.vm, Runtime.flutter];
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
      case Compiler.appJitk:
      case Compiler.dartk:
      case Compiler.dartkb:
        return Runtime.vm;
      case Compiler.precompiler:
      case Compiler.dartkp:
        return Runtime.dartPrecompiled;
      case Compiler.specParser:
      case Compiler.fasta:
        return Runtime.none;
      case Compiler.none:
        return Runtime.vm;
    }

    throw "unreachable";
  }

  Mode get defaultMode {
    switch (this) {
      case Compiler.dart2analyzer:
      case Compiler.dart2js:
      case Compiler.dartdevc:
      case Compiler.dartdevk:
      case Compiler.fasta:
        return Mode.release;

      default:
        return Mode.debug;
    }
  }
}

class Mode extends NamedEnum {
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

  const Mode._(String name) : super(name);

  bool get isDebug => this == debug;
}

class Runtime extends NamedEnum {
  static const vm = const Runtime._('vm');
  static const flutter = const Runtime._('flutter');
  static const dartPrecompiled = const Runtime._('dart_precompiled');
  static const d8 = const Runtime._('d8');
  static const jsshell = const Runtime._('jsshell');
  static const firefox = const Runtime._('firefox');
  static const chrome = const Runtime._('chrome');
  static const safari = const Runtime._('safari');
  static const ie9 = const Runtime._('ie9');
  static const ie10 = const Runtime._('ie10');
  static const ie11 = const Runtime._('ie11');
  static const edge = const Runtime._('edge');
  static const chromeOnAndroid = const Runtime._('chromeOnAndroid');
  static const selfCheck = const Runtime._('self_check');
  static const none = const Runtime._('none');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, Runtime>.fromIterable([
    vm,
    flutter,
    dartPrecompiled,
    d8,
    jsshell,
    firefox,
    chrome,
    safari,
    ie9,
    ie10,
    ie11,
    edge,
    chromeOnAndroid,
    selfCheck,
    none
  ], key: (runtime) => (runtime as Runtime).name);

  static Runtime find(String name) {
    var runtime = _all[name];
    if (runtime != null) return runtime;

    throw new ArgumentError('Unknown runtime "$name".');
  }

  const Runtime._(String name) : super(name);

  bool get isBrowser => const [
        ie9,
        ie10,
        ie11,
        edge,
        safari,
        chrome,
        firefox,
        chromeOnAndroid
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
      case edge:
      case chromeOnAndroid:
        return Compiler.dart2js;

      case selfCheck:
        return Compiler.dartk;

      case none:
        // If we aren't running it, we probably just want to analyze it.
        return Compiler.dart2analyzer;
    }

    throw "unreachable";
  }
}

class System extends NamedEnum {
  static const android = const System._('android');
  static const fuchsia = const System._('fuchsia');
  static const linux = const System._('linux');
  static const mac = const System._('mac');
  static const win = const System._('win');

  static final List<String> names = _all.keys.toList();

  static final _all = new Map<String, System>.fromIterable(
      [android, fuchsia, linux, mac, win],
      key: (system) => (system as System).name);

  /// Gets the system of the current machine.
  static System get host => find(Platform.operatingSystem);

  static System find(String name) {
    var system = _all[name];
    if (system != null) return system;

    // Also allow dart:io's names for the operating systems.
    switch (Platform.operatingSystem) {
      case "macos":
        return mac;
      case "windows":
        return win;
    }
    // TODO(rnystrom): What about ios?

    throw new ArgumentError('Unknown operating system "$name".');
  }

  const System._(String name) : super(name);

  /// The root directory name for build outputs on this system.
  String get outputDirectory {
    switch (this) {
      case android:
      case fuchsia:
      case linux:
      case win:
        return 'out/';

      case mac:
        return 'xcodebuild/';
    }

    throw "unreachable";
  }
}

/// Base class for an enum-like class whose values are identified by name.
abstract class NamedEnum {
  final String name;

  const NamedEnum(this.name);

  String toString() => name;
}
