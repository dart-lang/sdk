// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

abstract class A {
  m(x);
}

class B implements A {
  noSuchMethod(Invocation i) {
    print("nsm call: ${i.memberName}");
    if (i.isGetter) {
      throw (" - tearoff");
    }
    if (i.isMethod) {
      print(" - method invocation");
      return 42;
    }
    return 123;
  }
}

void main() {
  A x = new B();
  var tearoff = x.m;
  Expect.equals(42, tearoff(3));
}
