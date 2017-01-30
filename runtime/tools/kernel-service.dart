// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library runtime.tools.kernel_service;

// This is an interface to the Dart Kernel parser and Kernel binary generator.
//
// It is used by the kernel-isolate to load Dart source code and generate
// Kernel binary format.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

const bool verbose = const bool.fromEnvironment('DFE_VERBOSE') ?? false;

class DataSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {
    // Nothing to do.
  }
}

// Note: these values must match Dart_KernelCompilationStatus in dart_api.h.
const int STATUS_OK = 0; // Compilation was successful.
const int STATUS_ERROR = 1; // Compilation failed with a compile time error.
const int STATUS_CRASH = 2; // Compiler crashed.

abstract class CompilationResult {
  List toResponse();
}

class CompilationOk extends CompilationResult {
  final Uint8List binary;

  CompilationOk(this.binary);

  List toResponse() => [STATUS_OK, binary];

  String toString() => "CompilationOk(${binary.length} bytes)";
}

abstract class CompilationFail extends CompilationResult {
  String get errorString;
}

class CompilationError extends CompilationFail {
  final List<String> errors;

  CompilationError(this.errors);

  List toResponse() => [STATUS_ERROR, errorString];

  String get errorString => errors.take(10).join('\n');

  String toString() => "CompilationError(${errorString})";
}

class CompilationCrash extends CompilationFail {
  final String exception;
  final String stack;

  CompilationCrash(this.exception, this.stack);

  List toResponse() => [STATUS_CRASH, errorString];

  String get errorString => "${exception}\n${stack}";

  String toString() => "CompilationCrash(${errorString})";
}

Future<CompilationResult> parseScriptImpl(DartLoaderBatch batch_loader,
    Uri fileName, String packageConfig, String sdkPath) async {
  if (!FileSystemEntity.isFileSync(fileName.path)) {
    throw "Input file '${fileName.path}' does not exist.";
  }

  if (!FileSystemEntity.isDirectorySync(sdkPath)) {
    throw "Patched sdk directory not found at $sdkPath";
  }

  Target target = getTarget("vm", new TargetFlags(strongMode: false));
  DartOptions dartOptions = new DartOptions(
      strongMode: false,
      strongModeSdk: false,
      sdk: sdkPath,
      packagePath: packageConfig,
      customUriMappings: const {},
      declaredVariables: const {});
  DartLoader loader =
      await batch_loader.getLoader(new Repository(), dartOptions);
  var program = loader.loadProgram(fileName, target: target);

  var errors = loader.errors;
  if (errors.isNotEmpty) {
    return new CompilationError(loader.errors.toList());
  }

  // Link program into one file, cf. --link option in dartk.
  target.transformProgram(program);

  // Write the program to a list of bytes and return it.
  var sink = new DataSink();
  new BinaryPrinter(sink).writeProgramFile(program);
  return new CompilationOk(sink.builder.takeBytes());
}

Future<CompilationResult> parseScript(DartLoaderBatch loader, Uri fileName,
    String packageConfig, String sdkPath) async {
  try {
    return await parseScriptImpl(loader, fileName, packageConfig, sdkPath);
  } catch (err, stack) {
    return new CompilationCrash(err.toString(), stack.toString());
  }
}

Future _processLoadRequestImpl(String inputFileUrl) async {
  Uri scriptUri = Uri.parse(inputFileUrl);

  // Because we serve both Loader and bootstrapping requests we need to
  // duplicate the logic from _resolveScriptUri(...) here and attempt to
  // resolve schemaless uris using current working directory.
  if (scriptUri.scheme == '') {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    scriptUri = Directory.current.uri.resolveUri(scriptUri);
  }

  if (scriptUri.scheme != 'file') {
    // TODO: reuse loader code to support other schemes.
    throw "Expected 'file' scheme for a script uri: got ${scriptUri.scheme}";
  }

  final Uri packagesUri = (Platform.packageConfig != null)
      ? Uri.parse(Platform.packageConfig)
      : await _findPackagesFile(scriptUri);
  if (packagesUri == null) {
    throw "Could not find .packages";
  }

  final Uri patchedSdk =
      Uri.parse(Platform.resolvedExecutable).resolve("patched_sdk");

  if (verbose) {
    print("""DFE: Requesting compilation {
  scriptUri: ${scriptUri}
  packagesUri: ${packagesUri}
  patchedSdk: ${patchedSdk}
}""");
  }

  return await parseScript(
      new DartLoaderBatch(), scriptUri, packagesUri.path, patchedSdk.path);
}

// Process a request from the runtime. See KernelIsolate::CompileToKernel in
// kernel_isolate.cc and Loader::SendKernelRequest in loader.cc.
Future _processLoadRequest(request) async {
  if (verbose) {
    print("DFE: request: $request");
    print("DFE: Platform.packageConfig: ${Platform.packageConfig}");
    print("DFE: Platform.resolvedExecutable: ${Platform.resolvedExecutable}");
  }

  final int tag = request[0];
  final SendPort port = request[1];
  final String inputFileUrl = request[2];

  var result;
  try {
    result = await _processLoadRequestImpl(inputFileUrl);
  } catch (error, stack) {
    result = new CompilationCrash(error.toString(), stack.toString());
  }

  if (verbose) {
    print("DFE:> ${result}");
  }

  // Check whether this is a Loader request or a bootstrapping request from
  // KernelIsolate::CompileToKernel.
  final isBootstrapRequest = tag == null;
  if (isBootstrapRequest) {
    port.send(result.toResponse());
  } else {
    // See loader.cc for the code that handles these replies.
    if (result is CompilationOk) {
      port.send([tag, inputFileUrl, inputFileUrl, null, result]);
    } else {
      port.send([-tag, inputFileUrl, inputFileUrl, null, result.errorString]);
    }
  }
}

main() => new RawReceivePort()..handler = _processLoadRequest;

// This duplicates functionality from the Loader which we can't easily
// access from here.
Uri _findPackagesFile(Uri base) async {
  var dir = new File.fromUri(base).parent;
  while (true) {
    final packagesFile = dir.uri.resolve(".packages");
    if (await new File.fromUri(packagesFile).exists()) {
      return packagesFile;
    }
    if (dir.parent == dir) {
      break;
    }
    dir = dir.parent;
  }
  return null;
}
