// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is an interface to the Dart Kernel parser and Kernel binary generator.
///
/// It is used by the kernel-isolate to load Dart source code and generate
/// Kernel binary format.
///
/// This is either invoked as the root script of the Kernel isolate when used
/// as a part of
///
///         dart --dfe=pkg/vm/bin/kernel_service.dart ...
///
/// invocation or it is invoked as a standalone script to perform training for
/// the app-jit snapshot
///
///         dart pkg/vm/bin/kernel_service.dart --train <source-file>
///
///
library runtime.tools.kernel_service;

import 'dart:async' show Future, ZoneSpecification, runZoned;
import 'dart:collection' show UnmodifiableMapBase;
import 'dart:convert' show utf8;
import 'dart:io' show Directory, File, Platform, stderr hide FileSystemEntity;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_prototype/front_end.dart' as fe
    show CompilerResult;
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_unstable/vm.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/binary/ast_from_binary.dart'
    show BinaryBuilderWithMetadata;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/kernel.dart' show Component, Library, Procedure;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:vm/incremental_compiler.dart';
import 'package:vm/kernel_front_end.dart'
    show autoDetectNullSafetyMode, createLoadedLibrariesSet;
import 'package:vm/http_filesystem.dart';
import 'package:vm/target/vm.dart' show VmTarget;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;

final bool verbose = new bool.fromEnvironment('DFE_VERBOSE');
final bool dumpKernel = new bool.fromEnvironment('DFE_DUMP_KERNEL');
const String platformKernelFile = 'virtual_platform_kernel.dill';
const String dotPackagesFile = '.packages';

// NOTE: Any changes to these tags need to be reflected in kernel_isolate.cc
// Tags used to indicate different requests to the dart frontend.
//
// Current tags include the following:
//   0 - Perform normal compilation.
//   1 - Update in-memory file system with in-memory sources (used by tests).
//   2 - Accept last compilation result.
//   3 - APP JIT snapshot training run for kernel_service.
//   4 - Compile an individual expression in some context (for debugging
//       purposes).
//   5 - List program dependencies (for creating depfiles)
//   6 - Isolate shutdown that potentially should result in compiler cleanup.
const int kCompileTag = 0;
const int kUpdateSourcesTag = 1;
const int kAcceptTag = 2;
const int kTrainTag = 3;
const int kCompileExpressionTag = 4;
const int kListDependenciesTag = 5;
const int kNotifyIsolateShutdownTag = 6;
const int kDetectNullabilityTag = 7;

bool allowDartInternalImport = false;

// Null Safety command line options
//
// Note: The values of these constants must match the
// values of flag sound_null_safety in ../../../../runtime/vm/flag_list.h.
// 0 - No --[no-]sound-null-safety option specified on the command line.
// 1 - '--no-sound-null-safety' specified on the command line.
// 2 - '--sound-null-safety' option specified on the command line.
const int kNullSafetyOptionUnspecified = 0;
const int kNullSafetyOptionWeak = 1;
const int kNullSafetyOptionStrong = 2;

CompilerOptions setupCompilerOptions(
    FileSystem fileSystem,
    Uri platformKernelPath,
    bool suppressWarnings,
    bool enableAsserts,
    int nullSafety,
    List<String> experimentalFlags,
    Uri packagesUri,
    List<String> errors) {
  final expFlags = <String>[];
  if (experimentalFlags != null) {
    for (String flag in experimentalFlags) {
      expFlags.addAll(flag.split(","));
    }
  }

  return new CompilerOptions()
    ..fileSystem = fileSystem
    ..target = new VmTarget(new TargetFlags(
        enableNullSafety: nullSafety == kNullSafetyOptionStrong))
    ..packagesFileUri = packagesUri
    ..sdkSummary = platformKernelPath
    ..verbose = verbose
    ..omitPlatform = true
    ..explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(expFlags),
        onError: (msg) => errors.add(msg))
    ..environmentDefines = new EnvironmentMap()
    ..nnbdMode = (nullSafety == kNullSafetyOptionStrong)
        ? NnbdMode.Strong
        : NnbdMode.Weak
    ..onDiagnostic = (DiagnosticMessage message) {
      bool printMessage;
      switch (message.severity) {
        case Severity.error:
        case Severity.internalProblem:
          // TODO(sigmund): support emitting code with errors as long as they
          // are handled in the generated code.
          printMessage = false; // errors are printed by VM
          errors.addAll(message.plainTextFormatted);
          break;
        case Severity.warning:
          printMessage = !suppressWarnings;
          break;
        case Severity.context:
        case Severity.ignored:
          throw "Unexpected severity: ${message.severity}";
      }
      if (printMessage) {
        printDiagnosticMessage(message, stderr.writeln);
      }
    };
}

