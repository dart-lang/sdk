// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 macrosAreApplied,
 macrosAreAvailable
*/

import 'macro_lib.dart';

@Macro1()
/*member: main:appliedMacros=[Macro1]*/
void main() {}

@Macro2()
/*class: Class1:
 appliedMacros=[Macro2],
 macrosAreApplied
*/
class Class1 {
  @Macro1()
  @Macro2()
  /*member: Class1.method:appliedMacros=[
    Macro1,
    Macro2]*/
  void method() {}
}

@NonMacro()
class Class2 {}

/*class: Class3:macrosAreApplied*/
class Class3 {
  @Macro1()
  /*member: Class3.field:appliedMacros=[Macro1]*/
  var field;
}

class Class4 {
  @NonMacro()
  var field;
}
