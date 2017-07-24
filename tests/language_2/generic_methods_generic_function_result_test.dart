// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--generic-method-syntax,--error-on-bad-type

// Verify that function type parameter S can be resolved in bar's result type.
// Verify that generic function types are not allowed as type arguments.

import "package:expect/expect.dart";

int foo
       <T>  //# 01: continued
          (int i, int j) => i + j;

List<int Function
                 <T>  //# 01: compile-time error
                    (S, int)> bar<S extends int>() {
  return <int Function
                      <T>  //# 01: continued
                         (S, int)>[foo, foo];
}

void main() {
  var list = bar<int>();
  print(list[0].runtimeType);
  Expect.equals(123, list[1]<int>(100, 23));
}
