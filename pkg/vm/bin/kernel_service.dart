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

import 'dart:async' show Future;
import 'dart:io' show Platform hide FileSystemEntity;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import 'package:front_end/file_system.dart';
import 'package:front_end/front_end.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/testing/hybrid_file_system.dart';
import 'package:kernel/kernel.dart' show Program;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm.dart' show VmTarget;

const bool verbose = const bool.fromEnvironment('DFE_VERBOSE');

abstract class Compiler {
  final FileSystem fileSystem;
  final bool strongMode;
  final List<String> errors = new List<String>();

  CompilerOptions options;

  Compiler(this.fileSystem, Uri platformKernel, {this.strongMode: false}) {
    Uri packagesUri = (Platform.packageConfig != null)
        ? Uri.parse(Platform.packageConfig)
        : null;

    if (verbose) {
      print("DFE: Platform.packageConfig: ${Platform.packageConfig}");
      print("DFE: packagesUri: ${packagesUri}");
      print("DFE: Platform.resolvedExecutable: ${Platform.resolvedExecutable}");
      print("DFE: platformKernel: ${platformKernel}");
      print("DFE: strongMode: ${strongMode}");
    }

    options = new CompilerOptions()
      ..strongMode = strongMode
      ..fileSystem = fileSystem
      ..target = new VmTarget(new TargetFlags(strongMode: strongMode))
      ..packagesFileUri = packagesUri
      ..sdkSummary = platformKernel
      ..verbose = verbose
      ..reportMessages = true
      ..onError = (CompilationMessage e) {
        if (e.severity == Severity.error) {
          // TODO(sigmund): support emitting code with errors as long as they
          // are handled in the generated code (issue #30194).
          errors.add(e.message);
        }
      };
  }

  Future<Program> compile(Uri script);
}

class IncrementalCompiler extends Compiler {
  IncrementalKernelGenerator generator;

  IncrementalCompiler(FileSystem fileSystem, Uri platformKernel,
      {strongMode: false})
      : super(fileSystem, platformKernel, strongMode: strongMode);

  @override
  Future<Program> compile(Uri script) async {
    if (generator == null) {
      generator = await IncrementalKernelGenerator.newInstance(options, script);
    }
    DeltaProgram deltaProgram = await generator.computeDelta();
    // TODO(aam): Accepting/rejecting should be done based on VM response.
    generator.acceptLastDelta();
    return deltaProgram.newProgram;
  }

  void invalidate(Uri uri) {
    generator.invalidate(uri);
  }
}

class SingleShotCompiler extends Compiler {
  final bool requireMain;

  SingleShotCompiler(FileSystem fileSystem, Uri platformKernel,
      {this.requireMain: false, strongMode: false})
      : super(fileSystem, platformKernel, strongMode: strongMode);

  @override
  Future<Program> compile(Uri script) async {
    return requireMain
        ? kernelForProgram(script, options)
        : kernelForBuildUnit([script], options..chaseDependencies = true);
  }
}

final Map<int, Compiler> isolateCompilers = new Map<int, Compiler>();

Future<Compiler> lookupOrBuildNewIncrementalCompiler(
    int isolateId, List sourceFiles, Uri platformKernel,
    {strongMode: false}) async {
  IncrementalCompiler compiler;
  if (isolateCompilers.containsKey(isolateId)) {
    compiler = isolateCompilers[isolateId];
    final HybridFileSystem fileSystem = compiler.fileSystem;
    if (sourceFiles != null) {
      for (int i = 0; i < sourceFiles.length ~/ 2; i++) {
        Uri uri = Uri.parse(sourceFiles[i * 2]);
        fileSystem.memory
            .entityForUri(uri)
            .writeAsBytesSync(sourceFiles[i * 2 + 1]);
        compiler.invalidate(uri);
      }
    }
  } else {
    final FileSystem fileSystem = sourceFiles == null
        ? PhysicalFileSystem.instance
        : _buildFileSystem(sourceFiles);

    // TODO(aam): IncrementalCompiler instance created below have to be
    // destroyed when corresponding isolate is shut down. To achieve that kernel
    // isolate needs to receive a message indicating that particular
    // isolate was shut down. Message should be handled here in this script.
    compiler = new IncrementalCompiler(fileSystem, platformKernel,
        strongMode: strongMode);
    isolateCompilers[isolateId] = compiler;
  }
  return compiler;
}

