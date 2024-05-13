// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 13817.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Tag {
  final name;
  const Tag({named}) : this.name = named;
}

@Tag(named: undefined)
//          ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'undefined'.
class A {}

@Tag(named: D.instanceMethod())
//          ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
//            ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.STATIC_ACCESS_TO_INSTANCE_MEMBER
// [cfe] Member not found: 'D.instanceMethod'.
class D {
  instanceMethod() {}
}

@Tag(named: instanceField)
//          ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'instanceField'.
class E {
  var instanceField;
}

@Tag(named: F.nonConstStaticField)
// [error column 2]
// [cfe] Constant evaluation error:
//          ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
class F {
  static var nonConstStaticField = 6;
}

@Tag(named: instanceMethod)
//          ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'instanceMethod'.
class G {
  instanceMethod() {}
}

@Tag(named: this)
//          ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.INVALID_REFERENCE_TO_THIS
// [cfe] Expected identifier, but got 'this'.
class H {
  instanceMethod() {}
}

@Tag(named: super)
//          ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONSTANT_ARGUMENT
// [analyzer] COMPILE_TIME_ERROR.SUPER_IN_INVALID_CONTEXT
// [cfe] Expected identifier, but got 'super'.
class I {
  instanceMethod() {}
}

main() {}
