// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library firstClassLibrariestest;

import "package:expect/expect.dart";
import 'first_class_types_lib1.dart' as lib1;
import 'first_class_types_lib2.dart' as lib2;

class C<X> {}

sameType(a, b) {
  Expect.equals(a.runtimeType, b.runtimeType);
}

differentType(a, b) {
  Expect.notEquals(a.runtimeType, b.runtimeType);
}

main() {
  sameType(new lib1.A(), new lib1.A());
  differentType(new lib1.A(), new lib2.A());
  differentType(new C<lib1.A>(), new C<lib2.A>());
}
