// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that annotating a getter that cannot be evaluated to a constant fails.

late List<String> args;

@pragma("vm:platform-const")
bool get notConstant => args.isEmpty;

void main(List<String> a) {
  args = a;
}
