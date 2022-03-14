// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Definitions:
import 'org-dartlang-test:///a/b/c/main.dart' as i0;


augment i0.A topLevelFunction1(i0.A a, ) {
  print('isExactly=true');
  print('isSubtype=true');
  throw 42;
}
augment i0.B2 topLevelFunction2(i0.B1 a, ) {
  print('isExactly=false');
  print('isSubtype=true');
  throw 42;
}
augment i0.C2 topLevelFunction3(i0.C1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}
augment i0.D2 topLevelFunction4(i0.D1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}
*/

import 'package:macro/macro.dart';

class A {}

class B1 {}

class B2 extends B1 {}

class C1 extends C2 {}

class C2 {}

class D1 {}

class D2 {}

/*member: topLevelFunction1:
void topLevelFunction1GeneratedMethod_es() {}

augment A topLevelFunction1(A a, ) {
  print('isExactly=true');
  print('isSubtype=true');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external A topLevelFunction1(A a);

/*member: topLevelFunction2:
void topLevelFunction2GeneratedMethod_s() {}

augment B2 topLevelFunction2(B1 a, ) {
  print('isExactly=false');
  print('isSubtype=true');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external B2 topLevelFunction2(B1 a);

/*member: topLevelFunction3:
void topLevelFunction3GeneratedMethod_() {}

augment C2 topLevelFunction3(C1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external C2 topLevelFunction3(C1 a);

/*member: topLevelFunction4:
void topLevelFunction4GeneratedMethod_() {}

augment D2 topLevelFunction4(D1 a, ) {
  print('isExactly=false');
  print('isSubtype=false');
  throw 42;
}*/
@FunctionDeclarationsMacro2()
@FunctionDefinitionMacro2()
external D2 topLevelFunction4(D1 a);
