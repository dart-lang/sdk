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
library;

import 'dart:async' show Future, ZoneSpecification, runZoned;
import 'dart:collection' show UnmodifiableMapBase;
import 'dart:convert' show utf8;
import 'dart:io'
    show Directory, File, Platform, stderr, stdout
    hide FileSystemEntity;
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
import 'package:kernel/kernel.dart'
    show Component, Library, Procedure, NonNullableByDefaultCompiledMode;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:vm/incremental_compiler.dart';
import 'package:vm/kernel_front_end.dart'
    show createLoadedLibrariesSet, ErrorDetector;
import 'package:vm/http_filesystem.dart';
import 'package:vm/native_assets/diagnostic_message.dart';
import 'package:vm/native_assets/synthesizer.dart';
import 'package:vm/target/vm.dart' show VmTarget;

final bool verbose = new bool.fromEnvironment('DFE_VERBOSE');
final bool dumpKernel = new bool.fromEnvironment('DFE_DUMP_KERNEL');
const String platformKernelFile = 'virtual_platform_kernel.dill';
const String packageConfigFile = '.dart_tool/package_config.json';

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
//   7 - Reject last compilation result.
const int kCompileTag = 0;
const int kUpdateSourcesTag = 1;
const int kAcceptTag = 2;
const int kTrainTag = 3;
const int kCompileExpressionTag = 4;
const int kListDependenciesTag = 5;
const int kNotifyIsolateShutdownTag = 6;
const int kRejectTag = 7;

bool allowDartInternalImport = false;

CompilerOptions setupCompilerOptions(
    FileSystem fileSystem,
    Uri? platformKernelPath,
    bool enableAsserts,
    bool embedSources,
    bool nullSafety,
    List<String>? experimentalFlags,
    Uri? packagesUri,
    List<String> errorsPlain,
    List<String> errorsColorized,
    String invocationModes,
    String verbosityLevel,
    bool enableMirrors) {
  final expFlags = <String>[];
  if (experimentalFlags != null) {
    for (String flag in experimentalFlags) {
      expFlags.addAll(flag.split(","));
    }
  }

  Verbosity verbosity = Verbosity.parseArgument(verbosityLevel);
  return new CompilerOptions()
    ..fileSystem = fileSystem
    ..target = new VmTarget(new TargetFlags(
        soundNullSafety: nullSafety, supportMirrors: enableMirrors))
    ..packagesFileUri = packagesUri
    ..sdkSummary = platformKernelPath
    ..embedSourceText = embedSources
    ..verbose = verbose
    ..omitPlatform = false // so that compilation results can be rejected,
    // which potentially is only relevant for
    // incremental, rather than single-shot compilter
    ..explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(expFlags), onError: (msg) {
      errorsPlain.add(msg);
      errorsColorized.add(msg);
    })
    ..environmentDefines = new EnvironmentMap()
    ..nnbdMode = nullSafety ? NnbdMode.Strong : NnbdMode.Weak
    ..onDiagnostic = (DiagnosticMessage message) {
      bool printToStdErr = false;
      bool printToStdOut = false;
      switch (message.severity) {
        case Severity.error:
        case Severity.internalProblem:
          // TODO(sigmund): support emitting code with errors as long as they
          // are handled in the generated code.
          printToStdErr = false; // errors are printed by VM
          errorsPlain.addAll(message.plainTextFormatted);
          errorsColorized.addAll(message.ansiFormatted);
          break;
        case Severity.warning:
          printToStdErr = true;
          break;
        case Severity.info:
          printToStdErr = true;
          break;
        case Severity.context:
        case Severity.ignored:
          throw "Unexpected severity: ${message.severity}";
      }
      if (Verbosity.shouldPrint(verbosity, message)) {
        if (printToStdErr) {
          printDiagnosticMessage(message, stderr.writeln);
        }
        // ignore: dead_code
        else if (printToStdOut) {
          printDiagnosticMessage(message, stdout.writeln);
        }
      }
    }
    ..invocationModes = InvocationMode.parseArguments(invocationModes)
    ..verbosity = verbosity;
}

