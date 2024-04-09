// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class:CreateMacro.new()
Definition Order:
 Class.create:CreateMethodMacro.new()
Definitions:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'org-dartlang-test:///a/b/c/main.dart' as prefix0;

augment class Class {
  augment prefix0.Class create()  => prefix0.Class();
}
*/

import 'package:macro/cascade.dart';

@CreateMacro()
/*class: Class:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'package:macro/cascade.dart' as prefix0;
import 'org-dartlang-test:///a/b/c/main.dart' as prefix1;

augment class Class {
  @prefix0.CreateMethodMacro()
  external prefix1.Class create();
}
*/
class Class {}
