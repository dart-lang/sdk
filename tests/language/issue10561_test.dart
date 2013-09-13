// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to miscompile classes
// extending HashMap, because HashMap is patched.

import "package:expect/expect.dart";

import 'dart:collection';

class Foo extends HashSet {
}

main() {
  Expect.equals(0, new Foo().length);
}
