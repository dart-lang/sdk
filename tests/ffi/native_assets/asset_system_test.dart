// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test compiles itself with gen_kernel and invokes the compiled kernel
// file with `Process.run(dart, <...>)` and `Isolate.spawn` and
// `Isolate.spawnUri`.
//
// This tests test including a native asset mapping with resolved on the system
// path.

// OtherResources=asset_system_test.dart
// OtherResources=helpers.dart

// ignore_for_file: deprecated_member_use

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

const asset2Name = 'myAsset';

Future<void> selfInvokes() async {
  final selfSourceUri = Platform.script.resolve('asset_system_test.dart');
  final assetMapping = [
    'system',
    Platform.isWindows
        ? 'ole32.dll'
        : (Platform.isMacOS || Platform.isIOS)
            ? 'libc.dylib'
            : 'libc.so.6', // lib.so contains plain text with GROUP( ... ).
  ];
  final nativeAssetsYaml = createNativeAssetYaml(
    asset: selfSourceUri.toString(),
    assetMapping: assetMapping,
    asset2: asset2Name,
    asset2Mapping: assetMapping,
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
    protobufAwareTreeshaking: true,
  );
}

Future<void> runTests() async {
  testProcessOrSystem();
  testProcessOrSystemViaAddressOf();
  testNonExistingFunction();
}

@Native<Pointer Function(IntPtr)>()
external Pointer malloc(int size);

@Native<Void Function(Pointer)>(assetId: asset2Name)
external void free(Pointer pointer);

@Native<Pointer Function(Size)>()
external Pointer CoTaskMemAlloc(int cb);

@Native<Void Function(Pointer)>(assetId: asset2Name)
external void CoTaskMemFree(Pointer pv);

void testProcessOrSystem() {
  if (Platform.isWindows) {
    final pointer2 = CoTaskMemAlloc(8);
    Expect.notEquals(nullptr, pointer2);
    CoTaskMemFree(pointer2);
  } else {
    final pointer2 = malloc(8);
    Expect.notEquals(nullptr, pointer2);
    free(pointer2);
  }
}

void testProcessOrSystemViaAddressOf() {
  if (Platform.isWindows) {
    final memAlloc =
        Native.addressOf<NativeFunction<Pointer Function(Size)>>(CoTaskMemAlloc)
            .asFunction<Pointer Function(int)>();
    final memFree =
        Native.addressOf<NativeFunction<Void Function(Pointer)>>(CoTaskMemFree)
            .asFunction<void Function(Pointer)>();

    final pointer = memAlloc(8);
    Expect.notEquals(nullptr, pointer);
    memFree(pointer);
  } else {
    final mallocViaAddrOf =
        Native.addressOf<NativeFunction<Pointer Function(IntPtr)>>(malloc)
            .asFunction<Pointer Function(int)>();
    final freeViaAddrOf =
        Native.addressOf<NativeFunction<Void Function(Pointer)>>(free)
            .asFunction<void Function(Pointer)>();

    final pointer = mallocViaAddrOf(8);
    Expect.notEquals(nullptr, pointer);
    freeViaAddrOf(pointer);
  }
}
