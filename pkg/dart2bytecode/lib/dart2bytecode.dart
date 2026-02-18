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
        CfeDiagnosticMessage,
        Verbosity,
        parseExperimentalArguments,
        parseExperimentalFlags,
        resolveInputUri;
import 'package:kernel/ast.dart' show Component, Library, Source;
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
      help: 'Path to vm_platform.dill file', defaultsTo: null)
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
  ..addOption('validate',
      help:
          'Validate dynamic module against specified dynamic interface YAML file',
      defaultsTo: null)
  ..addOption('verbosity',
      help: 'Sets the verbosity level used for filtering messages during '
          'compilation.',
      defaultsTo: Verbosity.defaultValue)
  ..addOption('prefix-library-uris',
      help: 'Slash-separated prefix to add to all library uris',
      defaultsTo: '');

final String _usage = '''
Usage: dart2bytecode --platform vm_platform.dill [--import-dill host_app.dill] [--validate dynamic_interface.yaml] [options] input.dart
Compiles Dart sources to Dart bytecode.

Options:
${_argParser.usage}
''';

Future<void> main(List<String> arguments) async {
  io.exitCode = await runCompilerWithCommandLineArguments(arguments);
}

/// Run bytecode compiler tool with given [arguments]
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

  final String? importDill = options['import-dill'];
  final String? validateDynamicInterface = options['validate'];
  final String messageVerbosity = options['verbosity'];
  final String cfeInvocationModes = options['invocation-modes'];
  final bool trackWidgetCreation = options['track-widget-creation'];
  final List<String>? bytecodeGeneratorOptions = options['bytecode-options'];
  final String libraryUrisPrefix = options['prefix-library-uris']!;

  return await runCompilerWithOptions(
    input: input,
    platformKernel: platformKernel,
    outputFileName: outputFileName,
    targetName: targetName,
    packages: packages,
    importDill: importDill,
    validateDynamicInterface: validateDynamicInterface,
    enableAsserts: enableAsserts,
    experimentalFlags: experimentalFlags,
    environmentDefines: environmentDefines,
    fileSystemScheme: fileSystemScheme,
    fileSystemRoots: fileSystemRoots,
    messageVerbosity: messageVerbosity,
    cfeInvocationModes: cfeInvocationModes,
    trackWidgetCreation: trackWidgetCreation,
    bytecodeGeneratorOptions: bytecodeGeneratorOptions,
    depfile: depfile,
    depfileTarget: depfileTarget,
    libraryUrisPrefix: libraryUrisPrefix,
  );
}

