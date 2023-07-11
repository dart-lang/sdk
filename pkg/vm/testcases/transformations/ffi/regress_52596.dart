// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

class A implements Finalizable {}

void main() {
  // ignore: unused_local_variable
  A a;

  if (int.parse('1') == 1) {
    a = A();
  }

  if (int.parse('2') == 2) {
    print('hi');
    return;
  }

  a = A();
}
