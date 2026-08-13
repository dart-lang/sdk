// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';
import 'print_helper.dart';

void main() {
  final propertyCall = testExpression('a.f(1)');
  Expect.type<Call>(propertyCall);

  testExpression('#.g(2)', propertyCall, 'a.f(1).g(2)');

  // Calls in the `new` target need to be parenthesized to prevent the call
  // arguments from being taken as the `new` arguments.
  testExpression('new #.a()', propertyCall, 'new (a.f(1)).a()');
  testExpression('new #(2)', testExpression('f(1)'), 'new (f(1))(2)');
  testExpression('new #(2)', testExpression('f(1).x'), 'new (f(1)).x(2)');
  testExpression('new #(2)', testExpression('f(1).x()'), 'new (f(1).x())(2)');

  testExpression('new (f.x)()', 'new f.x()');
  testExpression('new (f().x)()', 'new (f()).x()'); // Also ok: `new (f().x)()`
  testExpression('new (f.x())()', 'new (f.x())()');

  testExpression('(new f.x(1))(2)', 'new f.x(1)(2)');

  testExpression('new (new f(g(1).x))(2)', 'new new f(g(1).x)(2)');

  testExpression('new f[g(1).x](2)');
  testExpression('new (f()[g(1).x])(2)', 'new (f())[g(1).x](2)');
  testExpression('new (f[g(1).x])(2)', 'new f[g(1).x](2)');

  // All the operators that have a second expression that is not protected (by
  // being inside an argument list or `[]` index) have lower priority than the
  // `new` MemberExpression, so require parentheses regardless of whether they
  // contain a call.
  testExpression('new (f || g)(1)');
  testExpression('new (f ** g)(3)');
  testExpression('new (f(1) || g(2))(3)');
}
