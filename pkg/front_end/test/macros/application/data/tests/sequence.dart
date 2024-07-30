// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class1:SequenceMacro.new(IntArgument:0)
 Class2:SequenceMacro.new(IntArgument:1)
 Class2:SequenceMacro.new(IntArgument:0)
 Class3.method:SequenceMacro.new(IntArgument:1)
 Class3:SequenceMacro.new(IntArgument:0)
 Class4.method:SequenceMacro.new(IntArgument:3)
 Class4.method2:SequenceMacro.new(IntArgument:5)
 Class4.method2:SequenceMacro.new(IntArgument:4)
 Class4:SequenceMacro.new(IntArgument:2)
 Class4:SequenceMacro.new(IntArgument:1)
 Class4:SequenceMacro.new(IntArgument:0)
 Class5a:SequenceMacro.new(IntArgument:0)
 Class5b:SequenceMacro.new(IntArgument:0)
 Class5c:SequenceMacro.new(IntArgument:0)
 Class6c:SequenceMacro.new(IntArgument:0)
 Class6a:SequenceMacro.new(IntArgument:0)
 Class6b:SequenceMacro.new(IntArgument:0)
 Class6d:SequenceMacro.new(IntArgument:0)
 Class7a:SequenceMacro.new(IntArgument:0)
 Class7b:SequenceMacro.new(IntArgument:0)
 Class7c:SequenceMacro.new(IntArgument:0)
 Class7d:SequenceMacro.new(IntArgument:0)*/

import 'package:macro/macro.dart';

@SequenceMacro(0)
/*class: Class1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class1 {
  method() {}
}
*/
class Class1 {}

@SequenceMacro(0)
@SequenceMacro(1)
/*class: Class2:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class2 {
  method() {}
}

augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class2 {
  method1() {}
}
*/
class Class2 {}

@SequenceMacro(0)
/*class: Class3:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class3 {
  method1() {}
}
*/
class Class3 {
  @SequenceMacro(1)
  method() {}
}

@SequenceMacro(0)
@SequenceMacro(1)
@SequenceMacro(2)
/*class: Class4:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class4 {
  method1() {}
}

augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class4 {
  method3() {}
}

augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class4 {
  method4() {}
}
*/
class Class4 {
  @SequenceMacro(3)
  method() {}
  @SequenceMacro(4)
  @SequenceMacro(5)
  method2() {}
}

@SequenceMacro(0)
/*class: Class5c:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class5c {
  method2() {}
}
*/
class Class5c extends Class5b {}

@SequenceMacro(0)
/*class: Class5b:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class5b {
  method1() {}
}
*/
class Class5b extends Class5a {}

@SequenceMacro(0)
/*class: Class5a:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class5a {
  method() {}
}
*/
class Class5a {}

@SequenceMacro(0)
/*class: Class6d:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment abstract class Class6d {
  method2() {}
}
*/
abstract class Class6d implements Class6c, Class6b {}

@SequenceMacro(0)
/*class: Class6c:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class6c {
  method() {}
}
*/
class Class6c {}

@SequenceMacro(0)
/*class: Class6b:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment abstract class Class6b {
  method1() {}
}
*/
abstract class Class6b implements Class6a {}

@SequenceMacro(0)
/*class: Class6a:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class6a {
  method() {}
}
*/
class Class6a {}

/*class: Class7d:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class7d {
  method2() {}
}
*/
@SequenceMacro(0)
class Class7d extends Class7b with Class7c {}

@SequenceMacro(0)
/*class: Class7c:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment mixin Class7c {
  method() {}
}
*/
mixin Class7c {}

@SequenceMacro(0)
/*class: Class7b:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class7b {
  method1() {}
}
*/
class Class7b with Class7a {}

@SequenceMacro(0)
/*class: Class7a:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment mixin Class7a {
  method() {}
}
*/
mixin Class7a {}
