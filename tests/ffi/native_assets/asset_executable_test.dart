// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test compiles itself with gen_kernel and invokes the compiled kernel
// file with `Process.run(dart, <...>)` and `Isolate.spawn` and
// `Isolate.spawnUri`.
//
// This tests test including a native asset mapping that looks up its symbols
// in the executable.

// OtherResources=asset_executable_test.dart
// OtherResources=helpers.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'helpers.dart';

const runTestsArg = 'run-tests';

main(List<String> args, Object? message) async {
  return await selfInvokingTest(
    doOnOuterInvocation: selfInvokes,
    doOnProcessInvocation: () async {
      await runTests();
      await testIsolateSpawn(runTests);
      await testIsolateSpawnUri(spawnUri: Platform.script, arguments: args);
    },
    doOnSpawnUriInvocation: () async {
      await runTests();
      await testIsolateSpawn(runTests);
    },
  )(args, message);
}

Future<void> selfInvokes() async {
  final selfSourceUri = Platform.script.resolve('asset_executable_test.dart');
  final nativeAssetsYaml = createNativeAssetYaml(
      asset: selfSourceUri.toString(), assetMapping: ['executable']);
  await invokeSelf(
    selfSourceUri: selfSourceUri,
    runtime: Runtime.jit,
    arguments: [runTestsArg],
    nativeAssetsYaml: nativeAssetsYaml,
    protobufAwareTreeshaking: true,
  );
  await invokeSelf(
    selfSourceUri: selfSourceUri,
    runtime: Runtime.aot,
    arguments: [runTestsArg],
    nativeAssetsYaml: nativeAssetsYaml,
  );
}

Future<void> runTests() async {
  await testExecutable();
  testNonExistingFunction();
}

typedef _PostInteger = Bool Function(Int64 port, Int64 message);

@Native<_PostInteger>()
external bool Dart_PostInteger(int port, int message);

Future<void> testExecutable() async {
  await _testWith(Dart_PostInteger);

  final viaAddressOf =
      Native.addressOf<NativeFunction<_PostInteger>>(Dart_PostInteger);
  await _testWith(viaAddressOf.asFunction());
}

Future<void> _testWith(bool Function(int, int) postInteger) async {
  const int message = 1337 * 42;

  final completer = Completer();

  final receivePort = ReceivePort()
    ..listen((receivedMessage) => completer.complete(receivedMessage));

  final bool success = postInteger(receivePort.sendPort.nativePort, message);
  Expect.isTrue(success);

  final postedMessage = await completer.future;
  Expect.equals(message, postedMessage);

  receivePort.close();
}
