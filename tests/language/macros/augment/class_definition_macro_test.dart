// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'package:expect/expect.dart';

import 'impl/class_definition_macro.dart';

@ClassDefinitionBuildConstructor(
  name: 'a',
  initializers: ['x = 3'],
  body: null, // TODO(davidmorgan): test body.
  comments: null, // TODO(davidmorgan): test comments.
)
class A {
  final int x;

  A.a();
}

@ClassDefinitionBuildField(
  name: 'x',
  getter: '`int` get x => 3;',
  setter: null, // TODO(davidmorgan): test setter.
  initializer: null, // TODO(davidmorgan): test initializer.
  initializerComments: null, // TODO(davidmorgan): test comments.
)
class B {
  // TODO(davidmorgan): should "abstract" be allowed, required?
  abstract final int x;
}

@ClassDefinitionBuildMethod(
  name: 'x',
  body: '=> 3;',
  comments: null, // TODO(davidmorgan): test comments.
)
class C {
  int x();
}

void main() {
  Expect.equals(A.a().x, 3);
  Expect.equals(B().x, 3);
  Expect.equals(C().x, 3);
}
