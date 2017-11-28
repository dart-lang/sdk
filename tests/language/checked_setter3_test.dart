// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bool get inCheckedMode {
  try {
    var i = 42;
    String a = i;
  } catch (e) {
    return true;
  }
  return false;
}

class A<T> {
  T field;
}

class B<T> {
  T field = 42; //# 01: static type warning
}

class C<T> {
  T field = 42; //# 02: static type warning
}

main() {
  var a = new A<String>();
  var c = new C<int>();
  var i = 42;
  var s = 'foo';
  if (inCheckedMode) {
    Expect.throws(() => a.field = i, (e) => e is TypeError);
    Expect.throws(() => new B<String>(), (e) => e is TypeError); //# 01: continued
    Expect.throws(() => c.field = s, (e) => e is TypeError); //# 02: continued
  } else {
    a.field = i;
    new B<String>(); //# 01: continued
    c.field = s; //# 02: continued
  }
}
