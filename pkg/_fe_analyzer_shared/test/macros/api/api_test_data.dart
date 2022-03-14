// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api_test_macro.dart';

main() {}

var field;
get getter => null;
set setter(_) => null;

@ClassMacro()
class Class1 {}

@ClassMacro()
abstract class Class2 {}

@ClassMacro()
class Class3 extends Class2 {}

mixin Mixin {}

@ClassMacro()
class Class4 extends Class1 with Mixin {}

@FunctionMacro()
void topLevelFunction1(Class1 a, {Class1? b, required Class2? c}) {}

@FunctionMacro()
external Class2 topLevelFunction2(Class1 a, [Class2? b]);
