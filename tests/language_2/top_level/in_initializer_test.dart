// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that constructor initializers can access top level elements.

const topLevelField = 1;
topLevelMethod() => 1;
get topLevelGetter {
  return 1;
}

class Foo {
  Foo.one() : x = topLevelField;
  Foo.second() : x = topLevelMethod;
  Foo.third() : x = topLevelGetter;
  var x;
}

main() {
  Expect.equals(topLevelField, new Foo.one().x);
  Expect.equals(topLevelMethod(), new Foo.second().x());
  Expect.equals(topLevelGetter, new Foo.third().x);
}
