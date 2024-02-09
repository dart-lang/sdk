// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/54128.
// Verifies that flow graph checker doesn't crash in debug mode
// after constant is propagated in the call argument but not its
// enviornment.

@pragma('vm:never-inline')
void foo(int port) {
  try {
    print('hi');
  } catch (e) {
    if (port != 0) rethrow;
    bar(port);
  }
}

@pragma('vm:never-inline')
void bar(int x) {
  print(x);
}

void main() {
  foo(int.parse('2'));
  bar(int.parse('3'));
}
