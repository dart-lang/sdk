// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_out.dart';

abstract class Interface {
  int? method1();
  int method2();
  int? method3();
  int method4();
}

class Class1 extends LegacyClass {
  int method1() => /*int!*/ 0;
  int? method2() => /*int!*/ 0;
}

class Class2 extends LegacyClass implements Interface {}

main() {
  Class1 c1 = new /*Class1!*/ Class1();
  /*Class1!*/ c1. /*invoke: int!*/ method1();
  /*Class1!*/ c1. /*invoke: int?*/ method2();
  /*Class1!*/ c1. /*invoke: int*/ method3();
  /*Class1!*/ c1. /*invoke: int*/ method4();
  Interface i = new /*Class2!*/ Class2();
  /*Interface!*/ i. /*invoke: int?*/ method1();
  /*Interface!*/ i. /*invoke: int!*/ method2();
  /*Interface!*/ i. /*invoke: int?*/ method3();
  /*Interface!*/ i. /*invoke: int!*/ method4();
  Class2 c2 = new /*Class2!*/ Class2();
  /*Class2!*/ c2. /*invoke: int?*/ method1();
  /*Class2!*/ c2. /*invoke: int!*/ method2();
  /*Class2!*/ c2. /*invoke: int?*/ method3();
  /*Class2!*/ c2. /*invoke: int!*/ method4();
}
