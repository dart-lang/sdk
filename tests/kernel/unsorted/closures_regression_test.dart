// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

f(fun) => fun();

class A {
  identity(arg) {
    return f(() {
      print(this);
      return f(() {
        return this;
      });
    });
  }
}

main() {
  var a = new A();
  Expect.isTrue(identical(a.identity(42), a));
}
