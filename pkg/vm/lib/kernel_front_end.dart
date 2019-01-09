// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the VM-specific translation of Dart source code to kernel binaries.
library vm.kernel_front_end;

import 'dart:async';
import 'dart:io' show File, IOSink, IOException;

import 'package:args/args.dart' show ArgParser, ArgResults;

import 'package:build_integration/file_system/multi_root.dart'
    show MultiRootFileSystem, MultiRootFileSystemEntity;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerContext,
        CompilerOptions,
        DiagnosticMessage,
        DiagnosticMessageHandler,
        FileSystem,
        FileSystemEntity,
        FileSystemException,
        ProcessedOptions,
        Severity,
        StandardFileSystem,
        getMessageUri,
        kernelForProgram,
        printDiagnosticMessage;

import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/ast.dart'
    show Component, Field, Library, Reference, StaticGet;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/binary/limited_ast_to_binary.dart'
    show LimitedBinaryPrinter;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;
import 'package:kernel/transformations/constants.dart' as constants;
import 'package:kernel/vm/constants_native_effects.dart' as vm_constants;

import 'bytecode/gen_bytecode.dart' show generateBytecode;

import 'constants_error_reporter.dart' show ForwardConstantEvaluationErrors;
import 'target/install.dart' show installAdditionalTargets;
import 'transformations/devirtualization.dart' as devirtualization
    show transformComponent;
import 'transformations/mixin_deduplication.dart' as mixin_deduplication
    show transformComponent;
import 'transformations/no_dynamic_invocations_annotator.dart'
    as no_dynamic_invocations_annotator show transformComponent;
import 'transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;
import 'transformations/obfuscation_prohibitions_annotator.dart'
    as obfuscationProhibitions;
import 'transformations/call_site_annotator.dart' as call_site_annotator;

/// Declare options consumed by [runCompiler].
void declareCompilerOptions(ArgParser args) {
  args.addOption('platform',
      help: 'Path to vm_platform_strong.dill file', defaultsTo: null);
  args.addOption('packages', help: 'Path to .packages file', defaultsTo: null);
  args.addOption('output',
      abbr: 'o', help: 'Path to resulting dill file', defaultsTo: null);
  args.addFlag('aot',
      help:
          'Produce kernel file for AOT compilation (enables global transformations).',
      defaultsTo: false);
  args.addOption('depfile', help: 'Path to output Ninja depfile');
  args.addFlag('link-platform',
      help: 'Include platform into resulting kernel file.', defaultsTo: true);
  args.addFlag('embed-sources',
      help: 'Embed source files in the generated kernel component',
      defaultsTo: true);
  args.addMultiOption('filesystem-root',
      help: 'A base path for the multi-root virtual file system.'
          ' If multi-root file system is used, the input script and .packages file should be specified using URI.');
  args.addOption('filesystem-scheme',
      help: 'The URI scheme for the multi-root virtual filesystem.');
  args.addOption('target',
      help: 'Target model that determines what core libraries are available',
      allowed: <String>['vm', 'flutter', 'flutter_runner', 'dart_runner'],
      defaultsTo: 'vm');
  args.addFlag('tfa',
      help:
          'Enable global type flow analysis and related transformations in AOT mode.',
      defaultsTo: true);
  args.addMultiOption('define',
      abbr: 'D',
      help: 'The values for the environment constants (e.g. -Dkey=value).');
  args.addFlag('enable-asserts',
      help: 'Whether asserts will be enabled.', defaultsTo: false);
  args.addFlag('enable-constant-evaluation',
      help: 'Whether kernel constant evaluation will be enabled.',
      defaultsTo: true);
  args.addFlag('split-output-by-packages',
      help:
          'Split resulting kernel file into multiple files (one per package).',
      defaultsTo: false);
  args.addFlag('gen-bytecode', help: 'Generate bytecode', defaultsTo: false);
  args.addFlag('emit-bytecode-source-positions',
      help: 'Emit source positions in bytecode', defaultsTo: false);
  args.addFlag('drop-ast',
      help: 'Drop AST for members with bytecode', defaultsTo: false);
  args.addFlag('use-future-bytecode-format',
      help: 'Generate bytecode in the bleeding edge format', defaultsTo: false);
}