abstract class Compiler {
  final int isolateGroupId;
  final FileSystem fileSystem;
  final Uri? platformKernelPath;
  final bool enableAsserts;
  final bool embedSources;
  final bool nullSafety;
  final List<String>? experimentalFlags;
  final String? packageConfig;
  final String invocationModes;
  final String verbosityLevel;
  final bool enableMirrors;

  // Code coverage and hot reload are only supported by incremental compiler,
  // which is used if vm-service is enabled.
  final bool supportCodeCoverage;
  final bool supportHotReload;

  final List<String> errorsPlain = <String>[];
  final List<String> errorsColorized = <String>[];

  late final CompilerOptions options;

  Compiler(this.isolateGroupId, this.fileSystem, this.platformKernelPath,
      {this.enableAsserts = false,
      this.embedSources = true,
      this.nullSafety = true,
      this.experimentalFlags = null,
      this.supportCodeCoverage = false,
      this.supportHotReload = false,
      this.packageConfig = null,
      this.invocationModes = '',
      this.verbosityLevel = Verbosity.defaultValue,
      required this.enableMirrors}) {
    Uri? packagesUri = null;
    final packageConfig = this.packageConfig ?? Platform.packageConfig;
    if (packageConfig != null) {
      packagesUri = resolveInputUri(packageConfig);
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
        enableAsserts,
        embedSources,
        nullSafety,
        experimentalFlags,
        packagesUri,
        errorsPlain,
        errorsColorized,
        invocationModes,
        verbosityLevel,
        enableMirrors);
  }

  Future<CompilerResult> compile(Uri script) {
    return runWithPrintToStderr(() async {
      final CompilerResult compilerResult = await compileInternal(script);
      final Component? component = compilerResult.component;

      if (errorsPlain.isEmpty) {
        // Record dependencies only if compilation was error free.
        _recordDependencies(isolateGroupId, component, options.packagesFileUri);
      }

      return compilerResult;
    });
  }

  Future<CompilerResult> compileInternal(Uri script);
}

class CompilerResult {
  final Component? component;

  /// Set of libraries loaded from .dill, with or without the SDK depending on
  /// the compilation settings.
  final Set<Library> loadedLibraries;
  final ClassHierarchy? classHierarchy;
  final CoreTypes? coreTypes;

  CompilerResult(this.component, this.loadedLibraries, this.classHierarchy,
      this.coreTypes);
}

// Environment map which looks up environment defines in the VM environment
// at runtime.
// TODO(askesc): This is a temporary hack to get hold of the environment during
// JIT compilation. We use a lazy map accessing the VM runtime environment using
// new String.fromEnvironment, since the VM currently does not support providing
// the full (isolate specific) environment as a finite, static map.
class EnvironmentMap extends UnmodifiableMapBase<String, String> {
  @override
  bool containsKey(Object? key) {
    return key is String && new bool.hasEnvironment(key);
  }

