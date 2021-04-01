// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  final baz = Foo<Null>().baz;
  Expect.equals("Baz<Bar<Null>?>", baz.runtimeType.toString());
  baz.v = baz.v;
}

class Bar<T> {}

class Foo<T> extends Quux<Bar<T>> {}

class Baz<T> {
  Baz(this.v);
  T v;
}

class Quux<T> {
  final baz = Baz<T?>(null);
}
