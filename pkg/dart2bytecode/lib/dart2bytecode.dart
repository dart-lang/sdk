// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show exitCode, File, IOSink;

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        InvocationMode,
        DiagnosticMessage,
        Verbosity,
        parseExperimentalArguments,
        parseExperimentalFlags,
        resolveInputUri;
import 'package:kernel/ast.dart' show Component;
import 'package:vm/kernel_front_end.dart'
    show
        badUsageExitCode,
        compileTimeErrorExitCode,
        compileToKernel,
        convertToPackageUri,
        createFrontEndFileSystem,
        createFrontEndTarget,
        ErrorDetector,
        ErrorPrinter,
        KernelCompilationArguments,
        parseCommandLineDefines,
        successExitCode,
        writeDepfile;

import 'bytecode_serialization.dart' show BytecodeSizeStatistics;
import 'bytecode_generator.dart' show generateBytecode;
import 'options.dart' show BytecodeOptions;

final ArgParser _argParser = ArgParser(allowTrailingOptions: true)
  ..addOption('platform',
      help: 'Path to vm_platform_strong.dill file', defaultsTo: null)
  ..addOption('packages',
      help: 'Path to .dart_tool/package_config.json file', defaultsTo: null)
  ..addOption('output',
      abbr: 'o', help: 'Path to resulting bytecode file', defaultsTo: null)
  ..addOption('depfile', help: 'Path to output Ninja depfile')
  ..addOption(
    'depfile-target',
    help: 'Override the target in the generated depfile',
    hide: true,
  )
  ..addMultiOption('filesystem-root',
      help: 'A base path for the multi-root virtual file system.'
          ' If multi-root file system is used, the input script and .dart_tool/package_config.json file should be specified using URI.')
  ..addOption('filesystem-scheme',
      help: 'The URI scheme for the multi-root virtual filesystem.')
  ..addOption('target',
      help: 'Target model that determines what core libraries are available',
      allowed: <String>['vm', 'flutter', 'flutter_runner', 'dart_runner'],
      defaultsTo: 'vm')
  ..addMultiOption('define',
      abbr: 'D',
      help: 'The values for the environment constants (e.g. -Dkey=value).')
  ..addOption('import-dill',
      help: 'Import libraries from existing dill file', defaultsTo: null)
  ..addFlag('enable-asserts',
      help: 'Whether asserts will be enabled.', defaultsTo: false)
  ..addMultiOption('bytecode-options',
      help: 'Specify options for bytecode generation:',
      valueHelp: 'opt1,opt2,...',
      allowed: BytecodeOptions.commandLineFlags.keys,
      allowedHelp: BytecodeOptions.commandLineFlags)
  ..addMultiOption('enable-experiment',
      help: 'Comma separated list of experimental features to enable.')
  ..addFlag('help',
      abbr: 'h', negatable: false, help: 'Print this help message.')
  ..addFlag('track-widget-creation',
      help: 'Run a kernel transformer to track creation locations for widgets.',
      defaultsTo: false)
  ..addOption('invocation-modes',
      help: 'Provides information to the front end about how it is invoked.',
      defaultsTo: '')
  ..addOption('verbosity',
      help: 'Sets the verbosity level used for filtering messages during '
          'compilation.',
      defaultsTo: Verbosity.defaultValue);

final String _usage = '''
Usage: dart2bytecode --platform vm_platform_strong.dill [--import-dill host_app.dill] [options] input.dart
Compiles Dart sources to Dart bytecode.

Options:
${_argParser.usage}
''';

Future<void> main(List<String> arguments) async {
  io.exitCode = await runCompiler(_argParser.parse(arguments));
}

