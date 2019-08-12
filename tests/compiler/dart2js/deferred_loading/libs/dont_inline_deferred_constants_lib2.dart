// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dont_inline_deferred_constants_main.dart" show C;
import "dont_inline_deferred_constants_main.dart" as main;

const C4 = "string4";

const C5 = const C(1);

const C6 = const C(2);

/*member: foo:OutputUnit(3, {lib2})*/
foo() {
  print("lib2");
  main.foo();
}
