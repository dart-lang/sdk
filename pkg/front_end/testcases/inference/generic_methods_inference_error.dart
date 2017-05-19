// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void f() {
  List<String> y;
  Iterable<String> x = y. /*@typeArgs=String*/ /*@target=Iterable::map*/ map(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ /*@returnType=double*/ (String
              z) =>
          1.0);
}

main() {}
