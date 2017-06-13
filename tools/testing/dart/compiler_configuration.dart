// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'configuration.dart';
import 'runtime_configuration.dart';
import 'test_runner.dart';
import 'test_suite.dart';
import 'utils.dart';

List<String> replaceDartFileWith(List<String> list, String replacement) {
  var copy = new List<String>.from(list);
  for (var i = 0; i < copy.length; i++) {
    if (copy[i].endsWith(".dart")) {
      copy[i] = replacement;
    }
  }
  return copy;
}

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

  /// Only some subclasses support this check, but we statically allow calling
  /// it on [CompilerConfiguration].
  bool get useDfe {
    throw new UnsupportedError("This compiler does not support DFE.");
  }

  factory CompilerConfiguration(Configuration configuration) {
    switch (configuration.compiler) {
      case Compiler.dart2analyzer:
        return new AnalyzerCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked,
            isStrong: configuration.isStrong,
            isHostChecked: configuration.isHostChecked,
            useSdk: configuration.useSdk);

      case Compiler.dart2js:
        return new Dart2jsCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked,
            isHostChecked: configuration.isHostChecked,
            useSdk: configuration.useSdk,
            isCsp: configuration.isCsp,
            useFastStartup: configuration.useFastStartup,
            useKernel: configuration.useDart2JSWithKernel,
            extraDart2jsOptions: configuration.dart2jsOptions);

      case Compiler.appJit:
        return new AppJitCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked);

      case Compiler.precompiler:
        return new PrecompilerCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked,
            arch: configuration.architecture,
            useBlobs: configuration.useBlobs,
            isAndroid: configuration.system == System.android);

      case Compiler.dartk:
        return new NoneCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked,
            isHostChecked: configuration.isHostChecked,
            useSdk: configuration.useSdk,
            hotReload: configuration.hotReload,
            hotReloadRollback: configuration.hotReloadRollback,
            useDfe: true);

      case Compiler.dartkp:
        return new PrecompilerCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked,
            arch: configuration.architecture,
            useBlobs: configuration.useBlobs,
            isAndroid: configuration.system == System.android,
            useDfe: true);

      case Compiler.none:
        return new NoneCompilerConfiguration(
            isDebug: configuration.mode.isDebug,
            isChecked: configuration.isChecked,
            isHostChecked: configuration.isHostChecked,
            useSdk: configuration.useSdk,
            hotReload: configuration.hotReload,
            hotReloadRollback: configuration.hotReloadRollback);
    }

    throw "unreachable";
  }

  CompilerConfiguration._subclass(
      {this.isDebug: false,
      this.isChecked: false,
      this.isStrong: false,
      this.isHostChecked: false,
      this.useSdk: false});

  /// A multiplier used to give tests longer time to run.
  int get timeoutMultiplier => 1;

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
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact([], null, null);
  }

  List<String> computeCompilerArguments(
      List<String> vmOptions, List<String> sharedOptions, List<String> args) {
    return sharedOptions.toList()..addAll(args);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [artifact.filename];
  }
}

/// The "none" compiler.
class NoneCompilerConfiguration extends CompilerConfiguration {
  final bool hotReload;
  final bool hotReloadRollback;
  final bool useDfe;

  NoneCompilerConfiguration(
      {bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk,
      bool this.hotReload,
      bool this.hotReloadRollback,
      this.useDfe: false})
      : super._subclass(
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useSdk: useSdk);

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
    if (useDfe) {
      args.add('--dfe=${buildDir}/gen/kernel-service.dart.snapshot');
      args.add('--platform=${buildDir}/patched_sdk/platform.dill');
    }
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

/// The "dartk" compiler.
class DartKCompilerConfiguration extends CompilerConfiguration {
  final bool verify, strong, treeShake;

  DartKCompilerConfiguration(
      {bool isChecked,
      bool isHostChecked,
      bool useSdk,
      this.verify,
      this.strong,
      this.treeShake})
      : super._subclass(
            isChecked: isChecked, isHostChecked: isHostChecked, useSdk: useSdk);

  @override
  String computeCompilerPath(String buildDir) {
    return 'tools/dartk_wrappers/dartk$executableScriptSuffix';
  }

