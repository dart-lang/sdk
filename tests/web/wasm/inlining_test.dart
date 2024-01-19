// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that dart2wasm doesn't recursively inline.

import 'package:expect/expect.dart';

class Widget {
  final List<Widget> _children;

  @pragma("wasm:prefer-inline")
  Widget(int numChildren)
      : _children = [
          for (var i = 0; i < numChildren; i++) Widget(0),
        ];
}

@pragma("wasm:prefer-inline")
int fib(int n) {
  if (n == 0) {
    return 0;
  } else if (n == 1) {
    return 1;
  } else {
    return fib(n - 1) + fib(n - 2);
  }
}

void main() {
  final widget = Widget(10);
  Expect.equals(widget._children.length, 10);
  Expect.equals(fib(5), 5);
}
