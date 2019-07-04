// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/deferred_constant1_lib1.dart';
import '../libs/deferred_constant1_lib2.dart' deferred as lib2;

/*strong.member: main:OutputUnit(main, {})*/
/*strongConst.member: main:
 OutputUnit(main, {}),
 constants=[
  ConstructedConstant(C(value=ConstructedConstant(C(value=IntConstant(7)))))=OutputUnit(1, {lib2}),
  ConstructedConstant(C(value=IntConstant(1)))=OutputUnit(main, {}),
  ConstructedConstant(C(value=IntConstant(2)))=OutputUnit(1, {lib2}),
  ConstructedConstant(C(value=IntConstant(4)))=OutputUnit(main, {}),
  ConstructedConstant(C(value=IntConstant(5)))=OutputUnit(main, {})]
*/
main() async {
  C1.value;
  print(const C(4));
  /*OutputUnit(main, {})*/ () => print(const C(5));
  await lib2.loadLibrary();
  print(lib2.C2.value);
  print(lib2.C3.value);
  print(lib2.C4.value);
  print(lib2.C5.value);
  print(lib2.C6);
  print(lib2.C7.value);
}
