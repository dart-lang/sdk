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
import 'dart:convert';
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
  testFfiTestfunctionsDll();
  testFfiTestFieldsDll();
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

@Native<Int32>()
external int globalInt;

@Native<Int32>(symbol: 'globalInt')
external int get globalIntProcedure;

@Native<Int32>(symbol: 'globalInt')
external set globalIntProcedure(int value);

@Native<Void Function(Int32)>()
external void SetGlobalVar(int value);

@Native<Int32 Function()>()
external int GetGlobalVar();

@Native()
external final Pointer<Char> globalString;

final class Coord extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  external Pointer<Coord> next;
}

@Native()
external Coord globalStruct;

@Native<Coord Function()>()
external Coord GetGlobalStruct();

@Native()
@Array(3)
external Array<Int> globalArray;

@Native()
@Array(3, 3)
external final Array<Array<Double>> identity3x3;

void testFfiTestFieldsDll() {
  SetGlobalVar(42);
  Expect.equals(globalInt, 42);
  Expect.equals(globalIntProcedure, 42);
  globalInt = 13;
  Expect.equals(GetGlobalVar(), 13);
  globalIntProcedure = 26;
  Expect.equals(GetGlobalVar(), 26);

  var readString = utf8.decode(globalString.cast<Uint8>().asTypedList(11));
  Expect.equals(readString, 'Hello Dart!');

  globalStruct
    ..x = 1
    ..y = 2
    ..next = nullptr;
  final viaFunction = GetGlobalStruct();
  Expect.equals(viaFunction.x, 1.0);
  Expect.equals(viaFunction.y, 2.0);
  Expect.equals(viaFunction.next, nullptr);

  viaFunction.x *= 2;
  viaFunction.y *= 2;
  viaFunction.next = Pointer.fromAddress(0xdeadbeef);
  globalStruct = viaFunction;

  Expect.equals(globalStruct.x, 2.0);
  Expect.equals(globalStruct.y, 4.0);
  Expect.equals(globalStruct.next.address, 0xdeadbeef);

  Expect.equals(globalArray[0], 1);
  Expect.equals(globalArray[1], 2);
  Expect.equals(globalArray[2], 3);

  globalArray[0] = 42;
  Expect.equals(globalArray[0], 42);
  globalArray[0] = 1;

  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 3; j++) {
      if (i == j) {
        Expect.equals(identity3x3[i][j], 1);
      } else {
        Expect.equals(identity3x3[i][j], 0);
      }
    }
  }
}
