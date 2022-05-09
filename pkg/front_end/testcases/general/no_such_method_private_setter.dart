// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import './no_such_method_private_setter_lib.dart';

// `Bar' contains a private setter `_x'. The generated Kernel code for `Foo'
// should contain a no such method forwarder for `_x'.

class Foo implements Bar {}

main() {
  baz(new Foo());
}
