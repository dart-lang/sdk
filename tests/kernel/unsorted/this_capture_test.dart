// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  capture() {
    return () {
      return this;
    };
  }

  captureFirst(a, b) {
    return () {
      print(a);
      return this;
    };
  }

  captureLast(a, b) {
    return () {
      print(b);
      return this;
    };
  }
}

main() {
  var foo = new Foo();
  Expect.isTrue(identical(foo, (foo.capture())()));
  Expect.isTrue(identical(foo, (foo.captureFirst(1, 2))()));
  Expect.isTrue(identical(foo, (foo.captureLast(1, 2))()));
}
