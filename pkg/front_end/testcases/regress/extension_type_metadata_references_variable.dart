// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Foo._(int _x) {
  Foo(this._x, int bar){
    @bar
    int a1, a2;
  }
}
