// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef void ToValue<T>(T value);

test() {
  ToValue<T> f<T>(T x) => throw '';
  var /*@type=(int) -> void*/ x = f<int>(42);
  var /*@type=(int) -> void*/ y = f /*@typeArgs=int*/ (42);
  ToValue<int> takesInt = x;
  takesInt = y;
}
