/*
 * Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

// 'covariant' when used incorrectly should report an error and not crash
// the VM.

typedef bool Test(covariant num arg); //# none: compile-time error

void main() {
  Test t = (int value) => false;
}
