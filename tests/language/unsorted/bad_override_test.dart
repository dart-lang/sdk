// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Fisk {
  get fisk => null;
  static
  set fisk(x) {}
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] This static member conflicts with an instance member.

  static
  get hest => null;
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] This static member conflicts with an instance member.
  set hest(x) {}

  foo() {}
  var field;
  method() {}
  nullary() {}
}

class Hest extends Fisk {
  static foo() {}
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_STATIC_AND_INSTANCE
  // [cfe] Can't declare a member that conflicts with an inherited one.
  field() {}
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_METHOD_AND_FIELD
// [cfe] Can't declare a member that conflicts with an inherited one.
  var method;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONFLICTING_FIELD_AND_METHOD
  // [cfe] Can't declare a member that conflicts with an inherited one.
  nullary(x) {}
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
// [cfe] The method 'Hest.nullary' has more required arguments than those of overridden method 'Fisk.nullary'.
}

main() {
  new Fisk();
  new Hest();
}
