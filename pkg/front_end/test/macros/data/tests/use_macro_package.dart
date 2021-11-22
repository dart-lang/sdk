// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 appliedMacros=[Macro3],
 macrosAreApplied,
 macrosAreAvailable
*/
@Macro3()
library use_macro_package;

import 'package:macro/macro.dart';

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
  @Macro3()
  /*member: Class3.field:appliedMacros=[Macro3]*/
  var field;
}

class Class4 {
  @NonMacro()
  var field;
}
