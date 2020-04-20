// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that types of arguments of redirecting initializers are
// checked against the corresponding formal parameter types of the redirection
// targets, and the downcasts are inserted where appropriate.

class X {}

class Foo<T extends X> {
  T x;
  Foo.fromX(X _init) : this._internal(x: _init);
  Foo.fromT(T _init) : this._internal(x: _init);
  Foo._internal({this.x});
}

void main() {}
