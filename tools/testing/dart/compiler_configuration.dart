// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler_configuration;

import 'dart:io' show Platform;

import 'runtime_configuration.dart' show RuntimeConfiguration;

import 'test_runner.dart' show Command, CommandBuilder, CompilationCommand;

import 'test_suite.dart' show TestInformation, TestUtils;

/// Grouping of a command with its expected result.
class CommandArtifact {
  final List<Command> commands;

  /// Expected result of running [command].
  final String filename;

  /// MIME type of [filename].
  final String mimeType;

  CommandArtifact(this.commands, this.filename, this.mimeType);
}

Uri nativeDirectoryToUri(String nativePath) {
  Uri uri = new Uri.file(nativePath);
  String path = uri.path;
  return (path == '' || path.endsWith('/')) ? uri : Uri.parse('$uri/');
}

abstract class CompilerConfiguration {
  final bool isDebug;
  final bool isChecked;
  final bool isStrong;
  final bool isHostChecked;
  final bool useSdk;

  // TODO(ahe): Remove this constructor and move the switch to
  // test_options.dart.  We probably want to store an instance of
  // [CompilerConfiguration] in [configuration] there.
  factory CompilerConfiguration(Map configuration) {
    String compiler = configuration['compiler'];

    // TODO(ahe): Move these booleans into a struction configuration object
    // which can eventually completely replace the Map-based configuration
    // object.
    bool isDebug = configuration['mode'] == 'debug';
    bool isChecked = configuration['checked'];
    bool isStrong = configuration['strong'];
    bool isHostChecked = configuration['host_checked'];
    bool useSdk = configuration['use_sdk'];
    bool isCsp = configuration['csp'];
    bool useCps = configuration['cps_ir'];
    bool useBlobs = configuration['use_blobs'];
    bool hotReload = configuration['hot_reload'];
    bool hotReloadRollback = configuration['hot_reload_rollback'];
    bool useFastStartup = configuration['fast_startup'];

    switch (compiler) {
      case 'dart2analyzer':
        return new AnalyzerCompilerConfiguration(
            isDebug: isDebug,
            isChecked: isChecked,
            isStrong: isStrong,
            isHostChecked: isHostChecked,
            useSdk: useSdk);
      case 'dart2js':
        return new Dart2jsCompilerConfiguration(
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useCps: useCps,
            useSdk: useSdk,
            isCsp: isCsp,
            useFastStartup: useFastStartup,
            extraDart2jsOptions:
                TestUtils.getExtraOptions(configuration, 'dart2js_options'));
      case 'dart2app':
        return new Dart2AppSnapshotCompilerConfiguration(
            isDebug: isDebug, isChecked: isChecked);
      case 'dart2appjit':
        return new Dart2AppJitSnapshotCompilerConfiguration(
            isDebug: isDebug, isChecked: isChecked, useBlobs: useBlobs);
      case 'precompiler':
        return new PrecompilerCompilerConfiguration(
            isDebug: isDebug,
            isChecked: isChecked,
            arch: configuration['arch'],
            useBlobs: useBlobs,
            isAndroid: configuration['system'] == 'android');
      case 'none':
        return new NoneCompilerConfiguration(
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useSdk: useSdk,
            hotReload: hotReload,
            hotReloadRollback: hotReloadRollback);
      default:
        throw "Unknown compiler '$compiler'";
    }
  }

  CompilerConfiguration._subclass(
      {this.isDebug: false,
      this.isChecked: false,
      this.isStrong: false,
      this.isHostChecked: false,
      this.useSdk: false});

  /// Return a multiplier used to give tests longer time to run.
  // TODO(ahe): Convert to getter!
  int computeTimeoutMultiplier() {
    return 1;
  }

  // TODO(ahe): It shouldn't be necessary to pass [buildDir] to any of these
  // functions. It is fixed for a given configuration.
  String computeCompilerPath(String buildDir) {
    throw "Unknown compiler for: $runtimeType";
  }

  bool get hasCompiler => true;

  String get executableScriptSuffix => Platform.isWindows ? '.bat' : '';

  // TODO(ahe): Remove this.
  bool get isCsp => false;

