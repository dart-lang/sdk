// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Types Order:
 topLevelFunction1:FunctionTypesMacro1.new()
 topLevelFunction2:FunctionTypesMacro1.new()
 topLevelFunction3:FunctionTypesMacro1.new()
 topLevelFunction4:FunctionTypesMacro1.new()
 topLevelFunction5:FunctionTypesMacro1.new()
Types:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix0;
import 'package:macro/macro.dart' as prefix1;

class topLevelFunction1GeneratedClass {
  external void method();
}
class topLevelFunction2GeneratedClass {
  external prefix0.dynamic method();
}
class topLevelFunction3GeneratedClass {
  external prefix0.int method();
}
class topLevelFunction4GeneratedClass {
  external prefix1.FunctionTypesMacro1? method();
}
class topLevelFunction5GeneratedClass {
  external OmittedType0 method();
}
*/

import 'package:macro/macro.dart';

/*member: topLevelFunction1:
types:
class topLevelFunction1GeneratedClass {
  external void method();
}*/
@FunctionTypesMacro1()
void topLevelFunction1() {}

/*member: topLevelFunction2:
types:
class topLevelFunction2GeneratedClass {
  external dynamic method();
}*/
@FunctionTypesMacro1()
dynamic topLevelFunction2() {}

/*member: topLevelFunction3:
types:
class topLevelFunction3GeneratedClass {
  external int method();
}*/
@FunctionTypesMacro1()
int topLevelFunction3() => 0;

/*member: topLevelFunction4:
types:
class topLevelFunction4GeneratedClass {
  external FunctionTypesMacro1? method();
}*/
@FunctionTypesMacro1()
FunctionTypesMacro1? topLevelFunction4() => null;

/*member: topLevelFunction5:
types:
class topLevelFunction5GeneratedClass {
  external Instance of '_OmittedTypeAnnotationImpl' method();
}*/
@FunctionTypesMacro1()
topLevelFunction5() {}