  @override
  String? operator [](Object? key) {
    // The fromEnvironment constructor is specified to throw when called using
    // new. However, the VM implementation actually looks up the given name in
    // the environment.
    if (containsKey(key)) {
      return new String.fromEnvironment(key as String);
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
  IncrementalCompiler? generator;

  IncrementalCompilerWrapper(
      int isolateGroupId, FileSystem fileSystem, Uri? platformKernelPath,
      {bool enableAsserts = false,
      bool nullSafety = true,
      List<String>? experimentalFlags,
      String? packageConfig,
      String invocationModes = '',
      String verbosityLevel = Verbosity.defaultValue,
      required bool enableMirrors})
      : super(isolateGroupId, fileSystem, platformKernelPath,
            enableAsserts: enableAsserts,
            nullSafety: nullSafety,
            experimentalFlags: experimentalFlags,
            supportHotReload: true,
            supportCodeCoverage: true,
            packageConfig: packageConfig,
            invocationModes: invocationModes,
            verbosityLevel: verbosityLevel,
            enableMirrors: enableMirrors);

  factory IncrementalCompilerWrapper.forExpressionCompilationOnly(
      Component component,
      int isolateGroupId,
      FileSystem fileSystem,
      Uri? platformKernelPath,
      {bool enableAsserts = false,
      List<String>? experimentalFlags,
      String? packageConfig,
      String invocationModes = '',
      required bool enableMirrors}) {
    IncrementalCompilerWrapper result = IncrementalCompilerWrapper(
        isolateGroupId, fileSystem, platformKernelPath,
        enableAsserts: enableAsserts,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig,
        invocationModes: invocationModes,
        enableMirrors: enableMirrors);
    result.generator = new IncrementalCompiler.forExpressionCompilationOnly(
        component,
        result.options,
        [component.mainMethod!.enclosingLibrary.fileUri]);
    return result;
  }

  @override
  Future<CompilerResult> compileInternal(Uri script) async {
    final generator = this.generator ??= IncrementalCompiler(options, [script]);
    errorsPlain.clear();
    errorsColorized.clear();
    final compilerResult = await generator.compile(entryPoints: [script]);
    final component = compilerResult.component;
    return new CompilerResult(component, const {},
        compilerResult.classHierarchy, compilerResult.coreTypes);
  }

  void accept() => generator!.accept();
  Future<void> reject() async => generator!.reject();
  void invalidate(Uri uri) => generator!.invalidate(uri);

  Future<IncrementalCompilerWrapper> clone(int isolateGroupId) async {
    IncrementalCompilerWrapper clone = IncrementalCompilerWrapper(
        isolateGroupId, fileSystem, platformKernelPath,
        enableAsserts: enableAsserts,
        nullSafety: nullSafety,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig,
        invocationModes: invocationModes,
        enableMirrors: enableMirrors);
    final generator = this.generator!;
    // TODO(VM TEAM): This does not seem safe. What if cloning while having
    // pending deltas for instance?
    generator.resetDeltaState();
    IncrementalCompilerResult compilerResult = await generator.compile();
    Component fullComponent = compilerResult.component;

    // Assume fileSystem is HybridFileSystem because that is the setup where
    // clone should be used for.
    MemoryFileSystem memoryFileSystem = (fileSystem as HybridFileSystem).memory;

    String filename = 'full-component-$isolateGroupId.dill';
    Sink<List<int>> sink =
        FileSink(memoryFileSystem.entityForUri(Uri.file(filename)));
    new BinaryPrinter(sink).writeComponentFile(fullComponent);
    sink.close();

    clone.generator = new IncrementalCompiler(options, generator.entryPoints,
        initializeFromDillUri: Uri.file(filename));
    return clone;
  }
}

class SingleShotCompilerWrapper extends Compiler {
  final bool requireMain;

  SingleShotCompilerWrapper(
      int isolateGroupId, FileSystem fileSystem, Uri platformKernelPath,
      {this.requireMain = false,
      bool enableAsserts = false,
      bool embedSources = true,
      bool nullSafety = true,
      List<String>? experimentalFlags,
      String? packageConfig,
      String invocationModes = '',
      String verbosityLevel = Verbosity.defaultValue,
      required bool enableMirrors})
      : super(isolateGroupId, fileSystem, platformKernelPath,
            enableAsserts: enableAsserts,
            embedSources: embedSources,
            nullSafety: nullSafety,
            experimentalFlags: experimentalFlags,
            packageConfig: packageConfig,
            invocationModes: invocationModes,
            verbosityLevel: verbosityLevel,
            enableMirrors: enableMirrors);

  @override
  Future<CompilerResult> compileInternal(Uri script) async {
    final fe.CompilerResult? compilerResult = requireMain
        ? await kernelForProgram(script, options)
        : await kernelForModule([script], options);
    if (compilerResult == null) {
      return CompilerResult(null, const {}, null, null);
    }

    Set<Library> loadedLibraries = createLoadedLibrariesSet(
        compilerResult.loadedComponents, compilerResult.sdkComponent,
        includePlatform: false);

    return new CompilerResult(compilerResult.component, loadedLibraries,
        compilerResult.classHierarchy, compilerResult.coreTypes);
  }
}

final Map<int, IncrementalCompilerWrapper> isolateCompilers = {};
final Map<int, List<Uri>> isolateDependencies = {};
final Map<int, _ExpressionCompilationFromDillSettings> isolateLoadNotifies = {};

IncrementalCompilerWrapper? lookupIncrementalCompiler(int isolateGroupId) {
  return isolateCompilers[isolateGroupId];
}

Future<Compiler> lookupOrBuildNewIncrementalCompiler(int isolateGroupId,
    List sourceFiles, Uri platformKernelPath, List<int>? platformKernel,
    {bool enableAsserts = false,
    bool nullSafety = true,
    List<String>? experimentalFlags,
    String? packageConfig,
    String? multirootFilepaths,
    String? multirootScheme,
    String invocationModes = '',
    String verbosityLevel = Verbosity.defaultValue,
    required bool enableMirrors}) async {
  IncrementalCompilerWrapper? compiler =
      lookupIncrementalCompiler(isolateGroupId);
  if (compiler != null) {
    updateSources(compiler, sourceFiles);
    invalidateSources(compiler, sourceFiles);
  } else {
    // This is how identify scenario where child isolate hot reload requests
    // requires setting up actual compiler first: non-empty sourceFiles list has
    // no actual content specified for the source file.
    if (sourceFiles.isNotEmpty && sourceFiles[1] == null) {
      // Just use first compiler that should represent main isolate as a source for cloning.
      var source = isolateCompilers.entries.first;
      compiler = await source.value.clone(isolateGroupId);
    } else {
      FileSystem fileSystem = _buildFileSystem(
          sourceFiles, platformKernel, multirootFilepaths, multirootScheme);

      // TODO(aam): IncrementalCompilerWrapper instance created below have to be
      // destroyed when corresponding isolate is shut down. To achieve that kernel
      // isolate needs to receive a message indicating that particular
      // isolate was shut down. Message should be handled here in this script.
      compiler = new IncrementalCompilerWrapper(
          isolateGroupId, fileSystem, platformKernelPath,
          enableAsserts: enableAsserts,
          nullSafety: nullSafety,
          experimentalFlags: experimentalFlags,
          packageConfig: packageConfig,
          invocationModes: invocationModes,
          verbosityLevel: verbosityLevel,
          enableMirrors: enableMirrors);
    }
    isolateCompilers[isolateGroupId] = compiler;
  }
  return compiler;
}

void updateSources(IncrementalCompilerWrapper compiler, List sourceFiles) {
  final bool hasMemoryFS = compiler.fileSystem is HybridFileSystem;
  if (sourceFiles.isNotEmpty) {
    final FileSystem fs = compiler.fileSystem;
    for (int i = 0; i < sourceFiles.length ~/ 2; i++) {
      Uri uri = Uri.parse(sourceFiles[i * 2]);
      List<int>? source = sourceFiles[i * 2 + 1];
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
  final int isolateGroupId = request[2];
  final dynamic dartPlatformKernel = request[3];
  final String expression = request[4];
  final List<String> definitions = request[5].cast<String>();
  final List<String> definitionTypes = request[6].cast<String>();
  final List<String> typeDefinitions = request[7].cast<String>();
  final List<String> typeBounds = request[8].cast<String>();
  final List<String> typeDefaults = request[9].cast<String>();
  final String libraryUri = request[10];
  final String? klass = request[11];
  final String? method = request[12];
  final bool isStatic = request[13];
  final List<List<int>> dillData = request[14].cast<List<int>>();
  final int blobLoadCount = request[15];
  final bool enableAsserts = request[16];
  final List<String>? experimentalFlags =
      request[17] != null ? request[17].cast<String>() : null;
  final bool enableMirrors = request[18];

  IncrementalCompilerWrapper? compiler = isolateCompilers[isolateGroupId];

  _ExpressionCompilationFromDillSettings? isolateLoadDillData =
      isolateLoadNotifies[isolateGroupId];
  if (isolateLoadDillData != null) {
    // Check if we can reuse the compiler.
    if (isolateLoadDillData.blobLoadCount != blobLoadCount ||
        isolateLoadDillData.prevDillCount != dillData.length) {
      isolateCompilers.remove(isolateGroupId);
      compiler = null;
    }
  }

  if (compiler == null) {
    if (dillData.isNotEmpty) {
      if (verbose) {
        print("DFE: Initializing compiler from ${dillData.length} dill files");
      }
      isolateLoadNotifies[isolateGroupId] =
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
        if (library.importUri.isScheme("dart") &&
            library.importUri.path == "core" &&
            !library.isSynthetic) {
          foundDartCore = true;
          break;
        }
      }
      if (!foundDartCore) {
        List<int> platformKernel;
        if (dartPlatformKernel is List<int>) {
          platformKernel = dartPlatformKernel;
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
          _buildFileSystem([packageConfigFile, <int>[]], null, null, null);

      // TODO(aam): IncrementalCompilerWrapper instance created below have to be
      // destroyed when corresponding isolate is shut down. To achieve that
      // kernel isolate needs to receive a message indicating that particular
      // isolate was shut down. Message should be handled here in this script.
      try {
        compiler = new IncrementalCompilerWrapper.forExpressionCompilationOnly(
            component, isolateGroupId, fileSystem, null,
            enableAsserts: enableAsserts,
            experimentalFlags: experimentalFlags,
            packageConfig: packageConfigFile,
            enableMirrors: enableMirrors);
        isolateCompilers[isolateGroupId] = compiler;
        await compiler.compile(
            component.mainMethod?.enclosingLibrary.importUri ??
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

  compiler.errorsPlain.clear();
  compiler.errorsColorized.clear();

  CompilationResult result;
  try {
    Procedure? procedure = await compiler.generator!.compileExpression(
        expression,
        definitions,
        definitionTypes,
        typeDefinitions,
        typeBounds,
        typeDefaults,
        libraryUri,
        klass,
        method,
        isStatic);

    if (procedure == null) {
      port.send(
          new CompilationResult.errors(["Invalid scope."], null).toResponse());
      return;
    }

    assert(compiler.errorsPlain.length == compiler.errorsColorized.length);
    // Any error will be printed verbatim in observatory, so we always use the
    // plain version (i.e. the one without ANSI escape codes in it).
    if (compiler.errorsPlain.isNotEmpty) {
      // TODO(sigmund): the compiler prints errors to the console, so we
      // shouldn't print those messages again here.
      result = new CompilationResult.errors(compiler.errorsPlain, null);
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
    int isolateGroupId, Component? component, Uri? packageConfig) {
  final dependencies = isolateDependencies[isolateGroupId] ??= <Uri>[];

  if (component != null) {
    for (var lib in component.libraries) {
      if (lib.importUri.isScheme("dart")) continue;

      dependencies.add(lib.fileUri);
      for (var part in lib.parts) {
        final fileUri = lib.fileUri.resolve(part.partUri);
        if (fileUri.hasScheme && !fileUri.isScheme("file")) {
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

Uint8List _serializeDependencies(List<Uri> uris) {
  return utf8.encode(uris.map(_escapeDependency).join(" "));
}

Future _processListDependenciesRequest(
    SendPort port, int isolateGroupId) async {
  final List<Uri> dependencies = isolateDependencies[isolateGroupId] ?? <Uri>[];

  CompilationResult result;
  try {
    result = new CompilationResult.ok(_serializeDependencies(dependencies));
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  port.send(result.toResponse());
}

Future _processIsolateShutdownNotification(request) async {
  final int isolateGroupId = request[1];
  isolateCompilers.remove(isolateGroupId);
  isolateDependencies.remove(isolateGroupId);
  isolateLoadNotifies.remove(isolateGroupId);
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

  if (tag == kNotifyIsolateShutdownTag) {
    await _processIsolateShutdownNotification(request);
    return;
  }

  final SendPort port = request[1];
  final int isolateGroupId = request[8];
  if (tag == kListDependenciesTag) {
    await _processListDependenciesRequest(port, isolateGroupId);
    return;
  }

  final String? inputFileUri = request[2];
  final Uri? script =
      inputFileUri != null ? Uri.base.resolve(inputFileUri) : null;
  final bool incremental = request[4];
  final bool forSnapshot = request[5];
  final bool embedSources = request[6];
  final bool nullSafety = request[7];
  final List sourceFiles = request[9];
  final bool enableAsserts = request[10];
  final List<String>? experimentalFlags =
      request[11] != null ? request[11].cast<String>() : null;
  final String? packageConfig = request[12];
  final String? multirootFilepaths = request[13];
  final String? multirootScheme = request[14];
  final String verbosityLevel = request[16];
  final bool enableMirrors = request[17];
  Uri platformKernelPath;
  List<int>? platformKernel = null;
  if (request[3] is String) {
    platformKernelPath = Uri.base.resolveUri(new Uri.file(request[3]));
  } else if (request[3] is List<int>) {
    platformKernelPath = Uri.parse(platformKernelFile);
    platformKernel = request[3];
  } else {
    platformKernelPath =
        computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
  }

  final String invocationModes = forSnapshot ? 'compile' : '';

  Compiler? compiler;

  // Update the in-memory file system with the provided sources. Currently, only
  // unit tests compile sources that are not on the file system, so this can only
  // happen during unit tests.
  if (tag == kUpdateSourcesTag) {
    assert(incremental,
        "Incremental compiler required for use of 'kUpdateSourcesTag'");
    compiler = lookupIncrementalCompiler(isolateGroupId);
    if (compiler == null) {
      port.send(new CompilationResult.errors(
              ["No incremental compiler available for this isolate."], null)
          .toResponse());
      return;
    }
    updateSources(compiler as IncrementalCompilerWrapper, sourceFiles);
    port.send(new CompilationResult.ok(null).toResponse());
    return;
  } else if (tag == kAcceptTag || tag == kRejectTag) {
    assert(
        incremental,
        "Incremental compiler required for use of 'kAcceptTag' or "
        "'kRejectTag");
    compiler = lookupIncrementalCompiler(isolateGroupId);
    // There are unit tests that invoke the IncrementalCompiler directly and
    // request a reload, meaning that we won't have a compiler for this isolate.
    if (compiler != null) {
      final wrapper = compiler as IncrementalCompilerWrapper;
      try {
        if (tag == kAcceptTag) {
          wrapper.accept();
        } else {
          await wrapper.reject();
        }
      } catch (e, st) {
        port.send(CompilationResult.crash(e, st).toResponse());
        return;
      }
    }
    port.send(new CompilationResult.ok(null).toResponse());
    return;
  }

  // script should only be null for kUpdateSourcesTag.
  assert(script != null);

  // TODO(aam): There should be no need to have an option to choose
  // one compiler or another. We should always use an incremental
  // compiler as its functionality is a super set of the other one. We need to
  // watch the performance though.
  FileSystem fileSystem;
  if (incremental) {
    compiler = await lookupOrBuildNewIncrementalCompiler(
        isolateGroupId, sourceFiles, platformKernelPath, platformKernel,
        enableAsserts: enableAsserts,
        nullSafety: nullSafety,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig,
        multirootFilepaths: multirootFilepaths,
        multirootScheme: multirootScheme,
        invocationModes: invocationModes,
        verbosityLevel: verbosityLevel,
        enableMirrors: enableMirrors);
    fileSystem = compiler.fileSystem;
  } else {
    fileSystem = _buildFileSystem(
        sourceFiles, platformKernel, multirootFilepaths, multirootScheme);
    compiler = new SingleShotCompilerWrapper(
        isolateGroupId, fileSystem, platformKernelPath,
        requireMain: false,
        embedSources: embedSources,
        enableAsserts: enableAsserts,
        nullSafety: nullSafety,
        experimentalFlags: experimentalFlags,
        packageConfig: packageConfig,
        invocationModes: invocationModes,
        verbosityLevel: verbosityLevel,
        enableMirrors: enableMirrors);
  }

  CompilationResult result;
  try {
    if (verbose) {
      print("DFE: scriptUri: ${script}");
    }

    CompilerResult compilerResult = await compiler.compile(script!);
    Set<Library> loadedLibraries = compilerResult.loadedLibraries;

    final String? nativeAssets = await findNativeAssets(
      packagesFileUri:
          packageConfig != null ? resolveInputUri(packageConfig) : null,
      script: script,
      fileSystem: fileSystem,
    );
    Component? nativeAssetsComponent;
    final nativeAssetsErrors = <NativeAssetsDiagnosticMessage>[];
    if (nativeAssets != null) {
      final errorDetector = ErrorDetector(
          previousErrorHandler: (message) =>
              nativeAssetsErrors.add(message as NativeAssetsDiagnosticMessage));
      final nativeAssetsLibrary =
          await NativeAssetsSynthesizer.synthesizeLibraryFromYamlString(
        nativeAssets,
        errorDetector,
        nonNullableByDefaultCompiledMode: nullSafety
            ? NonNullableByDefaultCompiledMode.Strong
            : NonNullableByDefaultCompiledMode.Weak,
        pragmaClass: compilerResult.coreTypes?.pragmaClass,
      );
      if (nativeAssetsLibrary != null) {
        nativeAssetsComponent = Component(
          libraries: [nativeAssetsLibrary],
          mode: nativeAssetsLibrary.nonNullableByDefaultCompiledMode,
        );
      }
    }

    assert(compiler.errorsPlain.length == compiler.errorsColorized.length);
    // http://dartbug.com/45137
    // enableColors calls `stdout.supportsAnsiEscapes` which - on Windows -
    // does something with line endings. To avoid this when no error
    // messages are do be printed anyway, we are careful not to call it unless
    // necessary.
    if (compiler.errorsColorized.isNotEmpty || nativeAssetsErrors.isNotEmpty) {
      final List<String> errors = [
        ...(enableColors) ? compiler.errorsColorized : compiler.errorsPlain,
        ...nativeAssetsErrors.map((e) => e.message)
      ];
      final component = compilerResult.component;
      if (component != null) {
        result = new CompilationResult.errors(
            errors,
            serializeComponent(component,
                filter: (lib) => !loadedLibraries.contains(lib),
                nativeAssetsComponent: nativeAssetsComponent));
      } else {
        result = new CompilationResult.errors(errors, null);
      }
    } else {
      // We serialize the component excluding vm_platform.dill because the VM has
      // these sources built-in. Everything loaded as a summary in
      // [kernelForProgram] is marked `external`, so we can use that bit to
      // decide what to exclude.
      result = new CompilationResult.ok(serializeComponent(
          compilerResult.component!,
          filter: (lib) => !loadedLibraries.contains(lib),
          nativeAssetsComponent: nativeAssetsComponent));
    }
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  if (verbose) print("DFE:> ${result}");

  if (tag == kTrainTag) {
    // In training mode make sure to read the sdk a few more times...
    ProcessedOptions p = new ProcessedOptions(options: compiler.options);
    final bytes = (await p.loadSdkSummaryBytes())!;
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

/// Returns the contents of the `native_assets.yaml` for the host os in JIT,
/// if it exists.
///
/// Order or priority:
/// 1. If a `package_config.json` is picked by the kernel service, look to see
///    if there is a `native_assets.yaml` next to it.
/// 2. If no `package_config.json` is picked by the kernel service, walk up
///    folder hierarchy to find one and look next to it.
Future<String?> findNativeAssets({
  Uri? packagesFileUri,
  Uri? script,
  required FileSystem fileSystem,
}) async {
  if (packagesFileUri != null &&
      (packagesFileUri.scheme == '' || packagesFileUri.scheme == 'file')) {
    final nativeAssetsUri = packagesFileUri.resolve('native_assets.yaml');
    final nativeAssetsEntity = fileSystem.entityForUri(nativeAssetsUri);
    if (await nativeAssetsEntity.exists()) {
      return await nativeAssetsEntity.readAsString();
    }
    return null;
  }
  if (script != null && (script.scheme == '' || script.scheme == 'file')) {
    Future<String?> tryLoadNativeAssetsYaml(Uri uri) async {
      final nativeAssetsUri = uri.resolve('.dart_tool/native_assets.yaml');
      final nativeAssetsEntity = fileSystem.entityForUri(nativeAssetsUri);
      if (await nativeAssetsEntity.exists()) {
        return await nativeAssetsEntity.readAsString();
      }
      return null;
    }

    Uri folderUri = script.resolve('.');
    while (true) {
      final found = await tryLoadNativeAssetsYaml(folderUri);
      if (found != null) {
        return found;
      }
      final parentUri = folderUri.resolve('..');
      if (parentUri.path == folderUri.path) {
        return null;
      }
      folderUri = parentUri;
    }
  }
  return null;
}

Uint8List serializeComponent(Component component,
    {bool Function(Library library)? filter,
    Component? nativeAssetsComponent}) {
  final byteSink = new BytesSink();
  BinaryPrinter printer = new BinaryPrinter(byteSink, libraryFilter: filter);
  printer.writeComponentFile(component);
  if (nativeAssetsComponent != null) {
    BinaryPrinter printer = new BinaryPrinter(byteSink);
    printer.writeComponentFile(nativeAssetsComponent);
  }
  return byteSink.builder.takeBytes();
}

/// Creates a file system containing the files specified in [sourceFiles] and
/// that delegates to the underlying file system for any other file request.
/// The [sourceFiles] list interleaves file name string and
/// raw file content Uint8List.
///
/// The result can be used instead of StandardFileSystem.instance by the
/// frontend.
FileSystem _buildFileSystem(List sourceFiles, List<int>? platformKernel,
    String? multirootFilepaths, String? multirootScheme) {
  FileSystem fileSystem = new HttpAwareFileSystem(StandardFileSystem.instance);

  if (sourceFiles.isNotEmpty || platformKernel != null) {
    MemoryFileSystem memoryFileSystem =
        new MemoryFileSystem(Uri.parse('file:///'));
    for (int i = 0; i < sourceFiles.length ~/ 2; i++) {
      memoryFileSystem
          .entityForUri(Uri.parse(sourceFiles[i * 2]))
          .writeAsBytesSync(sourceFiles[i * 2 + 1]);
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

train(String scriptUri, String? platformKernelPath) async {
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

Future trainInternal(String scriptUri, String? platformKernelPath) async {
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
    false /* for_snapshot */,
    true /* embed_sources */,
    true /* null safety */,
    1 /* isolateGroupId chosen randomly */,
    [] /* source files */,
    false /* enable asserts */,
    null /* experimental_flags */,
    null /* package_config */,
    null /* multirootFilepaths */,
    null /* multirootScheme */,
    null /* original working directory */,
    'all' /* CFE logging mode */,
    true /* enableMirrors */,
    null /* native assets yaml */,
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
    final String? platform = (argIndex < args.length) ? args[argIndex] : null;
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

  factory CompilationResult.ok(Uint8List? bytes) = _CompilationOk;

  factory CompilationResult.nullSafety(bool val) = _CompilationNullSafety;

  factory CompilationResult.errors(List<String> errors, Uint8List? bytes) =
      _CompilationError;

  factory CompilationResult.crash(Object exception, StackTrace stack) =
      _CompilationCrash;

  Status get status;

  get payload;

  List toResponse() => [status.index, payload];
}

class _CompilationOk extends CompilationResult {
  final Uint8List? bytes;

  _CompilationOk(this.bytes) : super._() {
    if (dumpKernel) {
      final bytes = this.bytes;
      if (bytes != null) {
        _debugDumpKernel(bytes);
      }
    }
  }

  @override
  Status get status => Status.ok;

  @override
  get payload => bytes;

  String toString() => "_CompilationOk(${bytes?.length ?? 0} bytes)";
}

class _CompilationNullSafety extends CompilationResult {
  final bool _nullSafety;

  _CompilationNullSafety(this._nullSafety) : super._() {}

  @override
  Status get status => Status.ok;

  @override
  get payload => _nullSafety;

  String toString() => "_CompilationNullSafety($_nullSafety)";
}

abstract class _CompilationFail extends CompilationResult {
  _CompilationFail() : super._();

  String get errorString;

  @override
  get payload => errorString;
}

class _CompilationError extends _CompilationFail {
  final Uint8List? bytes;
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
  return runZoned(
    () => new Future<T>(f),
    zoneSpecification: new ZoneSpecification(
      // ignore: non_constant_identifier_names
      print: (_1, _2, _3, String line) => stderr.writeln(line),
    ),
  );
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
