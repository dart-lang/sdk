// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no-enable-fast-object-copy
// VMOptions=--enable-fast-object-copy
// VMOptions=--no-enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation
// VMOptions=--enable-fast-object-copy --gc-on-foc-slow-path --force-evacuation

// The tests in this file will only succeed when isolate groups are enabled
// (hence the VMOptions above).

import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'fast_object_copy_test.dart' show ClassWithNativeFields;

class HashThrower {
  static bool throwOnHashCode = true;

  const HashThrower();

  int get hashCode => throwOnHashCode ? throw 'failing' : 2;
  bool operator ==(other) => identical(this, other);
}

Future testWithClosure<T>(
    void Function(SendPort) entrypoint, T expectedResult) async {
  final rp = ReceivePort();
  try {
    await Isolate.spawn(entrypoint, rp.sendPort);
    Expect.equals(expectedResult, await rp.first);
  } finally {
    rp.close();
  }
}

class ClosureEntrypointTester {
  int instanceValue = 42;

  void send42(SendPort sendPort) => sendPort.send(42);

  Future run() async {
    await noCapturedVariablesTest();
    await capturedInt();
    await capturedInstanceInt();
    await captureThisViaMethodTearOff();
    await captureInvalidObject();
    await captureRehashThrower();
  }

  Future noCapturedVariablesTest() async {
    print('noCapturedVariablesTest');
    await testWithClosure((SendPort s) => s.send(42), 42);
  }

  Future capturedInt() async {
    print('capturedInt');
    int value = 42;
    await testWithClosure((SendPort s) => s.send(value), 42);
  }

  Future capturedInstanceInt() async {
    print('capturedInstanceValue');
    await testWithClosure((SendPort s) => s.send(this.instanceValue), 42);
  }

  Future captureThisViaMethodTearOff() async {
    print('captureThisViaMethodTearOff');
    await testWithClosure(send42, 42);
  }

  Future captureInvalidObject() async {
    print('captureInvalidObject');
    final invalidObject = ClassWithNativeFields();
    send42(SendPort sendPort) {
      '$invalidObject'; // Use an object that cannot be copied.
      sendPort.send(42);
    }

    throwsAsync<ArgumentError>(() => testWithClosure(send42, 42));
  }

  Future captureRehashThrower() async {
    print('captureRehashThrower');
    HashThrower.throwOnHashCode = false;
    final hashThrower = {HashThrower()};
    send42(SendPort sendPort) {
      '$hashThrower'; // Use an object that cannot be deserialized.
      sendPort.send(42);
    }

    throwsAsync<IsolateSpawnException>(() => testWithClosure(send42, 42));
  }

  Future throwsAsync<T>(Future Function() fun) async {
    try {
      await fun();
    } catch (e) {
      if (e is T) return;
      rethrow;
    }
    throw 'Function failed to throw ArgumentError';
  }
}

main() async {
  await ClosureEntrypointTester().run();
}