  List<Uri> bootstrapDependencies(String buildDir) => const <Uri>[];

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact([], null, null);
  }

  List<String> computeCompilerArguments(vmOptions, sharedOptions, args) {
    return new List<String>()..addAll(sharedOptions)..addAll(args);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return <String>[artifact.filename];
  }
}

/// The "none" compiler.
class NoneCompilerConfiguration extends CompilerConfiguration {
  final bool hotReload;
  final bool hotReloadRollback;

  NoneCompilerConfiguration(
      {bool isDebug, bool isChecked, bool isHostChecked, bool useSdk,
       bool hotReload,
       bool hotReloadRollback})
      : super._subclass(
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useSdk: useSdk),
        this.hotReload = hotReload,
        this.hotReloadRollback = hotReloadRollback;

  bool get hasCompiler => false;

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    List<String> args = [];
    if (isChecked) {
      args.add('--enable_asserts');
      args.add('--enable_type_checks');
    }
    if (hotReload) {
      args.add('--hot-reload-test-mode');
    } else if (hotReloadRollback) {
      args.add('--hot-reload-rollback-test-mode');
    }
    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }
}

/// Common configuration for dart2js-based tools, such as, dart2js
class Dart2xCompilerConfiguration extends CompilerConfiguration {
  final String moniker;
  static Map<String, List<Uri>> _bootstrapDependenciesCache =
      new Map<String, List<Uri>>();

  Dart2xCompilerConfiguration(this.moniker,
      {bool isDebug, bool isChecked, bool isHostChecked, bool useSdk})
      : super._subclass(
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useSdk: useSdk);

  String computeCompilerPath(String buildDir) {
    var prefix = 'sdk/bin';
    String suffix = executableScriptSuffix;
    if (isHostChecked) {
      // The script dart2js_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dart2js_developer$suffix';
    } else {
      if (useSdk) {
        prefix = '$buildDir/dart-sdk/bin';
      }
      return '$prefix/dart2js$suffix';
    }
  }

  CompilationCommand computeCompilationCommand(
      String outputFileName,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    arguments = new List.from(arguments);
    arguments.add('--out=$outputFileName');

    return commandBuilder.getCompilationCommand(
        moniker,
        outputFileName,
        !useSdk,
        bootstrapDependencies(buildDir),
        computeCompilerPath(buildDir),
        arguments,
        environmentOverrides);
  }

  List<Uri> bootstrapDependencies(String buildDir) {
    if (!useSdk) return const <Uri>[];
    return _bootstrapDependenciesCache.putIfAbsent(
        buildDir,
        () => [
              Uri.base
                  .resolveUri(nativeDirectoryToUri(buildDir))
                  .resolve('dart-sdk/bin/snapshots/dart2js.dart.snapshot')
            ]);
  }
}

/// Configuration for dart2js compiler.
class Dart2jsCompilerConfiguration extends Dart2xCompilerConfiguration {
  final bool isCsp;
  final bool useCps;
  final bool useFastStartup;
  final List<String> extraDart2jsOptions;
  // We cache the extended environment to save memory.
  static Map<String, String> cpsFlagCache;
  static Map<String, String> environmentOverridesCacheObject;

  Dart2jsCompilerConfiguration(
      {bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk,
      bool this.useCps,
      bool this.isCsp,
      bool this.useFastStartup,
      this.extraDart2jsOptions})
      : super('dart2js',
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useSdk: useSdk);

  int computeTimeoutMultiplier() {
    int multiplier = 1;
    if (isDebug) multiplier *= 4;
    if (isChecked) multiplier *= 2;
    if (isHostChecked) multiplier *= 16;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    List compilerArguments = new List.from(arguments)
      ..addAll(extraDart2jsOptions);
    return new CommandArtifact(<Command>[
      this.computeCompilationCommand('$tempDir/out.js', buildDir,
          CommandBuilder.instance, compilerArguments, environmentOverrides)
    ], '$tempDir/out.js', 'application/javascript');
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    Uri sdk = useSdk
        ? nativeDirectoryToUri(buildDir).resolve('dart-sdk/')
        : nativeDirectoryToUri(TestUtils.dartDir.toNativePath())
            .resolve('sdk/');
    Uri preambleDir = sdk.resolve('lib/_internal/js_runtime/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
      ..add(artifact.filename);
  }
}

class PrecompilerCompilerConfiguration extends CompilerConfiguration {
  final String arch;
  final bool useBlobs;
  final bool isAndroid;

