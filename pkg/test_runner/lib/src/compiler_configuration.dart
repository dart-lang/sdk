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

/// Generates a list with a single `--enable-experiment=` option that includes
/// all experiments enabled by [configuration] and [testFile].
///
/// Returns an empty list if there are no experiments to enable. Returning a
/// list allows the result of calling this to be spread into another list.
List<String> _experimentsArgument(
    TestConfiguration configuration, TestFile testFile) {
  var experiments = {
    ...configuration.experiments,
    ...testFile.experiments,
  };
  if (experiments.isEmpty) {
    return const [];
  }

  return ['--enable-experiment=${experiments.join(',')}'];
}

List<String> _nnbdModeArgument(TestConfiguration configuration) {
  switch (configuration.nnbdMode) {
    case NnbdMode.legacy:
      return [];
    case NnbdMode.strong:
      return ['--sound-null-safety'];
    case NnbdMode.weak:
      return ['--no-sound-null-safety'];
  }

  throw 'unreachable';
}

/// Grouping of a command with its expected result.
class CommandArtifact {
  final List<Command> commands;

  /// Expected result of running [commands].
  final String filename;

  /// MIME type of [filename].
  final String mimeType;

  CommandArtifact(this.commands, this.filename, this.mimeType);
}

abstract class CompilerConfiguration {
  final TestConfiguration _configuration;

  bool get _isDebug => _configuration.mode.isDebug;

  bool get _isHostChecked => _configuration.isHostChecked;

  bool get _useSdk => _configuration.useSdk;

  bool get _enableAsserts => _configuration.enableAsserts;

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
        if (configuration.architecture == Architecture.simarm ||
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

  List<Uri> bootstrapDependencies() => const <Uri>[];

  CommandArtifact computeCompilationArtifact(

      /// Each test has its own temporary directory to avoid name collisions.
      String tempDir,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    return CommandArtifact([], null, null);
  }

  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...args
    ];
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
      if (_enableAsserts) '--enable_asserts',
      if (_configuration.hotReload)
        '--hot-reload-test-mode'
      else if (_configuration.hotReloadRollback)
        '--hot-reload-rollback-test-mode',
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
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
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
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
      filename = "${DartkAdbRuntimeConfiguration.deviceTestDir}/out.dill";
    }

    return [
      if (_enableAsserts) '--enable_asserts',
      if (_configuration.hotReload)
        '--hot-reload-test-mode'
      else if (_configuration.hotReloadRollback)
        '--hot-reload-rollback-test-mode',
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
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
      List<String> arguments, Map<String, String> environmentOverrides) {
    var allCommands = <Command>[];

    // The first compilation command is as usual.
    var compileArguments =
        pipelineCommands[0].extractArguments(arguments, null);
    var artifact = pipelineCommands[0]
        .compilerConfiguration
        .computeCompilationArtifact(
            tempDir, compileArguments, environmentOverrides);
    allCommands.addAll(artifact.commands);

    // The following compilation commands are based on the output of the
    // previous one.
    for (var i = 1; i < pipelineCommands.length; i++) {
      var command = pipelineCommands[i];

      compileArguments = command.extractArguments(arguments, artifact.filename);
      artifact = command.compilerConfiguration.computeCompilationArtifact(
          tempDir, compileArguments, environmentOverrides);

      allCommands.addAll(artifact.commands);
    }

    return CommandArtifact(allCommands, artifact.filename, artifact.mimeType);
  }

  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    // The result will be passed as an input to [extractArguments]
    // (i.e. the arguments to the [PipelineCommand]).
    return [
      ...vmOptions,
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...args
    ];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    var lastCompilerConfiguration = pipelineCommands.last.compilerConfiguration;
    return lastCompilerConfiguration.computeRuntimeArguments(
        runtimeConfiguration, testFile, vmOptions, originalArguments, artifact);
  }
}

