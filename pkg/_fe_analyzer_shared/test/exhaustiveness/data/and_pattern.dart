// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

and(A o1, A o2) {
  var a = /*
   fields={hashCode:int,runtimeType:Type},
   type=A
  */switch (o1) {
    A() && var a /*space=??*/=> 0,
    _ /*space=()*/=> 1,
  };

  var b = /*
   error=non-exhaustive:A,
   fields={hashCode:int,runtimeType:Type},
   type=A
  */switch (o1) {
    A() && var a /*space=??*/=> 0,
  };
}