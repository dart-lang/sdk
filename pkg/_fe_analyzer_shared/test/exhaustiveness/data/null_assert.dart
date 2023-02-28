// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int field;

  A(this.field);
}

simpleAssert(o1, o2) {
  var a = /*
   fields={},
   subtypes={Object,Null},
   type=Object?
  */switch (o1) {
    _! /*space=??*/=> 0,
    _ /*space=()*/=> 1
  };

  var b = /*
   error=non-exhaustive:Object,
   fields={},
   subtypes={Object,Null},
   type=Object?
  */switch (o2) {
    _! /*space=??*/=> 0,
  };
}

restrictedCase(o1, o2) {
  // Null assert shouldn't match everything, because even though it doesn't
  // throw, it might not match.
  var a = /*
   fields={},
   subtypes={Object,Null},
   type=Object?
  */switch (o1) {
    A(field: 42)! /*space=??*/=> 0,
    _ /*space=()*/=> 1
  };

  var b = /*
   error=non-exhaustive:Object,
   fields={},
   subtypes={Object,Null},
   type=Object?
  */switch (o2) {
    A(field: 42)! /*space=??*/=> 0,
  };
}