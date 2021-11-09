// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:expect/expect.dart';

main() async {
  // In the main isolate we don't want to throw.
  Foo.throwOnHashCode = false;

  final onError = ReceivePort()
    ..listen((error) {
      print('Child isolate error: $error');
    });
  final onExit = ReceivePort();
  var spawnError;
  try {
    await Isolate.spawn(
        other,
        // Rehashing of this map on receiver side will throw.
        {Foo(): 1},
        onError: onError.sendPort,
        onExit: onExit.sendPort);

    await onExit.first;
  } on IsolateSpawnException catch (error) {
    spawnError = error;
  } finally {
    onError.close();
    onExit.close();
  }
  Expect.contains(
      'Unable to spawn isolate: Failed to deserialize the passed arguments to the new isolate',
      '$spawnError');
}

class Foo {
  static bool throwOnHashCode = true;

  int get hashCode => throwOnHashCode ? (throw 'rehashing error') : 1;
}

other(message) {}
