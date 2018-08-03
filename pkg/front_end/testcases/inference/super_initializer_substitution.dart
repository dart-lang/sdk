// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

class B<T> {
  B(T t);
}

class C<U> extends B<List<U>> {
  C() : super(/*@typeArgs=List<C::U>*/ f());
}

main() {}
