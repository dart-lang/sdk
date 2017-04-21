// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a class with a [call] property does not implement [Function] or
// a typedef of function type.

import 'package:expect/expect.dart';

class Call {
  int get call => 0;
}

typedef void F();

main() {
  Expect.isFalse(new Call() is Function);
  Expect.isFalse(new Call() is F);
}
