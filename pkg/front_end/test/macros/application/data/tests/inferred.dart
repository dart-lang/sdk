// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class.field:InferableMacro.new()
 Class.method:InferableMacro.new()
 Class.staticField:InferableMacro.new()
 Class.staticMethod:InferableMacro.new()
 Class.:InferableMacro.new()*/

import 'package:macro/macro.dart';

abstract class Interface {
  String method();

  String get_method();

  int get_field(int i);
}

class Class implements Interface {
  /*member: Class.field:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix0;

augment class Class {
OmittedType0 get_field(OmittedType0 f) => this.field;
OmittedType0 Function() get_fieldFunc(OmittedType0 Function(OmittedType0) f) => () => this.field;
prefix0.List<OmittedType0> get_fieldList(prefix0.List<OmittedType0> l) => [this.field];
}
*/
  @InferableMacro()
  var field = 0;

  /*member: Class.:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix0;

augment class Class {
OmittedType0 get_() => throw "";
OmittedType0 Function() get_Func() => throw "";
prefix0.List<OmittedType0> get_List() => throw "";
}
*/
  @InferableMacro()
  Class(this.field);

  /*member: Class.method:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix0;

augment class Class {
OmittedType0 get_method() => this.method();
OmittedType0 Function() get_methodFunc() => () => this.method();
prefix0.List<OmittedType0> get_methodList() => [this.method()];
}
*/
  @InferableMacro()
  method() => '42';

  @InferableMacro()
  /*member: Class.staticField:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix0;

augment class Class {
OmittedType0 get_staticField(OmittedType0 f) => this.staticField;
OmittedType0 Function() get_staticFieldFunc(OmittedType0 Function(OmittedType0) f) => () => this.staticField;
prefix0.List<OmittedType0> get_staticFieldList(prefix0.List<OmittedType0> l) => [this.staticField];
}
*/
  var staticField = '42';

  @InferableMacro()
  /*member: Class.staticMethod:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix0;

augment class Class {
OmittedType0 get_staticMethod() => this.staticMethod();
OmittedType0 Function() get_staticMethodFunc() => () => this.staticMethod();
prefix0.List<OmittedType0> get_staticMethodList() => [this.staticMethod()];
}
*/
  staticMethod() => '42';
}
