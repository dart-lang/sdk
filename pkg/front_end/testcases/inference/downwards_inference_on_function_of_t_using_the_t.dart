// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  {
    T f<T>(T x) => null;
    var /*@type=f(T x) → T*/ v1 = f;
    v1 = /*@returnType=S*/ <S>(/*@type=S*/ x) => x;
  }
  {
    List<T> f<T>(T x) => null;
    var /*@type=f(T x) → List<T>*/ v2 = f;
    v2 = /*@returnType=List<S>*/ <S>(/*@type=S*/ x) => /*@typeArgs=S*/ [x];
    Iterable<int> r = /*@promotedType=none*/ v2(42);
    Iterable<String> s = /*@promotedType=none*/ v2('hello');
    Iterable<List<int>> t = /*@promotedType=none*/ v2(<int>[]);
    Iterable<num> u = /*@promotedType=none*/ v2(42);
    Iterable<num> v = /*@promotedType=none*/ v2<num>(42);
  }
}
