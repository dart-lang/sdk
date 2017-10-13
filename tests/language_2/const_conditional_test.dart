// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for conditionals as compile-time constants.

import 'package:expect/expect.dart';

class Marker {
  final field;
  const Marker(this.field);
}

var var0 = const Marker(0);
var var1 = const Marker(1);
const const0 = const Marker(0);
const const1 = const Marker(1);

const trueConst = true;
const falseConst = false;
var nonConst = true;
const zeroConst = 0;

const cond1 = trueConst ? const0 : const1;
const cond1a = trueConst ? nonConst : const1; //# 01: compile-time error
const cond1b = trueConst ? const0 : nonConst; //# 02: compile-time error

const cond2 = falseConst ? const0 : const1;
const cond2a = falseConst ? nonConst : const1; //# 03: compile-time error
const cond2b = falseConst ? const0 : nonConst; //# 04: compile-time error

const cond3 = nonConst ? const0 : const1; //# 05: compile-time error
const cond3a = nonConst ? nonConst : const1; //# 06: compile-time error
const cond3b = nonConst ? const0 : nonConst; //# 07: compile-time error

const cond4 = zeroConst ? const0 : const1; //# 08: compile-time error
const cond4a = zeroConst ? nonConst : const1; //# 09: compile-time error
const cond4b = zeroConst ? const0 : nonConst; //# 10: compile-time error

void main() {
  Expect.identical(var0, cond1);
  Expect.identical(nonConst, cond1a); //# 01: continued
  Expect.identical(var0, cond1b); //# 02: continued

  Expect.identical(var1, cond2);
  Expect.identical(var1, cond2a); //# 03: continued
  Expect.identical(nonConst, cond2b); //# 04: continued

  Expect.identical(var0, cond3); // //# 05: continued
  Expect.identical(nonConst, cond3a); //# 06: continued
  Expect.identical(var0, cond3b); //# 07: continued

  Expect.identical(var1, cond4); // //# 08: continued
  Expect.identical(var1, cond4a); //# 09: continued
  Expect.identical(nonConst, cond4b); //# 10: continued
}
