// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that partially instantiated generic function remains instantiated
// after received via ReceivePort.

import 'dart:isolate';
import 'package:expect/expect.dart';
import 'package:async_helper/async_minitest.dart';

// Prevent obfuscation.
@pragma('vm:entry-point')
class Dog {}

// Prevent obfuscation.
@pragma('vm:entry-point')
List<T> decodeFrom<T>(String s) {
  return List();
}

// Prevent obfuscation.
@pragma('vm:entry-point')
List<Dog> Function(String s) decodeFromDog = decodeFrom;

void main() async {
  final receivePort = ReceivePort();
  receivePort.listen(expectAsync1((data) {
    print("Received $data");
    Expect.equals('$data',
        "[Closure: (String) => List<Dog> from Function 'decodeFrom': static.]");
    receivePort.close();
  }));
  print("Sending $decodeFromDog");
  receivePort.sendPort.send(<dynamic>[decodeFromDog]);
}
