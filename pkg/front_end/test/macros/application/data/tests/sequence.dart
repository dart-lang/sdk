// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class1:SequenceMacro.new(0)
 Class2:SequenceMacro.new(1)
 Class2:SequenceMacro.new(0)
 Class3.method:SequenceMacro.new(1)
 Class3:SequenceMacro.new(0)
 Class4.method:SequenceMacro.new(3)
 Class4.method2:SequenceMacro.new(5)
 Class4.method2:SequenceMacro.new(4)
 Class4:SequenceMacro.new(2)
 Class4:SequenceMacro.new(1)
 Class4:SequenceMacro.new(0)*/

import 'package:macro/macro.dart';

/*class: Class1:
augment class Class1 {
  method() {}
}*/
@SequenceMacro(0)
class Class1 {}

/*class: Class2:
augment class Class2 {
  method() {}
  method1() {}
}*/
@SequenceMacro(0)
@SequenceMacro(1)
class Class2 {}

/*class: Class3:
augment class Class3 {
  method1() {}
}*/
@SequenceMacro(0)
class Class3 {
  @SequenceMacro(1)
  method() {}
}

/*class: Class4:
augment class Class4 {
  method1() {}
  method3() {}
  method4() {}
}*/
@SequenceMacro(0)
@SequenceMacro(1)
@SequenceMacro(2)
class Class4 {
  @SequenceMacro(3)
  method() {}
  @SequenceMacro(4)
  @SequenceMacro(5)
  method2() {}
}
