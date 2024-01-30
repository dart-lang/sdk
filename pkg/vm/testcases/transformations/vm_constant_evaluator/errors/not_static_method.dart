// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that annotating a non-static method fails.

class A {
  @pragma("vm:platform-const")
  bool get isA => true;
}

void main() => null;
