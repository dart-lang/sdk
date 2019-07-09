// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'command.dart';
import 'configuration.dart';
import 'path.dart';
import 'repository.dart';
import 'runtime_configuration.dart';
import 'test_file.dart';
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
  final TestConfiguration _configuration;

  bool get _isDebug => _configuration.mode.isDebug;

  bool get _isChecked => _configuration.isChecked;

  bool get _isHostChecked => _configuration.isHostChecked;

  bool get _useSdk => _configuration.useSdk;

  bool get _useEnableAsserts => _configuration.useEnableAsserts;

  bool get previewDart2 => !_configuration.noPreviewDart2;

  /// Whether to run the runtime on the compilation result of a test which
  /// expects a compile-time error and the compiler did not emit one.
  bool get runRuntimeDespiteMissingCompileTimeError => false;

  factory CompilerConfiguration(TestConfiguration configuration) {
    switch (configuration.compiler) {
      case Compiler.dart2analyzer:
        return AnalyzerCompilerConfiguration(configuration);

      case Compiler.compareAnalyzerCfe:
        return CompareAnalyzerCfeCompilerConfiguration(configuration);

      case Compiler.dart2js:
        return Dart2jsCompilerConfiguration(configuration);

      case Compiler.dartdevc:
        return DevCompilerConfiguration(configuration);

      case Compiler.dartdevk:
        return DevCompilerConfiguration(configuration);

      case Compiler.appJitk:
        return AppJitCompilerConfiguration(configuration);

      case Compiler.dartk:
      case Compiler.dartkb:
        if (configuration.architecture == Architecture.simdbc64 ||
            configuration.architecture == Architecture.simarm ||
            configuration.architecture == Architecture.simarm64 ||
            configuration.system == System.android) {
          return VMKernelCompilerConfiguration(configuration);
        }
        return NoneCompilerConfiguration(configuration);

      case Compiler.dartkp:
        return PrecompilerCompilerConfiguration(configuration);

      case Compiler.specParser:
        return SpecParserCompilerConfiguration(configuration);

      case Compiler.fasta:
        return FastaCompilerConfiguration(configuration);

      case Compiler.none:
        return NoneCompilerConfiguration(configuration);
    }

    throw "unreachable";
  }

  CompilerConfiguration._subclass(this._configuration);

  /// A multiplier used to give tests longer time to run.
  int get timeoutMultiplier {
    if (_configuration.configuration.vmOptions
        .any((s) => s.contains("optimization-counter-threshold"))) {
      return 2;
    } else {
      return 1;
    }
  }

  String computeCompilerPath() {
    throw "Unknown compiler for: $runtimeType";
  }

  bool get hasCompiler => true;

  String get executableScriptSuffix => Platform.isWindows ? '.bat' : '';

  List<Uri> bootstrapDependencies() => const <Uri>[];

  CommandArtifact computeCompilationArtifact(

      /// Each test has its own temporary directory to avoid name collisions.
      String tempDir,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    return CommandArtifact([], null, null);
  }

  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> args) {
    return [...sharedOptions, ..._configuration.sharedOptions, ...args];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [artifact.filename];
  }
}

/// The "none" compiler.
class NoneCompilerConfiguration extends CompilerConfiguration {
  NoneCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  bool get hasCompiler => false;

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [
      if (_isDebug)
        // Temporarily disable background compilation to avoid flaky crashes
        // (see http://dartbug.com/30016 for details).
        '--no-background-compilation',
      if (_useEnableAsserts) '--enable_asserts',
      if (_configuration.hotReload)
        '--hot-reload-test-mode'
      else if (_configuration.hotReloadRollback)
        '--hot-reload-rollback-test-mode',
      ...vmOptions,
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ...originalArguments,
      ...testFile.dartOptions
    ];
  }
}

