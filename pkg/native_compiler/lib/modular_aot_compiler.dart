// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show exitCode, File, Platform;

import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:cfg/ir/global_context.dart';
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        InvocationMode,
        CfeDiagnosticMessage,
        Verbosity,
        parseExperimentalArguments,
        parseExperimentalFlags,
        resolveInputUri;
import 'package:kernel/ast.dart' as ast show Component;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:native_compiler/compilation_set.dart';
import 'package:native_compiler/configuration.dart';
import 'package:path/path.dart' as path;
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

final ArgParser _argParser = ArgParser(allowTrailingOptions: true)
  ..addOption(
    'platform',
    help: 'Path to vm_platform.dill file',
    defaultsTo: null,
  )
  ..addOption(
    'packages',
    help: 'Path to .dart_tool/package_config.json file',
    defaultsTo: null,
  )
  ..addOption(
    'output',
    abbr: 'o',
    help: 'Path to resulting snapshot file',
    defaultsTo: null,
  )
  ..addOption('depfile', help: 'Path to output Ninja depfile')
  ..addOption(
    'depfile-target',
    help: 'Override the target in the generated depfile',
    hide: true,
  )
  ..addMultiOption(
    'filesystem-root',
    help:
        'A base path for the multi-root virtual file system.'
        ' If multi-root file system is used, the input script and .dart_tool/package_config.json file should be specified using URI.',
  )
  ..addOption(
    'filesystem-scheme',
    help: 'The URI scheme for the multi-root virtual filesystem.',
  )
  ..addOption(
    'target',
    help: 'Target model that determines what core libraries are available',
    allowed: <String>['vm', 'flutter', 'flutter_runner', 'dart_runner'],
    defaultsTo: 'vm',
  )
  ..addOption(
    'target-arch',
    abbr: 'a',
    help: 'Target CPU architecture.',
    allowed: TargetCPU.allowedNames,
    defaultsTo: TargetCPU.defaultName,
  )
  ..addOption(
    'image-format',
    help: 'Image format of the output snapshot.',
    allowed: ImageFormat.allowedNames,
    defaultsTo: ImageFormat.defaultName,
  )
  ..addMultiOption(
    'define',
    abbr: 'D',
    help: 'The values for the environment constants (e.g. -Dkey=value).',
  )
  ..addOption(
    'import-dill',
    help: 'Import libraries from existing dill file',
    defaultsTo: null,
  )
  ..addFlag(
    'enable-asserts',
    help: 'Whether asserts will be enabled.',
    defaultsTo: false,
  )
  ..addMultiOption(
    'enable-experiment',
    help: 'Comma separated list of experimental features to enable.',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Print this help message.',
  )
  ..addFlag(
    'track-widget-creation',
    help: 'Run a kernel transformer to track creation locations for widgets.',
    defaultsTo: false,
  )
  ..addOption(
    'invocation-modes',
    help: 'Provides information to the front end about how it is invoked.',
    defaultsTo: '',
  )
  ..addOption(
    'verbosity',
    help:
        'Sets the verbosity level used for filtering messages during '
        'compilation.',
    defaultsTo: Verbosity.defaultValue,
  );

final String _usage =
    '''
Usage: modular_aot_compiler --platform vm_platform.dill [--import-dill other.dill] [options] input.dart
Compiles Dart sources to modular snapshot with native code.

Options:
${_argParser.usage}
''';

Future<void> main(List<String> arguments) async {
  io.exitCode = await runCompilerWithCommandLineArguments(arguments);
}

/// Run compiler with given [arguments]
/// and return exit code (0 on success, non-zero on failure).
Future<int> runCompilerWithCommandLineArguments(List<String> arguments) async {
  final ArgResults options = _argParser.parse(arguments);
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

  final String outputFileName =
      options['output'] ?? "$input.$snapshotExtension";
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

  final String? importDill = options['import-dill'];
  final String messageVerbosity = options['verbosity'];
  final String cfeInvocationModes = options['invocation-modes'];
  final bool trackWidgetCreation = options['track-widget-creation'];

  final TargetCPU targetCPU = TargetCPU.fromName(options['target-arch']);
  final ImageFormat imageFormat = ImageFormat.fromName(options['image-format']);

  final fileSystem = createFrontEndFileSystem(
    fileSystemScheme,
    fileSystemRoots,
  );

  final Uri? packagesUri = packages != null ? resolveInputUri(packages) : null;

  final platformKernelUri = Uri.base.resolveUri(new Uri.file(platformKernel));

  final additionalDills = <Uri>[];
  if (importDill != null) {
    additionalDills.add(Uri.base.resolveUri(new Uri.file(importDill)));
  }

  final verbosity = Verbosity.parseArgument(messageVerbosity);
  final errorPrinter = ErrorPrinter(verbosity, println: print);
  final errorDetector = ErrorDetector(previousErrorHandler: errorPrinter.call);

  Uri mainUri = resolveInputUri(input);
  if (packagesUri != null) {
    mainUri = await convertToPackageUri(fileSystem, mainUri, packagesUri);
  }

  final compilerOptions = CompilerOptions()
    ..sdkSummary = platformKernelUri
    ..fileSystem = fileSystem
    ..additionalDills = additionalDills
    ..packagesFileUri = packagesUri
    ..explicitExperimentalFlags = parseExperimentalFlags(
      parseExperimentalArguments(experimentalFlags),
      onError: print,
    )
    ..onDiagnostic = (CfeDiagnosticMessage m) {
      errorDetector(m);
    }
    ..embedSourceText = false
    ..invocationModes = InvocationMode.parseArguments(cfeInvocationModes)
    ..verbosity = verbosity
    ..target = createFrontEndTarget(
      targetName,
      trackWidgetCreation: trackWidgetCreation,
      supportMirrors: false,
      isClosureContextLoweringEnabled: false,
    );

  if (compilerOptions.target == null) {
    print('Failed to create front-end target $targetName.');
    return badUsageExitCode;
  }

  final results = await compileToKernel(
    KernelCompilationArguments(
      source: mainUri,
      options: compilerOptions,
      requireMain: false,
      includePlatform: false,
      environmentDefines: Map.of(environmentDefines),
      enableAsserts: enableAsserts,
    ),
  );

  errorPrinter.printCompilationMessages();

  final ast.Component? component = results.component;
  if (errorDetector.hasCompilationErrors || component == null) {
    return compileTimeErrorExitCode;
  }

  final libraries = component.libraries
      .where((lib) => !results.loadedLibraries.contains(lib))
      .toList();
  final typeEnvironment = TypeEnvironment(
    results.coreTypes!,
    results.classHierarchy!,
  );
  final config = DevelopmentCompilerConfiguration(
    targetCPU,
    imageFormat,
    enableAsserts: enableAsserts,
    outputLibraryName: path.basename(outputFileName),
  );
  final context = GlobalContext(typeEnvironment: typeEnvironment);
  await GlobalContext.withContext(context, () {
    final compilationSet = CompilationSet(libraries, config);
    compilationSet.compileAllFunctions();
    final sink = io.File(outputFileName).openWrite();
    compilationSet.writeSnapshot(sink);
    return sink.close();
  });

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

String snapshotExtension(String name) {
  if (io.Platform.isLinux || io.Platform.isAndroid || io.Platform.isFuchsia) {
    return ".so";
  }
  if (io.Platform.isMacOS) {
    return ".dylib";
  }
  if (io.Platform.isWindows) {
    return ".dll";
  }
  throw 'Platform is not supported';
}
