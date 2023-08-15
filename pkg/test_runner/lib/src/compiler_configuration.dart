// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'command.dart';
import 'configuration.dart';
import 'path.dart';
import 'repository.dart';
import 'runtime_configuration.dart';
import 'test_case.dart' show TestCase;
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
  var experiments = TestCase.getExperiments(testFile, configuration);
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

      case Compiler.dart2js:
        return Dart2jsCompilerConfiguration(configuration);

      case Compiler.dart2wasm:
        return Dart2WasmCompilerConfiguration(configuration);

      case Compiler.ddc:
        return DevCompilerConfiguration(configuration);

      case Compiler.appJitk:
        return AppJitCompilerConfiguration(configuration);

      case Compiler.dartk:
        if (configuration.architecture == Architecture.simarm ||
            configuration.architecture == Architecture.simarm64 ||
            configuration.architecture == Architecture.simarm64c ||
            configuration.architecture == Architecture.simriscv32 ||
            configuration.architecture == Architecture.simriscv64 ||
            configuration.system == System.android ||
            configuration.useQemu) {
          return VMKernelCompilerConfiguration(configuration);
        }
        return NoneCompilerConfiguration(configuration);

      case Compiler.dartkp:
        return PrecompilerCompilerConfiguration(configuration);

      case Compiler.specParser:
        return SpecParserCompilerConfiguration(configuration);

      case Compiler.fasta:
        return FastaCompilerConfiguration(configuration);
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
      Map<String, String> environmentOverrides);

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
      CommandArtifact? artifact) {
    return artifact == null ? [] : [artifact.filename];
  }
}

/// The "none" compiler.
class NoneCompilerConfiguration extends CompilerConfiguration {
  NoneCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  final bool hasCompiler = false;

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
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

  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    throw UnsupportedError(
        '"None" compiler configuration has no compilation artifacts');
  }
}

class VMKernelCompilerConfiguration extends CompilerConfiguration
    with VMKernelCompilerMixin {
  VMKernelCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
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
  @override
  bool get runRuntimeDespiteMissingCompileTimeError => true;

  @override
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

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    var filename = artifact!.filename;
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
    List<String> globalArguments, String? previousCompilerOutput);

class PipelineCommand {
  final CompilerConfiguration compilerConfiguration;
  final CompilerArgumentsFunction _argumentsFunction;

  PipelineCommand._(this.compilerConfiguration, this._argumentsFunction);

  factory PipelineCommand.runWithGlobalArguments(
      CompilerConfiguration configuration) {
    return PipelineCommand._(configuration, (globalArguments, previousOutput) {
      assert(previousOutput == null);
      return globalArguments;
    });
  }

  factory PipelineCommand.runWithDartOrKernelFile(
      CompilerConfiguration configuration) {
    return PipelineCommand._(configuration,
        (List<String> globalArguments, String? previousOutput) {
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
        (List<String> globalArguments, String? previousOutput) {
      assert(previousOutput!.endsWith('.dill'));
      return _replaceDartFiles(globalArguments, previousOutput!);
    });
  }

  List<String> extractArguments(
      List<String> globalArguments, String? previousOutput) {
    return _argumentsFunction(globalArguments, previousOutput);
  }
}

class ComposedCompilerConfiguration extends CompilerConfiguration {
  final List<PipelineCommand> pipelineCommands;

  ComposedCompilerConfiguration(
      TestConfiguration configuration, this.pipelineCommands)
      : super._subclass(configuration);

  @override
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

  @override
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

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    var lastCompilerConfiguration = pipelineCommands.last.compilerConfiguration;
    return lastCompilerConfiguration.computeRuntimeArguments(
        runtimeConfiguration, testFile, vmOptions, originalArguments, artifact);
  }
}

/// Configuration for dart2js.
class Dart2jsCompilerConfiguration extends CompilerConfiguration {
  static final Map<String, List<Uri>> _bootstrapDependenciesCache = {};

