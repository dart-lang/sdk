// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './public_method_tearoff_lib.dart';

// `Bar' contains a public method `f'. The function `baz' is declared in the
// same library as `Bar' and attempts to invoke `f`. The generated Kernel code
// for `Foo' should _not_ contain a no such method forwarder for `f'.

class Foo extends Bar {}

void main() {
  baz(new Foo());
}