/// Create ArgParser and populate it with options consumed by [runCompiler].
ArgParser createCompilerArgParser() {
  final ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  declareCompilerOptions(argParser);
  return argParser;
}

const int successExitCode = 0;
const int badUsageExitCode = 1;
const int compileTimeErrorExitCode = 254;

/// Run kernel compiler tool with given [options] and [usage]
/// and return exit code.
Future<int> runCompiler(ArgResults options, String usage) async {
  final String platformKernel = options['platform'];

  if ((options.rest.length != 1) || (platformKernel == null)) {
    print(usage);
    return badUsageExitCode;
  }

  final String input = options.rest.single;
  final String outputFileName = options['output'] ?? "$input.dill";
  final String packages = options['packages'];
  final String targetName = options['target'];
  final String fileSystemScheme = options['filesystem-scheme'];
  final String depfile = options['depfile'];
  final List<String> fileSystemRoots = options['filesystem-root'];
  final bool aot = options['aot'];
  final bool tfa = options['tfa'];
  final bool linkPlatform = options['link-platform'];
  final bool genBytecode = options['gen-bytecode'];
  final bool emitBytecodeSourcePositions =
      options['emit-bytecode-source-positions'];
  final bool dropAST = options['drop-ast'];
  final bool useFutureBytecodeFormat = options['use-future-bytecode-format'];
  final bool enableAsserts = options['enable-asserts'];
  final bool enableConstantEvaluation = options['enable-constant-evaluation'];
  final bool splitOutputByPackages = options['split-output-by-packages'];
  final Map<String, String> environmentDefines = {};

  if (!parseCommandLineDefines(options['define'], environmentDefines, usage)) {
    return badUsageExitCode;
  }

  final target = createFrontEndTarget(targetName);
  if (target == null) {
    print('Failed to create front-end target $targetName.');
    return badUsageExitCode;
  }

  final fileSystem =
      createFrontEndFileSystem(fileSystemScheme, fileSystemRoots);

  final Uri packagesUri = packages != null
      ? convertFileOrUriArgumentToUri(fileSystem, packages)
      : null;

  final platformKernelUri = Uri.base.resolveUri(new Uri.file(platformKernel));
  final List<Uri> linkedDependencies = <Uri>[];
  if (aot || linkPlatform) {
    linkedDependencies.add(platformKernelUri);
  }

  Uri mainUri = convertFileOrUriArgumentToUri(fileSystem, input);
  if (packagesUri != null) {
    mainUri = await convertToPackageUri(fileSystem, mainUri, packagesUri);
  }

  final errorPrinter = new ErrorPrinter();
  final errorDetector = new ErrorDetector(previousErrorHandler: errorPrinter);

  final CompilerOptions compilerOptions = new CompilerOptions()
    ..sdkSummary = platformKernelUri
    ..target = target
    ..fileSystem = fileSystem
    ..linkedDependencies = linkedDependencies
    ..packagesFileUri = packagesUri
    ..onDiagnostic = (DiagnosticMessage m) {
      errorDetector(m);
    }
    ..embedSourceText = options['embed-sources'];

  final component = await compileToKernel(mainUri, compilerOptions,
      aot: aot,
      useGlobalTypeFlowAnalysis: tfa,
      environmentDefines: environmentDefines,
      genBytecode: genBytecode,
      emitBytecodeSourcePositions: emitBytecodeSourcePositions,
      dropAST: dropAST && !splitOutputByPackages,
      useFutureBytecodeFormat: useFutureBytecodeFormat,
      enableAsserts: enableAsserts,
      enableConstantEvaluation: enableConstantEvaluation);

  errorPrinter.printCompilationMessages();

  if (errorDetector.hasCompilationErrors || (component == null)) {
    return compileTimeErrorExitCode;
  }

  final IOSink sink = new File(outputFileName).openWrite();
  final BinaryPrinter printer = new BinaryPrinter(sink);
  printer.writeComponentFile(component);
  await sink.close();

  if (depfile != null) {
    await writeDepfile(fileSystem, component, outputFileName, depfile);
  }

  if (splitOutputByPackages) {
    await writeOutputSplitByPackages(
      mainUri,
      compilerOptions,
      component,
      outputFileName,
      environmentDefines: environmentDefines,
      genBytecode: genBytecode,
      emitBytecodeSourcePositions: emitBytecodeSourcePositions,
      dropAST: dropAST,
    );
  }

  return successExitCode;
}