class VMKernelCompilerConfiguration extends CompilerConfiguration
    with VMKernelCompilerMixin {
  VMKernelCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  bool get _isAot => false;

  // Issue(http://dartbug.com/29840): Currently fasta sometimes does not emit a
  // compile-time error (even though it should).  The VM will emit some of these
  // compile-time errors (e.g. in constant evaluator, class finalizer, ...).
  //
  //   => Since this distinction between fasta and vm reported compile-time
  //      errors do not exist when running dart with the kernel-service, we will
  //      also not make this distinction when compiling to .dill and then run.
  //
  // The corresponding http://dartbug.com/29840 tracks to get the frontend to
  // emit all necessary compile-time errors (and *additionally* encode them
  // in the AST in certain cases).
  bool get runRuntimeDespiteMissingCompileTimeError => true;

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    final commands = <Command>[
      computeCompileToKernelCommand(tempDir, arguments, environmentOverrides),
    ];
    return CommandArtifact(commands, tempKernelFile(tempDir),
        'application/kernel-ir-fully-linked');
  }

  @override
  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> args) {
    return [
      ...sharedOptions,
      ..._configuration.sharedOptions,
      ...vmOptions,
      ...args
    ];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    var filename = artifact.filename;
    if (runtimeConfiguration is DartkAdbRuntimeConfiguration) {
      // On Android the Dill file will be pushed to a different directory on the
      // device. Use that one instead.
      filename = "${DartkAdbRuntimeConfiguration.DeviceTestDir}/out.dill";
    }

    return [
      if (_useEnableAsserts) '--enable_asserts',
      if (_configuration.hotReload)
        '--hot-reload-test-mode'
      else if (_configuration.hotReloadRollback)
        '--hot-reload-rollback-test-mode',
      ...vmOptions,
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._replaceDartFiles(originalArguments, filename),
      ...testFile.dartOptions
    ];
  }
}

typedef CompilerArgumentsFunction = List<String> Function(
    List<String> globalArguments, String previousCompilerOutput);

class PipelineCommand {
  final CompilerConfiguration compilerConfiguration;
  final CompilerArgumentsFunction _argumentsFunction;

  PipelineCommand._(this.compilerConfiguration, this._argumentsFunction);

  factory PipelineCommand.runWithGlobalArguments(
      CompilerConfiguration configuration) {
    return PipelineCommand._(configuration,
        (List<String> globalArguments, String previousOutput) {
      assert(previousOutput == null);
      return globalArguments;
    });
  }

  factory PipelineCommand.runWithDartOrKernelFile(
      CompilerConfiguration configuration) {
    return PipelineCommand._(configuration,
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
    return PipelineCommand._(configuration,
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
      TestConfiguration configuration, this.pipelineCommands)
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

    return CommandArtifact(allCommands, artifact.filename, artifact.mimeType);
  }

  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> args) {
    // The result will be passed as an input to [extractArguments]
    // (i.e. the arguments to the [PipelineCommand]).
    return [
      ...vmOptions,
      ...sharedOptions,
      ..._configuration.sharedOptions,
      ...args
    ];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    CompilerConfiguration lastCompilerConfiguration =
        pipelineCommands.last.compilerConfiguration;
    return lastCompilerConfiguration.computeRuntimeArguments(
        runtimeConfiguration, testFile, vmOptions, originalArguments, artifact);
  }
}

/// Common configuration for dart2js-based tools, such as dart2js.
class Dart2xCompilerConfiguration extends CompilerConfiguration {
  final String moniker;
  static Map<String, List<Uri>> _bootstrapDependenciesCache = {};

  Dart2xCompilerConfiguration(this.moniker, TestConfiguration configuration)
      : super._subclass(configuration);

  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    var suffix = executableScriptSuffix;

    if (_isHostChecked) {
      if (_useSdk) {
        // Note: when [_useSdk] is true, dart2js is run from a snapshot that was
        // built without checked mode. The VM cannot make such snapshot run in
        // checked mode later. These two flags could be used together if we also
        // build an sdk with checked snapshots.
        throw "--host-checked and --use-sdk cannot be used together";
      }
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
                  .resolveUri(Uri.directory(_configuration.buildDirectory))
                  .resolve('dart-sdk/bin/snapshots/dart2js.dart.snapshot')
            ]);
  }
}

