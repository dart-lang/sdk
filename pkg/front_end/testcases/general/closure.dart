// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var _field = new Bar();
}

class Bar {}

useCallback(callback) {
  var _ = callback();
}

main() {
  var x;
  inner() {
    x = new Foo();
    return new Foo();
  }

  useCallback(inner);
  var _ = inner()._field;
}
