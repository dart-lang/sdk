// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

/*member: topLevelFunction1:
class topLevelFunction1GeneratedClass<T extends void> {}*/
@FunctionTypesMacro1()
void topLevelFunction1() {}

/*member: topLevelFunction2:
class topLevelFunction2GeneratedClass<T extends dynamic> {}*/
@FunctionTypesMacro1()
dynamic topLevelFunction2() {}

/*member: topLevelFunction3:
import 'dart:core' as i0;


class topLevelFunction3GeneratedClass<T extends i0.int> {}*/
@FunctionTypesMacro1()
int topLevelFunction3() => 0;

/*member: topLevelFunction4:
import 'package:macro/macro.dart' as i0;


class topLevelFunction4GeneratedClass<T extends i0.FunctionTypesMacro1?> {}*/
@FunctionTypesMacro1()
FunctionTypesMacro1? topLevelFunction4() => null;

/*member: topLevelFunction5:
class topLevelFunction5GeneratedClass<T extends dynamic> {}*/
@FunctionTypesMacro1()
topLevelFunction5() {}