abstract class Compiler {
  final int isolateId;
  final FileSystem fileSystem;
  final Uri platformKernelPath;
  final bool suppressWarnings;
  final bool enableAsserts;
  final int nullSafety;
  final List<String> experimentalFlags;
  final String packageConfig;

  // Code coverage and hot reload are only supported by incremental compiler,
  // which is used if vm-service is enabled.
  final bool supportCodeCoverage;
  final bool supportHotReload;

  final List<String> errors = <String>[];

  CompilerOptions options;

  Compiler(this.isolateId, this.fileSystem, this.platformKernelPath,
      {this.suppressWarnings: false,
      this.enableAsserts: false,
      this.nullSafety: kNullSafetyOptionUnspecified,
      this.experimentalFlags: null,
      this.supportCodeCoverage: false,
      this.supportHotReload: false,
      this.packageConfig: null}) {
    Uri packagesUri = null;
    if (packageConfig != null) {
      packagesUri = Uri.parse(packageConfig);
    } else if (Platform.packageConfig != null) {
      packagesUri = Uri.parse(Platform.packageConfig);
    }

    if (verbose) {
      print("DFE: Platform.packageConfig: ${Platform.packageConfig}");
      print("DFE: packagesUri: ${packagesUri}");
      print("DFE: Platform.resolvedExecutable: ${Platform.resolvedExecutable}");
      print("DFE: platformKernelPath: ${platformKernelPath}");
    }

    options = setupCompilerOptions(
        fileSystem,
        platformKernelPath,
        suppressWarnings,
        enableAsserts,
        nullSafety,
        experimentalFlags,
        packagesUri,
        errors);
  }

  Future<CompilerResult> compile(Uri script) {
    return runWithPrintToStderr(() async {
      final CompilerResult compilerResult = await compileInternal(script);
      final Component component = compilerResult.component;

      if (errors.isEmpty) {
        // Record dependencies only if compilation was error free.
        _recordDependencies(isolateId, component, options.packagesFileUri);
      }

      return compilerResult;
    });
  }

  Future<CompilerResult> compileInternal(Uri script);
}

class CompilerResult {
  final Component component;

  /// Set of libraries loaded from .dill, with or without the SDK depending on
  /// the compilation settings.
  final Set<Library> loadedLibraries;
  final ClassHierarchy classHierarchy;
  final CoreTypes coreTypes;

  CompilerResult(
      this.component, this.loadedLibraries, this.classHierarchy, this.coreTypes)
      : assert(component != null),
        assert(loadedLibraries != null),
        assert(classHierarchy != null),
        assert(coreTypes != null);
}

// Environment map which looks up environment defines in the VM environment
// at runtime.
// TODO(askesc): This is a temporary hack to get hold of the environment during
// JIT compilation. We use a lazy map accessing the VM runtime environment using
// new String.fromEnvironment, since the VM currently does not support providing
// the full (isolate specific) environment as a finite, static map.
class EnvironmentMap extends UnmodifiableMapBase<String, String> {
  @override
  bool containsKey(Object key) {
    return new bool.hasEnvironment(key);
  }

  @override
  String operator [](Object key) {
    // The fromEnvironment constructor is specified to throw when called using
    // new. However, the VM implementation actually looks up the given name in
    // the environment.
    if (containsKey(key)) {
      return new String.fromEnvironment(key);
    }
    return null;
  }

  @override
  get keys => throw "Environment map iteration not supported";
}

class FileSink implements Sink<List<int>> {
  MemoryFileSystemEntity entityForUri;
  List<int> bytes = <int>[];

  FileSink(this.entityForUri);

  @override
  void add(List<int> data) {
    bytes.addAll(data);
  }

  @override
  void close() {
    this.entityForUri.writeAsBytesSync(bytes);
  }
}

class IncrementalCompilerWrapper extends Compiler {
  IncrementalCompiler generator;

  IncrementalCompilerWrapper(
      int isolateId, FileSystem fileSystem, Uri platformKernelPath,
      {bool suppressWarnings: false,
      bool enableAsserts: false,
      int nullSafety: kNullSafetyOptionUnspecified,
      List<String> experimentalFlags: null,
      String packageConfig: null})
      : super(isolateId, fileSystem, platformKernelPath,
            suppressWarnings: suppressWarnings,
            enableAsserts: enableAsserts,
            nullSafety: nullSafety,
            experimentalFlags: experimentalFlags,
            supportHotReload: true,
            supportCodeCoverage: true,
            packageConfig: packageConfig);

