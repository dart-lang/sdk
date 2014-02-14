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
  T field = 42;
}

class C<T> {
  T field = 42;
}

main() {
  var a = new A<String>();
  var c = new C<int>();
  if (inCheckedMode) {
    Expect.throws(() => a.field = 42, (e) => e is TypeError);
    Expect.throws(() => new B<String>(), (e) => e is TypeError);
    Expect.throws(() => c.field = 'foo', (e) => e is TypeError);
  } else {
    a.field = 42;
    new B<String>();
    c.field = 'foo';
  }
}