  Dart2jsCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  String computeCompilerPath() {
    if (_isHostChecked && _useSdk) {
      // When [_useSdk] is true, dart2js is compiled into a snapshot that was
      // built without checked mode. The VM cannot make such snapshot run in
      // checked mode later. These two flags could be used together if we also
      // build an sdk with checked snapshots.
      throw "--host-checked and --use-sdk cannot be used together";
    }

    if (_useSdk) {
      var dartSdk = '${_configuration.buildDirectory}/dart-sdk';
      // When using the shipped sdk, we invoke dart2js via the dart CLI using
      // `dart compile js`.  The additional `compile js` arguments are added
      // within [Dart2jsCompilationCommand]. This is because the arguments are
      // added differently depending on whether the command is executed in batch
      // mode or not.
      return '$dartSdk/bin/dart$executableExtension';
    } else {
      var scriptName = _isHostChecked ? 'dart2js_developer' : 'dart2js';
      return 'sdk/bin/$scriptName$shellScriptExtension';
    }
  }

  Command computeCompilationCommand(String outputFileName,
      List<String> arguments, Map<String, String> environmentOverrides) {
    arguments = arguments.toList();
    arguments.add('--out=$outputFileName');

    return Dart2jsCompilationCommand(outputFileName, bootstrapDependencies(),
        computeCompilerPath(), arguments, environmentOverrides,
        useSdk: _useSdk, alwaysCompile: !_useSdk);
  }

  @override
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

  @override
  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...testFile.dart2jsOptions,
      ..._nnbdModeArgument(_configuration),
      if (_configuration.nnbdMode == NnbdMode.weak)
        // Unsound platform dill files are no longer packaged in the SDK and
        // must be read from the build directory during tests.
        '--platform-binaries=${_configuration.buildDirectory}',
      ...args
    ];
  }

  @override
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
    if (babel.isNotEmpty) {
      out = out.replaceAll('.js', '.raw.js');
    }
    var commands = [
      computeCompilationCommand(out, compilerArguments, environmentOverrides),
      if (babel.isNotEmpty) computeBabelCommand(out, babelOut, babel)
    ];

    return CommandArtifact(commands, babelOut, 'application/javascript');
  }

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    var sdk = _useSdk
        ? Uri.directory(_configuration.buildDirectory).resolve('dart-sdk/')
        : Uri.directory(Repository.dir.toNativePath()).resolve('sdk/');
    var preambleDir = sdk.resolve('lib/_internal/js_runtime/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
      ..add(artifact!.filename);
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

/// Common configuration for dart2wasm-based tools, such as dart2wasm.
class Dart2WasmCompilerConfiguration extends CompilerConfiguration {
  Dart2WasmCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    if (_isHostChecked) {
      if (_useSdk) {
        throw "--host-checked and --use-sdk cannot be used together";
      }
      // The script dart2wasm_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dart2wasm_developer$shellScriptExtension';
    }
    if (_useSdk) {
      prefix = '${_configuration.buildDirectory}/dart-sdk/bin';
    }
    return '$prefix/dart2wasm$shellScriptExtension';
  }

  @override
  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...testFile.dart2wasmOptions,
      // The file being compiled is the last argument.
      args.last
    ];
  }

  Command computeCompilationCommand(String outputFileName,
      List<String> arguments, Map<String, String> environmentOverrides) {
    arguments = arguments.toList();
    arguments.add(outputFileName);

    return CompilationCommand(
        'dart2wasm',
        outputFileName,
        bootstrapDependencies(),
        computeCompilerPath(),
        arguments,
        environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var compilerArguments = [
      ...arguments,
    ];

    var inputFile = arguments.last;
    var inputFilename = Uri.file(inputFile).pathSegments.last;
    var out = "$tempDir/${inputFilename.replaceAll('.dart', '.wasm')}";
    var commands = [
      computeCompilationCommand(out, compilerArguments, environmentOverrides),
    ];

    return CommandArtifact(commands, out, 'application/wasm');
  }

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    final filename = artifact!.filename;
    final args = testFile.dartOptions;
    return [
      '--experimental-wasm-gc',
      '--experimental-wasm-type-reflection',
      '--wasm-final-types',
      '--wasm-disable-deprecated',
      'pkg/dart2wasm/bin/run_wasm.js',
      '--',
      '${filename.substring(0, filename.lastIndexOf('.'))}.mjs',
      filename,
      ...testFile.sharedObjects
          .map((obj) => '${_configuration.buildDirectory}/wasm/$obj.wasm'),
      if (args.isNotEmpty) '--',
      ...args,
    ];
  }
}

