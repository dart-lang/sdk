// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

@lazy import 'deferred_class_library.dart';

const lazy = const DeferredLibrary('deferred_class_library');

main() {
  var x;
  Expect.throws(() => const MyClass());
  Expect.throws(() => const Constant(42));
  Expect.throws(() => const [const Constant(42)]);
  int counter = 0;
  asyncStart();
  lazy.load().then((bool didLoad) {
    Expect.isTrue(didLoad);
    Expect.equals(1, ++counter);
    print('deferred_class_library was loaded');
    x = const MyClass();
    Expect.equals(42, x.foo(87));
    Expect.listEquals(const [const Constant(42)], [new Constant(42)]);
    asyncEnd();
  });
  Expect.equals(0, counter);
  Expect.isNull(x);
  asyncStart();
  lazy.load().then((bool didLoad) {
    Expect.isFalse(didLoad);
    Expect.equals(2, ++counter);
    print('deferred_class_library was loaded');
    x = const MyClass();
    Expect.equals(42, x.foo(87));
    Expect.listEquals(const [const Constant(42)], [new Constant(42)]);
    asyncEnd();
  });
  Expect.equals(0, counter);
  Expect.isNull(x);
  Expect.throws(() => const Constant(42));
  Expect.throws(() => const [const Constant(42)]);
  Expect.isNull(x);
}
