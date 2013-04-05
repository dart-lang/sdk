// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that that the basic API for deferred/lazy loading works.  This
// test deliberately does not test that the deferred elements throw a
// NoSuchMethodError before the deferred library is loaded.  This
// makes it possible to pass this test without having implemented
// deferred loading correctly.

import "package:expect/expect.dart";
import 'dart:async';

@lazy
import 'deferred_api_library.dart';

const lazy = const DeferredLibrary('deferred_api_library');

main() {
  print('unittest-suite-wait-for-done');

  int counter = 0;
  lazy.load().then((bool didLoad) {
    Expect.isTrue(didLoad);
    Expect.equals(1, ++counter);
    Expect.equals(42, foo('b'));
    print('lazy was loaded');
  });
  Expect.equals(0, counter);
  lazy.load().then((bool didLoad) {
    Expect.isFalse(didLoad);
    Expect.equals(2, ++counter);
    Expect.equals(42, foo('b'));
    print('lazy was loaded');
    print('unittest-suite-success');
  });
  Expect.equals(0, counter);
}