/// Generates a kernel representation of the program whose main library is in
/// the given [source]. Intended for whole program (non-modular) compilation.
///
/// VM-specific replacement of [kernelForProgram].
///
Future<Component> compileToKernel(Uri source, CompilerOptions options,
    {bool aot: false,
    bool useGlobalTypeFlowAnalysis: false,
    Map<String, String> environmentDefines,
    bool genBytecode: false,
    bool emitBytecodeSourcePositions: false,
    bool dropAST: false,
    bool useFutureBytecodeFormat: false,
    bool enableAsserts: false,
    bool enableConstantEvaluation: true}) async {
  // Replace error handler to detect if there are compilation errors.
  final errorDetector =
      new ErrorDetector(previousErrorHandler: options.onDiagnostic);
  options.onDiagnostic = errorDetector;

  final component = await kernelForProgram(source, options);

  // If we don't default back to the current VM we'll add environment defines
  // for the core libraries.
  if (component != null && environmentDefines != null) {
    if (environmentDefines['dart.vm.product'] == 'true') {
      environmentDefines['dart.developer.causal_async_stacks'] = 'false';
    }
    environmentDefines['dart.isVM'] = 'true';
    for (final library in component.libraries) {
      if (library.importUri.scheme == 'dart') {
        final path = library.importUri.path;
        if (!path.startsWith('_')) {
          environmentDefines['dart.library.${path}'] = 'true';
        }
      }
    }
  }

  // Run global transformations only if component is correct.
  if (aot && component != null) {
    await _runGlobalTransformations(
        source,
        options,
        component,
        useGlobalTypeFlowAnalysis,
        environmentDefines,
        enableAsserts,
        enableConstantEvaluation,
        errorDetector);
  }

  if (genBytecode && !errorDetector.hasCompilationErrors && component != null) {
    await runWithFrontEndCompilerContext(source, options, component, () {
      generateBytecode(component,
          dropAST: dropAST,
          emitSourcePositions: emitBytecodeSourcePositions,
          useFutureBytecodeFormat: useFutureBytecodeFormat,
          environmentDefines: environmentDefines);
    });
  }

  // Restore error handler (in case 'options' are reused).
  options.onDiagnostic = errorDetector.previousErrorHandler;

  return component;
}

