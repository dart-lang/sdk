// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class I {
  void call();
}

class C implements I {
  void call([int x]) {}
}

main() {
  I i = new C();
  // The implicit tear-off of i.call should be ok because its type (void
  // Function()) is a supertype of the expected type, hence it is assignable.
  void Function([int]) f = i;
  Expect.equals(f, i.call);
}