/// Common configuration for dart2js-based tools, such as dart2js.
class Dart2xCompilerConfiguration extends CompilerConfiguration {
  static final Map<String, List<Uri>> _bootstrapDependenciesCache = {};

  final String moniker;

  Dart2xCompilerConfiguration(this.moniker, TestConfiguration configuration)
      : super._subclass(configuration);

  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    var suffix = shellScriptExtension;

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

    return CompilationCommand(moniker, outputFileName, bootstrapDependencies(),
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
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...testFile.dart2jsOptions,
      ..._nnbdModeArgument(_configuration),
      ...args
    ];
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var compilerArguments = [
      ...arguments,
      ..._configuration.dart2jsOptions,
      ..._nnbdModeArgument(_configuration),
    ];

    // TODO(athom): input filename extraction is copied from DDC. Maybe this
    // should be passed to computeCompilationArtifact, instead?
    var inputFile = arguments.last;
    var inputFilename = Uri.file(inputFile).pathSegments.last;
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
    var sdk = _useSdk
        ? Uri.directory(_configuration.buildDirectory).resolve('dart-sdk/')
        : Uri.directory(Repository.dir.toNativePath()).resolve('sdk/');
    var preambleDir = sdk.resolve('lib/_internal/js_runtime/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
      ..add(artifact.filename);
  }

  Command computeBabelCommand(String input, String output, String options) {
    var uri = Repository.uri;
    var babelTransform =
        uri.resolve('pkg/test_runner/lib/src/babel_transform.js').toFilePath();
    var babelStandalone =
        uri.resolve('third_party/babel/babel.min.js').toFilePath();
    return CompilationCommand(
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
    return "$dir/bin/dartdevc$shellScriptExtension";
  }

  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...testFile.ddcOptions,
      if (_configuration.nnbdMode == NnbdMode.strong) '--sound-null-safety',
      // The file being compiled is the last argument.
      args.last
    ];
  }

  Command _createCommand(String inputFile, String outputFile,
      List<String> sharedOptions, Map<String, String> environment) {
    var args = <String>[];
    // Remove option for generating non-null assertions for non-nullable
    // method parameters in weak mode. DDC treats this as a runtime flag for
    // the bootstrapping code, instead of a compiler option.
    var options = sharedOptions.toList();
    options.remove('--null-assertions');
    if (!_useSdk) {
      // If we're testing a built SDK, DDC will find its own summary.
      //
      // For local development we don't have a built SDK yet, so point directly
      // at the built summary file location.
      var sdkSummaryFile = _configuration.nnbdMode == NnbdMode.strong
          ? 'ddc_outline_sound.dill'
          : 'ddc_outline.dill';
      var sdkSummary = Path(_configuration.buildDirectory)
          .append(sdkSummaryFile)
          .absolute
          .toNativePath();
      args.addAll(["--dart-sdk-summary", sdkSummary]);
    }
    args.addAll(options);
    args.addAll(_configuration.sharedOptions);

    args.addAll([
      "--ignore-unrecognized-flags",
      "--no-summarize",
      "-o",
      outputFile,
      inputFile,
    ]);

    // Link to the summaries for the available packages, so that they don't
    // get recompiled into the test's own module.
    var packageSummaryDir =
        _configuration.nnbdMode == NnbdMode.strong ? 'pkg_sound' : 'pkg_kernel';
    for (var package in testPackages) {
      args.add("-s");

      // Since the summaries for the packages are not near the tests, we give
      // dartdevc explicit module paths for each one. When the test is run, we
      // will tell require.js where to find each package's compiled JS.
      var summary = Path(_configuration.buildDirectory)
          .append("/gen/utils/dartdevc/$packageSummaryDir/$package.dill")
          .absolute
          .toNativePath();
      args.add("$summary=$package");
    }

    var inputDir = Path(inputFile).append("..").canonicalize().toNativePath();
    var displayName = useKernel ? 'dartdevk' : 'dartdevc';
    return CompilationCommand(displayName, outputFile, bootstrapDependencies(),
        computeCompilerPath(), args, environment,
        workingDirectory: inputDir);
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    // The list of arguments comes from a call to our own
    // computeCompilerArguments(). It contains the shared options followed by
    // the input file path.
    // TODO(rnystrom): Jamming these into a list in order to pipe them from
    // computeCompilerArguments() to here seems hacky. Is there a cleaner way?
    var sharedOptions = arguments.sublist(0, arguments.length - 1);
    var inputFile = arguments.last;
    var inputFilename = Uri.file(inputFile).pathSegments.last;
    var outputFile = "$tempDir/${inputFilename.replaceAll('.dart', '.js')}";

    return CommandArtifact([
      _createCommand(inputFile, outputFile, sharedOptions, environmentOverrides)
    ], outputFile, "application/javascript");
  }
}

