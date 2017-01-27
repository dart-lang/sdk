// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is an interface to the Dart Kernel parser and Kernel binary generator.
// It is used by the kernel-isolate to load Dart source code and generate
// Kernel binary format.

import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

const verbose = false;

class DataSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  void add(List<int> data) {
    builder.add(data);
  }

  void close() {
    // Nothing to do.
  }
}

Future<Uint8List> parseScript(
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
      await new DartLoaderBatch().getLoader(new Repository(), dartOptions);
  var program = loader.loadProgram(fileName, target: target);

  var errors = loader.errors;
  if (errors.isNotEmpty) {
    throw loader.errors.first;
  }

  // Link program into one file, cf. --link option in dartk.
  target.transformProgram(program);

  // Write the program to a list of bytes and return it.
  var sink = new DataSink();
  new BinaryPrinter(sink).writeProgramFile(program);
  return sink.builder.takeBytes();
}

Future _processLoadRequest(request) async {
  if (verbose) {
    print("FROM DART KERNEL: load request: $request");
    print("FROM DART KERNEL: package: ${Platform.packageConfig}");
    print("FROM DART KERNEL: exec: ${Platform.resolvedExecutable}");
  }

  int tag = request[0];
  SendPort port = request[1];
  String inputFileUrl = request[2];
  Uri scriptUri = Uri.parse(inputFileUrl);
  Uri packagesUri = Uri.parse(Platform.packageConfig ?? ".packages");
  Uri patchedSdk =
      Uri.parse(Platform.resolvedExecutable).resolve("patched_sdk");

  var result;
  try {
    result = await parseScript(scriptUri, packagesUri.path, patchedSdk.path);
  } catch (error) {
    tag = -tag; // Mark reply as an exception.
    result = error.toString();
  }

  port.send([tag, inputFileUrl, inputFileUrl, null, result]);
}

main() => new RawReceivePort()..handler = _processLoadRequest;