/// Configuration for "ddc".
class DevCompilerConfiguration extends CompilerConfiguration {
  final bool _soundNullSafety;

  /// The output directory under `_configuration.buildDirectory` where DDC build
  /// targets are output.
  final String genDir;

  DevCompilerConfiguration(TestConfiguration configuration)
      : _soundNullSafety = configuration.nnbdMode == NnbdMode.strong,
        genDir = [
          'gen/utils/ddc/',
          if (configuration.ddcOptions.contains('--canary'))
            'canary'
          else
            'stable',
          if (configuration.nnbdMode != NnbdMode.strong) '_unsound'
        ].join(),
        super._subclass(configuration);

  @override
  String computeCompilerPath() {
    // DDC is a Dart program and not an executable itself, so the command to
    // spawn as a subprocess is a Dart VM.
    // Internally the [DevCompilerCompilationCommand] will prepend the snapshot
    // or Dart library entrypoint that is executed by the VM.
    // This will change once we update the DDC to use AOT instead of a snapshot.
    var dir = _useSdk ? '${_configuration.buildDirectory}/dart-sdk' : 'sdk';
    return '$dir/bin/dart$executableExtension';
  }

  @override
  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      ...testFile.sharedOptions,
      ...testFile.ddcOptions,
      ..._configuration.sharedOptions,
      ..._configuration.ddcOptions,
      ..._experimentsArgument(_configuration, testFile),
      if (_soundNullSafety) '--sound-null-safety' else '--no-sound-null-safety',
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
    if (!_useSdk || !_soundNullSafety) {
      // If we're testing a built SDK, DDC will find its own summary.
      //
      // Unsound summary files are not longer bundled with the built SDK so they
      // must always be specified manually.
      //
      // For local development we don't have a built SDK yet, so point directly
      // at the built summary file location.
      var sdkSummaryFile =
          _soundNullSafety ? 'ddc_outline.dill' : 'ddc_outline_unsound.dill';
      var sdkSummary = Path(_configuration.buildDirectory)
          .append(sdkSummaryFile)
          .absolute
          .toNativePath();
      args.addAll(["--dart-sdk-summary", sdkSummary]);
    }
    args.addAll(options);
    args.addAll(_configuration.sharedOptions);

    var d8Runtime = _configuration.runtime == Runtime.d8;

    args.addAll([
      "--ignore-unrecognized-flags",
      "--no-summarize",
      if (d8Runtime) "--modules=legacy",
      "-o",
      outputFile,
      inputFile,
    ]);

    if (!d8Runtime) {
      // TODO(sigmund): allow caching of shared packages in legacy mode too.
      // Link to the summaries for the available packages, so that they don't
      // get recompiled into the test's own module.
      for (var package in testPackages) {
        args.add("-s");

        // Since the summaries for the packages are not near the tests, we give
        // dartdevc explicit module paths for each one. When the test is run, we
        // will tell require.js where to find each package's compiled JS.
        var summary = Path(_configuration.buildDirectory)
            .append('$genDir/pkg/$package.dill')
            .absolute
            .toNativePath();
        args.add("$summary=$package");
      }
    }

