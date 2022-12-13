// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reduction of https://github.com/flutter/flutter/issues/116405

import "package:expect/expect.dart";

class Foo {
  Foo(this.bar);
  Bar bar;
}

class Bar {
  int call(int x) => x * 2;
}

@pragma("vm:never-inline")
@pragma("dart2js:noInline")
int doCallThroughGetter(dynamic foo, int x) {
  return foo.bar(x);
}

void main() {
  Expect.equals(4, doCallThroughGetter(Foo(Bar()), 2));
}
