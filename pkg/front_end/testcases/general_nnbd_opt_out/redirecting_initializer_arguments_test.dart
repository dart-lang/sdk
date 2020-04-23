// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// The test checks that types of arguments of redirecting initializers are
// checked against the corresponding formal parameter types of the redirection
// targets, and the compile-time error is emitted in the case they are not
// assignable.

class Foo<T> {
  T x;
  Foo.from(String _init) : this._internal(x: _init);
  Foo._internal({this.x});
}

void main() {}