/// Run bytecode compiler tool with given [options]
/// and return exit code.
Future<int> runCompiler(ArgResults options) async {
  final String? platformKernel = options['platform'];

  if (options['help']) {
    print(_usage);
    return successExitCode;
  }

  final String? input = options.rest.singleOrNull;
  if (input == null || platformKernel == null) {
    print(_usage);
    return badUsageExitCode;
  }

  final String outputFileName = options['output'] ?? "$input.bytecode";
  final String? packages = options['packages'];
  final String targetName = options['target'];
  final String? fileSystemScheme = options['filesystem-scheme'];
  final String? depfile = options['depfile'];
  final String? depfileTarget = options['depfile-target'];
  final List<String>? fileSystemRoots = options['filesystem-root'];
  final bool enableAsserts = options['enable-asserts'];
  final List<String>? experimentalFlags = options['enable-experiment'];
  final Map<String, String> environmentDefines = {};

  if (!parseCommandLineDefines(options['define'], environmentDefines, _usage)) {
    return badUsageExitCode;
  }

  final fileSystem =
      createFrontEndFileSystem(fileSystemScheme, fileSystemRoots);

  final Uri? packagesUri = packages != null ? resolveInputUri(packages) : null;

  final platformKernelUri = Uri.base.resolveUri(new Uri.file(platformKernel));

  final List<Uri> additionalDills = <Uri>[];
  final String? importDill = options['import-dill'];
  if (importDill != null) {
    additionalDills.add(Uri.base.resolveUri(new Uri.file(importDill)));
  }

  final verbosity = Verbosity.parseArgument(options['verbosity']);
  final errorPrinter = ErrorPrinter(verbosity);
  final errorDetector = ErrorDetector(previousErrorHandler: errorPrinter.call);

  Uri mainUri = resolveInputUri(input);
  if (packagesUri != null) {
    mainUri = await convertToPackageUri(fileSystem, mainUri, packagesUri);
  }

  final CompilerOptions compilerOptions = CompilerOptions()
    ..sdkSummary = platformKernelUri
    ..fileSystem = fileSystem
    ..additionalDills = additionalDills
    ..packagesFileUri = packagesUri
    ..explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(experimentalFlags),
        onError: print)
    ..onDiagnostic = (DiagnosticMessage m) {
      errorDetector(m);
    }
    ..embedSourceText = false
    ..invocationModes =
        InvocationMode.parseArguments(options['invocation-modes'])
    ..verbosity = verbosity;

  compilerOptions.target = createFrontEndTarget(targetName,
      trackWidgetCreation: options['track-widget-creation'],
      supportMirrors: false);
  if (compilerOptions.target == null) {
    print('Failed to create front-end target $targetName.');
    return badUsageExitCode;
  }

  final results = await compileToKernel(KernelCompilationArguments(
      source: mainUri,
      options: compilerOptions,
      includePlatform: false,
      environmentDefines: environmentDefines,
      enableAsserts: enableAsserts));

  errorPrinter.printCompilationMessages();

  final Component? component = results.component;
  if (errorDetector.hasCompilationErrors || component == null) {
    return compileTimeErrorExitCode;
  }

  final BytecodeOptions bytecodeOptions =
      BytecodeOptions(enableAsserts: enableAsserts)
        ..parseCommandLineFlags(options['bytecode-options']);

  if (bytecodeOptions.showBytecodeSizeStatistics) {
    BytecodeSizeStatistics.reset();
  }
  final io.IOSink sink = io.File(outputFileName).openWrite();
  generateBytecode(component, sink,
      libraries: component.libraries
          .where((lib) => !results.loadedLibraries.contains(lib))
          .toList(),
      hierarchy: results.classHierarchy!,
      coreTypes: results.coreTypes!,
      options: bytecodeOptions,
      target: compilerOptions.target!);
  await sink.close();
  if (bytecodeOptions.showBytecodeSizeStatistics) {
    BytecodeSizeStatistics.dump();
  }

  if (depfile != null) {
    await writeDepfile(
      fileSystem,
      results.compiledSources!,
      depfileTarget ?? outputFileName,
      depfile,
    );
  }

  return successExitCode;
}
