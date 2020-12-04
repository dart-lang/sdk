// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

const c = "string3";

/*class: C:
 class_unit=main{},
 type_unit=main{}
*/
class C {
  /*member: C.p:member_unit=main{}*/
  final p;

  const C(this.p);
}

/*member: foo:member_unit=2{lib1, lib2}*/
foo() => print("main");

/*member: main:
 constants=[
  ConstructedConstant(C(p=IntConstant(1)))=main{},
  ConstructedConstant(C(p=IntConstant(1010)))=1{lib1},
  ConstructedConstant(C(p=IntConstant(2)))=2{lib1, lib2},
  ConstructedConstant(C(p=StringConstant("string1")))=1{lib1},
  ConstructedConstant(C(p=StringConstant("string2")))=1{lib1}],
 member_unit=main{}
*/
void main() {
  lib1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    lib2.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      lib1.foo();
      lib2.foo();
      print(lib1.C1);
      print(lib1.C1b);
      print(lib1.C2);
      print(lib1.C2b);
      print(lib1.D.C3);
      print(lib1.D.C3b);
      print(c);
      print(lib1.C4);
      print(lib2.C4);
      print(lib1.C5);
      print(lib2.C5);
      print(lib1.C6);
      print(lib2.C6);
      print("string4");
      print(const C(1));
    });
  });
}