/// Configuration for dart2js.
class Dart2jsCompilerConfiguration extends Dart2xCompilerConfiguration {
  Dart2jsCompilerConfiguration(TestConfiguration configuration)
      : super('dart2js', configuration);

  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> args) {
    return [
      ...sharedOptions,
      ..._configuration.sharedOptions,
      ...dart2jsOptions,
      ...args
    ];
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var compilerArguments = [...arguments, ..._configuration.dart2jsOptions];

    // TODO(athom): input filename extraction is copied from DDC. Maybe this
    // should be passed to computeCompilationArtifact, instead?
    var inputFile = arguments.last;
    var inputFilename = (Uri.file(inputFile)).pathSegments.last;
    var out = "$tempDir/${inputFilename.replaceAll('.dart', '.js')}";
    var babel = _configuration.babel;
    var babelOut = out;
    if (babel != null && babel.isNotEmpty) {
      out = out.replaceAll('.js', '.raw.js');
    }
    var commands = [
      computeCompilationCommand(out, compilerArguments, environmentOverrides),
      if (babel != null && babel.isNotEmpty)
        computeBabelCommand(out, babelOut, babel)
    ];

    return CommandArtifact(commands, babelOut, 'application/javascript');
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    Uri sdk = _useSdk
        ? Uri.directory(_configuration.buildDirectory).resolve('dart-sdk/')
        : Uri.directory(Repository.dir.toNativePath()).resolve('sdk/');
    Uri preambleDir = sdk.resolve('lib/_internal/js_runtime/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
      ..add(artifact.filename);
  }

  Command computeBabelCommand(String input, String output, String options) {
    var uri = Repository.uri;
    var babelTransform =
        uri.resolve('pkg/test_runner/lib/src/babel_transform.js').toFilePath();
    var babelStandalone =
        uri.resolve('third_party/babel/babel.min.js').toFilePath();
    return Command.compilation(
        'babel',
        output,
        [],
        _configuration.runtimeConfiguration.d8FileName,
        [babelTransform, "--", babelStandalone, options, input],
        {},
        alwaysCompile: true); // TODO(athom): ensure dependency tracking works.
  }
}

/// Configuration for `dartdevc` and `dartdevk` (DDC with Kernel)
class DevCompilerConfiguration extends CompilerConfiguration {
  DevCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  bool get useKernel => _configuration.compiler == Compiler.dartdevk;

