// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that otherwise uninstantiated classes can be instantiated
// reflectively.

import "dart:mirrors";

class Foo {
  int a;
}

main() {
  // Do NOT instantiate Foo.
  var m = reflectClass(Foo);
  var instance = m.newInstance(const Symbol(''), []);
  print(instance);
  bool threw = false;
  try {
    m.newInstance(#noSuchConstructor, []);
    throw 'Expected an exception';
  } on NoSuchMethodError catch (e) {
    print(e);
    threw = true;
  }
  if (!threw) throw 'Expected a NoSuchMethodError';
}