  CompilationCommand computeCompilationCommand(
      String outputFileName,
      String buildDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    Iterable<String> extraArguments = [
      '--sdk',
      '$buildDir/patched_sdk',
      '--link',
      '--target=vm',
      treeShake ? '--tree-shake' : null,
      strong ? '--strong' : null,
      verify ? '--verify-ir' : null,
      '--out',
      outputFileName
    ].where((x) => x != null);
    return commandBuilder.getKernelCompilationCommand(
        'dartk',
        outputFileName,
        true,
        bootstrapDependencies(buildDir),
        computeCompilerPath(buildDir),
        <String>[]..addAll(arguments)..addAll(extraArguments),
        environmentOverrides);
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact(<Command>[
      computeCompilationCommand('$tempDir/out.dill', buildDir,
          CommandBuilder.instance, arguments, environmentOverrides)
    ], '$tempDir/out.dill', 'application/dart');
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

    var newOriginalArguments =
        replaceDartFileWith(originalArguments, artifact.filename);

    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(newOriginalArguments);
  }
}

typedef List<String> CompilerArgumentsFunction(
    List<String> globalArguments, String previousCompilerOutput);

class PipelineCommand {
  final CompilerConfiguration compilerConfiguration;
  final CompilerArgumentsFunction _argumentsFunction;

  PipelineCommand._(this.compilerConfiguration, this._argumentsFunction);

  factory PipelineCommand.runWithGlobalArguments(CompilerConfiguration conf) {
    return new PipelineCommand._(conf,
        (List<String> globalArguments, String previousOutput) {
      assert(previousOutput == null);
      return globalArguments;
    });
  }

  factory PipelineCommand.runWithDartOrKernelFile(CompilerConfiguration conf) {
    return new PipelineCommand._(conf,
        (List<String> globalArguments, String previousOutput) {
      var filtered = globalArguments
          .where(
              (String name) => name.endsWith('.dart') || name.endsWith('.dill'))
          .toList();
      assert(filtered.length == 1);
      return filtered;
    });
  }

  factory PipelineCommand.runWithPreviousKernelOutput(
      CompilerConfiguration conf) {
    return new PipelineCommand._(conf,
        (List<String> globalArguments, String previousOutput) {
      assert(previousOutput.endsWith('.dill'));
      return replaceDartFileWith(globalArguments, previousOutput);
    });
  }

  List<String> extractArguments(
      List<String> globalArguments, String previousOutput) {
    return _argumentsFunction(globalArguments, previousOutput);
  }
}

class ComposedCompilerConfiguration extends CompilerConfiguration {
  final List<PipelineCommand> pipelineCommands;

  ComposedCompilerConfiguration(this.pipelineCommands) : super._subclass();

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List<String> globalArguments,
      Map<String, String> environmentOverrides) {
    List<Command> allCommands = [];

    // The first compilation command is as usual.
    var arguments = pipelineCommands[0].extractArguments(globalArguments, null);
    CommandArtifact artifact = pipelineCommands[0]
        .compilerConfiguration
        .computeCompilationArtifact(
            buildDir, tempDir, commandBuilder, arguments, environmentOverrides);
    allCommands.addAll(artifact.commands);

    // The following compilation commands are based on the output of the
    // previous one.
    for (int i = 1; i < pipelineCommands.length; i++) {
      PipelineCommand pc = pipelineCommands[i];

      arguments = pc.extractArguments(globalArguments, artifact.filename);
      artifact = pc.compilerConfiguration.computeCompilationArtifact(
          buildDir, tempDir, commandBuilder, arguments, environmentOverrides);

      allCommands.addAll(artifact.commands);
    }

    return new CommandArtifact(
        allCommands, artifact.filename, artifact.mimeType);
  }

  List<String> computeCompilerArguments(vmOptions, sharedOptions, args) {
    // The result will be passed as an input to [extractArguments]
    // (i.e. the arguments to the [PipelineCommand]).
    return <String>[]..addAll(vmOptions)..addAll(sharedOptions)..addAll(args);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    CompilerConfiguration lastCompilerConfiguration =
        pipelineCommands.last.compilerConfiguration;
    return lastCompilerConfiguration.computeRuntimeArguments(
        runtimeConfiguration,
        buildDir,
        info,
        vmOptions,
        sharedOptions,
        originalArguments,
        artifact);
  }

