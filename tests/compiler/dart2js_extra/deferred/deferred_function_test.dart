// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that loading of a library (with top-level functions only) can
// be deferred.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'deferred_function_library.dart' deferred as lib;

isError(e) => e is Error;

readFoo() {
  return lib.foo;
}

main() {
  Expect.throws(() { lib.foo('a'); }, isError);
  Expect.throws(readFoo, isError);
  int counter = 0;
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals(1, ++counter);
    print('lazy was loaded');
    Expect.equals(42, lib.foo('b'));
    Expect.isNotNull(readFoo());
    asyncEnd();
  });
  Expect.equals(0, counter);
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals(2, ++counter);
    print('lazy was loaded');
    Expect.equals(42, lib.foo('b'));
    Expect.isNotNull(readFoo());
    asyncEnd();
  });
  Expect.equals(0, counter);
  Expect.throws(() { lib.foo('a'); }, isError);
  Expect.throws(readFoo, isError);
}