Future _runGlobalTransformations(
    Uri source,
    CompilerOptions compilerOptions,
    Component component,
    bool useGlobalTypeFlowAnalysis,
    Map<String, String> environmentDefines,
    bool enableAsserts,
    bool enableConstantEvaluation,
    ErrorDetector errorDetector) async {
  if (errorDetector.hasCompilationErrors) return;

  final coreTypes = new CoreTypes(component);
  _patchVmConstants(coreTypes);

  // TODO(alexmarkov, dmitryas): Consider doing canonicalization of identical
  // mixin applications when creating mixin applications in frontend,
  // so all backends (and all transformation passes from the very beginning)
  // can benefit from mixin de-duplication.
  // At least, in addition to VM/AOT case we should run this transformation
  // when building a platform dill file for VM/JIT case.
  mixin_deduplication.transformComponent(component);

  if (enableConstantEvaluation) {
    await _performConstantEvaluation(source, compilerOptions, component,
        coreTypes, environmentDefines, enableAsserts);

    if (errorDetector.hasCompilationErrors) return;
  }

  if (useGlobalTypeFlowAnalysis) {
    globalTypeFlow.transformComponent(
        compilerOptions.target, coreTypes, component);
  } else {
    devirtualization.transformComponent(coreTypes, component);
    no_dynamic_invocations_annotator.transformComponent(component);
  }

  // TODO(35069): avoid recomputing CSA by reading it from the platform files.
  void ignoreAmbiguousSupertypes(cls, a, b) {}
  final hierarchy = new ClassHierarchy(component,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  call_site_annotator.transformLibraries(
      component, component.libraries, coreTypes, hierarchy);

  // We don't know yet whether gen_snapshot will want to do obfuscation, but if
  // it does it will need the obfuscation prohibitions.
  obfuscationProhibitions.transformComponent(component, coreTypes);
}

/// Runs given [action] with [CompilerContext]. This is needed to
/// be able to report compile-time errors.
Future<T> runWithFrontEndCompilerContext<T>(Uri source,
    CompilerOptions compilerOptions, Component component, T action()) async {
  final processedOptions =
      new ProcessedOptions(options: compilerOptions, inputs: [source]);

  // Run within the context, so we have uri source tokens...
  return await CompilerContext.runWithOptions(processedOptions,
      (CompilerContext context) async {
    // To make the fileUri/fileOffset -> line/column mapping, we need to
    // pre-fill the map.
    context.uriToSource.addAll(component.uriToSource);

    return action();
  });
}

Future _performConstantEvaluation(
    Uri source,
    CompilerOptions compilerOptions,
    Component component,
    CoreTypes coreTypes,
    Map<String, String> environmentDefines,
    bool enableAsserts) async {
  final vmConstants =
      new vm_constants.VmConstantsBackend(environmentDefines, coreTypes);

  await runWithFrontEndCompilerContext(source, compilerOptions, component, () {
    final hierarchy = new ClassHierarchy(component);
    final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);

    // TFA will remove constants fields which are unused (and respects the
    // vm/embedder entrypoints).
    constants.transformComponent(component, vmConstants,
        keepFields: true,
        evaluateAnnotations: true,
        enableAsserts: enableAsserts,
        errorReporter: new ForwardConstantEvaluationErrors(typeEnvironment));
  });
}

void _patchVmConstants(CoreTypes coreTypes) {
  // Fix Endian.host to be a const field equal to Endial.little instead of
  // a final field. VM does not support big-endian architectures at the
  // moment.
  // Can't use normal patching process for this because CFE does not
  // support patching fields.
  // See http://dartbug.com/32836 for the background.
  final Field host =
      coreTypes.index.getMember('dart:typed_data', 'Endian', 'host');
  host.isConst = true;
  host.initializer = new StaticGet(
      coreTypes.index.getMember('dart:typed_data', 'Endian', 'little'))
    ..parent = host;
}

class ErrorDetector {
  final DiagnosticMessageHandler previousErrorHandler;
  bool hasCompilationErrors = false;

  ErrorDetector({this.previousErrorHandler});

  void call(DiagnosticMessage message) {
    if (message.severity == Severity.error) {
      hasCompilationErrors = true;
    }

    previousErrorHandler?.call(message);
  }
}

class ErrorPrinter {
  final DiagnosticMessageHandler previousErrorHandler;
  final compilationMessages = <Uri, List<DiagnosticMessage>>{};

  ErrorPrinter({this.previousErrorHandler});

  void call(DiagnosticMessage message) {
    final sourceUri = getMessageUri(message);
    (compilationMessages[sourceUri] ??= <DiagnosticMessage>[]).add(message);
    previousErrorHandler?.call(message);
  }

