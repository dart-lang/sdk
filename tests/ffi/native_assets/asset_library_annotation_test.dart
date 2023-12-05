// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that `@DefaultAsset(assetName)` on `library;` works.

// OtherResources=asset_library_annotation_test.dart
// OtherResources=helpers.dart

// SharedObjects=ffi_test_functions

@DefaultAsset(assetName)
library asset_test;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

import 'helpers.dart';

const runTestsArg = 'run-tests';

main(List<String> args, Object? message) => selfInvokingTest(
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

const assetName = 'myAsset';

Future<void> selfInvokes() async {
  final selfSourceUri =
      Platform.script.resolve('asset_library_annotation_test.dart');
  final nativeAssetsYaml = createNativeAssetYaml(
    asset: assetName,
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
}

@Native<Int32 Function(Int32, Int32)>()
external int SumPlus42(int a, int b);

void testFfiTestfunctionsDll() {
  final result2 = SumPlus42(2, 3);
  Expect.equals(2 + 3 + 42, result2);

  final ptr =
      Native.addressOf<NativeFunction<Int32 Function(Int32, Int32)>>(SumPlus42);
  final function = ptr.asFunction<int Function(int, int)>();
  Expect.equals(2 + 3 + 42, function(2, 3));
}
