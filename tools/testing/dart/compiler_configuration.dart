// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'command.dart';
import 'configuration.dart';
import 'path.dart';
import 'runtime_configuration.dart';
import 'test_suite.dart';
import 'utils.dart';

List<String> _replaceDartFiles(List<String> list, String replacement) {
  return list
      .map((file) => file.endsWith(".dart") ? replacement : file)
      .toList();
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

abstract class CompilerConfiguration {
  final Configuration _configuration;

  bool get _isDebug => _configuration.mode.isDebug;
  bool get _isChecked => _configuration.isChecked;
  bool get _isStrong => _configuration.isStrong;
  bool get _isHostChecked => _configuration.isHostChecked;
  bool get _useSdk => _configuration.useSdk;

  /// Only some subclasses support this check, but we statically allow calling
  /// it on [CompilerConfiguration].
  bool get useDfe {
    throw new UnsupportedError("This compiler does not support DFE.");
  }

  factory CompilerConfiguration(Configuration configuration) {
    switch (configuration.compiler) {
      case Compiler.dart2analyzer:
        return new AnalyzerCompilerConfiguration(configuration);

      case Compiler.dart2js:
        return new Dart2jsCompilerConfiguration(configuration);

      case Compiler.dartdevc:
        return new DartdevcCompilerConfiguration(configuration);

      case Compiler.appJit:
        return new AppJitCompilerConfiguration(configuration);

      case Compiler.precompiler:
        return new PrecompilerCompilerConfiguration(configuration);

      case Compiler.dartk:
        return new NoneCompilerConfiguration(configuration, useDfe: true);

      case Compiler.dartkp:
        return new PrecompilerCompilerConfiguration(configuration,
            useDfe: true);

      case Compiler.none:
        return new NoneCompilerConfiguration(configuration);
    }

    throw "unreachable";
  }

  CompilerConfiguration._subclass(this._configuration);

  /// A multiplier used to give tests longer time to run.
  int get timeoutMultiplier => 1;

  // TODO(ahe): It shouldn't be necessary to pass [buildDir] to any of these
  // functions. It is fixed for a given configuration.
  String computeCompilerPath() {
    throw "Unknown compiler for: $runtimeType";
  }

  bool get hasCompiler => true;

  String get executableScriptSuffix => Platform.isWindows ? '.bat' : '';

  List<Uri> bootstrapDependencies() => const <Uri>[];

  /// Creates a [Command] to compile [inputFile] to [outputFile].
  Command createCommand(String inputFile, String outputFile) {
    // TODO(rnystrom): See if this method can be unified with
    // computeCompilationArtifact() and/or computeCompilerArguments() for the
    // other compilers.
    throw new UnsupportedError("$this does not support createCommand().");
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    return new CommandArtifact([], null, null);
  }

  List<String> computeCompilerArguments(
      List<String> vmOptions, List<String> sharedOptions, List<String> args) {
    return sharedOptions.toList()..addAll(args);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
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
  final bool useDfe;

  NoneCompilerConfiguration(Configuration configuration, {this.useDfe: false})
      : super._subclass(configuration);

  bool get hasCompiler => false;

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    var buildDir = _configuration.buildDirectory;
    var args = <String>[];
    if (useDfe) {
      args.add('--dfe=${buildDir}/gen/kernel-service.dart.snapshot');
      args.add('--kernel-binaries=${buildDir}/patched_sdk');
      if (_isDebug) {
        // Temporarily disable background compilation to avoid flaky crashes
        // (see http://dartbug.com/30016 for details).
        args.add('--no-background-compilation');
      }
    }
    if (_isChecked) {
      args.add('--enable_asserts');
      args.add('--enable_type_checks');
    }
    if (_configuration.hotReload) {
      args.add('--hot-reload-test-mode');
    } else if (_configuration.hotReloadRollback) {
      args.add('--hot-reload-rollback-test-mode');
    }
    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }
}

typedef List<String> CompilerArgumentsFunction(
    List<String> globalArguments, String previousCompilerOutput);

class PipelineCommand {
  final CompilerConfiguration compilerConfiguration;
  final CompilerArgumentsFunction _argumentsFunction;

  PipelineCommand._(this.compilerConfiguration, this._argumentsFunction);

  factory PipelineCommand.runWithGlobalArguments(
      CompilerConfiguration configuration) {
    return new PipelineCommand._(configuration,
        (List<String> globalArguments, String previousOutput) {
      assert(previousOutput == null);
      return globalArguments;
    });
  }

  factory PipelineCommand.runWithDartOrKernelFile(
      CompilerConfiguration configuration) {
    return new PipelineCommand._(configuration,
        (List<String> globalArguments, String previousOutput) {
      var filtered = globalArguments
          .where((name) => name.endsWith('.dart') || name.endsWith('.dill'))
          .toList();
      assert(filtered.length == 1);
      return filtered;
    });
  }

  factory PipelineCommand.runWithPreviousKernelOutput(
      CompilerConfiguration configuration) {
    return new PipelineCommand._(configuration,
        (List<String> globalArguments, String previousOutput) {
      assert(previousOutput.endsWith('.dill'));
      return _replaceDartFiles(globalArguments, previousOutput);
    });
  }

  List<String> extractArguments(
      List<String> globalArguments, String previousOutput) {
    return _argumentsFunction(globalArguments, previousOutput);
  }
}

class ComposedCompilerConfiguration extends CompilerConfiguration {
  final List<PipelineCommand> pipelineCommands;

  ComposedCompilerConfiguration(
      Configuration configuration, this.pipelineCommands)
      : super._subclass(configuration);

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> globalArguments, Map<String, String> environmentOverrides) {
    var allCommands = <Command>[];

    // The first compilation command is as usual.
    var arguments = pipelineCommands[0].extractArguments(globalArguments, null);
    CommandArtifact artifact = pipelineCommands[0]
        .compilerConfiguration
        .computeCompilationArtifact(tempDir, arguments, environmentOverrides);
    allCommands.addAll(artifact.commands);

    // The following compilation commands are based on the output of the
    // previous one.
    for (var i = 1; i < pipelineCommands.length; i++) {
      PipelineCommand command = pipelineCommands[i];

      arguments = command.extractArguments(globalArguments, artifact.filename);
      artifact = command.compilerConfiguration
          .computeCompilationArtifact(tempDir, arguments, environmentOverrides);

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
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    CompilerConfiguration lastCompilerConfiguration =
        pipelineCommands.last.compilerConfiguration;
    return lastCompilerConfiguration.computeRuntimeArguments(
        runtimeConfiguration,
        info,
        vmOptions,
        sharedOptions,
        originalArguments,
        artifact);
  }
}

/// Common configuration for dart2js-based tools, such as, dart2js
class Dart2xCompilerConfiguration extends CompilerConfiguration {
  final String moniker;
  static Map<String, List<Uri>> _bootstrapDependenciesCache = {};

  Dart2xCompilerConfiguration(this.moniker, Configuration configuration)
      : super._subclass(configuration);

  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    var suffix = executableScriptSuffix;

    if (_isHostChecked) {
      // The script dart2js_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dart2js_developer$suffix';
    }

    if (_useSdk) {
      prefix = '${_configuration.buildDirectory}/dart-sdk/bin';
    }
    return '$prefix/dart2js$suffix';
  }

  Command computeCompilationCommand(String outputFileName,
      List<String> arguments, Map<String, String> environmentOverrides) {
    arguments = arguments.toList();
    arguments.add('--out=$outputFileName');

    return Command.compilation(moniker, outputFileName, bootstrapDependencies(),
        computeCompilerPath(), arguments, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  List<Uri> bootstrapDependencies() {
    if (!_useSdk) return const <Uri>[];
    return _bootstrapDependenciesCache.putIfAbsent(
        _configuration.buildDirectory,
        () => [
              Uri.base
                  .resolveUri(new Uri.directory(_configuration.buildDirectory))
                  .resolve('dart-sdk/bin/snapshots/dart2js.dart.snapshot')
            ]);
  }
}

/// Configuration for dart2js compiler.
class Dart2jsCompilerConfiguration extends Dart2xCompilerConfiguration {
  Dart2jsCompilerConfiguration(Configuration configuration)
      : super('dart2js', configuration);

  int get timeoutMultiplier {
    var multiplier = 1;
    if (_isDebug) multiplier *= 4;
    if (_isChecked) multiplier *= 2;
    if (_isHostChecked) multiplier *= 16;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var compilerArguments = arguments.toList()
      ..addAll(_configuration.dart2jsOptions);
    return new CommandArtifact([
      computeCompilationCommand(
          '$tempDir/out.js', compilerArguments, environmentOverrides)
    ], '$tempDir/out.js', 'application/javascript');
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    Uri sdk = _useSdk
        ? new Uri.directory(_configuration.buildDirectory).resolve('dart-sdk/')
        : new Uri.directory(TestUtils.dartDir.toNativePath()).resolve('sdk/');
    Uri preambleDir = sdk.resolve('lib/_internal/js_runtime/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
      ..add(artifact.filename);
  }
}

/// Configuration for dart2js compiler.
class DartdevcCompilerConfiguration extends CompilerConfiguration {
  DartdevcCompilerConfiguration(Configuration configuration)
      : super._subclass(configuration);

  String computeCompilerPath() {
    var dir = _useSdk ? "${_configuration.buildDirectory}/dart-sdk" : "sdk";
    return "$dir/bin/dartdevc$executableScriptSuffix";
  }

  Command createCommand(String inputFile, String outputFile) {
    var moduleRoot =
        new Path(outputFile).directoryPath.directoryPath.toNativePath();

    var args = [
      "--dart-sdk",
      "${_configuration.buildDirectory}/dart-sdk",
      "--library-root",
      new Path(inputFile).directoryPath.toNativePath(),
      "--module-root",
      moduleRoot,
      "--no-summarize",
      "--no-source-map",
      "-o",
      outputFile,
      inputFile,
    ];

    // Link to the summaries for the available packages, so that they don't
    // get recompiled into the test's own module.
    for (var package in testPackages) {
      args.add("-s");

      // Since the summaries for the packages are not near the tests, we give
      // dartdevc explicit module paths for each one. When the test is run, we
      // will tell require.js where to find each package's compiled JS.
      var summary = _configuration.buildDirectory +
          "/gen/utils/dartdevc/pkg/$package.sum";
      args.add("$summary=$package");
    }

    return Command.compilation(Compiler.dartdevc.name, outputFile,
        bootstrapDependencies(), computeCompilerPath(), args, const {});
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    // TODO(rnystrom): Are there other arguments here that we need to keep?
    // What about arguments specified in the test itself?
    var inputFile = arguments.last;
    var outputFile = "$tempDir/${inputFile.replaceAll('.dart', '.js')}";

    return new CommandArtifact([createCommand(inputFile, outputFile)],
        outputFile, "application/javascript");
  }
}

class PrecompilerCompilerConfiguration extends CompilerConfiguration {
  final bool useDfe;

  bool get _isAndroid => _configuration.system == System.android;
  bool get _isArm => _configuration.architecture == Architecture.arm;
  bool get _isArm64 => _configuration.architecture == Architecture.arm64;

  PrecompilerCompilerConfiguration(Configuration configuration,
      {this.useDfe: false})
      : super._subclass(configuration);

  int get timeoutMultiplier {
    var multiplier = 2;
    if (_isDebug) multiplier *= 4;
    if (_isChecked) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var commands = [
      computeCompilationCommand(tempDir, arguments, environmentOverrides)
    ];

    if (!_configuration.useBlobs) {
      commands.add(
          computeAssembleCommand(tempDir, arguments, environmentOverrides));
      commands.add(computeRemoveAssemblyCommand(
          tempDir, arguments, environmentOverrides));
    }

    return new CommandArtifact(
        commands, '$tempDir', 'application/dart-precompiled');
  }

  Command computeCompilationCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var buildDir = _configuration.buildDirectory;
    String exec;
    if (_isAndroid) {
      if (_isArm) {
        exec = "$buildDir/clang_x86/dart_bootstrap";
      } else if (_configuration.architecture == Architecture.arm64) {
        exec = "$buildDir/clang_x64/dart_bootstrap";
      }
    } else {
      exec = "$buildDir/dart_bootstrap";
    }

    var args = <String>[];
    if (useDfe) {
      args.add('--dfe=utils/kernel-service/kernel-service.dart');
      args.add('--kernel-binaries=${buildDir}/patched_sdk');
    }

    args.add("--snapshot-kind=app-aot");
    if (_configuration.useBlobs) {
      args.add("--snapshot=$tempDir/out.aotsnapshot");
      args.add("--use-blobs");
    } else {
      args.add("--snapshot=$tempDir/out.S");
    }

    if (_isAndroid && _isArm) {
      args.add('--no-sim-use-hardfp');
    }

    args.addAll(arguments);

    return Command.compilation('precompiler', tempDir, bootstrapDependencies(),
        exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  Command computeAssembleCommand(String tempDir, List arguments,
      Map<String, String> environmentOverrides) {
    String cc, shared, ldFlags;
    if (_isAndroid) {
      var ndk = "third_party/android_tools/ndk";
      String triple;
      if (_isArm) {
        triple = "arm-linux-androideabi";
      } else if (_isArm64) {
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
    switch (_configuration.architecture) {
      case Architecture.x64:
      case Architecture.simarm64:
        ccFlags = "-m64";
        break;
      case Architecture.ia32:
      case Architecture.simarm:
      case Architecture.arm:
      case Architecture.arm64:
        ccFlags = null;
        break;
      default:
        throw "Architecture not supported: ${_configuration.architecture.name}";
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

    return Command.compilation('assemble', tempDir, bootstrapDependencies(),
        exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  // This step reduces the amount of space needed to run the precompilation
  // tests by 60%.
  Command computeRemoveAssemblyCommand(String tempDir, List arguments,
      Map<String, String> environmentOverrides) {
    var exec = 'rm';
    var args = ['$tempDir/out.S'];

    return Command.compilation('remove_assembly', tempDir,
        bootstrapDependencies(), exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
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
    if (_isChecked) {
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
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    var args = <String>[];
    if (_isChecked) {
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
        _replaceDartFiles(originalArguments, "$dir/out.aotsnapshot");

    return args
      ..addAll(vmOptions)
      ..addAll(sharedOptions)
      ..addAll(originalArguments);
  }
}

class AppJitCompilerConfiguration extends CompilerConfiguration {
  AppJitCompilerConfiguration(Configuration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier {
    var multiplier = 1;
    if (_isDebug) multiplier *= 2;
    if (_isChecked) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var snapshot = "$tempDir/out.jitsnapshot";
    return new CommandArtifact(
        [computeCompilationCommand(tempDir, arguments, environmentOverrides)],
        snapshot,
        'application/dart-snapshot');
  }

  Command computeCompilationCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var exec = "${_configuration.buildDirectory}/dart";
    var snapshot = "$tempDir/out.jitsnapshot";
    var args = ["--snapshot=$snapshot", "--snapshot-kind=app-jit"];
    args.addAll(arguments);

    return Command.compilation('app_jit', tempDir, bootstrapDependencies(),
        exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  List<String> computeCompilerArguments(
      vmOptions, sharedOptions, originalArguments) {
    var args = <String>[];
    if (_isChecked) {
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
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    var args = <String>[];
    if (_isChecked) {
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
  AnalyzerCompilerConfiguration(Configuration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier => 4;

  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    String suffix = executableScriptSuffix;
    if (_isHostChecked) {
      if (_useSdk) {
        throw "--host-checked and --use-sdk cannot be used together";
      }
      // The script dartanalyzer_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dartanalyzer_developer$suffix';
    }
    if (_useSdk) {
      prefix = '${_configuration.buildDirectory}/dart-sdk/bin';
    }
    return '$prefix/dartanalyzer$suffix';
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    arguments = arguments.toList();
    if (_isChecked || _isStrong) {
      arguments.add('--enable_type_checks');
    }
    if (_isStrong) {
      arguments.add('--strong');
    }

    // Since this is not a real compilation, no artifacts are produced.
    return new CommandArtifact([
      Command.analysis(computeCompilerPath(), arguments, environmentOverrides)
    ], null, null);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return <String>[];
  }
}
