// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'package:smith/configuration.dart' show Architecture;

final _one = int.parse('1');
final _two = int.parse('2');

final _objects = [Object(), Architecture.x64, Architecture.arm];

final archX64 = _objects[_one];
final archArm = _objects[_two];

main() {
  // We get the normal `Architecture.toString()`
  Expect.equals('x64', archX64.toString());
  Expect.equals('arm', archArm.toString());
}
