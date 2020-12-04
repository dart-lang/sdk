// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  String method(num i);
}

abstract class Interface2 {
  String method(covariant int i);
}

mixin A implements Interface {
  String method(num i, {String s = "hello"}) => s;
}

abstract class D implements Interface, Interface2 {}

abstract class C1 {
  method2();
}

abstract class C2 {
  method2([String a]);
}

abstract class C3 implements C1, C2 {}

abstract class C4 {
  method2([covariant String a]);
}

abstract class C5 extends C3 implements C4 {}

abstract class C7 {
  method2([String a, num b]);
}