    var compilerPath = _useSdk
        ? '${_configuration.buildDirectory}/dart-sdk/bin/snapshots/dartdevc.dart.snapshot'
        : Repository.uri.resolve('pkg/dev_compiler/bin/dartdevc.dart').path;
    return DevCompilerCompilationCommand(outputFile, bootstrapDependencies(),
        computeCompilerPath(), args, environment,
        compilerPath: compilerPath, alwaysCompile: false);
  }

  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    // The list of arguments comes from a call to our own
    // computeCompilerArguments(). It contains the shared options followed by
    // the input file path.
    // TODO(rnystrom): Jamming these into a list in order to pipe them from
    // computeCompilerArguments() to here seems hacky. Is there a cleaner way?
    var sharedOptions = arguments.sublist(0, arguments.length - 1);
    var inputFile = arguments.last;
    var inputUri = Uri.file(inputFile);
    var inputFilename = inputUri.pathSegments.last;
    var moduleName =
        inputFilename.substring(0, inputFilename.length - ".dart".length);
    var outputFile = "$tempDir/$moduleName.js";
    var runFile = outputFile;

    if (_configuration.runtime == Runtime.d8) {
      // TODO(sigmund): ddc should have a flag to emit an entrypoint file like
      // the one below, otherwise it is susceptible to break, for example, if
      // library naming conventions were to change in the future.
      runFile = "$tempDir/$moduleName.d8.js";
      var nonNullAsserts = arguments.contains('--null-assertions');
      var nativeNonNullAsserts = arguments.contains('--native-null-assertions');
      var weakNullSafetyErrors =
          arguments.contains('--weak-null-safety-errors');
      var weakNullSafetyWarnings = !(weakNullSafetyErrors || _soundNullSafety);
      var repositoryUri = Uri.directory(Repository.dir.toNativePath());
      var dartLibraryPath = repositoryUri
          .resolve('pkg/dev_compiler/lib/js/legacy/dart_library.js')
          .path;
      var sdkJsDir =
          Uri.directory(_configuration.buildDirectory).resolve('$genDir/sdk');
      var sdkJsPath = 'dart_sdk.js';
      var libraryName = inputUri.path
          .substring(repositoryUri.path.length)
          .replaceAll("/", "__")
          .replaceAll("-", "_")
          .replaceAll(".dart", "");

      // Note: this assumes that d8 is invoked with the dart2js d8.js preamble.
      // TODO(sigmund): to support other runtimes like js-shell, we may want to
      // remove the `load` statements here and instead provide those files
      // through the runtime command-line arguments.
      File(runFile).writeAsStringSync('''
        load("$dartLibraryPath");
        load("$sdkJsDir/$sdkJsPath");
        load("$outputFile");

        let sdk = dart_library.import("dart_sdk");
        sdk.dart.weakNullSafetyWarnings($weakNullSafetyWarnings);
        sdk.dart.weakNullSafetyErrors($weakNullSafetyErrors);
        sdk.dart.nonNullAsserts($nonNullAsserts);
        sdk.dart.nativeNonNullAsserts($nativeNonNullAsserts);

        // Invoke main through the d8 preamble to ensure the code is running
        // within the fake event loop.
        self.dartMainRunner(function () {
          dart_library.start("$moduleName", "$libraryName");
        });
      '''
          .replaceAll("\n        ", "\n"));
    }

    return CommandArtifact([
      _createCommand(inputFile, outputFile, sharedOptions, environmentOverrides)
    ], runFile, "application/javascript");
  }

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    var sdkDir = _useSdk
        ? Uri.directory(_configuration.buildDirectory).resolve('dart-sdk/')
        : Uri.directory(Repository.dir.toNativePath()).resolve('sdk/');
    var preambleDir = sdkDir.resolve('lib/_internal/js_runtime/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
      ..add(artifact!.filename);
  }
}

