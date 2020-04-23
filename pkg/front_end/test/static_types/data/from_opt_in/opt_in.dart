// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

abstract class Interface {
  int? method1();
  int method2();
  int? method3();
  int method4();
}

class Class {
  int method1() => /*int!*/ 0;
  int? method2() => /*int!*/ 0;
}
