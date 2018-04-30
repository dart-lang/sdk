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
import 'dart:io' show Platform, stderr hide FileSystemEntity;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/testing/hybrid_file_system.dart';
import 'package:kernel/kernel.dart' show Component;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm.dart' show VmTarget;
import 'package:vm/incremental_compiler.dart';

const bool verbose = const bool.fromEnvironment('DFE_VERBOSE');
const String platformKernelFile = 'virtual_platform_kernel.dill';

// NOTE: Any changes to these tags need to be reflected in kernel_isolate.cc
// Tags used to indicate different requests to the dart frontend.
//
// Current tags include the following:
//   0 - Perform normal compilation.
//   1 - Update in-memory file system with in-memory sources (used by tests).
//   2 - Accept last compilation result.
//   3 - APP JIT snapshot training run for kernel_service.
const int kCompileTag = 0;
const int kUpdateSourcesTag = 1;
const int kAcceptTag = 2;
const int kTrainTag = 3;

abstract class Compiler {
  final FileSystem fileSystem;
  final bool strongMode;
  final List<String> errors = new List<String>();

  CompilerOptions options;

  Compiler(this.fileSystem, Uri platformKernelPath,
      {this.strongMode: false,
      bool suppressWarnings: false,
      bool syncAsync: false}) {
    Uri packagesUri = (Platform.packageConfig != null)
        ? Uri.parse(Platform.packageConfig)
        : null;

    if (verbose) {
      print("DFE: Platform.packageConfig: ${Platform.packageConfig}");
      print("DFE: packagesUri: ${packagesUri}");
      print("DFE: Platform.resolvedExecutable: ${Platform.resolvedExecutable}");
      print("DFE: platformKernelPath: ${platformKernelPath}");
      print("DFE: strongMode: ${strongMode}");
      print("DFE: syncAsync: ${syncAsync}");
    }

    options = new CompilerOptions()
      ..strongMode = strongMode
      ..fileSystem = fileSystem
      ..target = new VmTarget(
          new TargetFlags(strongMode: strongMode, syncAsync: syncAsync))
      ..packagesFileUri = packagesUri
      ..sdkSummary = platformKernelPath
      ..verbose = verbose
      ..onProblem = (FormattedMessage message, Severity severity,
          List<FormattedMessage> context) {
        bool printMessage;
        switch (severity) {
          case Severity.error:
          case Severity.internalProblem:
            // TODO(sigmund): support emitting code with errors as long as they
            // are handled in the generated code (issue #30194).
            printMessage = false; // errors are printed by VM
            errors.add(message.formatted);
            break;
          case Severity.nit:
            printMessage = false;
            break;
          case Severity.warning:
            printMessage = !suppressWarnings;
            break;
          case Severity.errorLegacyWarning:
          case Severity.context:
            throw "Unexpected severity: $severity";
        }
        if (printMessage) {
          stderr.writeln(message.formatted);
          for (FormattedMessage message in context) {
            stderr.writeln(message.formatted);
          }
        }
      };
  }

  Future<Component> compile(Uri script) {
    return runWithPrintToStderr(() => compileInternal(script));
  }

  Future<Component> compileInternal(Uri script);
}

class IncrementalCompilerWrapper extends Compiler {
  IncrementalCompiler generator;

  IncrementalCompilerWrapper(FileSystem fileSystem, Uri platformKernelPath,
      {bool strongMode: false, bool suppressWarnings: false, syncAsync: false})
      : super(fileSystem, platformKernelPath,
            strongMode: strongMode,
            suppressWarnings: suppressWarnings,
            syncAsync: syncAsync);

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
}

class SingleShotCompilerWrapper extends Compiler {
  final bool requireMain;

  SingleShotCompilerWrapper(FileSystem fileSystem, Uri platformKernelPath,
      {this.requireMain: false,
      bool strongMode: false,
      bool suppressWarnings: false,
      bool syncAsync: false})
      : super(fileSystem, platformKernelPath,
            strongMode: strongMode,
            suppressWarnings: suppressWarnings,
            syncAsync: syncAsync);

  @override
  Future<Component> compileInternal(Uri script) async {
    return requireMain
        ? kernelForProgram(script, options)
        : kernelForComponent([script], options..chaseDependencies = true);
  }
}

final Map<int, Compiler> isolateCompilers = new Map<int, Compiler>();

Compiler lookupIncrementalCompiler(int isolateId) {
  return isolateCompilers[isolateId];
}

