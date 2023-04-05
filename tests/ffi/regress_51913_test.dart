// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

// Should have been `@Native<Void Function()>` or something.
@Native() //# 1: compile-time error
external void foo(); //# 1: compile-time error

void main() {
  print('something');
}
