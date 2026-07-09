// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks how programs with Never type in their outline compile.

Never foo() {
  while (true) {}
}

Never? bar() => null;

main() {}
