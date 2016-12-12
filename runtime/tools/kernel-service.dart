// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is an interface to the Dart Kernel parser and Kernel binary generator.
// It is used by the kernel-isolate to load Dart source code and generate
// Kernel binary format.

import 'dart:isolate';
import 'dart:async';
import "dart:io";
import "dart:typed_data";

import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';

bool verbose = false;

final RawReceivePort scriptLoadPort = new RawReceivePort();


bool checkIsFile(String path) {
  var stat = new File(path).statSync();
  switch (stat.type) {
    case FileSystemEntityType.DIRECTORY:
      return false;
    case FileSystemEntityType.NOT_FOUND:
      return false;
  }
  return true;
}


void checkSdkDirectory(String path) {
  var stat = new File(path).statSync();
  switch (stat.type) {
    case FileSystemEntityType.DIRECTORY:
    case FileSystemEntityType.LINK:
      return true;
    default:
      return false;
  }
}


class DataSink implements StreamSink<List<int>> {
  var buffer = [];
  add(List<int> data) {
    buffer.addAll(data);
  }
  close() {
    // Nothing to do.
  }
}


List writeProgramToBuffer(Program program) {
  var sink = new DataSink();
  try {
    new BinaryPrinter(sink).writeProgramFile(program);
  } finally {
    sink.close();
  }
  return new Uint8List.fromList(sink.buffer);
}


Future parseScript(Uri fileName, String packageConfig, String sdkPath) async {

  if (!checkIsFile(fileName.path)) {
    throw "Input file '${fileName.path}' does not exist.";
  }

  if (!checkSdkDirectory(sdkPath)) {
    throw "Patched sdk directory not found at $sdkPath";
  }

  Target target = getTarget("vm", new TargetFlags(strongMode: false));
  DartOptions dartOptions = new DartOptions(
        strongMode: false,
        strongModeSdk: false,
        sdk: sdkPath,
        packagePath: packageConfig,
        customUriMappings: {},
        declaredVariables: {});
  DartLoader loader =
      await new DartLoaderBatch().getLoader(new Repository(), dartOptions);
  var program = loader.loadProgram(fileName, target: target);

  var errors = loader.errors;
  if (errors.isNotEmpty) {
    throw loader.errors.first;
  }

  // Link program into one file, cf. --link option in dartk
  target.transformProgram(program);

  return writeProgramToBuffer(program);
}


_processLoadRequest(request) {
  if (verbose) {
    print("FROM DART KERNEL: load request: $request");
    print("FROM DART KERNEL: package: ${Platform.packageConfig}");
    print("FROM DART KERNEL: exec: ${Platform.resolvedExecutable}");
  }
  int tag = request[0];
  SendPort sp = request[1];
  String inputFileUrl = request[2];
  Uri scriptUri = Uri.parse(inputFileUrl);
  Uri packagesUri = Uri.parse(Platform.packageConfig ?? ".packages");
  Uri patched_sdk = Uri.parse(Platform.resolvedExecutable).resolve("patched_sdk");

  var parsingDone = parseScript(scriptUri, packagesUri.path, patched_sdk.path);

  parsingDone
    .then((data) {
        var msg = new List(5);
        msg[0] = tag;
        msg[1] = inputFileUrl;
        msg[2] = inputFileUrl;
        msg[3] = null;
        msg[4] = data;
        sp.send(msg);
        return;
    })
    .catchError((e) {
        var msg = new List(5);
        msg[0] = -tag;
        msg[1] = inputFileUrl;
        msg[2] = inputFileUrl;
        msg[3] = null;
        msg[4] = e.toString();
        sp.send(msg);
    });
}


main() {
  scriptLoadPort.handler = _processLoadRequest;
  Timer.run(() {});
  return scriptLoadPort;
}