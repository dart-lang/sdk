// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*library: file=main.dart*/

/*member: main:main*/
main() {
  // ignore: unused_element
  /*main.localFunction*/ localFunction() {}

  /*main.<anonymous>*/
  () {};

  // Use all declarations.
  setter = field = getter;
  var c = new Class();
  c = new Class.constructor();
  c.setter = c.field = c.getter;
  c.method();
}

/*member: field:field*/
var field;

/*member: getter:getter*/
get getter => null;

/*member: setter=:setter=*/
set setter(_) {}

/*class: Class:Class*/
class Class {
  /*member: Class.:Class.*/
  Class();

  /*member: Class.constructor:Class.constructor*/
  factory Class.constructor() => new Class();

  /*member: Class.field:Class.field*/
  var field;

  /*member: Class.getter:Class.getter*/
  get getter => null;

  /*member: Class.setter=:Class.setter=*/
  set setter(_) {}

  /*member: Class.method:Class.method*/
  void method() {
    // ignore: unused_element
    /*Class.method.localFunction*/ localFunction() {}

    /*Class.method.<anonymous>*/
    () {};
  }
}
