// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

untypedList(List list) {
  var a = /*cfe.
   error=non-exhaustive:List<dynamic>,
   fields={first:Object?,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<dynamic>,last:Object?,length:int,reversed:Iterable<dynamic>,runtimeType:Type,single:Object?},
   type=List<dynamic>
  *//*analyzer.
   error=non-exhaustive:List<dynamic>,
   fields={first:Object?,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<dynamic>,last:Object?,length:int,runtimeType:Type},
   type=List<dynamic>
  */switch (list) {
    [] /*space=??*/=> 0,
    [_] /*space=??*/=> 1,
    [_, _] /*space=??*/=> 2,
    [_, ..., _] /*space=??*/=> 3,
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
    [B b, ..., _] /*space=??*/=> 4,
    [C c, ..., _] /*space=??*/=> 5,
  };
}

restWithSubpattern(List list) {
  var a = /*cfe.
   error=non-exhaustive:List<dynamic>,
   fields={first:Object?,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<dynamic>,last:Object?,length:int,reversed:Iterable<dynamic>,runtimeType:Type,single:Object?},
   type=List<dynamic>
  *//*analyzer.
   error=non-exhaustive:List<dynamic>,
   fields={first:Object?,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<dynamic>,last:Object?,length:int,runtimeType:Type},
   type=List<dynamic>
  */switch (list) {
    [...var l] /*space=??*/=> l.length,
  };
  var b = /*cfe.
   error=non-exhaustive:List<dynamic>,
   fields={first:Object?,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<dynamic>,last:Object?,length:int,reversed:Iterable<dynamic>,runtimeType:Type,single:Object?},
   type=List<dynamic>
  *//*analyzer.
   error=non-exhaustive:List<dynamic>,
   fields={first:Object?,hashCode:int,isEmpty:bool,isNotEmpty:bool,iterator:Iterator<dynamic>,last:Object?,length:int,runtimeType:Type},
   type=List<dynamic>
  */switch (list) {
    [...List<String> l] /*space=??*/=> l.length,
  };
}
