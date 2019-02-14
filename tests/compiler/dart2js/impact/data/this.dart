// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: Class.:static=[Object.(0)]*/
class Class {
  /*element: Class.field1:type=[inst:JSNull]*/
  var field1;

  /*element: Class.field2:type=[inst:JSNull]*/
  var field2;

  /*element: Class.method1:dynamic=[this:Class.method2(0)]*/
  method1() {
    method2();
  }

  /*element: Class.method2:dynamic=[this:Class.field1=,this:Class.field2]*/
  method2() {
    field1 = field2;
  }
}

/*element: Subclass.:static=[Class.(0)]*/
class Subclass extends Class {
  /*element: Subclass.field1:type=[inst:JSNull]*/
  var field1;
  /*element: Subclass.field2:type=[inst:JSNull]*/
  var field2;

  /*element: Subclass.method1:*/
  method1() {}

  /*element: Subclass.method2:dynamic=[this:Subclass.method3(0)]*/
  method2() {
    method3();
  }

  method3() {}
}

/*element: Subtype.:static=[Object.(0)]*/
class Subtype implements Class {
  /*element: Subtype.field1:type=[inst:JSNull]*/
  var field1;
  /*element: Subtype.field2:type=[inst:JSNull]*/
  var field2;

  method1() {}

  method2() {
    method4();
  }

  method4() {
    method2();
  }
}

/*element: main:
 dynamic=[Class.method1(0)],
 static=[Class.(0),Subclass.(0),Subtype.(0)]
*/
main() {
  var c = new Class();
  c = new Subclass();
  c = new Subtype();
  c.method1();
}
