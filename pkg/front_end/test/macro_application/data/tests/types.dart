// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

@FunctionTypesMacro1()
/*member: topLevelFunction1:
class topLevelFunction1GeneratedClass {}
*/
void topLevelFunction1() {}

@FunctionTypesMacro1()
/*member: topLevelFunction2:
class topLevelFunction2GeneratedClass {}
*/
void topLevelFunction2() {}
