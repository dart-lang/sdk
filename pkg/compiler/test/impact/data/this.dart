// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: Class.:static=[Object.(0)]*/
class Class {
  /*member: Class.field1:type=[inst:JSNull]*/
  var field1;

  /*member: Class.field2:type=[inst:JSNull]*/
  var field2;

  /*member: Class.method1:dynamic=[this:Class.method2(0)]*/
  method1() {
    method2();
  }

  /*member: Class.method2:dynamic=[this:Class.field1=,this:Class.field2]*/
  method2() {
    field1 = field2;
  }
}

/*member: Subclass.:static=[Class.(0)]*/
class Subclass extends Class {
  /*member: Subclass.field1:type=[inst:JSNull]*/
  var field1;
  /*member: Subclass.field2:type=[inst:JSNull]*/
  var field2;

  /*member: Subclass.method1:*/
  method1() {}

  /*member: Subclass.method2:dynamic=[this:Subclass.method3(0)]*/
  method2() {
    method3();
  }

  method3() {}
}

/*member: Subtype.:static=[Object.(0)]*/
class Subtype implements Class {
  /*member: Subtype.field1:type=[inst:JSNull]*/
  var field1;
  /*member: Subtype.field2:type=[inst:JSNull]*/
  var field2;

  method1() {}

  method2() {
    method4();
  }

  method4() {
    method2();
  }
}

/*member: main:
 dynamic=[Class.method1(0)],
 static=[Class.(0),Subclass.(0),Subtype.(0)]
*/
main() {
  var c = new Class();
  c = new Subclass();
  c = new Subtype();
  c.method1();
}
