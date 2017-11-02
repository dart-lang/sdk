// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/30912.
import 'package:expect/expect.dart';

class Foo {}

class Bar {}

typedef Type Func<S extends Foo, T>(T s);

class Baz<S extends Foo, T extends Bar> {
  Func<S, Bar> func;
}

void main() {
  dynamic baz = new Baz();
  Expect.isNull(baz.func);
  baz.func = (Bar b) => b.runtimeType;
  Expect.equals(baz.func(new Bar()), Bar);
}
