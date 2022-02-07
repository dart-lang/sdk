// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

void main() {
  testWeakReference();
}

class Nonce {
  final int value;

  Nonce(this.value);

  String toString() => 'Nonce($value)';
}

void testWeakReference() async {
  final weakRef = () {
    final object = Nonce(23);
    final weakRef = WeakReference(object);
    // Left to right argument evaluation: evaluate weakRef.target first.
    Expect.equals(weakRef.target, object);
    return weakRef;
  }();

  print('do gc');
  triggerGc();
  await Future.delayed(Duration(milliseconds: 1));
  triggerGc();
  await Future.delayed(Duration(milliseconds: 1));
  triggerGc();
  await Future.delayed(Duration(milliseconds: 1));
  triggerGc();

  // The weak reference should not target anything anymore.
  Expect.isNull(weakRef.target);

  print('End of test, shutting down.');
}

final void Function() triggerGc = () {
  String _platformPath(String name, {String? path}) {
    if (path == null) path = "";
    if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia)
      return path + "lib" + name + ".so";
    if (Platform.isMacOS) return path + "lib" + name + ".dylib";
    if (Platform.isWindows) return path + name + ".dll";
    throw Exception("Platform not implemented");
  }

  DynamicLibrary dlopenPlatformSpecific(String name, {String? path}) {
    String fullPath = _platformPath(name, path: path);
    return DynamicLibrary.open(fullPath);
  }

  final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

  return ffiTestFunctions
      .lookupFunction<Void Function(), void Function()>("TriggerGC");
}();
