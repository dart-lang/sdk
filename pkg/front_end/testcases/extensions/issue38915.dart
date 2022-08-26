// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  void method1({bool b = false, String s = ', '}) => null;
  void method2([bool b = false, String s = ', ']) => null;
  void method3(int i, {bool b = false, String s = ', '}) {}
  void method4(int i, [bool b = false, String s = ', ']) {}
}

main() {
  var c = new Class();
  c.method1();
  c.method1(s: 'foo');
  c.method1(b: true);
  c.method1(b: true, s: 'foo');
  c.method1(s: 'foo', b: true);
  c.method2();
  c.method2(true);
  c.method2(true, 'foo');
  c.method3(42);
  c.method3(42, s: 'foo');
  c.method3(42, b: true);
  c.method3(42, b: true, s: 'foo');
  c.method3(42, s: 'foo', b: true);
  c.method4(42);
  c.method4(42, true);
  c.method4(42, true, 'foo');
}
