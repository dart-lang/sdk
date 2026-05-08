// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  Object? method() => null;
}

class Box {
  int? value;
}

mixin M on A {
  final Box _box = Box();

  @override
  Object? method() => _Result(this);
}

class _Result {
  _Result(M arg) {
    arg._box.value = 1;
  }
}

Object? foo(A b) {
  return b.method();
}