  factory IncrementalCompilerWrapper.forExpressionCompilationOnly(
      Component component,
      int isolateId,
      FileSystem fileSystem,
      Uri platformKernelPath,
      {bool suppressWarnings: false,
      bool enableAsserts: false,
      List<String> experimentalFlags: null,
      String packageConfig: null}) {
    IncrementalCompilerWrapper result = IncrementalCompilerWrapper(
        isolateId, fileSystem, platformKernelPath,
        suppressWarnings: suppressWarnings,
        enableAsserts: enableAsserts,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig);
    result.generator = new IncrementalCompiler.forExpressionCompilationOnly(
        component,
        result.options,
        component.mainMethod?.enclosingLibrary?.fileUri);
    return result;
  }

  @override
  Future<CompilerResult> compileInternal(Uri script) async {
    if (generator == null) {
      generator = new IncrementalCompiler(options, script);
    }
    errors.clear();
    final component = await generator.compile(entryPoint: script);
    return new CompilerResult(component, const {},
        generator.getClassHierarchy(), generator.getCoreTypes());
  }

  void accept() => generator.accept();
  void invalidate(Uri uri) => generator.invalidate(uri);

  Future<IncrementalCompilerWrapper> clone(int isolateId) async {
    IncrementalCompilerWrapper clone = IncrementalCompilerWrapper(
        isolateId, fileSystem, platformKernelPath,
        suppressWarnings: suppressWarnings,
        enableAsserts: enableAsserts,
        nullSafety: nullSafety,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig);

    generator.resetDeltaState();
    Component fullComponent = await generator.compile();

    // Assume fileSystem is HybridFileSystem because that is the setup where
    // clone should be used for.
    MemoryFileSystem memoryFileSystem = (fileSystem as HybridFileSystem).memory;

    String filename = 'full-component-$isolateId.dill';
    Sink sink = FileSink(memoryFileSystem.entityForUri(Uri.file(filename)));
    new BinaryPrinter(sink).writeComponentFile(fullComponent);
    await sink.close();

    clone.generator = new IncrementalCompiler(options, generator.entryPoint,
        initializeFromDillUri: Uri.file(filename));
    return clone;
  }
}

class SingleShotCompilerWrapper extends Compiler {
  final bool requireMain;

  SingleShotCompilerWrapper(
      int isolateId, FileSystem fileSystem, Uri platformKernelPath,
      {this.requireMain: false,
      bool suppressWarnings: false,
      bool enableAsserts: false,
      int nullSafety: kNullSafetyOptionUnspecified,
      List<String> experimentalFlags: null,
      String packageConfig: null})
      : super(isolateId, fileSystem, platformKernelPath,
            suppressWarnings: suppressWarnings,
            enableAsserts: enableAsserts,
            nullSafety: nullSafety,
            experimentalFlags: experimentalFlags,
            packageConfig: packageConfig);

  @override
  Future<CompilerResult> compileInternal(Uri script) async {
    fe.CompilerResult compilerResult = requireMain
        ? await kernelForProgram(script, options)
        : await kernelForModule([script], options);

    Set<Library> loadedLibraries = createLoadedLibrariesSet(
        compilerResult?.loadedComponents, compilerResult?.sdkComponent,
        includePlatform: !options.omitPlatform);

    return new CompilerResult(compilerResult.component, loadedLibraries,
        compilerResult.classHierarchy, compilerResult.coreTypes);
  }
}

// TODO(33428): This state is leaked on isolate shutdown.
final Map<int, IncrementalCompilerWrapper> isolateCompilers =
    new Map<int, IncrementalCompilerWrapper>();
final Map<int, List<Uri>> isolateDependencies = new Map<int, List<Uri>>();
final Map<int, _ExpressionCompilationFromDillSettings> isolateLoadNotifies =
    new Map<int, _ExpressionCompilationFromDillSettings>();

IncrementalCompilerWrapper lookupIncrementalCompiler(int isolateId) {
  return isolateCompilers[isolateId];
}

