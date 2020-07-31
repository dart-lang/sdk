// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  String get call => "My name is A";
}

class B {
  String Function() get call => () => "My name is B";
}

extension on int {
  String get call => "My name is int";
}

extension on num {
  String get call => "My name is num";
}

extension on String {
  String Function() get call => () => "My name is String";
}

main() {
  ""();
}

var topLevel1 = 1(10);
var topLevel2 = 1("10");
var topLevel3 = 1.0(10);
var topLevel4 = 1.0("10");
A a = new A();
var topLevel5 = a(2);
B b = new B();
var topLevel6 = a(2, "3");

errors() {
  1(10);
  1("10");
  1.0(10);
  1.0("10");
  A a = new A();
  a(2);
  a(2, "3");
  B b = new B();
  b();
}
