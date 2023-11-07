// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:isolate' show RawReceivePort, ReceivePort, SendPort;

import "../bin/kernel_service.dart" as kernel_service;

import 'package:front_end/src/api_unstable/vm.dart' show Verbosity;

final bool verbose = new bool.fromEnvironment('TEST_VERBOSE');

Future<void> main() async {
  kernel_service.Status result;

  // Expect to work with both absolute and relative package specification
  // if the file specified exists and is valid.
  result = await singleShotCompile(
      relativeEntry, fooSourceFiles, absolutePackageConfig);
  expect(result, kernel_service.Status.ok);
  result = await singleShotCompile(
      relativeEntry, fooSourceFiles, relativePackageConfig);
  expect(result, kernel_service.Status.ok);

  // Expect an error with both absolute and relative package specification
  // if the file specified does not exist.
  result = await singleShotCompile(
      relativeEntry, fooSourceFiles, nonExistentAbsolutePackageConfig);
  expect(result, kernel_service.Status.error);
  result = await singleShotCompile(
      relativeEntry, fooSourceFiles, nonExistentRelativePackageConfig);
  expect(result, kernel_service.Status.error);

  // Expect an error with both absolute and relative package specification
  // if the file specified does exist but is invalid.
  result = await singleShotCompile(
      relativeEntry, fooSourceFiles, invalidAbsolutePackageConfig);
  expect(result, kernel_service.Status.error);
  result = await singleShotCompile(
      relativeEntry, fooSourceFiles, invalidRelativePackageConfig);
  expect(result, kernel_service.Status.error);
}

void expect(kernel_service.Status actual, kernel_service.Status expected) {
  if (actual != expected) {
    throw "Got $actual but expected $expected";
  }
}

String relativeEntry = "entry.dart";

String relativePackageConfig = "packageConfig.json";
String absolutePackageConfig = Uri.base.resolve(relativePackageConfig).path;

String nonExistentRelativePackageConfig = "nonexisting.json";
String nonExistentAbsolutePackageConfig =
    Uri.base.resolve(nonExistentRelativePackageConfig).path;

String invalidRelativePackageConfig = "invalidPackageConfig.json";
String invalidAbsolutePackageConfig =
    Uri.base.resolve(invalidRelativePackageConfig).path;

List fooSourceFiles = [
  Uri.base.resolve(relativeEntry).path,
  utf8.encode("""
        import "package:foo/bar.dart";
        main() {
          bar();
        }
      """),
  Uri.base.resolve("foo/lib/bar.dart").path,
  utf8.encode("""
        bar() {
          print("Hello from bar!");
        }
      """),
  absolutePackageConfig,
  utf8.encode("""
        {
          "configVersion": 2,
          "packages": [
            {
              "name": "foo",
              "rootUri": "foo/",
              "packageUri": "lib/"
            }
          ]
        }
      """),
  invalidAbsolutePackageConfig,
  utf8.encode(/* missing comma after rootUri line*/ """
        {
          "configVersion": 2,
          "packages": [
            {
              "name": "foo",
              "rootUri": "foo/"
              "packageUri": "lib/"
            }
          ]
        }
      """),
];

Future<kernel_service.Status> singleShotCompile(
    String entryFile, List sourceFiles, String? packageConfig) async {
  final RawReceivePort kernelServicePort = kernel_service.main();
  final SendPort sendPort = kernelServicePort.sendPort;
  final ReceivePort myReceivePort = new ReceivePort();

  sendPort.send([
    /* [0] = int = tag = */ kernel_service.kCompileTag,
    /* [1] = SendPort = sendport = */ myReceivePort.sendPort,
    /* [2] = String? = inputFileUri = */ entryFile,
    /* [3] = various = platformKernel = */ null,
    /* [4] = bool = incremental = */ false,
    /* [5] = bool = for_snapshot = */ false,
    /* [6] = bool = embed_sources = */ true,
    /* [7] = bool = soundNullSafety = */ true,
    /* [8] = int = isolateGroupId = */ 42,
    /* [9] = List = sourceFiles = */ sourceFiles,
    /* [10] = bool = enableAsserts = */ true,
    /* [11] = List<String>? = experimentalFlags = */ [],
    /* [12] = String? = packageConfig = */ packageConfig,
    /* [13] = String? = multirootFilepaths = */ null,
    /* [14] = String? = multirootScheme = */ null,
    /* [15] = String? = workingDirectory = */ null,
    /* [16] = String = verbosityLevel = */ Verbosity.all.name,
    /* [17] = bool = enableMirrors = */ false,
  ]);

  // Wait for kernel-service response.
  final StreamIterator streamIterator = new StreamIterator(myReceivePort);
  await streamIterator.moveNext();

  // Close ports so we can return below.
  kernelServicePort.close();
  myReceivePort.close();

  // Examine kernel-service response.
  final List m = streamIterator.current as List;
  final int status = m.first;
  if (status == kernel_service.Status.ok.index) {
    expectLength(m, 2);
    final List<int> bytes = m[1];
    if (verbose) {
      print("OK --- ${bytes.length} bytes dill");
    }
    return kernel_service.Status.ok;
  } else if (status == kernel_service.Status.error.index) {
    expectLength(m, 3);
    final String errors = m[1];
    final List<int> bytes = m[2];
    if (verbose) {
      print("Compiled with errors --- $errors and ${bytes.length} bytes dill");
    }
    return kernel_service.Status.error;
  } else if (status == kernel_service.Status.crash.index) {
    expectLength(m, 2);
    final String errors = m[1];
    if (verbose) {
      print("Compiler crashed --- $errors");
    }
    return kernel_service.Status.crash;
  } else {
    throw "Unknow status: $m";
  }
}

void expectLength(List list, int expectedLength) {
  if (list.length != expectedLength) {
    throw "Expected $expectedLength entries, got ${list.length}: $list";
  }
}
