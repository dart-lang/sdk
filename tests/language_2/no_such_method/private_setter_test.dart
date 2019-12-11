// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'no_such_method_private_setter_lib.dart';

class Foo implements Bar {}

main() {
  baz(new Foo()); //# 01: runtime error
}
