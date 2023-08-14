// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow sealed classes to be extended by multiple classes in the same library.
// Additionally, allow their subclasses/subtypes to be used freely.

import "package:expect/expect.dart";
import 'sealed_class_extend_lib.dart';

class AExtends extends A {
  int foo = 0;
  int bar(int value) => value;
}

class AImplements implements A {
  int nonAbstractFoo = 0;
  int foo = 0;
  int bar(int value) => value;
  int nonAbstractBar(int value) => value;
}

main() {
  A a = AImpl();
  Expect.equals(0, a.nonAbstractFoo);
  Expect.equals(1, a.foo);
  Expect.equals(3, a.bar(2));
  Expect.equals(100, a.nonAbstractBar(0));

  var b = B();
  Expect.equals(100, b.nonAbstractFoo);
  Expect.equals(2, b.foo);
  Expect.equals(2, b.bar(2));
  Expect.equals(100, b.nonAbstractBar(0));

  var aExtends = AExtends();
  Expect.equals(0, aExtends.nonAbstractFoo);
  Expect.equals(0, aExtends.foo);
  Expect.equals(0, aExtends.bar(0));
  Expect.equals(100, aExtends.nonAbstractBar(0));

  var aImplements = AImplements();
  Expect.equals(0, aImplements.nonAbstractFoo);
  Expect.equals(0, aImplements.foo);
  Expect.equals(0, aImplements.bar(0));
  Expect.equals(0, aImplements.nonAbstractBar(0));
}
