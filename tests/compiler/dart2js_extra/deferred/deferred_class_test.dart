// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

import 'deferred_class_library.dart' deferred as lib;

isError(e) => e is Error;

main() {
  var x;
  Expect.throws(() { x = new lib.MyClass(); }, isError);
  Expect.isNull(x);
  int counter = 0;
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals(1, ++counter);
    print('deferred_class_library was loaded');
    x = new lib.MyClass();
    Expect.equals(42, x.foo(87));
    asyncEnd();
  });
  Expect.equals(0, counter);
  Expect.isNull(x);
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals(2, ++counter);
    print('deferred_class_library was loaded');
    x = new lib.MyClass();
    Expect.equals(42, x.foo(87));
    asyncEnd();
  });
  Expect.equals(0, counter);
  Expect.isNull(x);
  Expect.throws(() { x = new lib.MyClass(); }, isError);
  Expect.isNull(x);
}