  PrecompilerCompilerConfiguration({bool isDebug, bool isChecked,
    this.arch, this.useBlobs, this.isAndroid})
      : super._subclass(isDebug: isDebug, isChecked: isChecked);

  int computeTimeoutMultiplier() {
    int multiplier = 2;
    if (isDebug) multiplier *= 4;
    if (isChecked) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    var commands = new List<Command>();
    commands.add(this.computeCompilationCommand(tempDir, buildDir, CommandBuilder.instance,
          arguments, environmentOverrides));
    if (!useBlobs) {
      commands.add(this.computeAssembleCommand(tempDir, buildDir, CommandBuilder.instance,
          arguments, environmentOverrides));
      commands.add(this.computeRemoveAssemblyCommand(tempDir, buildDir,
          CommandBuilder.instance, arguments, environmentOverrides));
    }
    return new CommandArtifact(commands, '$tempDir', 'application/dart-precompiled');
  }

  CompilationCommand computeCompilationCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    var exec = "$buildDir/dart_bootstrap";
    var args = new List();
    args.add("--snapshot-kind=app-aot");
    if (useBlobs) {
      args.add("--snapshot=$tempDir/out.aotsnapshot");
      args.add("--use-blobs");
    } else {
      args.add("--snapshot=$tempDir/out.S");
    }
    if (isAndroid && arch == 'arm') {
      args.add('--no-sim-use-hardfp');
    }
    args.addAll(arguments);

    return commandBuilder.getCompilationCommand('precompiler', tempDir, !useSdk,
        bootstrapDependencies(buildDir), exec, args, environmentOverrides);
  }

  CompilationCommand computeAssembleCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {

    var cc, shared;
    if (Platform.isLinux) {
      cc = 'gcc';
      shared = '-shared';
    } else if (Platform.isMacOS) {
      cc = 'clang';
      shared = '-dynamiclib';
    } else {
      throw "Platform not supported: ${Platform.operatingSystem}";
    }
    if (isAndroid) {
      // TODO: If we're not using "--use-blobs" we need to use the arm cross
      // compiler instead of just 'gcc' for .
    }

    var cc_flags;
    if (arch == 'x64') {
      cc_flags = "-m64";
    } else if (arch == 'simarm64') {
      cc_flags = "-m64";
    } else if (arch == 'ia32') {
      cc_flags = "-m32";
    } else if (arch == 'simarm') {
      cc_flags = "-m32";
    } else if (arch == 'simmips') {
      cc_flags = "-m32";
    } else if (arch == 'arm') {
      cc_flags = null;
    } else if (arch == 'mips') {
      cc_flags = "-EL";
    } else {
      throw "Architecture not supported: $arch";
    }

    var exec = cc;
    var args = (cc_flags != null) ? [ shared, cc_flags ] : [ shared ];
    args.addAll([
      '-o',
      '$tempDir/out.aotsnapshot',
      '$tempDir/out.S'
    ]);

    return commandBuilder.getCompilationCommand('assemble', tempDir, !useSdk,
        bootstrapDependencies(buildDir), exec, args, environmentOverrides);
  }

  // This step reduces the amount of space needed to run the precompilation
  // tests by 60%.
  CompilationCommand computeRemoveAssemblyCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    var exec = 'rm';
    var args = ['$tempDir/out.S'];

    return commandBuilder.getCompilationCommand(
        'remove_assembly',
        tempDir,
        !useSdk,
        bootstrapDependencies(buildDir),
        exec,
        args,
        environmentOverrides);
  }

  List<String> filterVmOptions(List<String> vmOptions) {
    var filtered = new List.from(vmOptions);
    filtered.removeWhere(
        (option) => option.startsWith("--optimization-counter-threshold"));
    filtered.removeWhere(
        (option) => option.startsWith("--optimization_counter_threshold"));
    return filtered;
  }

  List<String> computeCompilerArguments(
      vmOptions, sharedOptions, originalArguments) {
    List<String> args = [];
    if (isChecked) {
      args.add('--enable_asserts');
      args.add('--enable_type_checks');
    }
    return args
      ..addAll(filterVmOptions(vmOptions))
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    List<String> args = [];
    if (isChecked) {
      args.add('--enable_asserts');
      args.add('--enable_type_checks');
    }
    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }
}