Future<Compiler> lookupOrBuildNewIncrementalCompiler(int isolateId,
    List sourceFiles, Uri platformKernelPath, List<int> platformKernel,
    {bool suppressWarnings: false,
    bool enableAsserts: false,
    int nullSafety: kNullSafetyOptionUnspecified,
    List<String> experimentalFlags: null,
    String packageConfig: null,
    String multirootFilepaths,
    String multirootScheme}) async {
  IncrementalCompilerWrapper compiler = lookupIncrementalCompiler(isolateId);
  if (compiler != null) {
    updateSources(compiler, sourceFiles);
    invalidateSources(compiler, sourceFiles);
  } else {
    // This is how identify scenario where child isolate hot reload requests
    // requires setting up actual compiler first: non-empty sourceFiles list has
    // no actual content specified for the source file.
    if (sourceFiles != null &&
        sourceFiles.length > 0 &&
        sourceFiles[1] == null) {
      // Just use first compiler that should represent main isolate as a source for cloning.
      var source = isolateCompilers.entries.first;
      compiler = await source.value.clone(isolateId);
    } else {
      FileSystem fileSystem = _buildFileSystem(
          sourceFiles, platformKernel, multirootFilepaths, multirootScheme);

      // TODO(aam): IncrementalCompilerWrapper instance created below have to be
      // destroyed when corresponding isolate is shut down. To achieve that kernel
      // isolate needs to receive a message indicating that particular
      // isolate was shut down. Message should be handled here in this script.
      compiler = new IncrementalCompilerWrapper(
          isolateId, fileSystem, platformKernelPath,
          suppressWarnings: suppressWarnings,
          enableAsserts: enableAsserts,
          nullSafety: nullSafety,
          experimentalFlags: experimentalFlags,
          packageConfig: packageConfig);
    }
    isolateCompilers[isolateId] = compiler;
  }
  return compiler;
}

void updateSources(IncrementalCompilerWrapper compiler, List sourceFiles) {
  final bool hasMemoryFS = compiler.fileSystem is HybridFileSystem;
  if (sourceFiles.isNotEmpty) {
    final FileSystem fs = compiler.fileSystem;
    for (int i = 0; i < sourceFiles.length ~/ 2; i++) {
      Uri uri = Uri.parse(sourceFiles[i * 2]);
      List<int> source = sourceFiles[i * 2 + 1];
      // The source is only provided by unit tests and is normally empty.
      // Don't add an entry for the uri so the compiler will fallback to the
      // real file system for the updated source.
      if (hasMemoryFS && source != null) {
        (fs as HybridFileSystem)
            .memory
            .entityForUri(uri)
            .writeAsBytesSync(source);
      }
    }
  }
}

void invalidateSources(IncrementalCompilerWrapper compiler, List sourceFiles) {
  if (sourceFiles.isNotEmpty) {
    for (int i = 0; i < sourceFiles.length ~/ 2; i++) {
      compiler.invalidate(Uri.parse(sourceFiles[i * 2]));
    }
  }
}

