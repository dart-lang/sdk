// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_add/native_add.dart';
import 'package:native_subtract/native_subtract.dart';

void main() {
  testNativeAdd();
  testNativeSubtract();
}

void testNativeAdd() {
  final answer = add(5, 6);
  if (answer != 5 + 6) {
    throw 'Wrong answer';
  }
  print('add(5, 6) = $answer');
}

void testNativeSubtract() {
  final answer = subtract(5, 6);
  if (answer != 5 - 6) {
    throw 'Wrong answer';
  }
  print('subtract(5, 6) = $answer');
}