  void printCompilationMessages() {
    final sortedUris = compilationMessages.keys.toList()
      ..sort((a, b) => '$a'.compareTo('$b'));
    for (final Uri sourceUri in sortedUris) {
      for (final DiagnosticMessage message in compilationMessages[sourceUri]) {
        printDiagnosticMessage(message, print);
      }
    }
  }
}

bool parseCommandLineDefines(
    List<String> dFlags, Map<String, String> environmentDefines, String usage) {
  for (final String dflag in dFlags) {
    final equalsSignIndex = dflag.indexOf('=');
    if (equalsSignIndex < 0) {
      // Ignored.
    } else if (equalsSignIndex > 0) {
      final key = dflag.substring(0, equalsSignIndex);
      final value = dflag.substring(equalsSignIndex + 1);
      environmentDefines[key] = value;
    } else {
      print('The environment constant options must have a key (was: "$dflag")');
      print(usage);
      return false;
    }
  }
  return true;
}

/// Create front-end target with given name.
Target createFrontEndTarget(String targetName) {
  // Make sure VM-specific targets are available.
  installAdditionalTargets();

  final TargetFlags targetFlags = new TargetFlags();
  return getTarget(targetName, targetFlags);
}

/// Create a front-end file system.
/// If requested, create a virtual mutli-root file system.
FileSystem createFrontEndFileSystem(
    String multiRootFileSystemScheme, List<String> multiRootFileSystemRoots) {
  FileSystem fileSystem = StandardFileSystem.instance;
  if (multiRootFileSystemRoots != null &&
      multiRootFileSystemRoots.isNotEmpty &&
      multiRootFileSystemScheme != null) {
    final rootUris = <Uri>[];
    for (String root in multiRootFileSystemRoots) {
      rootUris.add(Uri.base.resolveUri(new Uri.file(root)));
    }
    fileSystem = new MultiRootFileSystem(
        multiRootFileSystemScheme, rootUris, fileSystem);
  }
  return fileSystem;
}

/// Convert command line argument [input] which is a file or URI to an
/// absolute URI.
///
/// If virtual multi-root file system is used, or [input] can be parsed to a
/// URI with 'package' scheme, then [input] is interpreted as URI.
/// Otherwise [input] is interpreted as a file path.
Uri convertFileOrUriArgumentToUri(FileSystem fileSystem, String input) {
  if (input == null) {
    return null;
  }
  // If using virtual multi-root file system, input source argument should be
  // specified as URI.
  if (fileSystem is MultiRootFileSystem) {
    return Uri.base.resolve(input);
  }
  try {
    Uri uri = Uri.parse(input);
    if (uri.scheme == 'package') {
      return uri;
    }
  } on FormatException {
    // Ignore, treat input argument as file path.
  }
  return Uri.base.resolveUri(new Uri.file(input));
}

/// Convert a URI which may use virtual file system schema to a real file URI.
Future<Uri> asFileUri(FileSystem fileSystem, Uri uri) async {
  FileSystemEntity fse = fileSystem.entityForUri(uri);
  if (fse is MultiRootFileSystemEntity) {
    fse = await (fse as MultiRootFileSystemEntity).delegate;
  }
  return fse.uri;
}

/// Convert URI to a package URI if it is inside one of the packages.
Future<Uri> convertToPackageUri(
    FileSystem fileSystem, Uri uri, Uri packagesUri) async {
  // Convert virtual URI to a real file URI.
  String uriString = (await asFileUri(fileSystem, uri)).toString();
  List<String> packages;
  try {
    packages =
        await new File((await asFileUri(fileSystem, packagesUri)).toFilePath())
            .readAsLines();
  } on IOException {
    // Can't read packages file - silently give up.
    return uri;
  }
  // file:///a/b/x/y/main.dart -> package:x.y/main.dart
  for (var line in packages) {
    final colon = line.indexOf(':');
    if (colon == -1) {
      continue;
    }
    final packageName = line.substring(0, colon);
    String packagePath;
    try {
      packagePath = (await asFileUri(
              fileSystem, packagesUri.resolve(line.substring(colon + 1))))
          .toString();
    } on FileSystemException {
      // Can't resolve package path.
      continue;
    }
    if (uriString.startsWith(packagePath)) {
      return Uri.parse(
          'package:$packageName/${uriString.substring(packagePath.length)}');
    }
  }
  return uri;
}

