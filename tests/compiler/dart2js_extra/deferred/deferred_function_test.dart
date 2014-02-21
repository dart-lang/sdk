// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that loading of a library (with top-level functions only) can
// be deferred.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

@lazy import 'deferred_function_library.dart' as lib;

const lazy = const DeferredLibrary('deferred_function_library');

isNoSuchMethodError(e) => e is NoSuchMethodError;

readFoo() {
  // TODO(ahe): There is a problem with type inference of deferred
  // function closures.  We think they are never null.
  if (new DateTime.now().millisecondsSinceEpoch == 87) return null;
  return lib.foo;
}

main() {
  Expect.throws(() { lib.foo('a'); }, isNoSuchMethodError);
  Expect.throws(readFoo, isNoSuchMethodError);
  int counter = 0;
  asyncStart();
  lazy.load().then((bool didLoad) {
    Expect.isTrue(didLoad);
    Expect.equals(1, ++counter);
    print('lazy was loaded');
    Expect.equals(42, lib.foo('b'));
    Expect.isNotNull(readFoo());
    asyncEnd();
  });
  Expect.equals(0, counter);
  asyncStart();
  lazy.load().then((bool didLoad) {
    Expect.isFalse(didLoad);
    Expect.equals(2, ++counter);
    print('lazy was loaded');
    Expect.equals(42, lib.foo('b'));
    Expect.isNotNull(readFoo());
    asyncEnd();
  });
  Expect.equals(0, counter);
  Expect.throws(() { lib.foo('a'); }, isNoSuchMethodError);
  Expect.throws(readFoo, isNoSuchMethodError);
}
