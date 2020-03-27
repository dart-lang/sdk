// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  {
    T f<T>(T x) => null;
    var /*@type=<T extends Object* = dynamic>(T*) ->* T**/ v1 = f;
    v1 = <S> /*@returnType=S**/ (/*@type=S**/ x) => x;
  }
  {
    List<T> f<T>(T x) => null;
    var /*@type=<T extends Object* = dynamic>(T*) ->* List<T*>**/ v2 = f;
    v2 = <S> /*@returnType=List<S*>**/
        (/*@type=S**/ x) => /*@typeArgs=S**/ [x];
    Iterable<int> r = v2 /*@typeArgs=int**/ (42);
    Iterable<String> s = v2 /*@typeArgs=String**/ ('hello');
    Iterable<List<int>> t = v2 /*@typeArgs=List<int*>**/ (<int>[]);
    Iterable<num> u = v2 /*@typeArgs=num**/ (42);
    Iterable<num> v = v2<num>(42);
  }
}