class PrecompilerCompilerConfiguration extends CompilerConfiguration
    with VMKernelCompilerMixin {
  bool get _isAndroid => _configuration.system == System.android;

  bool get _isArm => _configuration.architecture == Architecture.arm;

  bool get _isSimArm => _configuration.architecture == Architecture.simarm;

  bool get _isSimArm64 => _configuration.architecture == Architecture.simarm64;

  bool get _isArmX64 => _configuration.architecture == Architecture.arm_x64;

  bool get _isArm64 => _configuration.architecture == Architecture.arm64;

  bool get _isX64 => _configuration.architecture == Architecture.x64;

  bool get _isIA32 => _configuration.architecture == Architecture.ia32;

  bool get _isAot => true;

  PrecompilerCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  int get timeoutMultiplier {
    var multiplier = 2;
    if (_isDebug) multiplier *= 4;
    if (_enableAsserts) multiplier *= 2;
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

    if (!_configuration.useElf) {
      commands.add(
          computeAssembleCommand(tempDir, arguments, environmentOverrides));
      if (!_configuration.keepGeneratedFiles) {
        commands.add(computeRemoveAssemblyCommand(
            tempDir, arguments, environmentOverrides));
      }
    }

    if (_configuration.useElf && _isAndroid) {
      // On Android, run the NDK's "strip" tool with "--strip-unneeded" to copy
      // Flutter's workflow. Skip this step on tests for DWARF (which may get
      // stripped).
      if (!arguments.last.contains("dwarf")) {
        commands.add(computeStripCommand(tempDir, environmentOverrides));
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

    return CompilationCommand('remove_kernel_file', tempDir,
        bootstrapDependencies(), exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  Command computeDartBootstrapCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var buildDir = _configuration.buildDirectory;
    var exec = _configuration.genSnapshotPath;
    if (exec == null) {
      if (_isAndroid) {
        if (_isArm || _isIA32) {
          exec = "$buildDir/clang_x86/gen_snapshot";
        } else if (_isArm64 || _isX64 || _isArmX64) {
          exec = "$buildDir/clang_x64/gen_snapshot";
        } else {
          // Guaranteed by package:test_runner/src/configuration.dart's
          // TestConfiguration.validate().
          assert(false);
        }
      } else if (_configuration.builderTag == "crossword") {
        exec = "${buildDir}_X64/gen_snapshot";
      } else if (_isArm && _configuration.useQemu) {
        // DebugXARM --> DebugSIMARM_X64
        final simBuildDir = buildDir.replaceAll("XARM", "SIMARM_X64");
        exec = "$simBuildDir/gen_snapshot";
      } else if (_isArm64 && _configuration.useQemu) {
        exec = "$buildDir/clang_x64/gen_snapshot";
      } else {
        exec = "$buildDir/gen_snapshot";
      }
    }

    var args = [
      if (_configuration.useElf) ...[
        "--snapshot-kind=app-aot-elf",
        "--elf=$tempDir/out.aotsnapshot",
        // Only splitting with a ELF to avoid having to setup compilation of
        // multiple assembly files in the test harness.
        "--loading-unit-manifest=$tempDir/ignored.json",
      ] else ...[
        "--snapshot-kind=app-aot-assembly",
        "--assembly=$tempDir/out.S",
      ],
      if (_isAndroid && _isArm) '--no-sim-use-hardfp',
      if (_configuration.isMinified) '--obfuscate',
      // The SIMARM precompiler assumes support for integer division, but the
      // Qemu arm cpus do not support integer division.
      if (_configuration.useQemu) '--no-use-integer-division',
      ..._replaceDartFiles(arguments, tempKernelFile(tempDir)),
    ];

    return CompilationCommand('precompiler', tempDir, bootstrapDependencies(),
        exec, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  static const String ndkPath = "third_party/android_tools/ndk";
  String get abiTriple => _isArm || _isArmX64
      ? "arm-linux-androideabi"
      : _isArm64
          ? "aarch64-linux-android"
          : null;
  String get host => Platform.isLinux
      ? "linux"
      : Platform.isMacOS
          ? "darwin"
          : null;

  Command computeAssembleCommand(String tempDir, List arguments,
      Map<String, String> environmentOverrides) {
    String cc, shared, ldFlags;
    if (_isAndroid) {
      cc = "$ndkPath/toolchains/$abiTriple-4.9/prebuilt/"
          "$host-x86_64/bin/$abiTriple-gcc";
      shared = '-shared';
    } else if (Platform.isLinux) {
      if (_isSimArm || (_isArm && _configuration.useQemu)) {
        cc = 'arm-linux-gnueabihf-gcc';
      } else if (_isSimArm64 || (_isArm64 && _configuration.useQemu)) {
        cc = 'aarch64-linux-gnu-gcc';
      } else {
        cc = 'gcc';
      }
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
        ccFlags = "-m64";
        break;
      case Architecture.simarm64:
      case Architecture.ia32:
      case Architecture.simarm:
      case Architecture.arm:
      case Architecture.arm_x64:
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

    return CompilationCommand('assemble', tempDir, bootstrapDependencies(), cc,
        args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  Command computeStripCommand(
      String tempDir, Map<String, String> environmentOverrides) {
    var stripTool = "$ndkPath/toolchains/$abiTriple-4.9/prebuilt/"
        "$host-x86_64/bin/$abiTriple-strip";
    var args = ['--strip-unneeded', "$tempDir/out.aotsnapshot"];
    return CompilationCommand('strip', tempDir, bootstrapDependencies(),
        stripTool, args, environmentOverrides,
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
    return CompilationCommand('remove_assembly', tempDir,
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
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      if (_enableAsserts) '--enable_asserts',
      ...filterVmOptions(vmOptions),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...args
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
      dir = DartPrecompiledAdbRuntimeConfiguration.deviceTestDir;
    }
    originalArguments =
        _replaceDartFiles(originalArguments, "$dir/out.aotsnapshot");

    return [
      if (_enableAsserts) '--enable_asserts',
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
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
    if (_enableAsserts) multiplier *= 2;
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
    return CompilationCommand(
        'app_jit',
        tempDir,
        bootstrapDependencies(),
        "${_configuration.buildDirectory}/dart",
        ["--snapshot=$snapshot", "--snapshot-kind=app-jit", ...arguments],
        environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      if (_enableAsserts) '--enable_asserts',
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...args,
      ...testFile.dartOptions
    ];
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return [
      if (_enableAsserts) '--enable_asserts',
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
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
    if (_isHostChecked) {
      if (_useSdk) {
        throw "--host-checked and --use-sdk cannot be used together";
      }
      // The script dartanalyzer_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dartanalyzer_developer$shellScriptExtension';
    }
    if (_useSdk) {
      prefix = '${_configuration.buildDirectory}/dart-sdk/bin';
    }
    return '$prefix/dartanalyzer$shellScriptExtension';
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    const legacyTestDirectories = {
      "co19_2",
      "corelib_2",
      "ffi_2",
      "language_2",
      "lib_2",
      "service_2",
      "standalone_2"
    };

    // If we are running a legacy test with NNBD enabled, tell analyzer to use
    // a pre-NNBD language version for the test.
    var testPath = arguments.last;
    var segments = Path(testPath).relativeTo(Repository.dir).segments();
    var setLegacyVersion = segments.any(legacyTestDirectories.contains);

    var args = [
      ...arguments,
      if (_configuration.useAnalyzerCfe) '--use-cfe',
      if (_configuration.useAnalyzerFastaParser) '--use-fasta-parser',
      if (setLegacyVersion) '--default-language-version=2.7',
    ];

    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact(
        [AnalysisCommand(computeCompilerPath(), args, environmentOverrides)],
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
    if (_useSdk) {
      throw "--use-sdk cannot be used with compiler compare_analyzer_cfe";
    }
    return 'pkg/analyzer_fe_comparison/bin/'
        'compare_sdk_tests$shellScriptExtension';
  }

  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact([
      CompareAnalyzerCfeCommand(
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
      SpecParseCommand(computeCompilerPath(), arguments, environmentOverrides)
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
  TestConfiguration get _configuration;

  bool get _useSdk;

  bool get _isAot;

  bool get _enableAsserts;

  List<Uri> bootstrapDependencies();

  String tempKernelFile(String tempDir) =>
      Path('$tempDir/out.dill').toNativePath();

  Command computeCompileToKernelCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var pkgVmDir = Platform.script.resolve('../../../pkg/vm').toFilePath();
    var genKernel = '$pkgVmDir/tool/gen_kernel$shellScriptExtension';

    var kernelBinariesFolder = '${_configuration.buildDirectory}';
    if (_useSdk) {
      kernelBinariesFolder += '/dart-sdk/lib/_internal';
    }

    var vmPlatform = '$kernelBinariesFolder/vm_platform_strong.dill';

    var dillFile = tempKernelFile(tempDir);

    var isProductMode = _configuration.configuration.mode == Mode.product;

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
      '-Ddart.vm.product=$isProductMode',
      if (_enableAsserts ||
          arguments.contains('--enable-asserts') ||
          arguments.contains('--enable_asserts'))
        '--enable-asserts',
      ..._nnbdModeArgument(_configuration),
      ..._configuration.genKernelOptions,
    ];

    return VMKernelCompilationCommand(dillFile, bootstrapDependencies(),
        genKernel, args, environmentOverrides,
        alwaysCompile: true);
  }
}

class FastaCompilerConfiguration extends CompilerConfiguration {
  static final _compilerLocation =
      Repository.uri.resolve("pkg/front_end/tool/_fasta/compile.dart");

  final Uri _platformDill;

  final Uri _vmExecutable;

  factory FastaCompilerConfiguration(TestConfiguration configuration) {
    var buildDirectory =
        Uri.base.resolveUri(Uri.directory(configuration.buildDirectory));

    var dillDir = buildDirectory;
    if (configuration.useSdk) {
      dillDir = buildDirectory.resolve("dart-sdk/lib/_internal/");
    }

    var platformDill = dillDir.resolve("vm_platform_strong.dill");

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
      '--verify-skip-platform',
      "-o",
      outputFileName,
      "--platform",
      _platformDill.toFilePath(),
      ...arguments
    ];

    return CommandArtifact([
      FastaCompilationCommand(
          _compilerLocation,
          output.toFilePath(),
          bootstrapDependencies(),
          _vmExecutable.toFilePath(),
          compilerArguments,
          environmentOverrides,
          Repository.uri.toFilePath())
    ], outputFileName, "application/x.dill");
  }

  @override
  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    // Remove shared option for generating non-null assertions for non-nullable
    // method parameters in weak mode. It's currently unused by the front end.
    var options = testFile.sharedOptions.toList();
    options.remove('--null-assertions');
    var arguments = [
      ...options,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      if (_configuration.configuration.nnbdMode == NnbdMode.strong) ...[
        "--nnbd-strong"
      ]
    ];
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
