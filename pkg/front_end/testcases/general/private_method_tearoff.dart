// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './private_method_tearoff_lib.dart';

// `Bar' contains a private method `_f'. The function `baz' is declared in the
// same library as `Bar' and attempts to invoke `_f`. The generated Kernel code
// for `Foo' should contain a no such method forwarder for `_f'.

class Foo implements Bar {}

class Baz extends Foo {}

main() {
  baz(new Foo());
}
