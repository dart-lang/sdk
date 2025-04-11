// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

typedef SimpleAdditionType = Void Function(Int32, Int32);

void simpleAddition(int x, int y) {
  print("simpleAddition($x, $y)");
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    for (int i in [1, 2, 3]) {
      final result = Process.runSync(Platform.resolvedExecutable, [
        Platform.script.toFilePath(),
        '$i',
      ]);
      if (result.exitCode == 0) {
        throw 'Expected non-0 exit code: ${result.exitCode}';
      }
      if (!result.stderr.contains(
        'Cannot invoke native callback from a leaf call.',
      )) {
        throw "Expected stderr to contain 'Cannot invoke native callback from a leaf call.': ${result.stderr}";
      }
    }
    return;
  }
  final Pointer<NativeFunction<SimpleAdditionType>> callbackPointer;
  switch (arguments.single) {
    case "1":
      callbackPointer = Pointer.fromFunction<SimpleAdditionType>(
        simpleAddition,
      );
    case "2":
      callbackPointer = NativeCallable<SimpleAdditionType>.isolateLocal(
        simpleAddition,
      ).nativeFunction;
    case "3":
      callbackPointer = NativeCallable<SimpleAdditionType>.listener(
        simpleAddition,
      ).nativeFunction;
    default:
      throw "Unknown";
  }
  final function = callbackPointer.asFunction<void Function(int, int)>(
    isLeaf: true,
  );
  function(3, 4);
  print('We should have crashed by now.');
}
