// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that interface type variable usage in is checks is recursively
// detected, even if the interface is nested in a record type. Check
// both a user defined class as well as List because at -O3 we
// initialize the type parameters differently for Lists.

import "package:expect/expect.dart";

class Foo<T> {}

dynamic wrapInRecord(x) => (x,);

void main() {
  Expect.isTrue(wrapInRecord(Foo<int>()) is (Foo<int>,));
  Expect.isTrue(wrapInRecord(<int>[]) is (List<int>,));
  Expect.isTrue((<int>[],) is (List<int>,));
  Expect.isTrue((Foo<int>(),) is (Foo<int>,));
}
