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
///           dart --dfe=utils/kernel-service/kernel-service.dart ...
///
/// invocation or it is invoked as a standalone script to perform batch mode
/// compilation requested via an HTTP interface
///
///           dart utils/kernel-service/kernel-service.dart --batch
///
/// The port for the batch mode worker is controlled by DFE_WORKER_PORT
/// environment declarations (set by -DDFE_WORKER_PORT=... command line flag).
/// When not set (or set to 0) an ephemeral port returned by the OS is used
/// instead.
///
/// When this script is used as a Kernel isolate root script and DFE_WORKER_PORT
/// is set to non-zero value then Kernel isolate will forward all compilation
/// requests it receives to the batch worker on the given port.
///
/// Set DFE_USE_FASTA environment declaration to true to use fasta front-end
/// instead of dartk. Note: we expect patched_sdk folder to contain
/// platform.dill file that contains patched SDK in the Kernel binary form.
/// This file can be created using the following command line:
///
///   export DART_AOT_SDK=<path-to-patched_sdk>
///   dart pkg/front_end/lib/src/fasta/bin/compile_platform.dart \
///        ${DART_AOT_SDK}/platform.dill
///
library runtime.tools.kernel_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;
import 'package:front_end/src/fasta/ticker.dart' show Ticker;
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;
import 'package:front_end/src/fasta/ast_kind.dart' show AstKind;
import 'package:front_end/src/fasta/errors.dart' show InputError;

const bool verbose = const bool.fromEnvironment('DFE_VERBOSE');
const int workerPort = const int.fromEnvironment('DFE_WORKER_PORT') ?? 0;
const bool useFasta = const bool.fromEnvironment('DFE_USE_FASTA');

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

  Map<String, dynamic> toJson();

  static CompilationFail fromJson(Map m) {
    switch (m['status']) {
      case STATUS_ERROR:
        return new CompilationError(m['errors']);
      case STATUS_CRASH:
        return new CompilationCrash(m['exception'], m['stack']);
      default:
        throw "Can't deserialize CompilationFail from ${m}.";
    }
  }
}

class CompilationError extends CompilationFail {
  final List<String> errors;

  CompilationError(this.errors);

  List toResponse() => [STATUS_ERROR, errorString];

  Map<String, dynamic> toJson() => {
        "status": STATUS_ERROR,
        "errors": errors,
      };

  String get errorString => errors.take(10).join('\n');

  String toString() => "CompilationError(${errorString})";
}

class CompilationCrash extends CompilationFail {
  final String exception;
  final String stack;

  CompilationCrash(this.exception, this.stack);

  List toResponse() => [STATUS_CRASH, errorString];

  Map<String, dynamic> toJson() => {
        "status": STATUS_CRASH,
        "exception": exception,
        "stack": stack,
      };

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

  Program program;
  if (useFasta) {
    final uriTranslator = await TranslateUri.parse(new Uri.file(packageConfig));
    final Ticker ticker = new Ticker(isVerbose: verbose);
    final DillTarget dillTarget = new DillTarget(ticker, uriTranslator);
    dillTarget.read(new Uri.directory(sdkPath).resolve('platform.dill'));
    final KernelTarget kernelTarget =
        new KernelTarget(dillTarget, uriTranslator);
    try {
      kernelTarget.read(fileName);
      await dillTarget.writeOutline(null);
      program = await kernelTarget.writeOutline(null);
      program = await kernelTarget.writeProgram(null, AstKind.Kernel);
      if (kernelTarget.errors.isNotEmpty) {
        return new CompilationError(kernelTarget.errors
            .map((err) => err.toString())
            .toList(growable: false));
      }
    } on InputError catch (e) {
      return new CompilationError(<String>[e.format()]);
    }
  } else {
    DartOptions dartOptions = new DartOptions(
        strongMode: false,
        strongModeSdk: false,
        sdk: sdkPath,
        packagePath: packageConfig,
        customUriMappings: const {},
        declaredVariables: const {});
    DartLoader loader =
        await batch_loader.getLoader(new Repository(), dartOptions);
    program = loader.loadProgram(fileName, target: target);

    if (loader.errors.isNotEmpty) {
      return new CompilationError(loader.errors.toList(growable: false));
    }
  }

  // Perform target-specific transformations.
  target.performModularTransformations(program);
  target.performGlobalTransformations(program);

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

  if (workerPort != 0) {
    return await requestParse(scriptUri, packagesUri, patchedSdk);
  } else {
    return await parseScript(
        new DartLoaderBatch(), scriptUri, packagesUri.path, patchedSdk.path);
  }
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

Future<CompilationResult> requestParse(
    Uri scriptUri, Uri packagesUri, Uri patchedSdk) async {
  if (verbose) {
    print(
        "DFE: forwarding request to worker at http://localhost:${workerPort}/");
  }

  HttpClient client = new HttpClient();
  final rq = await client
      .postUrl(new Uri(host: 'localhost', port: workerPort, scheme: 'http'));
  rq.headers.contentType = ContentType.JSON;
  rq.write(JSON.encode({
    "inputFileUrl": scriptUri.toString(),
    "packagesUri": packagesUri.toString(),
    "patchedSdk": patchedSdk.toString(),
  }));
  final rs = await rq.close();
  try {
    if (rs.statusCode == HttpStatus.OK) {
      final BytesBuilder bb = new BytesBuilder();
      await rs.forEach(bb.add);
      return new CompilationOk(bb.takeBytes());
    } else {
      return CompilationFail.fromJson(JSON.decode(await UTF8.decodeStream(rs)));
    }
  } finally {
    await client.close();
  }
}

void startBatchServer() {
  final loader = new DartLoaderBatch();
  HttpServer.bind('localhost', workerPort).then((server) {
    print('READY ${server.port}');
    server.listen((HttpRequest request) async {
      final rq = JSON.decode(await UTF8.decodeStream(request));

      final Uri scriptUri = Uri.parse(rq['inputFileUrl']);
      final Uri packagesUri = Uri.parse(rq['packagesUri']);
      final Uri patchedSdk = Uri.parse(rq['patchedSdk']);

      final CompilationResult result = await parseScript(
          loader, scriptUri, packagesUri.path, patchedSdk.path);

      if (result is CompilationOk) {
        request.response.statusCode = HttpStatus.OK;
        request.response.headers.contentType = ContentType.BINARY;
        request.response.add(result.binary);
        request.response.close();
      } else {
        request.response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
        request.response.headers.contentType = ContentType.TEXT;
        request.response.write(JSON.encode(result));
        request.response.close();
      }
    });
    ProcessSignal.SIGTERM.watch().first.then((_) => server.close());
  });
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
  if (args?.length == 1 && args[0] == '--batch') {
    startBatchServer();
  } else if (args?.length == 2 && args[0] == '--train') {
    // This entry point is used when creating an app snapshot. The argument
    // provides a script to compile to warm-up generated code.
    train(args[1]);
  } else {
    // Entry point for the Kernel isolate.
    return new RawReceivePort()..handler = _processLoadRequest;
  }
}

// This duplicates functionality from the Loader which we can't easily
// access from here.
Future<Uri> _findPackagesFile(Uri base) async {
  var dir = new File.fromUri(base).parent;
  while (true) {
    final packagesFile = dir.uri.resolve(".packages");
    if (await new File.fromUri(packagesFile).exists()) {
      return packagesFile;
    }
    if (dir.parent.path == dir.path) {
      break;
    }
    dir = dir.parent;
  }
  return null;
}
