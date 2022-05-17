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
 Class4:SequenceMacro.new(0)
 Class5a:SequenceMacro.new(0)
 Class5b:SequenceMacro.new(0)
 Class5c:SequenceMacro.new(0)
 Class6c:SequenceMacro.new(0)
 Class6a:SequenceMacro.new(0)
 Class6b:SequenceMacro.new(0)
 Class6d:SequenceMacro.new(0)
 Class7a:SequenceMacro.new(0)
 Class7b:SequenceMacro.new(0)
 Class7c:SequenceMacro.new(0)
 Class7d:SequenceMacro.new(0)*/

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

/*class: Class5c:
augment class Class5c {
  method2() {}
}*/
@SequenceMacro(0)
class Class5c extends Class5b {}

/*class: Class5b:
augment class Class5b {
  method1() {}
}*/
@SequenceMacro(0)
class Class5b extends Class5a {}

/*class: Class5a:
augment class Class5a {
  method() {}
}*/
@SequenceMacro(0)
class Class5a {}

/*class: Class6d:
augment class Class6d {
  method2() {}
}*/
@SequenceMacro(0)
abstract class Class6d implements Class6c, Class6b {}

/*class: Class6c:
augment class Class6c {
  method() {}
}*/
@SequenceMacro(0)
class Class6c {}

/*class: Class6b:
augment class Class6b {
  method1() {}
}*/
@SequenceMacro(0)
abstract class Class6b implements Class6a {}

/*class: Class6a:
augment class Class6a {
  method() {}
}*/
@SequenceMacro(0)
class Class6a {}

/*class: Class7d:
augment class Class7d {
  method2() {}
}*/
@SequenceMacro(0)
class Class7d with Class7b, Class7c {}

/*class: Class7c:
augment class Class7c {
  method() {}
}*/
@SequenceMacro(0)
class Class7c {}

/*class: Class7b:
augment class Class7b {
  method1() {}
}*/
@SequenceMacro(0)
class Class7b with Class7a {}

/*class: Class7a:
augment class Class7a {
  method() {}
}*/
@SequenceMacro(0)
class Class7a {}
