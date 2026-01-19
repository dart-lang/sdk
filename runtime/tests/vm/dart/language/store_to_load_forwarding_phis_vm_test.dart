// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct handling of phis with only environment uses that were inserted
// by store to load forwarding.
// VMOptions=--optimization_counter_threshold=100 --no-background_compilation

library store_to_load_forwarding_phis_vm_test;

import 'dart:async';

class A {
  var _foo;

  get foo {
    if (_foo == null) {
      _foo = new A();
    }
    return _foo;
  }
}

foo(obj) {
  var a = obj.foo;
  return new Future.value().then((val) {});
}

main() {
  final obj = new A();
  for (var i = 0; i < 200; i++) {
    foo(obj);
  }
}
