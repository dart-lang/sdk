// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for the runtime type implementation.

library basic_tests;

import 'js_backend_cps_ir.dart';

const String getTypeArgument = r'H.getTypeArgumentByIndex';
const String getSubstitutedTypeArgument = 'H.getRuntimeTypeArgument';
const String typeToString = r'H.runtimeTypeToString';
const String createType = r'H.createRuntimeType';

const List<TestEntry> tests = const [
    const TestEntry.forMethod("function(C#foo)",
r"""
class C<T> {
  foo() => print(T);
}

main() {
  new C<int>().foo();
}""",
"""
function() {
  return P.print($createType($typeToString($getTypeArgument(this, 0))));
}"""),
    const TestEntry.forMethod("function(C#foo)",
r"""
class C<T, U> {
  foo() => print(U);
}

class D extends C<int, double> {}

main() {
  new D().foo();
}""",
"""
function() {
  return P.print($createType($typeToString($getSubstitutedTypeArgument(this, "C", 1))));
}"""),
  const TestEntry.forMethod('function(C#foo)', r"""
class C<T> {
  foo() => new D<C<T>>();
}
class D<T> {
  bar() => T;
}
main() {
  print(new C<int>().foo().bar());
}""", """
function() {
  return V.D\$([V.C, $getTypeArgument(this, 0)]);
}"""),
    const TestEntry.forMethod('generative_constructor(C#)', r"""
class C<X, Y, Z> {
  foo() => 'C<$X $Y, $Z>';
}
main() {
  new C<C, int, String>().foo();
}""", r"""
function($X, $Y, $Z) {
  return H.setRuntimeTypeInfo(new V.C(), [$X, $Y, $Z]);
}"""),
];

void main() {
  runTests(tests);
}
