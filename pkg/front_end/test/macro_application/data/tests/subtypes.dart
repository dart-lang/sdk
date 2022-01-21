// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

class A {}

class B1 {}

class B2 extends B1 {}

class C1 extends C2 {}

class C2 {}

class D1 {}

class D2 {}

/*member: topLevelFunction1:
augment A topLevelFunction1(A a, ) {
  print('isExactly=true');
  print('isSubtype=true');
}*/
@FunctionDefinitionMacro2()
external A topLevelFunction1(A a);

/*member: topLevelFunction2:
augment B2 topLevelFunction2(B1 a, ) {
  print('isExactly=false');
  print('isSubtype=true');
}*/
@FunctionDefinitionMacro2()
external B2 topLevelFunction2(B1 a);

/*member: topLevelFunction3:
augment C2 topLevelFunction3(C1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
}*/
@FunctionDefinitionMacro2()
external C2 topLevelFunction3(C1 a);

/*member: topLevelFunction4:
augment D2 topLevelFunction4(D1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
}*/
@FunctionDefinitionMacro2()
external D2 topLevelFunction4(D1 a);
