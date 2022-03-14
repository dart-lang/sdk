// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Types:
import 'dart:core' as i0;
import 'package:macro/macro.dart' as i1;


class topLevelFunction1GeneratedClass {
  external void method();
}
class topLevelFunction2GeneratedClass {
  external i0.dynamic method();
}
class topLevelFunction3GeneratedClass {
  external i0.int method();
}
class topLevelFunction4GeneratedClass {
  external i1.FunctionTypesMacro1? method();
}
class topLevelFunction5GeneratedClass {
  external i0.dynamic method();
}*/

import 'package:macro/macro.dart';

/*member: topLevelFunction1:
class topLevelFunction1GeneratedClass {
  external void method();
}*/
@FunctionTypesMacro1()
void topLevelFunction1() {}

/*member: topLevelFunction2:
class topLevelFunction2GeneratedClass {
  external dynamic method();
}*/
@FunctionTypesMacro1()
dynamic topLevelFunction2() {}

/*member: topLevelFunction3:
class topLevelFunction3GeneratedClass {
  external int method();
}*/
@FunctionTypesMacro1()
int topLevelFunction3() => 0;

/*member: topLevelFunction4:
class topLevelFunction4GeneratedClass {
  external FunctionTypesMacro1? method();
}*/
@FunctionTypesMacro1()
FunctionTypesMacro1? topLevelFunction4() => null;

/*member: topLevelFunction5:
class topLevelFunction5GeneratedClass {
  external dynamic method();
}*/
@FunctionTypesMacro1()
topLevelFunction5() {}
