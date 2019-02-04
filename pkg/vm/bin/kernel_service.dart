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
import 'dart:convert' show utf8;
import 'dart:io' show Platform, stderr hide FileSystemEntity;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_unstable/vm.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart' show Component, Procedure;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:vm/bytecode/gen_bytecode.dart' show generateBytecode;
import 'package:vm/incremental_compiler.dart';
import 'package:vm/kernel_front_end.dart' show runWithFrontEndCompilerContext;
import 'package:vm/http_filesystem.dart';
import 'package:vm/target/vm.dart' show VmTarget;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;

final bool verbose = new bool.fromEnvironment('DFE_VERBOSE');
const String platformKernelFile = 'virtual_platform_kernel.dill';

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

bool allowDartInternalImport = false;

abstract class Compiler {
  final FileSystem fileSystem;
  final Uri platformKernelPath;
  bool suppressWarnings;
  List<String> experimentalFlags;
  bool bytecode;
  String packageConfig;

  final List<String> errors = new List<String>();

  CompilerOptions options;

  Compiler(this.fileSystem, this.platformKernelPath,
      {this.suppressWarnings: false,
      this.experimentalFlags: null,
      this.bytecode: false,
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

    var expFlags = List<String>();
    if (experimentalFlags != null) {
      for (String flag in experimentalFlags) {
        expFlags.addAll(flag.split(","));
      }
    }

    options = new CompilerOptions()
      ..fileSystem = fileSystem
      ..target = new VmTarget(new TargetFlags())
      ..packagesFileUri = packagesUri
      ..sdkSummary = platformKernelPath
      ..verbose = verbose
      ..bytecode = bytecode
      ..experimentalFlags =
          parseExperimentalFlags(expFlags, (msg) => errors.add(msg))
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
          case Severity.errorLegacyWarning:
          case Severity.context:
          case Severity.ignored:
            throw "Unexpected severity: ${message.severity}";
        }
        if (printMessage) {
          printDiagnosticMessage(message, stderr.writeln);
        }
      };
  }

  Future<Component> compile(Uri script) {
    return runWithPrintToStderr(() async {
      final component = await compileInternal(script);

      if (options.bytecode && errors.isEmpty) {
        await runWithFrontEndCompilerContext(script, options, component, () {
          // TODO(alexmarkov): pass environment defines
          generateBytecode(component);
        });
      }

      return component;
    });
  }

  Future<Component> compileInternal(Uri script);
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

  IncrementalCompilerWrapper(FileSystem fileSystem, Uri platformKernelPath,
      {bool suppressWarnings: false,
      List<String> experimentalFlags: null,
      bool bytecode: false,
      String packageConfig: null})
      : super(fileSystem, platformKernelPath,
            suppressWarnings: suppressWarnings,
            experimentalFlags: experimentalFlags,
            bytecode: bytecode,
            packageConfig: packageConfig);

  @override
  Future<Component> compileInternal(Uri script) async {
    if (generator == null) {
      generator = new IncrementalCompiler(options, script);
    }
    errors.clear();
    return await generator.compile(entryPoint: script);
  }

  void accept() => generator.accept();
  void invalidate(Uri uri) => generator.invalidate(uri);

  Future<IncrementalCompilerWrapper> clone(int isolateId) async {
    IncrementalCompilerWrapper clone = IncrementalCompilerWrapper(
        fileSystem, platformKernelPath,
        suppressWarnings: suppressWarnings,
        experimentalFlags: experimentalFlags,
        bytecode: bytecode,
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

  SingleShotCompilerWrapper(FileSystem fileSystem, Uri platformKernelPath,
      {this.requireMain: false,
      bool suppressWarnings: false,
      List<String> experimentalFlags: null,
      bool bytecode: false,
      String packageConfig: null})
      : super(fileSystem, platformKernelPath,
            suppressWarnings: suppressWarnings,
            experimentalFlags: experimentalFlags,
            bytecode: bytecode,
            packageConfig: packageConfig);

  @override
  Future<Component> compileInternal(Uri script) async {
    return requireMain
        ? kernelForProgram(script, options)
        : kernelForComponent([script], options);
  }
}

// TODO(33428): This state is leaked on isolate shutdown.
final Map<int, IncrementalCompilerWrapper> isolateCompilers =
    new Map<int, IncrementalCompilerWrapper>();
final Map<int, List<Uri>> isolateDependencies = new Map<int, List<Uri>>();

IncrementalCompilerWrapper lookupIncrementalCompiler(int isolateId) {
  return isolateCompilers[isolateId];
}

Future<Compiler> lookupOrBuildNewIncrementalCompiler(int isolateId,
    List sourceFiles, Uri platformKernelPath, List<int> platformKernel,
    {bool suppressWarnings: false,
    List<String> experimentalFlags: null,
    bool bytecode: false,
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
      compiler = new IncrementalCompilerWrapper(fileSystem, platformKernelPath,
          suppressWarnings: suppressWarnings,
          experimentalFlags: experimentalFlags,
          bytecode: bytecode,
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
  final String expression = request[3];
  final List<String> definitions = request[4].cast<String>();
  final List<String> typeDefinitions = request[5].cast<String>();
  final String libraryUri = request[6];
  final String klass = request[7]; // might be null
  final bool isStatic = request[8];

  IncrementalCompilerWrapper compiler = isolateCompilers[isolateId];

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
      result = new CompilationResult.ok(serializeProcedure(procedure));
    }
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  port.send(result.toResponse());
}

void _recordDependencies(
    int isolateId, Component component, String packageConfig) {
  final dependencies = isolateDependencies[isolateId] ??= new List<Uri>();

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
    dependencies.add(Uri.parse(packageConfig));
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
}

Future _processLoadRequest(request) async {
  if (verbose) {
    for (int i = 0; i < request.length; i++) {
      var part = request[i];
      String partToString = part.toString();
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
  bool incremental = request[4];
  final int isolateId = request[6];
  final List sourceFiles = request[7];
  final bool suppressWarnings = request[8];
  final List<String> experimentalFlags =
      request[9] != null ? request[9].cast<String>() : null;
  final bool bytecode = request[10];
  final String packageConfig = request[11];
  final String multirootFilepaths = request[12];
  final String multirootScheme = request[13];

  if (bytecode) {
    // Bytecode generator is hooked into kernel service after kernel component
    // is produced. In case of incremental compilation resulting component
    // doesn't have core libraries which are needed for bytecode generation.
    // TODO(alexmarkov): Support bytecode generation in incremental compiler.
    incremental = false;
  }

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
    assert(compiler != null);
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
        experimentalFlags: experimentalFlags,
        bytecode: bytecode,
        packageConfig: packageConfig,
        multirootFilepaths: multirootFilepaths,
        multirootScheme: multirootScheme);
  } else {
    FileSystem fileSystem = _buildFileSystem(
        sourceFiles, platformKernel, multirootFilepaths, multirootScheme);
    compiler = new SingleShotCompilerWrapper(fileSystem, platformKernelPath,
        requireMain: false,
        suppressWarnings: suppressWarnings,
        experimentalFlags: experimentalFlags,
        bytecode: bytecode,
        packageConfig: packageConfig);
  }

  CompilationResult result;
  try {
    if (verbose) {
      print("DFE: scriptUri: ${script}");
    }

    Component component = await compiler.compile(script);

    if (compiler.errors.isNotEmpty) {
      if (component != null) {
        result = new CompilationResult.errors(compiler.errors,
            serializeComponent(component, filter: (lib) => !lib.isExternal));
      } else {
        result = new CompilationResult.errors(compiler.errors, null);
      }
    } else {
      // Record dependencies only if compilation was error free.
      _recordDependencies(isolateId, component, packageConfig);
      // We serialize the component excluding vm_platform.dill because the VM has
      // these sources built-in. Everything loaded as a summary in
      // [kernelForProgram] is marked `external`, so we can use that bit to
      // decide what to exclude.
      result = new CompilationResult.ok(
          serializeComponent(component, filter: (lib) => !lib.isExternal));
    }
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  if (verbose) print("DFE:> ${result}");

  if (tag == kTrainTag) {
    // In training mode make sure to read the sdk a few more times...
    ProcessedOptions p = new ProcessedOptions(options: compiler.options);
    var bytes = await p.loadSdkSummaryBytes();
    for (int i = 0; i < 100; i++) {
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

train(String scriptUri, String platformKernelPath) {
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
    true /* strong */,
    1 /* isolateId chosen randomly */,
    [] /* source files */,
    false /* suppress warnings */,
    null /* experimental_flags */,
    false /* generate bytecode */,
    null /* package_config */,
    null /* multirootFilepaths */,
    null /* multirootScheme */,
  ];
  _processLoadRequest(request);
}

main([args]) {
  if ((args?.length ?? 0) > 1 && args[0] == '--train') {
    // This entry point is used when creating an app snapshot. The argument
    // provides a script to compile to warm-up generated code.
    train(args[1], args.length > 2 ? args[2] : null);
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

  _CompilationOk(this.bytes) : super._();

  @override
  Status get status => Status.ok;

  @override
  get payload => bytes;

  String toString() => "_CompilationOk(${bytes.length} bytes)";
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
