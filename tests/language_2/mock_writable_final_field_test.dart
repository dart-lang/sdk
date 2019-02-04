// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final values = <int>[];

class Mock {
  noSuchMethod(Invocation i) {
    var expected = i.isGetter ? #x : const Symbol("x=");
    Expect.equals(expected.toString(), i.memberName.toString());
    values.add(i.positionalArguments[0]);
  }
}

class Foo {
  // Prevent obfuscation of 'x'.
  @pragma("vm:entry-point")
  int x;
}

class Bar extends Mock implements Foo {
  final int x = 42;
}

void main() {
  {
    Bar b = new Bar();
    Expect.equals(b.x, 42);
    b.x = 123;
    Expect.listEquals([123], values);
    values.clear();
  }
  {
    // It works the same if called statically through the Foo interface.
    Foo b = new Bar();
    Expect.equals(b.x, 42);
    b.x = 123;
    Expect.listEquals([123], values);
    values.clear();
  }
}
