// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

void main() {
  final (a, _) = b();
  print(a);
}

class A implements Finalizable {}

(A, bool) b() => (A(), true);
