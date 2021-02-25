// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[f1: {units: [1{lib1}], usedBy: [], needs: []}],
 steps=[lib1=(f1)]
*/

// @dart = 2.7

import 'dart:async';
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' as lib2;

/*member: main:
 constants=[ConstructedConstant(A())=1{lib1}],
 member_unit=main{}
*/
main() async {
  await lib1.loadLibrary();
  lib1.field is FutureOr<lib2.A>;
  lib1.field.method();
}