class Dart2AppSnapshotCompilerConfiguration extends CompilerConfiguration {
  Dart2AppSnapshotCompilerConfiguration({bool isDebug, bool isChecked})
      : super._subclass(isDebug: isDebug, isChecked: isChecked);

  int computeTimeoutMultiplier() {
    int multiplier = 2;
    if (isDebug) multiplier *= 4;
    if (isChecked) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact(<Command>[
      this.computeCompilationCommand(tempDir, buildDir,
          CommandBuilder.instance, arguments, environmentOverrides)
    ], tempDir, 'application/dart-snapshot');
  }

  CompilationCommand computeCompilationCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    var exec = "$buildDir/dart_bootstrap";
    var args = new List();
    args.add("--snapshot=$tempDir/out.jitsnapshot");
    args.add("--snapshot-kind=app-after-run");
    args.addAll(arguments);

    return commandBuilder.getCompilationCommand(
        'dart2snapshot',
        tempDir,
        !useSdk,
        bootstrapDependencies(buildDir),
        exec,
        args,
        environmentOverrides);
  }

  List<String> computeCompilerArguments(
      vmOptions, sharedOptions, originalArguments) {
    List<String> args = [];
    if (isChecked) {
      args.add('--enable_asserts');
      args.add('--enable_type_checks');
    }
    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    List<String> args = [];
    if (isChecked) {
      args.add('--enable_asserts');
      args.add('--enable_type_checks');
    }
    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }
}

class Dart2AppJitSnapshotCompilerConfiguration extends Dart2AppSnapshotCompilerConfiguration {
  final bool useBlobs;
  Dart2AppJitSnapshotCompilerConfiguration({bool isDebug, bool isChecked, bool useBlobs})
      : super(isDebug: isDebug, isChecked: isChecked), this.useBlobs = useBlobs;

  CompilationCommand computeCompilationCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    var exec = "$buildDir/dart";
    var args = new List();
    args.add("--snapshot=$tempDir/out.jitsnapshot");
    args.add("--snapshot-kind=app-jit-after-run");
    if (useBlobs) {
      args.add("--use-blobs");
    }
    args.addAll(arguments);

    return commandBuilder.getCompilationCommand(
        'dart2snapshot',
        tempDir,
        !useSdk,
        bootstrapDependencies(buildDir),
        exec,
        args,
        environmentOverrides);
  }
}

class AnalyzerCompilerConfiguration extends CompilerConfiguration {
  AnalyzerCompilerConfiguration(
      {bool isDebug, bool isChecked, bool isStrong, bool isHostChecked, bool
      useSdk})
      : super._subclass(
            isDebug: isDebug,
            isChecked: isChecked,
            isStrong: isStrong,
            isHostChecked: isHostChecked,
            useSdk: useSdk);

  int computeTimeoutMultiplier() {
    return 4;
  }

  String computeCompilerPath(String buildDir) {
    var prefix = 'sdk/bin';
    String suffix = executableScriptSuffix;
    if (isHostChecked) {
      if (useSdk) {
        throw "--host-checked and --use-sdk cannot be used together";
      }
      // The script dartanalyzer_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dartanalyzer_developer$suffix';
    }
    if (useSdk) {
      prefix = '$buildDir/dart-sdk/bin';
    }
    return '$prefix/dartanalyzer$suffix';
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    arguments = new List.from(arguments);
    if (isChecked || isStrong) {
      arguments.add('--enable_type_checks');
    }
    if (isStrong){
      arguments.add('--strong');
    }
    return new CommandArtifact(<Command>[
      commandBuilder.getAnalysisCommand('dart2analyzer',
          computeCompilerPath(buildDir), arguments, environmentOverrides,
          flavor: 'dart2analyzer')
    ], null, null); // Since this is not a real compilation, no artifacts are
    // produced.
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return <String>[];
  }
}
