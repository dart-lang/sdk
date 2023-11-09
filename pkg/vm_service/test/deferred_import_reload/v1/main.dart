// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'deferred.dart' deferred as prefix1;
import 'deferred.dart' deferred as prefix2;

Future<void> main(List<String> args, SendPort port) async {
  await prefix1.loadLibrary();
  // Notify the spawner that we've finished loading the library.
  port.send(null);
  RawReceivePort _ = RawReceivePort();
  print('spawned isolate running');
}

String test() {
  String x = '';

  try {
    x += prefix1.foo(); // Should retain loaded=true state across reload.
  } catch (e, st) {
    print(e);
    print(st);
    x += 'error';
  }

  x += ',';

  try {
    x += prefix2.foo(); // Should retain loaded=false state across reload.
  } catch (e, st) {
    print(e);
    print(st);
    x += 'error';
  }

  return x;
}
