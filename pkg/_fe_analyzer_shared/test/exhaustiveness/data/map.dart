// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

untypedMap(Map map) {
  var a = /*cfe.
   error=non-exhaustive:Map<dynamic, dynamic>,
   fields={entries:Iterable<MapEntry<dynamic, dynamic>>,hashCode:int,isEmpty:bool,isNotEmpty:bool,keys:Iterable<dynamic>,length:int,runtimeType:Type,values:Iterable<dynamic>},
   type=Map<dynamic, dynamic>
  *//*analyzer.
   error=non-exhaustive:Map<dynamic, dynamic>,
   fields={hashCode:int,isEmpty:bool,isNotEmpty:bool,keys:Iterable<dynamic>,length:int,runtimeType:Type,values:Iterable<dynamic>},
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
  var a = /*cfe.
   error=non-exhaustive:List<A>,
   fields={first:A,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<A>,last:A,length:int,reversed:Iterable<A>,runtimeType:Type,single:A},
   type=List<A>
  *//*analyzer.
   error=non-exhaustive:List<A>,
   fields={first:A,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<A>,last:A,length:int,runtimeType:Type},
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