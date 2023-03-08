// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

untypedList(List list) {
  var a = /*
   error=non-exhaustive:List<dynamic>,
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
  var a = /*
   error=non-exhaustive:List<A>,
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
  var a = /*
   error=non-exhaustive:List<dynamic>,
   type=List<dynamic>
  */switch (list) {
    [...var l] /*space=??*/=> l.length,
  };
  var b = /*
   error=non-exhaustive:List<dynamic>,
   type=List<dynamic>
  */switch (list) {
    [...List<String> l] /*space=??*/=> l.length,
  };
}