/// Run bytecode compiler tool with given options
/// and return exit code (0 on success, non-zero on failure).
Future<int> runCompilerWithOptions({
  required String input,
  required String platformKernel,
  required String outputFileName,
  required String targetName,
  String? packages,
  String? importDill,
  String? validateDynamicInterface,
  bool enableAsserts = false,
  List<String>? experimentalFlags,
  Map<String, String> environmentDefines = const {},
  String? fileSystemScheme,
  List<String>? fileSystemRoots,
  String messageVerbosity = Verbosity.defaultValue,
  void Function(String) printMessage = print,
  String cfeInvocationModes = '',
  bool trackWidgetCreation = false,
  List<String>? bytecodeGeneratorOptions,
  String? depfile,
  String? depfileTarget,
  required String libraryUrisPrefix,
}) async {
  final fileSystem =
      createFrontEndFileSystem(fileSystemScheme, fileSystemRoots);

  final Uri? packagesUri = packages != null ? resolveInputUri(packages) : null;

  final platformKernelUri = Uri.base.resolveUri(new Uri.file(platformKernel));

  final List<Uri> additionalDills = <Uri>[];
  if (importDill != null) {
    additionalDills.add(Uri.base.resolveUri(new Uri.file(importDill)));
  }

  final Uri? dynamicInterfaceSpecificationUri =
      (validateDynamicInterface != null)
          ? resolveInputUri(validateDynamicInterface)
          : null;

  final verbosity = Verbosity.parseArgument(messageVerbosity);
  final errorPrinter = ErrorPrinter(verbosity, println: printMessage);
  final errorDetector = ErrorDetector(previousErrorHandler: errorPrinter.call);

  Uri mainUri = resolveInputUri(input);
  if (packagesUri != null) {
    mainUri = await convertToPackageUri(fileSystem, mainUri, packagesUri);
  }

  final BytecodeOptions bytecodeOptions =
      BytecodeOptions(enableAsserts: enableAsserts)
        ..parseCommandLineFlags(bytecodeGeneratorOptions);

  final CompilerOptions compilerOptions = CompilerOptions()
    ..sdkSummary = platformKernelUri
    ..fileSystem = fileSystem
    ..additionalDills = additionalDills
    ..packagesFileUri = packagesUri
    ..dynamicInterfaceSpecificationUri = dynamicInterfaceSpecificationUri
    ..explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(experimentalFlags),
        onError: printMessage)
    ..onDiagnostic = (CfeDiagnosticMessage m) {
      errorDetector(m);
    }
    ..embedSourceText = bytecodeOptions.embedSourceText
    ..invocationModes = InvocationMode.parseArguments(cfeInvocationModes)
    ..verbosity = verbosity
    ..target = createFrontEndTarget(targetName,
        trackWidgetCreation: trackWidgetCreation,
        supportMirrors: false,
        isClosureContextLoweringEnabled:
            bytecodeOptions.isClosureContextLoweringEnabled);

  if (compilerOptions.target == null) {
    printMessage('Failed to create front-end target $targetName.');
    return badUsageExitCode;
  }

  final results = await compileToKernel(KernelCompilationArguments(
      source: mainUri,
      options: compilerOptions,
      requireMain: false,
      includePlatform: false,
      environmentDefines: Map.of(environmentDefines),
      enableAsserts: enableAsserts));

  errorPrinter.printCompilationMessages();

  Component? component = results.component;
  if (errorDetector.hasCompilationErrors || component == null) {
    return compileTimeErrorExitCode;
  }
  component =
      prefixLibraryUris(component, results.loadedLibraries, libraryUrisPrefix);
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
      target: compilerOptions.target!,
      extraLoadedLibraries: results.loadedLibraries);
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

Component prefixLibraryUris(Component component, Set<Library> loadedLibraries,
    String libraryUrisPrefix) {
  if (libraryUrisPrefix.isEmpty) {
    return component;
  }
  final prefixSegments = libraryUrisPrefix.split('/');
  final importUriReplacements = <Uri, Uri>{};

  for (final lib in component.libraries) {
    // Skip libraries that come from the host app or the SDK.
    if (loadedLibraries.contains(lib)) {
      continue;
    }
    final newImportUri = prefixUri(lib.importUri, prefixSegments);
    importUriReplacements[lib.importUri] = newImportUri;
    lib.importUri = newImportUri;
  }

  // Update import uris in sources.
  final allSourceFileUris = component.uriToSource.keys.toSet();
  for (final fileUri in allSourceFileUris) {
    final source = component.uriToSource[fileUri]!;
    final importUriReplacement = importUriReplacements[source.importUri];
    if (importUriReplacement == null) {
      continue;
    }

    // Rewrite the source with the new import URI.
    component.uriToSource[fileUri] = Source(
      source.lineStarts,
      source.source,
      importUriReplacement,
      source.fileUri,
    )
      ..cachedText = source.cachedText
      ..constantCoverageConstructors = source.constantCoverageConstructors;
  }

  return component;
}

Uri prefixUri(Uri uri, List<String> prefixSegments) {
  if (uri.scheme == 'package') {
    // For package URIs, the first segment is dot-separated package path, so
    // we prepend the prefix to the first segment.
    final pathSegments = uri.pathSegments.toList();
    pathSegments[0] = [...prefixSegments, pathSegments.first].join('.');
    return uri.replace(pathSegments: pathSegments);
  }

  // For other schemes, we just prepend the prefix to the path segments.
  return uri.replace(pathSegments: prefixSegments.followedBy(uri.pathSegments));
}