  String computeCompilerPath() {
    var dir = _useSdk ? "${_configuration.buildDirectory}/dart-sdk" : "sdk";
    return "$dir/bin/dartdevc$executableScriptSuffix";
  }

  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> args) {
    return [
      ...sharedOptions,
      ..._configuration.sharedOptions,
      ...ddcOptions,
      // The file being compiled is the last argument.
      args.last
    ];
  }

  Command _createCommand(String inputFile, String outputFile,
      List<String> sharedOptions, Map<String, String> environment) {
    /// This can be disabled to test DDC's hybrid mode (automatically converting
    /// Analyzer summaries to Kernel files).
    ///
    /// The current DDC configurations are:
    ///
    /// - using Analyzer ASTs and Analyzer summaries: the current default
    ///   configuration; used in internal builds.
    /// - using Kernel trees and Kernel IL files: the new default for external
    ///   users (e.g. Flutter Web), and in the future, the only DDC mode.
    /// - using Kernel trees, but Analyzer summaries (converted automatically):
    ///   this was intended to help migrate internal users, but is currently
    ///   unused.
    ///
    /// The first two are tested on the bots and are called "dartdevc" and
    /// "dartdevk" respectively. This flag switches "dartdevk" to use either
    /// Kernel IL files, or the Analyzer summaries.
    final useDillFormat = useKernel;

    var args = <String>[];
    if (useKernel) {
      args.add('--kernel');
    }
    if (!_useSdk) {
      // If we're testing a built SDK, DDC will find its own summary.
      //
      // For local development we don't have a built SDK yet, so point directly
      // at the built summary file location.
      var sdkSummaryFile =
          useDillFormat ? 'kernel/ddc_sdk.dill' : 'ddc_sdk.sum';
      var sdkSummary = Path(_configuration.buildDirectory)
          .append("/gen/utils/dartdevc/$sdkSummaryFile")
          .absolute
          .toNativePath();
      args.addAll(["--dart-sdk-summary", sdkSummary]);
    }
    args.addAll(sharedOptions);
    args.addAll(_configuration.sharedOptions);
    if (!useKernel) {
      // TODO(jmesserly): library-root needs to be removed.
      args.addAll(
          ["--library-root", Path(inputFile).directoryPath.toNativePath()]);
    }

    args.addAll([
      "--ignore-unrecognized-flags",
      "--no-summarize",
      "--no-source-map",
      "-o",
      outputFile,
      inputFile,
    ]);

    // Link to the summaries for the available packages, so that they don't
    // get recompiled into the test's own module.
    var pkgDir = useDillFormat ? 'pkg_kernel' : 'pkg';
    var pkgExtension = useDillFormat ? 'dill' : 'sum';
    for (var package in testPackages) {
      args.add("-s");

      // Since the summaries for the packages are not near the tests, we give
      // dartdevc explicit module paths for each one. When the test is run, we
      // will tell require.js where to find each package's compiled JS.
      var summary = Path(_configuration.buildDirectory)
          .append("/gen/utils/dartdevc/$pkgDir/$package.$pkgExtension")
          .absolute
          .toNativePath();
      args.add("$summary=$package");
    }

    var inputDir = Path(inputFile).append("..").canonicalize().toNativePath();
    var displayName = useKernel ? 'dartdevk' : 'dartdevc';
    return Command.compilation(displayName, outputFile, bootstrapDependencies(),
        computeCompilerPath(), args, environment,
        workingDirectory: inputDir);
  }

  CommandArtifact computeCompilationArtifact(
      String tempDir, List<String> arguments, Map<String, String> environment) {
    // The list of arguments comes from a call to our own
    // computeCompilerArguments(). It contains the shared options followed by
    // the input file path.
    // TODO(rnystrom): Jamming these into a list in order to pipe them from
    // computeCompilerArguments() to here seems hacky. Is there a cleaner way?
    var sharedOptions = arguments.sublist(0, arguments.length - 1);
    var inputFile = arguments.last;
    var inputFilename = (Uri.file(inputFile)).pathSegments.last;
    var outputFile = "$tempDir/${inputFilename.replaceAll('.dart', '.js')}";

    return CommandArtifact(
        [_createCommand(inputFile, outputFile, sharedOptions, environment)],
        outputFile,
        "application/javascript");
  }
}

