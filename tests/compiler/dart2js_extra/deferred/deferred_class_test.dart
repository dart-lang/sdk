// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';

@lazy import 'deferred_class_library.dart';

const lazy = const DeferredLibrary('deferred_class_library');

isNoSuchMethodError(e) => e is NoSuchMethodError;

main() {
  var x;
  Expect.throws(() { x = new MyClass(); }, isNoSuchMethodError);
  Expect.isNull(x);
  int counter = 0;
  lazy.load().then((bool didLoad) {
    Expect.isTrue(didLoad);
    Expect.equals(1, ++counter);
    print('deferred_class_library was loaded');
    x = new MyClass();
    Expect.equals(42, x.foo(87));
  });
  Expect.equals(0, counter);
  Expect.isNull(x);
  lazy.load().then((bool didLoad) {
    Expect.isFalse(didLoad);
    Expect.equals(2, ++counter);
    print('deferred_class_library was loaded');
    x = new MyClass();
    Expect.equals(42, x.foo(87));
  });
  Expect.equals(0, counter);
  Expect.isNull(x);
  Expect.throws(() { x = new MyClass(); }, isNoSuchMethodError);
  Expect.isNull(x);
}
