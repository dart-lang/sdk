// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class:Macro2.new()
 Macro2:Macro1.new()*/

import 'package:macro/macro2.dart';

@Macro2()
/*class: Class:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class {
  hasMacro() => true;

}
*/
class Class {}
