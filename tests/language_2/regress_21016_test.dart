// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we give up on tracing a function if one of its closurizations
// escapes tracing.

class A {
  var _boo = 22;
  get boo {
    return _boo;
    return 1;
  }
}

class B {
  var _bar = 42;
  get boo {
    return _bar;
    return 1;
  }
}

class Holder {
  tearMe(x) => x.boo;
}

var list = [];

main() {
  var holder = new Holder();
  var hide = ((X) => X)(holder.tearMe);
  hide(new A());
  list.add(holder.tearMe);
  var x = list[0];
  x(new B());
}