// Process a request from the runtime. See KernelIsolate::CompileToKernel in
// kernel_isolate.cc and Loader::SendKernelRequest in loader.cc.
Future _processExpressionCompilationRequest(request) async {
  final SendPort port = request[1];
  final int isolateId = request[2];
  final dynamic dart_platform_kernel = request[3];
  final String expression = request[4];
  final List<String> definitions = request[5].cast<String>();
  final List<String> typeDefinitions = request[6].cast<String>();
  final String libraryUri = request[7];
  final String klass = request[8]; // might be null
  final bool isStatic = request[9];
  final List dillData = request[10];
  final int blobLoadCount = request[11];
  final bool suppressWarnings = request[12];
  final bool enableAsserts = request[13];
  final List<String> experimentalFlags =
      request[14] != null ? request[14].cast<String>() : null;

  IncrementalCompilerWrapper compiler = isolateCompilers[isolateId];

  _ExpressionCompilationFromDillSettings isolateLoadDillData =
      isolateLoadNotifies[isolateId];
  if (isolateLoadDillData != null) {
    // Check if we can reuse the compiler.
    if (isolateLoadDillData.blobLoadCount != blobLoadCount ||
        isolateLoadDillData.prevDillCount != dillData.length) {
      compiler = isolateCompilers[isolateId] = null;
    }
  }

  if (compiler == null) {
    if (dillData.isNotEmpty) {
      if (verbose) {
        print("DFE: Initializing compiler from ${dillData.length} dill files");
      }
      isolateLoadNotifies[isolateId] =
          new _ExpressionCompilationFromDillSettings(
              blobLoadCount, dillData.length);

      // Create Component initialized from the bytes.
      Component component = new Component();

      // First try to just load all "dillData". This *might* include the
      // platform (and we might have the (same) platform both here and in
      // dart_platform_kernel).
      for (List<int> bytes in dillData) {
        // TODO(jensj): There might be an issue if main has changed.
        new BinaryBuilderWithMetadata(bytes, alwaysCreateNewNamedNodes: true)
            .readComponent(component);
      }

      // Check if the loaded component has the platform.
      // If it does not, try to load from dart_platform_kernel or from file.
      bool foundDartCore = false;
      for (Library library in component.libraries) {
        if (library.importUri.scheme == "dart" &&
            library.importUri.path == "core" &&
            !library.isSynthetic) {
          foundDartCore = true;
          break;
        }
      }
      if (!foundDartCore) {
        List<int> platformKernel = null;
        if (dart_platform_kernel is List<int>) {
          platformKernel = dart_platform_kernel;
        } else {
          final Uri platformUri = computePlatformBinariesLocation()
              .resolve('vm_platform_strong.dill');
          final File platformFile = new File.fromUri(platformUri);
          if (platformFile.existsSync()) {
            platformKernel = platformFile.readAsBytesSync();
          } else {
            port.send(new CompilationResult.errors(
                    ["No platform found to initialize incremental compiler."],
                    null)
                .toResponse());
            return;
          }
        }

        new BinaryBuilderWithMetadata(platformKernel,
                alwaysCreateNewNamedNodes: true)
            .readComponent(component);
      }

      FileSystem fileSystem =
          _buildFileSystem([dotPackagesFile, <int>[]], null, null, null);

      // TODO(aam): IncrementalCompilerWrapper instance created below have to be
      // destroyed when corresponding isolate is shut down. To achieve that
      // kernel isolate needs to receive a message indicating that particular
      // isolate was shut down. Message should be handled here in this script.
      try {
        compiler = new IncrementalCompilerWrapper.forExpressionCompilationOnly(
            component, isolateId, fileSystem, null,
            suppressWarnings: suppressWarnings,
            enableAsserts: enableAsserts,
            experimentalFlags: experimentalFlags,
            packageConfig: dotPackagesFile);
        isolateCompilers[isolateId] = compiler;
        await compiler.compile(
            component.mainMethod?.enclosingLibrary?.importUri ??
                component.libraries.last.importUri);
      } catch (e) {
        port.send(new CompilationResult.errors([
          "Error when trying to create a compiler for expression compilation: "
              "'$e'."
        ], null)
            .toResponse());
        return;
      }
    }
  }

  if (compiler == null) {
    port.send(new CompilationResult.errors(
            ["No incremental compiler available for this isolate."], null)
        .toResponse());
    return;
  }

  compiler.errors.clear();

  CompilationResult result;
  try {
    Procedure procedure = await compiler.generator.compileExpression(
        expression, definitions, typeDefinitions, libraryUri, klass, isStatic);

    if (procedure == null) {
      port.send(
          new CompilationResult.errors(["Invalid scope."], null).toResponse());
      return;
    }

    if (compiler.errors.isNotEmpty) {
      // TODO(sigmund): the compiler prints errors to the console, so we
      // shouldn't print those messages again here.
      result = new CompilationResult.errors(compiler.errors, null);
    } else {
      Component component = createExpressionEvaluationComponent(procedure);
      result = new CompilationResult.ok(serializeComponent(component));
    }
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  port.send(result.toResponse());
}

void _recordDependencies(
    int isolateId, Component component, Uri packageConfig) {
  final dependencies = isolateDependencies[isolateId] ??= <Uri>[];

  if (component != null) {
    for (var lib in component.libraries) {
      if (lib.importUri.scheme == "dart") continue;

      dependencies.add(lib.fileUri);
      for (var part in lib.parts) {
        final fileUri = lib.fileUri.resolve(part.partUri);
        if (fileUri.scheme != "" && fileUri.scheme != "file") {
          // E.g. part 'package:foo/foo.dart';
          // Maybe the front end should resolve this?
          continue;
        }
        dependencies.add(fileUri);
      }
    }
  }

  if (packageConfig != null) {
    dependencies.add(packageConfig);
  }
}

String _escapeDependency(Uri uri) {
  return uri.toFilePath().replaceAll("\\", "\\\\").replaceAll(" ", "\\ ");
}

List<int> _serializeDependencies(List<Uri> uris) {
  return utf8.encode(uris.map(_escapeDependency).join(" "));
}

Future _processListDependenciesRequest(request) async {
  final SendPort port = request[1];
  final int isolateId = request[6];

  final List<Uri> dependencies = isolateDependencies[isolateId] ?? <Uri>[];

  CompilationResult result;
  try {
    result = new CompilationResult.ok(_serializeDependencies(dependencies));
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  port.send(result.toResponse());
}

Future _processIsolateShutdownNotification(request) async {
  final int isolateId = request[1];
  isolateCompilers.remove(isolateId);
  isolateDependencies.remove(isolateId);
  isolateLoadNotifies.remove(isolateId);
}

Future _processLoadRequest(request) async {
  if (verbose) {
    for (int i = 0; i < request.length; i++) {
      var part = request[i];
      String partToString;
      if (part is List && part.isNotEmpty) {
        // Assume this is large and printing all of it takes a lot of time.
        StringBuffer sb = new StringBuffer();
        String prepend = "[";
        for (int j = 0; j < part.length; j++) {
          sb.write(prepend);
          sb.write(part[j]);
          prepend = ", ";
          if (sb.length > 256) break;
        }
        sb.write("]");
        partToString = sb.toString();
      } else {
        partToString = part.toString();
      }
      if (partToString.length > 256) {
        partToString = partToString.substring(0, 255) + "...";
      }
      print("DFE: request[$i]: $partToString");
    }
  }

  int tag = request[0];

  if (tag == kCompileExpressionTag) {
    await _processExpressionCompilationRequest(request);
    return;
  }

  if (tag == kListDependenciesTag) {
    await _processListDependenciesRequest(request);
    return;
  }

  if (tag == kNotifyIsolateShutdownTag) {
    await _processIsolateShutdownNotification(request);
    return;
  }

  final SendPort port = request[1];
  final String inputFileUri = request[2];
  final Uri script =
      inputFileUri != null ? Uri.base.resolve(inputFileUri) : null;
  final bool incremental = request[4];
  final int nullSafety = request[5];
  final int isolateId = request[6];
  final List sourceFiles = request[7];
  final bool suppressWarnings = request[8];
  final bool enableAsserts = request[9];
  final List<String> experimentalFlags =
      request[10] != null ? request[10].cast<String>() : null;
  final String packageConfig = request[11];
  final String multirootFilepaths = request[12];
  final String multirootScheme = request[13];
  final String workingDirectory = request[14];

  Uri platformKernelPath = null;
  List<int> platformKernel = null;
  if (request[3] is String) {
    platformKernelPath = Uri.base.resolveUri(new Uri.file(request[3]));
  } else if (request[3] is List<int>) {
    platformKernelPath = Uri.parse(platformKernelFile);
    platformKernel = request[3];
  } else {
    platformKernelPath =
        computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
  }

  Compiler compiler;

  // Update the in-memory file system with the provided sources. Currently, only
  // unit tests compile sources that are not on the file system, so this can only
  // happen during unit tests.
  if (tag == kUpdateSourcesTag) {
    assert(incremental,
        "Incremental compiler required for use of 'kUpdateSourcesTag'");
    compiler = lookupIncrementalCompiler(isolateId);
    if (compiler == null) {
      port.send(new CompilationResult.errors(
              ["No incremental compiler available for this isolate."], null)
          .toResponse());
      return;
    }
    updateSources(compiler, sourceFiles);
    port.send(new CompilationResult.ok(null).toResponse());
    return;
  } else if (tag == kAcceptTag) {
    assert(
        incremental, "Incremental compiler required for use of 'kAcceptTag'");
    compiler = lookupIncrementalCompiler(isolateId);
    // There are unit tests that invoke the IncrementalCompiler directly and
    // request a reload, meaning that we won't have a compiler for this isolate.
    if (compiler != null) {
      (compiler as IncrementalCompilerWrapper).accept();
    }
    port.send(new CompilationResult.ok(null).toResponse());
    return;
  } else if (tag == kDetectNullabilityTag) {
    FileSystem fileSystem = _buildFileSystem(
        sourceFiles, platformKernel, multirootFilepaths, multirootScheme);
    Uri packagesUri = null;
    if (packageConfig != null) {
      packagesUri = Uri.parse(packageConfig);
    } else if (Platform.packageConfig != null) {
      packagesUri = Uri.parse(Platform.packageConfig);
    }
    if (packagesUri != null && packagesUri.scheme == '') {
      // Script does not have a scheme, assume that it is a path,
      // resolve it against the working directory.
      packagesUri = Uri.directory(workingDirectory).resolveUri(packagesUri);
    }
    final List<String> errors = <String>[];
    var options = setupCompilerOptions(fileSystem, platformKernelPath, false,
        false, nullSafety, experimentalFlags, packagesUri, errors);

    // script should only be null for kUpdateSourcesTag.
    assert(script != null);
    await autoDetectNullSafetyMode(script, options);
    bool value = options.nnbdMode == NnbdMode.Strong;
    port.send(new CompilationResult.nullSafety(value).toResponse());
    return;
  }

  // script should only be null for kUpdateSourcesTag.
  assert(script != null);

  // TODO(aam): There should be no need to have an option to choose
  // one compiler or another. We should always use an incremental
  // compiler as its functionality is a super set of the other one. We need to
  // watch the performance though.
  if (incremental) {
    compiler = await lookupOrBuildNewIncrementalCompiler(
        isolateId, sourceFiles, platformKernelPath, platformKernel,
        suppressWarnings: suppressWarnings,
        enableAsserts: enableAsserts,
        nullSafety: nullSafety,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig,
        multirootFilepaths: multirootFilepaths,
        multirootScheme: multirootScheme);
  } else {
    FileSystem fileSystem = _buildFileSystem(
        sourceFiles, platformKernel, multirootFilepaths, multirootScheme);
    compiler = new SingleShotCompilerWrapper(
        isolateId, fileSystem, platformKernelPath,
        requireMain: false,
        suppressWarnings: suppressWarnings,
        enableAsserts: enableAsserts,
        nullSafety: nullSafety,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig);
  }

  CompilationResult result;
  try {
    if (verbose) {
      print("DFE: scriptUri: ${script}");
    }

    CompilerResult compilerResult = await compiler.compile(script);
    Set<Library> loadedLibraries = compilerResult.loadedLibraries;

    if (compiler.errors.isNotEmpty) {
      if (compilerResult.component != null) {
        result = new CompilationResult.errors(
            compiler.errors,
            serializeComponent(compilerResult.component,
                filter: (lib) => !loadedLibraries.contains(lib)));
      } else {
        result = new CompilationResult.errors(compiler.errors, null);
      }
    } else {
      // We serialize the component excluding vm_platform.dill because the VM has
      // these sources built-in. Everything loaded as a summary in
      // [kernelForProgram] is marked `external`, so we can use that bit to
      // decide what to exclude.
      result = new CompilationResult.ok(serializeComponent(
          compilerResult.component,
          filter: (lib) => !loadedLibraries.contains(lib)));
    }
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  if (verbose) print("DFE:> ${result}");

  if (tag == kTrainTag) {
    // In training mode make sure to read the sdk a few more times...
    ProcessedOptions p = new ProcessedOptions(options: compiler.options);
    var bytes = await p.loadSdkSummaryBytes();
    for (int i = 0; i < 5; i++) {
      p.loadComponent(bytes, null);
    }

    if (result.status != Status.ok) {
      tag = -tag;
    }
    port.send([tag, inputFileUri, inputFileUri, null, result.payload]);
  } else if (tag == kCompileTag) {
    port.send(result.toResponse());
  } else {
    port.send([
      -tag,
      inputFileUri,
      inputFileUri,
      null,
      new CompilationResult.errors(<String>["unknown tag"], null).payload
    ]);
  }
}

/// Creates a file system containing the files specified in [sourceFiles] and
/// that delegates to the underlying file system for any other file request.
/// The [sourceFiles] list interleaves file name string and
/// raw file content Uint8List.
///
/// The result can be used instead of StandardFileSystem.instance by the
/// frontend.
FileSystem _buildFileSystem(List sourceFiles, List<int> platformKernel,
    String multirootFilepaths, String multirootScheme) {
  FileSystem fileSystem = new HttpAwareFileSystem(StandardFileSystem.instance);

  if (!sourceFiles.isEmpty || platformKernel != null) {
    MemoryFileSystem memoryFileSystem =
        new MemoryFileSystem(Uri.parse('file:///'));
    if (sourceFiles != null) {
      for (int i = 0; i < sourceFiles.length ~/ 2; i++) {
        memoryFileSystem
            .entityForUri(Uri.parse(sourceFiles[i * 2]))
            .writeAsBytesSync(sourceFiles[i * 2 + 1]);
      }
    }
    if (platformKernel != null) {
      memoryFileSystem
          .entityForUri(Uri.parse(platformKernelFile))
          .writeAsBytesSync(platformKernel);
    }
    fileSystem = new HybridFileSystem(memoryFileSystem, fileSystem);
  }

  if (multirootFilepaths != null) {
    List<Uri> list = multirootFilepaths
        .split(',')
        .map((String s) => Uri.base.resolveUri(new Uri.file(s)))
        .toList();
    fileSystem = new MultiRootFileSystem(
        multirootScheme ?? "org-dartlang-root", list, fileSystem);
  }
  return fileSystem;
}

train(String scriptUri, String platformKernelPath) async {
  // Train on program asked to train on.
  await trainInternal(scriptUri, platformKernelPath);

  // Also train a few times on a hello-world program to make sure we exercise
  // the startup sequence.
  Directory tmpDir =
      Directory.systemTemp.createTempSync("kernel_service_train");
  File helloDart = new File.fromUri(tmpDir.uri.resolve("hello.dart"));
  helloDart.writeAsStringSync("""
          main() {
            print("Hello, World!");
          }
          """);
  try {
    for (int i = 0; i < 10; i++) {
      await trainInternal(helloDart.uri.toString(), platformKernelPath);
    }
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

Future trainInternal(String scriptUri, String platformKernelPath) async {
  var tag = kTrainTag;
  var responsePort = new RawReceivePort();
  responsePort.handler = (response) {
    if (response[0] == tag) {
      // Success.
      responsePort.close();
    } else if (response[0] == -tag) {
      // Compilation error.
      throw response[4];
    } else {
      throw "Unexpected response: $response";
    }
  };
  var request = [
    tag,
    responsePort.sendPort,
    scriptUri,
    platformKernelPath,
    false /* incremental */,
    kNullSafetyOptionUnspecified /* null safety */,
    1 /* isolateId chosen randomly */,
    [] /* source files */,
    false /* suppress warnings */,
    false /* enable asserts */,
    null /* experimental_flags */,
    null /* package_config */,
    null /* multirootFilepaths */,
    null /* multirootScheme */,
    null /* original working directory */,
  ];
  await _processLoadRequest(request);
}

main([args]) {
  if ((args?.length ?? 0) > 1 && args[0] == '--train') {
    // This entry point is used when creating an app snapshot.
    // It takes the following extra arguments:
    // 1) Script to compile.
    // 2) Optional platform kernel path.
    int argIndex = 1;
    final String script = args[argIndex++];
    final String platform = (argIndex < args.length) ? args[argIndex] : null;
    train(script, platform);
  } else {
    // Entry point for the Kernel isolate.
    return new RawReceivePort()..handler = _processLoadRequest;
  }
}

/// Compilation status codes.
///
/// Note: The [index] property of these constants must match
/// `Dart_KernelCompilationStatus` in
/// [dart_api.h](../../../../runtime/include/dart_api.h).
enum Status {
  /// Compilation was successful.
  ok,

  /// Compilation failed with a compile time error.
  error,

  /// Compiler crashed.
  crash,
}

abstract class CompilationResult {
  CompilationResult._();

  factory CompilationResult.ok(Uint8List bytes) = _CompilationOk;

  factory CompilationResult.nullSafety(bool val) = _CompilationNullSafety;

  factory CompilationResult.errors(List<String> errors, Uint8List bytes) =
      _CompilationError;

  factory CompilationResult.crash(Object exception, StackTrace stack) =
      _CompilationCrash;

  Status get status;

  get payload;

  List toResponse() => [status.index, payload];
}

class _CompilationOk extends CompilationResult {
  final Uint8List bytes;

  _CompilationOk(this.bytes) : super._() {
    if (dumpKernel && bytes != null) {
      _debugDumpKernel(bytes);
    }
  }

  @override
  Status get status => Status.ok;

  @override
  get payload => bytes;

  String toString() => "_CompilationOk(${bytes.length} bytes)";
}

class _CompilationNullSafety extends CompilationResult {
  final bool _null_safety;

  _CompilationNullSafety(this._null_safety) : super._() {}

  @override
  Status get status => Status.ok;

  @override
  get payload => _null_safety;

  String toString() => "_CompilationNullSafety($_null_safety)";
}

abstract class _CompilationFail extends CompilationResult {
  _CompilationFail() : super._();

  String get errorString;

  @override
  get payload => errorString;
}

class _CompilationError extends _CompilationFail {
  final Uint8List bytes;
  final List<String> errors;

  _CompilationError(this.errors, this.bytes);

  @override
  Status get status => Status.error;

  @override
  String get errorString => errors.take(10).join('\n');

  String toString() => "_CompilationError(${errorString})";

  List toResponse() => [status.index, payload, bytes];
}

class _CompilationCrash extends _CompilationFail {
  final Object exception;
  final StackTrace stack;

  _CompilationCrash(this.exception, this.stack);

  @override
  Status get status => Status.crash;

  @override
  String get errorString => "${exception}\n${stack}";

  String toString() => "_CompilationCrash(${errorString})";
}

Future<T> runWithPrintToStderr<T>(Future<T> f()) {
  return runZoned(() => new Future<T>(f),
      zoneSpecification: new ZoneSpecification(
          print: (_1, _2, _3, String line) => stderr.writeln(line)));
}

int _debugDumpCounter = 0;
void _debugDumpKernel(Uint8List bytes) {
  new File('kernel_service.tmp${_debugDumpCounter++}.dill')
      .writeAsBytesSync(bytes);
}

class _ExpressionCompilationFromDillSettings {
  int blobLoadCount;
  int prevDillCount;

  _ExpressionCompilationFromDillSettings(
      this.blobLoadCount, this.prevDillCount);
}
