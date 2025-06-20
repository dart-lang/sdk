// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo<T extends num> {}

main() {
  var a = new Foo();
  var b = Foo;
  Expect.equals(a.runtimeType, b);

  var runtimeTypeToString = "${a.runtimeType}";
  var typeLiteralToString = "${b}";
  Expect.equals(runtimeTypeToString, typeLiteralToString);

  if (!runtimeTypeToString.contains('minified:')) {
    Expect.equals("Foo<num>", runtimeTypeToString);
    Expect.equals("Foo<num>", typeLiteralToString);
  }
  print(runtimeTypeToString);
  print(typeLiteralToString);
}
