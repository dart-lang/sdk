// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


int Y; //LINT
const Z = 4; //OK

abstract class A {

  int X; //LINT
  static const Y = 3; // OK

  foo_bar();  //LINT

  baz(var B); //LINT

  bar({String Name}); //LINT

  foo([String Name]); //LINT

  static Foo() => null; //LINT

}

Main() => null; //LINT