class PrecompilerCompilerConfiguration extends CompilerConfiguration
    with VMKernelCompilerMixin {
  bool get _isAndroid => _configuration.system == System.android;

  bool get _isArm => _configuration.architecture == Architecture.arm;

  bool get _isArm64 => _configuration.architecture == Architecture.arm64;

  bool get _isAot => true;

  PrecompilerCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier {
    var multiplier = 2;
    if (_isDebug) multiplier *= 4;
    if (_useEnableAsserts) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var commands = <Command>[];

    commands.add(computeCompileToKernelCommand(
        tempDir, arguments, environmentOverrides));

    commands.add(
        computeDartBootstrapCommand(tempDir, arguments, environmentOverrides));

    if (!_configuration.keepGeneratedFiles) {
      commands.add(computeRemoveKernelFileCommand(
          tempDir, arguments, environmentOverrides));
    }

    if (!_configuration.useBlobs && !_configuration.useElf) {
      commands.add(
          computeAssembleCommand(tempDir, arguments, environmentOverrides));
      if (!_configuration.keepGeneratedFiles) {
        commands.add(computeRemoveAssemblyCommand(
            tempDir, arguments, environmentOverrides));
      }
    }

    return CommandArtifact(
        commands, '$tempDir', 'application/dart-precompiled');
  }

  /// Creates a command to clean up large temporary kernel files.
  ///
  /// Warning: this command removes temporary file and violates tracking of
  /// dependencies between commands, which may cause problems if multiple
  /// almost identical configurations are tested simultaneously.
  Command computeRemoveKernelFileCommand(String tempDir, List arguments,
      Map<String, String> environmentOverrides) {
    String exec;
    List<String> args;

    if (Platform.isWindows) {
      exec = 'cmd.exe';
      args = ['/c', 'del', tempKernelFile(tempDir)];
    } else {
      exec = 'rm';
      args = [tempKernelFile(tempDir)];
    }

    return Command.compilation('remove_kernel_file', tempDir,
        bootstrapDependencies(), exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  Command computeDartBootstrapCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var buildDir = _configuration.buildDirectory;
    var exec = _configuration.genSnapshotPath;
    if (exec == null) {
      if (_isAndroid) {
        if (_isArm) {
          exec = "$buildDir/clang_x86/gen_snapshot";
        } else if (_configuration.architecture == Architecture.arm64) {
          exec = "$buildDir/clang_x64/gen_snapshot";
        }
      } else {
        exec = "$buildDir/gen_snapshot";
      }
    }

    var args = [
      if (_configuration.useBlobs) ...[
        "--snapshot-kind=app-aot-blobs",
        "--blobs_container_filename=$tempDir/out.aotsnapshot"
      ] else if (_configuration.useElf) ...[
        "--snapshot-kind=app-aot-elf",
        "--elf=$tempDir/out.aotsnapshot"
      ] else ...[
        "--snapshot-kind=app-aot-assembly",
        "--assembly=$tempDir/out.S"
      ],
      if (_isAndroid && _isArm) '--no-sim-use-hardfp',
      if (_configuration.isMinified) '--obfuscate',
      ..._replaceDartFiles(arguments, tempKernelFile(tempDir))
    ];

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

    var args = [
      if (ccFlags != null) ccFlags,
      if (ldFlags != null) ldFlags,
      shared,
      '-nostdlib',
      '-o',
      '$tempDir/out.aotsnapshot',
      '$tempDir/out.S'
    ];

    return Command.compilation('assemble', tempDir, bootstrapDependencies(), cc,
        args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  /// Creates a command to clean up large temporary assembly files.
  ///
  /// This step reduces the amount of space needed to run the precompilation
  /// tests by 60%.
  /// Warning: this command removes temporary file and violates tracking of
  /// dependencies between commands, which may cause problems if multiple
  /// almost identical configurations are tested simultaneously.
  Command computeRemoveAssemblyCommand(String tempDir, List arguments,
      Map<String, String> environmentOverrides) {
    return Command.compilation('remove_assembly', tempDir,
        bootstrapDependencies(), 'rm', ['$tempDir/out.S'], environmentOverrides,
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
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> originalArguments) {
    return [
      if (_useEnableAsserts) '--enable_asserts',
      ...filterVmOptions(vmOptions),
      ...sharedOptions,
      ..._configuration.sharedOptions,
      ...originalArguments
    ];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    var dir = artifact.filename;
    if (runtimeConfiguration is DartPrecompiledAdbRuntimeConfiguration) {
      // On android the precompiled snapshot will be pushed to a different
      // directory on the device, use that one instead.
      dir = DartPrecompiledAdbRuntimeConfiguration.DeviceTestDir;
    }
    originalArguments =
        _replaceDartFiles(originalArguments, "$dir/out.aotsnapshot");

    return [
      if (_useEnableAsserts) '--enable_asserts',
      ...vmOptions,
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ...originalArguments,
      ...testFile.dartOptions
    ];
  }
}

class AppJitCompilerConfiguration extends CompilerConfiguration {
  AppJitCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier {
    var multiplier = 1;
    if (_isDebug) multiplier *= 2;
    if (_useEnableAsserts) multiplier *= 2;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var snapshot = "$tempDir/out.jitsnapshot";
    return CommandArtifact(
        [computeCompilationCommand(tempDir, arguments, environmentOverrides)],
        snapshot,
        'application/dart-snapshot');
  }

  Command computeCompilationCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var snapshot = "$tempDir/out.jitsnapshot";
    return Command.compilation(
        'app_jit',
        tempDir,
        bootstrapDependencies(),
        "${_configuration.buildDirectory}/dart",
        ["--snapshot=$snapshot", "--snapshot-kind=app-jit", ...arguments],
        environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> originalArguments) {
    return [
      if (_useEnableAsserts) '--enable_asserts',
      ...vmOptions,
      ...sharedOptions,
      ..._configuration.sharedOptions,
      ...originalArguments,
      ...dartOptions
    ];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [
      if (_useEnableAsserts) '--enable_asserts',
      ...vmOptions,
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._replaceDartFiles(originalArguments, artifact.filename),
      ...testFile.dartOptions
    ];
  }
}

/// Configuration for dartanalyzer.
class AnalyzerCompilerConfiguration extends CompilerConfiguration {
  AnalyzerCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier => 4;

  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    var suffix = executableScriptSuffix;
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
    if (!previewDart2) {
      throw ArgumentError('--no-preview-dart-2 not supported');
    }

    var args = [
      ...arguments,
      if (_configuration.useAnalyzerCfe) '--use-cfe',
      if (_configuration.useAnalyzerFastaParser) '--use-fasta-parser',
    ];

    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact(
        [Command.analysis(computeCompilerPath(), args, environmentOverrides)],
        null,
        null);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [];
  }
}

/// Configuration for compareAnalyzerCfe.
class CompareAnalyzerCfeCompilerConfiguration extends CompilerConfiguration {
  CompareAnalyzerCfeCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier => 4;

  String computeCompilerPath() {
    String suffix = executableScriptSuffix;
    if (_useSdk) {
      throw "--use-sdk cannot be used with compiler compare_analyzer_cfe";
    }
    return 'pkg/analyzer_fe_comparison/bin/compare_sdk_tests$suffix';
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    if (!previewDart2) {
      throw ArgumentError('--no-preview-dart-2 not supported');
    }

    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact([
      Command.compareAnalyzerCfe(
          computeCompilerPath(), arguments.toList(), environmentOverrides)
    ], null, null);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [];
  }
}

/// Configuration for spec_parser.
class SpecParserCompilerConfiguration extends CompilerConfiguration {
  SpecParserCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  String computeCompilerPath() => 'tools/spec_parse.py';

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    arguments = arguments.toList();

    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact([
      Command.specParse(computeCompilerPath(), arguments, environmentOverrides)
    ], null, null);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [];
  }
}

abstract class VMKernelCompilerMixin {
  static final noCausalAsyncStacksRegExp =
      RegExp('--no[_-]causal[_-]async[_-]stacks');

  TestConfiguration get _configuration;

  bool get _useSdk;

  bool get _isAot;

  bool get _useEnableAsserts;

  String get executableScriptSuffix;

  List<Uri> bootstrapDependencies();

  String tempKernelFile(String tempDir) =>
      Path('$tempDir/out.dill').toNativePath();

  Command computeCompileToKernelCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    final pkgVmDir = Platform.script.resolve('../../../pkg/vm').toFilePath();
    final genKernel = '${pkgVmDir}/tool/gen_kernel${executableScriptSuffix}';

    final String useAbiVersion = arguments.firstWhere(
        (arg) => arg.startsWith('--use-abi-version='),
        orElse: () => null);

    var kernelBinariesFolder = '${_configuration.buildDirectory}';
    if (useAbiVersion != null) {
      var version = useAbiVersion.split('=')[1];
      kernelBinariesFolder += '/dart-sdk/lib/_internal/abiversions/$version';
    } else if (_useSdk) {
      kernelBinariesFolder += '/dart-sdk/lib/_internal';
    }

    var vmPlatform = '$kernelBinariesFolder/vm_platform_strong.dill';

    var dillFile = tempKernelFile(tempDir);

    var causalAsyncStacks = !arguments.any(noCausalAsyncStacksRegExp.hasMatch);

    var args = [
      _isAot ? '--aot' : '--no-aot',
      '--platform=$vmPlatform',
      '-o',
      dillFile,
      arguments.where((name) => name.endsWith('.dart')).single,
      ...arguments.where((name) =>
          name.startsWith('-D') ||
          name.startsWith('--packages=') ||
          name.startsWith('--enable-experiment=')),
      '-Ddart.developer.causal_async_stacks=$causalAsyncStacks',
      if (_useEnableAsserts ||
          arguments.contains('--enable-asserts') ||
          arguments.contains('--enable_asserts'))
        '--enable-asserts',
      if (_configuration.useKernelBytecode) ...[
        '--gen-bytecode',
        '--drop-ast',
        '--bytecode-options=source-positions,local-var-info'
      ]
    ];

    var batchArgs = [if (useAbiVersion != null) useAbiVersion];

    return Command.vmKernelCompilation(dillFile, true, bootstrapDependencies(),
        genKernel, args, environmentOverrides, batchArgs);
  }
}

class FastaCompilerConfiguration extends CompilerConfiguration {
  static final _compilerLocation =
      Repository.uri.resolve("pkg/front_end/tool/_fasta/compile.dart");

  final Uri _platformDill;

  final Uri _vmExecutable;

  bool get _isLegacy => _configuration.noPreviewDart2;

  factory FastaCompilerConfiguration(TestConfiguration configuration) {
    var buildDirectory =
        Uri.base.resolveUri(Uri.directory(configuration.buildDirectory));

    var dillDir = buildDirectory;
    if (configuration.useSdk) {
      dillDir = buildDirectory.resolve("dart-sdk/lib/_internal/");
    }

    var suffix = !configuration.noPreviewDart2 ? "_strong" : "";
    var platformDill = dillDir.resolve("vm_platform$suffix.dill");

    var vmExecutable = buildDirectory
        .resolve(configuration.useSdk ? "dart-sdk/bin/dart" : "dart");
    return FastaCompilerConfiguration._(
        platformDill, vmExecutable, configuration);
  }

  FastaCompilerConfiguration._(
      this._platformDill, this._vmExecutable, TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  bool get runRuntimeDespiteMissingCompileTimeError => true;

  @override
  List<Uri> bootstrapDependencies() => [_platformDill];

  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var output =
        Uri.base.resolveUri(Uri.directory(tempDir)).resolve("out.dill");
    var outputFileName = output.toFilePath();

    var compilerArguments = [
      '--verify',
      if (_isLegacy) "--legacy-mode",
      "-o",
      outputFileName,
      "--platform",
      _platformDill.toFilePath(),
      ...arguments
    ];

    return CommandArtifact([
      Command.fasta(
          _compilerLocation,
          output,
          bootstrapDependencies(),
          _vmExecutable,
          compilerArguments,
          environmentOverrides,
          Repository.uri)
    ], outputFileName, "application/x.dill");
  }

  @override
  List<String> computeCompilerArguments(
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> dartOptions,
      List<String> dart2jsOptions,
      List<String> ddcOptions,
      List<String> args) {
    var arguments = [...sharedOptions, ..._configuration.sharedOptions];
    for (var argument in args) {
      if (argument == "--ignore-unrecognized-flags") continue;
      arguments.add(argument);
      if (!argument.startsWith("-")) {
        // Some tests pass arguments to the Dart program; that is, arguments
        // after the name of the test file. Such arguments have nothing to do
        // with the compiler and should be ignored.
        break;
      }
    }
    return arguments;
  }

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    if (runtimeConfiguration is! NoneRuntimeConfiguration) {
      throw "--compiler=fasta only supports --runtime=none";
    }

    return [];
  }
}
