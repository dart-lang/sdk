// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  {
    T f<T>(T x) => null;
    var /*@type=<T extends Object>(main::f::T) -> main::f::T*/ v1 = f;
    v1 = <S> /*@returnType=main::::S*/ (/*@type=main::::S*/ x) => x;
  }
  {
    List<T> f<T>(T x) => null;
    var /*@type=<T extends Object>(main::f::T) -> List<main::f::T>*/ v2 = f;
    v2 = <S> /*@returnType=List<main::::S>*/
        (/*@type=main::::S*/ x) => /*@typeArgs=main::::S*/ [x];
    Iterable<int> r = /*@typeArgs=int*/ v2(42);
    Iterable<String> s = /*@typeArgs=String*/ v2('hello');
    Iterable<List<int>> t = /*@typeArgs=List<int>*/ v2(<int>[]);
    Iterable<num> u = /*@typeArgs=num*/ v2(42);
    Iterable<num> v = v2<num>(42);
  }
}