class PrecompilerCompilerConfiguration extends CompilerConfiguration
    with VMKernelCompilerMixin {
  bool get _isAndroid => _configuration.system == System.android;

  bool get _isArm => _configuration.architecture == Architecture.arm;

  bool get _isSimArm => _configuration.architecture == Architecture.simarm;

  bool get _isSimArm64 =>
      _configuration.architecture == Architecture.simarm64 ||
      _configuration.architecture == Architecture.simarm64c;

  bool get _isArmX64 => _configuration.architecture == Architecture.arm_x64;

  bool get _isArm64 =>
      _configuration.architecture == Architecture.arm64 ||
      _configuration.architecture == Architecture.arm64c;

  bool get _isX64 =>
      _configuration.architecture == Architecture.x64 ||
      _configuration.architecture == Architecture.x64c;

  bool get _isIA32 => _configuration.architecture == Architecture.ia32;

  bool get _isRiscv32 => _configuration.architecture == Architecture.riscv32;

  bool get _isSimRiscv32 =>
      _configuration.architecture == Architecture.simriscv32;

  bool get _isRiscv64 => _configuration.architecture == Architecture.riscv64;

  bool get _isSimRiscv64 =>
      _configuration.architecture == Architecture.simriscv64;

  @override
  bool get _isAot => true;

  PrecompilerCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  int get timeoutMultiplier {
    var multiplier = 2;
    if (_isDebug) multiplier *= 4;
    if (_enableAsserts) multiplier *= 2;
    return multiplier;
  }

  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    var commands = <Command>[];

    commands.add(computeCompileToKernelCommand(
        tempDir, arguments, environmentOverrides));

    commands.add(
        computeGenSnapshotCommand(tempDir, arguments, environmentOverrides));

    if (arguments.contains('--print-flow-graph-optimized')) {
      commands.add(
          computeILCompareCommand(tempDir, arguments, environmentOverrides));
    }

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

    return CommandArtifact(commands, tempDir, 'application/dart-precompiled');
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

  Command computeGenSnapshotCommand(String tempDir, List<String> arguments,
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
      } else if (_isRiscv32 && _configuration.useQemu) {
        exec = "$buildDir/x86/gen_snapshot";
      } else if (_isRiscv64 && _configuration.useQemu) {
        exec = "$buildDir/x64/gen_snapshot";
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
      if (_isAndroid && (_isArm || _isArmX64)) ...[
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
      ],
      if (_configuration.isMinified) '--obfuscate',
      ..._nnbdModeArgument(_configuration),
      // The SIMARM precompiler assumes support for integer division, but the
      // Qemu arm cpus do not support integer division.
      if (_configuration.useQemu) '--no-use-integer-division',
      if (arguments.contains('--print-flow-graph-optimized'))
        '--redirect-isolate-log-to=$tempDir/out.il',
      if (arguments.contains('--print-flow-graph-optimized') &&
          (_configuration.isMinified || arguments.contains('--obfuscate')))
        '--save-obfuscation_map=$tempDir/renames.json',
      ..._replaceDartFiles(arguments, tempKernelFile(tempDir)),
    ];

    var command = CompilationCommand('precompiler', tempDir,
        bootstrapDependencies(), exec!, args, environmentOverrides,
        alwaysCompile: !_useSdk);
    if (_configuration.rr) {
      return RRCommand(command);
    }
    return command;
  }

  Command computeILCompareCommand(String tempDir, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var pkgVmDir = Platform.script.resolve('../../../pkg/vm').toFilePath();
    var compareIl = '$pkgVmDir/tool/compare_il$shellScriptExtension';

    var args = [
      arguments.firstWhere((arg) => arg.endsWith('_il_test.dart')),
      '$tempDir/out.il',
      if (arguments.contains('--obfuscate')) '$tempDir/renames.json',
    ];

    return CompilationCommand('compare_il', tempDir, bootstrapDependencies(),
        compareIl, args, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  static const String ndkPath = "third_party/android_tools/ndk";
  String? get abiTriple => _isArm || _isArmX64
      ? "arm-linux-androideabi"
      : _isArm64
          ? "aarch64-linux-android"
          : null;
  String? get host => Platform.isLinux
      ? "linux"
      : Platform.isMacOS
          ? "darwin"
          : null;

  Command computeAssembleCommand(String tempDir, List arguments,
      Map<String, String> environmentOverrides) {
    late String cc;
    String? shared;
    var ldFlags = <String>[];
    List<String>? target;
    if (_isAndroid) {
      cc = "$ndkPath/toolchains/$abiTriple-4.9/prebuilt/"
          "$host-x86_64/bin/$abiTriple-gcc";
      shared = '-shared';
      ldFlags.add('-Wl,--no-undefined');
    } else if (Platform.isLinux) {
      if (_isSimArm || (_isArm && _configuration.useQemu)) {
        cc = 'arm-linux-gnueabihf-gcc';
      } else if (_isSimArm64 || (_isArm64 && _configuration.useQemu)) {
        cc = 'aarch64-linux-gnu-gcc';
      } else if (_isSimRiscv32 || (_isRiscv32 && _configuration.useQemu)) {
        cc = 'riscv32-linux-gnu-gcc';
      } else if (_isSimRiscv64 || (_isRiscv64 && _configuration.useQemu)) {
        cc = 'riscv64-linux-gnu-gcc';
      } else {
        cc = 'gcc';
      }
      shared = '-shared';
      ldFlags.add('-Wl,--no-undefined');
    } else if (Platform.isMacOS) {
      cc = 'clang';
      shared = '-dynamiclib';
      ldFlags.add('-Wl,-undefined,error');
      // Tell Mac linker to give up generating eh_frame from dwarf.
      ldFlags.add('-Wl,-no_compact_unwind');
      switch (_configuration.architecture) {
        case Architecture.ia32:
          target = ['-arch', 'i386'];
          break;
        case Architecture.x64:
        case Architecture.x64c:
        case Architecture.simx64:
        case Architecture.simx64c:
          target = ['-arch', 'x86_64'];
          break;
        case Architecture.simarm:
        case Architecture.arm:
        case Architecture.arm_x64:
          target = ['-arch', 'armv7'];
          break;
        case Architecture.simarm64:
        case Architecture.simarm64c:
          target = ['-arch', 'arm64'];
          break;
        case Architecture.riscv32:
        case Architecture.simriscv32:
          target = ['-arch', 'riscv32'];
          break;
        case Architecture.riscv64:
        case Architecture.simriscv64:
          target = ['-arch', 'riscv64'];
          break;
      }
    } else {
      throw "Platform not supported: ${Platform.operatingSystem}";
    }

    var args = [
      if (target != null) ...target,
      ...ldFlags,
      shared,
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

  @override
  List<String> computeCompilerArguments(
      TestFile testFile, List<String> vmOptions, List<String> args) {
    return [
      if (testFile.isVmIntermediateLanguageTest) ...[
        '--print-flow-graph-optimized',
        '--print-flow-graph-as-json',
        '--print-flow-graph-filter=@pragma',
      ],
      if (_enableAsserts) '--enable_asserts',
      ...filterVmOptions(vmOptions),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ...args
    ];
  }

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    var dir = artifact!.filename;
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

  @override
  int get timeoutMultiplier {
    var multiplier = 1;
    if (_isDebug) multiplier *= 2;
    if (_enableAsserts) multiplier *= 2;
    return multiplier;
  }

  @override
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
    var executable = "${_configuration.buildDirectory}/dart";
    arguments = [
      "--snapshot=$snapshot",
      "--snapshot-kind=app-jit",
      ...arguments
    ];
    if (_configuration.useQemu) {
      final config = QemuConfig.all[_configuration.architecture]!;
      arguments.insert(0, executable);
      arguments.insertAll(0, config.arguments);
      executable = config.executable;
    }
    return CompilationCommand('app_jit', tempDir, bootstrapDependencies(),
        executable, arguments, environmentOverrides,
        alwaysCompile: !_useSdk);
  }

  @override
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

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
    return [
      if (_enableAsserts) '--enable_asserts',
      ...vmOptions,
      ..._nnbdModeArgument(_configuration),
      ...testFile.sharedOptions,
      ..._configuration.sharedOptions,
      ..._experimentsArgument(_configuration, testFile),
      ..._replaceDartFiles(originalArguments, artifact!.filename),
      ...testFile.dartOptions
    ];
  }
}

/// Configuration for dartanalyzer.
class AnalyzerCompilerConfiguration extends CompilerConfiguration {
  AnalyzerCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  int get timeoutMultiplier => 4;

  @override
  String computeCompilerPath() {
    var prefix = 'sdk/bin';
    if (_isHostChecked) {
      throw "--host-checked cannot be used for dartanalyzer";
    }
    if (_useSdk) {
      prefix = '${_configuration.buildDirectory}/dart-sdk/bin';
    }
    return '$prefix/dart$executableExtension';
  }

  String computeAnalyzerCliPath() {
    if (_useSdk) {
      // This is a non-standard use of _useSdk, as dartanalyzer is not part
      // of the SDK anymore, but there is no way to specify "use generated
      // snapshot" directly.
      return '${_configuration.buildDirectory}/gen/dartanalyzer.dart.snapshot';
    }
    return 'pkg/analyzer_cli/bin/analyzer.dart';
  }

  late final String compilerPath = computeCompilerPath();

  // TODO(jcollins-g): move most of this into analyzer.dart defaults once it
  // becomes an unpublished utility.
  late final List<String> analyzerCliCommonArgs = [
    ...computeDartOptions(),
    computeAnalyzerCliPath(),
    ...computeDartAnalyzerOptions(),
  ];

  /// [arguments].last must be the Dart source file.
  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact([
      AnalysisCommand(
          compilerPath, arguments, analyzerCliCommonArgs, environmentOverrides)
    ], arguments.last, 'application/vnd.dart');
  }

  /// Arguments passed to the Dart VM.
  List<String> computeDartOptions() {
    return _useSdk ? [] : ['--packages=.dart_tool/package_config.json'];
  }

  /// Arguments passed to the snapshot or CLI dart file.
  List<String> computeDartAnalyzerOptions() {
    return [
      // analyzer.dart requires normalized path for dart-sdk.
      if (!_useSdk) ...[
        '--use-analysis-driver-memory-byte-store',
        '--dart-sdk=${Repository.dir.absolute.join(Path('sdk'))}'
      ],
      if (_configuration.useAnalyzerCfe) '--use-cfe',
      if (_configuration.useAnalyzerFastaParser) '--use-fasta-parser',
    ];
  }
}

/// Configuration for spec_parser.
class SpecParserCompilerConfiguration extends CompilerConfiguration {
  SpecParserCompilerConfiguration(TestConfiguration configuration)
      : super._subclass(configuration);

  @override
  String computeCompilerPath() => 'tools/spec_parse.py';

  @override
  CommandArtifact computeCompilationArtifact(String tempDir,
      List<String> arguments, Map<String, String> environmentOverrides) {
    // Since this is not a real compilation, no artifacts are produced.
    return CommandArtifact([
      SpecParseCommand(computeCompilerPath(), arguments, environmentOverrides)
    ], arguments.singleWhere((argument) => argument.endsWith('.dart')),
        'application/vnd.dart');
  }

  @override
  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      TestFile testFile,
      List<String> vmOptions,
      List<String> originalArguments,
      CommandArtifact? artifact) {
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

    var kernelBinariesFolder = _configuration.buildDirectory;
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
          name.startsWith('--define') ||
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
      '--skip-platform-verification',
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
      CommandArtifact? artifact) {
    if (runtimeConfiguration is! NoneRuntimeConfiguration) {
      throw "--compiler=fasta only supports --runtime=none";
    }

    return [];
  }
}
