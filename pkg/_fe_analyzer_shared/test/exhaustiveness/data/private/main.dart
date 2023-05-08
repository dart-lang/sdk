// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class A {
  num get _a => 42
  int get _b => 42;
}

class C extends B {
}

exhaustiveA(A a) => /*
 fields={_a:num},
 type=A
*/switch (a) { A(: num _a) /*space=A(_a: num)*/=> 0, }

nonExhaustiveA(A a) => /*
 error=non-exhaustive:A(_a: double()),
 fields={_a:num},
 type=A
*/switch (a) { A(: int _a) /*space=A(_a: int)*/=> 0, }

exhaustiveB(B b) => /*
 fields={_b:int},
 type=B
*/switch (b) { B(: int _b) /*space=B(_b: int)*/=> 0, }

exhaustiveC(C c) => /*
 fields={_a:num},
 type=C
*/switch (c) { C(: num _a) /*space=C(_a: num)*/=> 0, }

nonExhaustiveA(C c) => /*analyzer.
 error=non-exhaustive:C(_a: double()),
 fields={_a:num},
 type=C
*/switch (c) { C(: int _a) /*analyzer.space=C(_a: int)*/=> 0, }
