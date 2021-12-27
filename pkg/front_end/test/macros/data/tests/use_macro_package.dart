// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:_fe_analyzer_shared/src/macros/api.dart,
  package:macro/macro.dart,
  main.dart],
 macrosAreApplied,
 macrosAreAvailable
*/
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
  @Macro3()
  /*member: Class1.:appliedMacros=[Macro3]*/
  Class1();

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

@Macro1()
/*member: field:appliedMacros=[Macro1]*/
var field;

extension Extension on int {
  @Macro1()
  /*member: Extension|field:appliedMacros=[Macro1]*/
  static var field;

  @Macro2()
  /*member: Extension|method:appliedMacros=[Macro2]*/
  void method() {}

  @Macro3()
  /*member: Extension|staticMethod:appliedMacros=[Macro3]*/
  static void staticMethod() {}
}
