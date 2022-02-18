// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 


*/

import 'package:macro/macro.dart';

@SequenceMacro()
/*class: Class1:
augment class Class1 {
  method() {}
}*/
class Class1 {}

@SequenceMacro()
@SequenceMacro()
/*class: Class2:
augment class Class2 {
  method() {}
}
augment class Class2 {
  method1() {}
}*/
class Class2 {}

@SequenceMacro()
/*class: Class3:
augment class Class3 {
  method1() {}
}*/
class Class3 {
  method() {}
}

@SequenceMacro()
@SequenceMacro()
@SequenceMacro()
/*class: Class4:
augment class Class4 {
  method1() {}
}
augment class Class4 {
  method3() {}
}
augment class Class4 {
  method4() {}
}*/
class Class4 {
  method() {}
  method2() {}
}
