// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// It is a compile-time error if a named formal parameter begins with an '_'

class Foo {
  num _y;
  Foo.optional_private({this._y: 77}) {}
}

main() {
  var obj;
  obj = new Foo.optional_private(_y: 222);
  Expect.equals(222, obj._y);

  obj = new Foo.optional_private();
  Expect.equals(77, obj._y);
}
