// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

/*member: topLevelFunction1:
void topLevelFunction1GeneratedMethod() {}
*/
@FunctionDeclarationsMacro1()
void topLevelFunction1() {}

@FunctionDeclarationsMacro1()
/*member: topLevelFunction2:
void topLevelFunction2GeneratedMethod() {}
*/
void topLevelFunction2() {}
