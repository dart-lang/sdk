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
///         dart --dfe=utils/kernel-service/kernel-service.dart ...
///
/// invocation or it is invoked as a standalone script to perform training for
/// the app-jit snapshot
///
///         dart utils/kernel-service/kernel-service.dart --train <source-file>
///
///
library runtime.tools.kernel_service;

import 'dart:async' show Future;
import 'dart:io' show Platform hide FileSystemEntity;
import 'dart:isolate';
import 'dart:typed_data' show Uint8List;

import 'package:front_end/file_system.dart';
import 'package:front_end/front_end.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/testing/hybrid_file_system.dart';
import 'package:kernel/kernel.dart' show Program;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;

const bool verbose = const bool.fromEnvironment('DFE_VERBOSE');
const bool strongMode = const bool.fromEnvironment('DFE_STRONG_MODE');

// Process a request from the runtime. See KernelIsolate::CompileToKernel in
// kernel_isolate.cc and Loader::SendKernelRequest in loader.cc.
Future _processLoadRequest(request) async {
  if (verbose) print("DFE: request: $request");

  int tag = request[0];
  final SendPort port = request[1];
  final String inputFileUri = request[2];
  final Uri script = Uri.base.resolve(inputFileUri);

  FileSystem fileSystem = request.length > 3
      ? _buildFileSystem(request[3])
      : PhysicalFileSystem.instance;

  Uri packagesUri = (Platform.packageConfig != null)
      ? Uri.parse(Platform.packageConfig)
      : null;

  Uri sdkSummary = Uri.base
      .resolveUri(new Uri.file(Platform.resolvedExecutable))
      .resolveUri(new Uri.directory("patched_sdk"))
      // TODO(sigmund): use outline.dill when the mixin transformer is modular.
      .resolve('platform.dill');

  if (verbose) {
    print("DFE: scriptUri: ${script}");
    print("DFE: Platform.packageConfig: ${Platform.packageConfig}");
    print("DFE: packagesUri: ${packagesUri}");
    print("DFE: Platform.resolvedExecutable: ${Platform.resolvedExecutable}");
    print("DFE: sdkSummary: ${sdkSummary}");
  }

  var errors = <String>[];
  var options = new CompilerOptions()
    ..strongMode = strongMode
    ..fileSystem = fileSystem
    ..target = new VmFastaTarget(new TargetFlags(strongMode: strongMode))
    ..packagesFileUri = packagesUri
    ..sdkSummary = sdkSummary
    ..verbose = verbose
    ..onError = (CompilationError e) => errors.add(e.message);

  CompilationResult result;
  try {
    Program program = await kernelForProgram(script, options);
    if (errors.isNotEmpty) {
      result = new CompilationResult.errors(errors);
    } else {
      // We serialize the program excluding platform.dill because the VM has
      // these sources built-in. Everything loaded as a summary in
      // [kernelForProgram] is marked `external`, so we can use that bit to
      // decide what to excluce.
      // TODO(sigmund): remove the following line (Issue #30111)
      program.libraries.forEach((e) => e.isExternal = false);
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
  var request = [tag, responsePort.sendPort, scriptUri];
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
