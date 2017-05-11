// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  {
    T f<T>(T x) => null;
    var /*@type=(T) -> T*/ v1 = f;
    v1 = /*@returnType=S*/ <S>(/*@type=S*/ x) => /*@promotedType=none*/ x;
  }
  {
    List<T> f<T>(T x) => null;
    var /*@type=(T) -> List<T>*/ v2 = f;
    v2 = /*@returnType=List<S>*/ <S>(/*@type=S*/ x) => /*@typeArgs=S*/ [
          /*@promotedType=none*/ x
        ];
    Iterable<int> r = /*@promotedType=none*/ /*@typeArgs=int*/ v2(42);
    Iterable<String>
        s = /*@promotedType=none*/ /*@typeArgs=String*/ v2('hello');
    Iterable<List<int>>
        t = /*@promotedType=none*/ /*@typeArgs=List<int>*/ v2(<int>[]);
    Iterable<num> u = /*@promotedType=none*/ /*@typeArgs=num*/ v2(42);
    Iterable<num> v = /*@promotedType=none*/ v2<num>(42);
  }
}
