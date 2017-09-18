// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for the dart2js implementation of runtime types.

library test.type_mirror_for_type;

import 'package:expect/expect.dart';

@MirrorsUsed(targets: 'test.type_mirror_for_type')
import 'dart:mirrors';

class C<T> {}

class X {
  Type foo() {}
}

main() {
  // Make sure that we need a type test against the runtime representation of
  // [Type].
  var a = (new DateTime.now().millisecondsSinceEpoch != 42)
      ? new C<Type>()
      : new C<int>();
  print(a is C<Type>);

  var typeMirror = reflectType(X) as ClassMirror;
  var declarationMirror = typeMirror.declarations[#foo] as MethodMirror;
  // Test that the runtime type implementation does not confuse the runtime type
  // representation of [Type] with an actual value of type [Type] when analyzing
  // the return type of [foo].
  Expect.equals(reflectType(Type), declarationMirror.returnType);
}