Future<Compiler> lookupOrBuildNewIncrementalCompiler(int isolateId,
    List sourceFiles, Uri platformKernelPath, List<int> platformKernel,
    {bool strongMode: false,
    bool suppressWarnings: false,
    bool syncAsync: false}) async {
  IncrementalCompilerWrapper compiler = lookupIncrementalCompiler(isolateId);
  if (compiler != null) {
    updateSources(compiler, sourceFiles);
    invalidateSources(compiler, sourceFiles);
  } else {
    final FileSystem fileSystem = sourceFiles.isEmpty && platformKernel == null
        ? StandardFileSystem.instance
        : _buildFileSystem(sourceFiles, platformKernel);

    // TODO(aam): IncrementalCompilerWrapper instance created below have to be
    // destroyed when corresponding isolate is shut down. To achieve that kernel
    // isolate needs to receive a message indicating that particular
    // isolate was shut down. Message should be handled here in this script.
    compiler = new IncrementalCompilerWrapper(fileSystem, platformKernelPath,
        strongMode: strongMode,
        suppressWarnings: suppressWarnings,
        syncAsync: syncAsync);
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
Future _processLoadRequest(request) async {
  if (verbose) print("DFE: request: $request");

  int tag = request[0];
  final SendPort port = request[1];
  final String inputFileUri = request[2];
  final Uri script =
      inputFileUri != null ? Uri.base.resolve(inputFileUri) : null;
  final bool incremental = request[4];
  final bool strong = request[5];
  final int isolateId = request[6];
  final List sourceFiles = request[7];
  final bool suppressWarnings = request[8];
  final bool syncAsync = request[9];

  Uri platformKernelPath = null;
  List<int> platformKernel = null;
  if (request[3] is String) {
    platformKernelPath = Uri.base.resolveUri(new Uri.file(request[3]));
  } else if (request[3] is List<int>) {
    platformKernelPath = Uri.parse(platformKernelFile);
    platformKernel = request[3];
  } else {
    platformKernelPath = computePlatformBinariesLocation()
        .resolve(strong ? 'vm_platform_strong.dill' : 'vm_platform.dill');
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
        strongMode: strong,
        suppressWarnings: suppressWarnings,
        syncAsync: syncAsync);
  } else {
    final FileSystem fileSystem = sourceFiles.isEmpty && platformKernel == null
        ? StandardFileSystem.instance
        : _buildFileSystem(sourceFiles, platformKernel);
    compiler = new SingleShotCompilerWrapper(fileSystem, platformKernelPath,
        requireMain: sourceFiles.isEmpty,
        strongMode: strong,
        suppressWarnings: suppressWarnings,
        syncAsync: syncAsync);
  }

  CompilationResult result;
  try {
    if (verbose) {
      print("DFE: scriptUri: ${script}");
    }

    Component component = await compiler.compile(script);

    if (compiler.errors.isNotEmpty) {
      result = new CompilationResult.errors(compiler.errors);
    } else {
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
      new CompilationResult.errors(<String>["unknown tag"]).payload
    ]);
  }
}

/// Creates a file system containing the files specified in [namedSources] and
/// that delegates to the underlying file system for any other file request.
/// The [namedSources] list interleaves file name string and
/// raw file content Uint8List.
///
/// The result can be used instead of StandardFileSystem.instance by the
/// frontend.
FileSystem _buildFileSystem(List namedSources, List<int> platformKernel) {
  MemoryFileSystem fileSystem = new MemoryFileSystem(Uri.parse('file:///'));
  if (namedSources != null) {
    for (int i = 0; i < namedSources.length ~/ 2; i++) {
      fileSystem
          .entityForUri(Uri.parse(namedSources[i * 2]))
          .writeAsBytesSync(namedSources[i * 2 + 1]);
    }
  }
  if (platformKernel != null) {
    fileSystem
        .entityForUri(Uri.parse(platformKernelFile))
        .writeAsBytesSync(platformKernel);
  }
  return new HybridFileSystem(fileSystem);
}

train(String scriptUri, String platformKernelPath) {
  // TODO(28532): Enable on Windows.
  if (Platform.isWindows) return;

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
    false /* strong */,
    1 /* isolateId chosen randomly */,
    [] /* source files */,
    false /* suppress warnings */,
    false /* synchronous async */,
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

  factory CompilationResult.errors(List<String> errors) = _CompilationError;

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
  final List<String> errors;

  _CompilationError(this.errors);

  @override
  Status get status => Status.error;

  @override
  String get errorString => errors.take(10).join('\n');

  String toString() => "_CompilationError(${errorString})";
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
