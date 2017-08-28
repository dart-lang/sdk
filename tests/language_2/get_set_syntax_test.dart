// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var get;
var get a; //           //# 00: compile-time error
var get b, c; //        //# 01: compile-time error

var set;
var set d; //           //# 02: compile-time error
var set e, f; //        //# 03: compile-time error

class C0 {
  var get;
  var get a; //         //# 04: compile-time error
  var get b, c; //      //# 05: compile-time error

  var set;
  var set d; //         //# 06: compile-time error
  var set e, f; //      //# 07: compile-time error
}

class C1 {
  List get;
  List get a;
  List get b, c; //     //# 09: compile-time error

  List set;
  List set d; //        //# 10: compile-time error
  List set e, f; //     //# 11: compile-time error
}

class C2 {
  List<int> get;
  List<int> get a;
  List<int> get b, c; //# 13: compile-time error

  List<int> set;
  List<int> set d; //   //# 14: compile-time error
  List<int> set e, f; //# 15: compile-time error
}

main() {
  new C0();
  new C1();
  new C2();
}
