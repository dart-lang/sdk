// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type PrivateInlineClass(int _it) {
  void test() {
    var a1 = this._it;
    var a2 = _it;
    var b1 = this._it<int>; // Error
    var b2 = _it<int>; // Error
    var c1 = this._it = 42; // Error, should not resolve to extension method.
    var c2 = _it = 42; // Error, should not resolve to extension method.
  }
}
