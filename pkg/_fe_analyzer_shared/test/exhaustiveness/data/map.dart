// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

untypedMap(Map map) {
  var a = /*
   error=non-exhaustive:Map<dynamic, dynamic>,
   type=Map<dynamic, dynamic>
  */switch (map) {
    {} /*space=??*/=> 0,
    {1: _} /*space=??*/=> 1,
    [1: _, 2: _] /*space=??*/=> 2,
    [1: _, ..., _] /*space=??*/=> 3,
    {...} /*space=??*/=> 4:
  };
}

sealed class A {}
class B extends A {}
class C extends A {}

typedList(List<A> list) {
  var a = /*
   error=non-exhaustive:List<A>,
   type=List<A>
  */switch (list) {
    [] /*space=??*/=> 0,
    [B b] /*space=??*/=> 1,
    [C c] /*space=??*/=> 2,
    [_, _] /*space=??*/=> 3,
    [B b, ... _] /*space=??*/=> 4,
    [C c, ... _] /*space=??*/=> 5,
  };
}