  static ComposedCompilerConfiguration createDartKPConfiguration(
      {bool isChecked,
      bool isHostChecked,
      Architecture arch,
      bool useBlobs,
      bool isAndroid,
      bool useSdk,
      bool verify,
      bool strong,
      bool treeShake}) {
    return new ComposedCompilerConfiguration([
      // Compile with dartk.
      new PipelineCommand.runWithGlobalArguments(new DartKCompilerConfiguration(
          isChecked: isChecked,
          isHostChecked: isHostChecked,
          useSdk: useSdk,
          verify: verify,
          strong: strong,
          treeShake: treeShake)),

      // Run the normal precompiler.
      new PipelineCommand.runWithPreviousKernelOutput(
          new PrecompilerCompilerConfiguration(
              isChecked: isChecked,
              arch: arch,
              useBlobs: useBlobs,
              isAndroid: isAndroid))
    ]);
  }

  static ComposedCompilerConfiguration createDartKConfiguration(
      {bool isChecked,
      bool isHostChecked,
      bool useSdk,
      bool verify,
      bool strong,
      bool treeShake}) {
    return new ComposedCompilerConfiguration([
      // Compile with dartk.
      new PipelineCommand.runWithGlobalArguments(new DartKCompilerConfiguration(
          isChecked: isChecked,
          isHostChecked: isHostChecked,
          useSdk: useSdk,
          verify: verify,
          strong: strong,
          treeShake: treeShake))
    ]);
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
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    arguments = arguments.toList();
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
  final bool useFastStartup;
  final bool useKernel;
  final List<String> extraDart2jsOptions;

  Dart2jsCompilerConfiguration(
      {bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk,
      bool this.isCsp,
      bool this.useFastStartup,
      this.useKernel,
      this.extraDart2jsOptions})
      : super('dart2js',
            isDebug: isDebug,
            isChecked: isChecked,
            isHostChecked: isHostChecked,
            useSdk: useSdk);

  int get timeoutMultiplier {
    var multiplier = 1;
    if (isDebug) multiplier *= 4;
    if (isChecked) multiplier *= 2;
    if (isHostChecked) multiplier *= 16;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    var compilerArguments = arguments.toList()..addAll(extraDart2jsOptions);
    return new CommandArtifact([
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
  final Architecture arch;
  final bool useBlobs;
  final bool isAndroid;
  final bool useDfe;

  PrecompilerCompilerConfiguration(
      {bool isDebug,
      bool isChecked,
      this.arch,
      this.useBlobs,
      this.isAndroid,
      this.useDfe: false})
      : super._subclass(isDebug: isDebug, isChecked: isChecked);

  int get timeoutMultiplier {
    var multiplier = 2;
    if (isDebug) multiplier *= 4;
    if (isChecked) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    var commands = new List<Command>();
    commands.add(this.computeCompilationCommand(tempDir, buildDir,
        CommandBuilder.instance, arguments, environmentOverrides));
    if (!useBlobs) {
      commands.add(this.computeAssembleCommand(tempDir, buildDir,
          CommandBuilder.instance, arguments, environmentOverrides));
      commands.add(this.computeRemoveAssemblyCommand(tempDir, buildDir,
          CommandBuilder.instance, arguments, environmentOverrides));
    }
    return new CommandArtifact(
        commands, '$tempDir', 'application/dart-precompiled');
  }

  CompilationCommand computeCompilationCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    String exec;
    if (isAndroid) {
      if (arch == Architecture.arm) {
        exec = "$buildDir/clang_x86/dart_bootstrap";
      } else if (arch == Architecture.arm64) {
        exec = "$buildDir/clang_x64/dart_bootstrap";
      }
    } else {
      exec = "$buildDir/dart_bootstrap";
    }
    var args = <String>[];
    if (useDfe) {
      args.add('--dfe=utils/kernel-service/kernel-service.dart');
      args.add('--platform=${buildDir}/patched_sdk/platform.dill');
    }
    args.add("--snapshot-kind=app-aot");
    if (useBlobs) {
      args.add("--snapshot=$tempDir/out.aotsnapshot");
      args.add("--use-blobs");
    } else {
      args.add("--snapshot=$tempDir/out.S");
    }
    if (isAndroid && arch == Architecture.arm) {
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
    String cc, shared, ldFlags;
    if (isAndroid) {
      var ndk = "third_party/android_tools/ndk";
      String triple;
      if (arch == Architecture.arm) {
        triple = "arm-linux-androideabi";
      } else if (arch == Architecture.arm64) {
        triple = "aarch64-linux-android";
      }
      String host;
      if (Platform.isLinux) {
        host = "linux";
      } else if (Platform.isMacOS) {
        host = "darwin";
      }
      cc = "$ndk/toolchains/$triple-4.9/prebuilt/$host-x86_64/bin/$triple-gcc";
      shared = '-shared';
    } else if (Platform.isLinux) {
      cc = 'gcc';
      shared = '-shared';
    } else if (Platform.isMacOS) {
      cc = 'clang';
      shared = '-dynamiclib';
      // Tell Mac linker to give up generating eh_frame from dwarf.
      ldFlags = '-Wl,-no_compact_unwind';
    } else {
      throw "Platform not supported: ${Platform.operatingSystem}";
    }

    String ccFlags;
    switch (arch) {
      case Architecture.x64:
      case Architecture.simarm64:
        ccFlags = "-m64";
        break;
      case Architecture.ia32:
      case Architecture.simarm:
      case Architecture.simmips:
        ccFlags = "-m32";
        break;
      case Architecture.arm:
      case Architecture.arm64:
        ccFlags = null;
        break;
      case Architecture.mips:
        ccFlags = "-EL";
        break;
      default:
        throw "Architecture not supported: ${arch.name}";
    }

    var exec = cc;
    var args = <String>[];
    if (ccFlags != null) args.add(ccFlags);
    if (ldFlags != null) args.add(ldFlags);
    args.add(shared);
    args.add('-nostdlib');
    args.add('-o');
    args.add('$tempDir/out.aotsnapshot');
    args.add('$tempDir/out.S');

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
    var filtered = vmOptions.toList();
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

    var dir = artifact.filename;
    if (runtimeConfiguration is DartPrecompiledAdbRuntimeConfiguration) {
      // On android the precompiled snapshot will be pushed to a different
      // directory on the device, use that one instead.
      dir = DartPrecompiledAdbRuntimeConfiguration.DeviceTestDir;
    }
    originalArguments =
        replaceDartFileWith(originalArguments, "$dir/out.aotsnapshot");

    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }
}

class AppJitCompilerConfiguration extends CompilerConfiguration {
  AppJitCompilerConfiguration({bool isDebug, bool isChecked})
      : super._subclass(isDebug: isDebug, isChecked: isChecked);

  int get timeoutMultiplier {
    var multiplier = 1;
    if (isDebug) multiplier *= 2;
    if (isChecked) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    var snapshot = "$tempDir/out.jitsnapshot";
    return new CommandArtifact(<Command>[
      this.computeCompilationCommand(tempDir, buildDir, CommandBuilder.instance,
          arguments, environmentOverrides)
    ], snapshot, 'application/dart-snapshot');
  }

  CompilationCommand computeCompilationCommand(
      String tempDir,
      String buildDir,
      CommandBuilder commandBuilder,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    var exec = "$buildDir/dart";
    var snapshot = "$tempDir/out.jitsnapshot";
    var args = ["--snapshot=$snapshot", "--snapshot-kind=app-jit"];
    args.addAll(arguments);

    return commandBuilder.getCompilationCommand('app_jit', tempDir, !useSdk,
        bootstrapDependencies(buildDir), exec, args, environmentOverrides);
  }

  List<String> computeCompilerArguments(
      vmOptions, sharedOptions, originalArguments) {
    var args = <String>[];
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
    args..addAll(vmOptions)..addAll(sharedOptions)..addAll(originalArguments);
    for (var i = 0; i < args.length; i++) {
      if (args[i].endsWith(".dart")) {
        args[i] = artifact.filename;
      }
    }
    return args;
  }
}

class AnalyzerCompilerConfiguration extends CompilerConfiguration {
  AnalyzerCompilerConfiguration(
      {bool isDebug,
      bool isChecked,
      bool isStrong,
      bool isHostChecked,
      bool useSdk})
      : super._subclass(
            isDebug: isDebug,
            isChecked: isChecked,
            isStrong: isStrong,
            isHostChecked: isHostChecked,
            useSdk: useSdk);

  int get timeoutMultiplier => 4;

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
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    arguments = arguments.toList();
    if (isChecked || isStrong) {
      arguments.add('--enable_type_checks');
    }
    if (isStrong) {
      arguments.add('--strong');
    }
    return new CommandArtifact([
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
