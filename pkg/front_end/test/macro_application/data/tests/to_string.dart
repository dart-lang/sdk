// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

@ToStringMacro()
/*class: A:
augment class A {
  toString() {
    return "A(a=${a},b=${b})";
  }
}*/
class A {
  var a;
  var b;
}

@ToStringMacro()
/*class: B:
augment class B {
  toString() {
    return "B(c=${c},d=${d},e=${e})";
  }
}*/
class B {
  var c, d;
  var e;
}

@ToStringMacro()
class C {
  var f;

  @override
  String toString() => 'C()';
}

class D {
  var g;
  var h;
}
