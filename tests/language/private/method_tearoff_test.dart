// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'method_tearoff_lib.dart';

// `Bar' contains a private method `_f'. The function `baz' is declared in the
// same library as `Bar'. Given an subtype of `Bar', it tearoffs `_f' and
// returns a string representation of its runtime type. For this code to
// evaluate correctly, the generated Kernel code for `Foo' must contain a no
// such method forwarder for `_f'.

class Foo implements Bar {}

main() {
  Expect.equals("() => void", baz(new Foo()));
}
