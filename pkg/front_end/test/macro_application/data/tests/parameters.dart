// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

/*member: topLevelFunction1:

augment void topLevelFunction1(int a, ) {
  return 42;
}*/
@FunctionDefinitionMacro1()
external void topLevelFunction1(int a);

/*member: topLevelFunction2:

augment void topLevelFunction2(int a, int b, ) {
  return 42;
}*/
@FunctionDefinitionMacro1()
external void topLevelFunction2(int a, int b);

/*member: topLevelFunction3:

augment void topLevelFunction3(int a, [int? b, ]) {
  return 42;
}*/
@FunctionDefinitionMacro1()
external void topLevelFunction3(int a, [int? b]);

/*member: topLevelFunction4:

augment void topLevelFunction4(int a, {int? b, int? c, }) {
  return 42;
}*/
@FunctionDefinitionMacro1()
external void topLevelFunction4(int a, {int? b, int? c});