// Process a request from the runtime. See KernelIsolate::CompileToKernel in
// kernel_isolate.cc and Loader::SendKernelRequest in loader.cc.
Future _processLoadRequest(request) async {
  if (verbose) print("DFE: request: $request");

  int tag = request[0];
  final SendPort port = request[1];
  final String inputFileUri = request[2];
  final Uri script = Uri.base.resolve(inputFileUri);
  final Uri platformKernel = request[3] != null
      ? Uri.base.resolveUri(new Uri.file(request[3]))
      : computePlatformBinariesLocation().resolve(
          // TODO(sigmund): use `vm_outline.dill` when the mixin transformer is
          // modular.
          'vm_platform.dill');

  final bool incremental = request[4];
  final bool strong = request[5];
  final int isolateId = request[6];
  final List sourceFiles = request[7];

  Compiler compiler;
  // TODO(aam): There should be no need to have an option to choose
  // one compiler or another. We should always use an incremental
  // compiler as its functionality is a super set of the other one. We need to
  // watch the performance though.
  if (incremental) {
    compiler = await lookupOrBuildNewIncrementalCompiler(
        isolateId, sourceFiles, platformKernel);
  } else {
    final FileSystem fileSystem = sourceFiles == null
        ? PhysicalFileSystem.instance
        : _buildFileSystem(sourceFiles);
    compiler = new SingleShotCompiler(fileSystem, platformKernel,
        requireMain: sourceFiles == null, strongMode: strong);
  }

  CompilationResult result;
  try {
    if (verbose) {
      print("DFE: scriptUri: ${script}");
    }

    Program program = await compiler.compile(script);

    if (compiler.errors.isNotEmpty) {
      // TODO(sigmund): the compiler prints errors to the console, so we
      // shouldn't print those messages again here.
      result = new CompilationResult.errors(compiler.errors);
    } else {
      // We serialize the program excluding vm_platform.dill because the VM has
      // these sources built-in. Everything loaded as a summary in
      // [kernelForProgram] is marked `external`, so we can use that bit to
      // decide what to exclude.
      result = new CompilationResult.ok(
          serializeProgram(program, filter: (lib) => !lib.isExternal));
    }
  } catch (error, stack) {
    result = new CompilationResult.crash(error, stack);
  }

  if (verbose) print("DFE:> ${result}");

  // Check whether this is a Loader request or a bootstrapping request from
  // KernelIsolate::CompileToKernel.
  final isBootstrapRequest = tag == null;
  if (isBootstrapRequest) {
    port.send(result.toResponse());
  } else {
    // See loader.cc for the code that handles these replies.
    if (result.status != Status.ok) {
      tag = -tag;
    }
    port.send([tag, inputFileUri, inputFileUri, null, result.payload]);
  }
}

/// Creates a file system containing the files specified in [namedSources] and
/// that delegates to the underlying file system for any other file request.
/// The [namedSources] list interleaves file name string and
/// raw file content Uint8List.
///
/// The result can be used instead of PhysicalFileSystem.instance by the
/// frontend.
FileSystem _buildFileSystem(List namedSources) {
  MemoryFileSystem fileSystem = new MemoryFileSystem(Uri.parse('file:///'));
  for (int i = 0; i < namedSources.length ~/ 2; i++) {
    fileSystem
        .entityForUri(Uri.parse(namedSources[i * 2]))
        .writeAsBytesSync(namedSources[i * 2 + 1]);
  }
  return new HybridFileSystem(fileSystem);
}

train(String scriptUri) {
  // TODO(28532): Enable on Windows.
  if (Platform.isWindows) return;

  var tag = 1;
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
    null /* platformKernel */,
    false /* incremental */,
    false /* strong */,
    1 /* isolateId chosen randomly */,
    null /* source files */
  ];
  _processLoadRequest(request);
}

main([args]) {
  if (args?.length == 2 && args[0] == '--train') {
    // This entry point is used when creating an app snapshot. The argument
    // provides a script to compile to warm-up generated code.
    train(args[1]);
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
