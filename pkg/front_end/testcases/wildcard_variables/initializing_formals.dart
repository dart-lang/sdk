// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int _;
  A(this._) {
    print(_);
  }
}

class InitializerListError {
  final int _;
  final int x;
  InitializerListError(this._) : x = _; // Error. `_` in initializer list.
}

class MultipleThisError {
  final int _;
  MultipleThisError(this._, this._); // Error. Multiple `this._`.
}

class B {
  final int _, v, w;
  B(this._, this.v, this.w);
}

class C extends B {
  final int z;
  C(super.x, super._, super._, this.z)
      : assert(x > 0),
        assert(_ >= 0) // Error: no `_` in scope.
  {
    print(_); // OK, means `this._` and refers to `A._`.
  }
}

main() {
  A(1);
  InitializerListError(1);
  MultipleThisError(1, 2);
  C(1, 2, 3, 4);
}
