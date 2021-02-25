// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[f1: {units: [1{lib2}], usedBy: [], needs: []}],
 steps=[lib2=(f1)]
*/

// @dart = 2.7

import 'lib1.dart';
import 'lib2.dart' deferred as lib2;

/*member: main:
 constants=[
  ConstructedConstant(C(value=ConstructedConstant(C(value=IntConstant(7)))))=1{lib2},
  ConstructedConstant(C(value=IntConstant(1)))=main{},
  ConstructedConstant(C(value=IntConstant(2)))=1{lib2},
  ConstructedConstant(C(value=IntConstant(4)))=main{},
  ConstructedConstant(C(value=IntConstant(5)))=main{}],
 member_unit=main{}
*/
main() async {
  C1.value;
  print(const C(4));
  /*closure_unit=main{}*/ () => print(const C(5));
  await lib2.loadLibrary();
  print(lib2.C2.value);
  print(lib2.C3.value);
  print(lib2.C4.value);
  print(lib2.C5.value);
  print(lib2.C6);
  print(lib2.C7.value);
}
