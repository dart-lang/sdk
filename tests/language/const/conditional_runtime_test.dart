// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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



const cond2 = falseConst ? const0 : const1;











void main() {
  Expect.identical(var0, cond1);



  Expect.identical(var1, cond2);










}