/// Write a separate kernel binary for each package. The name of the
/// output kernel binary is '[outputFileName]-$package.dilp'.
/// The list of package names is written into a file '[outputFileName]-packages'.
///
/// Generates bytecode for each package if requested.
Future writeOutputSplitByPackages(
  Uri source,
  CompilerOptions compilerOptions,
  Component component,
  String outputFileName, {
  Map<String, String> environmentDefines,
  bool genBytecode: false,
  bool emitBytecodeSourcePositions: false,
  bool dropAST: false,
  bool useFutureBytecodeFormat: false,
}) async {
  // Package sharing: make the encoding not depend on the order in which parts
  // of a package are loaded.
  component.libraries.sort((Library a, Library b) {
    return a.importUri.toString().compareTo(b.importUri.toString());
  });
  component.computeCanonicalNames();
  for (Library lib in component.libraries) {
    lib.additionalExports.sort((Reference a, Reference b) {
      return a.canonicalName.toString().compareTo(b.canonicalName.toString());
    });
  }

  final packagesSet = new Set<String>();
  for (Library lib in component.libraries) {
    packagesSet.add(packageFor(lib));
  }
  packagesSet.remove('main');
  packagesSet.remove(null);

  final List<String> packages = packagesSet.toList();
  packages.add('main'); // Make sure main package is last.

  await runWithFrontEndCompilerContext(source, compilerOptions, component,
      () async {
    for (String package in packages) {
      final String filename = '$outputFileName-$package.dilp';
      final IOSink sink = new File(filename).openWrite();

      final main = component.mainMethod;
      if (package != 'main') {
        component.mainMethod = null;
      }

      if (genBytecode) {
        final List<Library> libraries = component.libraries
            .where((lib) => packageFor(lib) == package)
            .toList();
        generateBytecode(component,
            libraries: libraries,
            dropAST: dropAST,
            emitSourcePositions: emitBytecodeSourcePositions,
            useFutureBytecodeFormat: useFutureBytecodeFormat,
            environmentDefines: environmentDefines);
      }

      final BinaryPrinter printer = new LimitedBinaryPrinter(sink,
          (lib) => packageFor(lib) == package, false /* excludeUriToSource */);
      printer.writeComponentFile(component);
      component.mainMethod = main;

      await sink.close();
    }
  });

  final IOSink packagesList = new File('$outputFileName-packages').openWrite();
  for (String package in packages) {
    packagesList.writeln(package);
  }
  await packagesList.close();
}

String packageFor(Library lib) {
  // Core libraries are not written into any package kernel binaries.
  if (lib.isExternal) return null;

  // Packages are written into their own kernel binaries.
  Uri uri = lib.importUri;
  if (uri.scheme == 'package') return uri.pathSegments.first;

  // Everything else (e.g., file: or data: imports) is lumped into the main
  // kernel binary.
  return 'main';
}

String _escapePath(String path) {
  return path.replaceAll('\\', '\\\\').replaceAll(' ', '\\ ');
}

/// Create ninja dependencies file, as described in
/// https://ninja-build.org/manual.html#_depfile
Future<void> writeDepfile(FileSystem fileSystem, Component component,
    String output, String depfile) async {
  final IOSink file = new File(depfile).openWrite();
  file.write(_escapePath(output));
  file.write(':');
  for (Uri dep in component.uriToSource.keys) {
    // Skip empty or corelib dependencies.
    if (dep == null || dep.scheme == 'org-dartlang-sdk') continue;
    Uri uri = await asFileUri(fileSystem, dep);
    file.write(' ');
    file.write(_escapePath(uri.toFilePath()));
  }
  file.write('\n');
  await file.close();
}
