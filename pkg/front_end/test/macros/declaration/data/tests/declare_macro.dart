// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[main.dart|package:_macros/src/api.dart|package:macros/macros.dart],
 declaredMacros=[MyMacro],
 macrosAreAvailable
*/

import 'package:macros/macros.dart';

macro class MyMacro implements Macro {}

void main() {}
