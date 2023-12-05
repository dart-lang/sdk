// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test compiles itself with gen_kernel and invokes the compiled kernel
// file with `Process.run(dart, <...>)` and `Isolate.spawn` and
// `Isolate.spawnUri`.
//
// This tests test including a native asset mapping with an absolute file path.

// OtherResources=asset_absolute_test.dart
// OtherResources=helpers.dart

// ignore_for_file: deprecated_member_use

// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

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
  final selfSourceUri = Platform.script.resolve('asset_absolute_test.dart');
  final nativeAssetsYaml = createNativeAssetYaml(
    asset: selfSourceUri.toString(),
    assetMapping: [
      'absolute',
      ffiTestFunctionsUriAbsolute.toFilePath(),
    ],
  );
  await invokeSelf(
    selfSourceUri: selfSourceUri,
    runtime: Runtime.jit,
    arguments: [runTestsArg],
    nativeAssetsYaml: nativeAssetsYaml,
  );
  await invokeSelf(
    selfSourceUri: selfSourceUri,
    runtime: Runtime.aot,
    arguments: [runTestsArg],
    nativeAssetsYaml: nativeAssetsYaml,
  );
}

Future<void> runTests() async {
  testFfiTestfunctionsDll();
  testNonExistingFunction();
}

@Native<Int32 Function(Int32, Int32)>()
external int SumPlus42(int a, int b);

void testFfiTestfunctionsDll() {
  final result2 = SumPlus42(2, 3);
  Expect.equals(2 + 3 + 42, result2);

  final viaAddressOf =
      Native.addressOf<NativeFunction<Int32 Function(Int32, Int32)>>(SumPlus42)
          .asFunction<int Function(int, int)>();
  Expect.equals(2 + 3 + 42, viaAddressOf(2, 3));
}
