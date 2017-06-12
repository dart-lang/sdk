// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that resolution does not resolve things we know will not be
// needed by the backend.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/apiimpl.dart';
import 'compiler_helper.dart';

const String NO_RUNTIME_TYPE = r"""
import 'dart:core' as prefix;
class A {
  A();
  A.z();
  static var bar;
  static foo() {}
}
main() {
  var print = prefix.print;
  // Check when accessing a static field.
  print(A.bar);
  print(A.bar());
  // Check when calling a static method.
  print(A.foo());
  print(A.foo);
  // Check when using a constructor.
  print(new A());
  // Check when using a named constructor.
  print(new A.z());
  // Check when using a type annotation.
  A a = new A();
  // Check when using a prefix.
  print(prefix.double.NAN);
  print(prefix.double.NAN());
  print(prefix.double.parse(''));
  print(prefix.double.parse);
  print(new prefix.DateTime(0));
  print(new prefix.DateTime.utc(0));
  prefix.DateTime c = new prefix.DateTime(0);
  A.bar = 0;
}
""";

const String HAS_RUNTIME_TYPE_1 = r"""
class A {
}
main() {
  print(A);
}
""";

const String HAS_RUNTIME_TYPE_2 = r"""
class A {
}
main() {
  print(2 + A);
}
""";

const String HAS_RUNTIME_TYPE_3 = r"""
class A {
}
main() {
  print(A[0]);
}
""";

const String HAS_RUNTIME_TYPE_4 = r"""
class A {
}
main() {
  var c = A;
}
""";

const String HAS_RUNTIME_TYPE_5 = r"""
import 'dart:core' as prefix;
main() {
  prefix.print(prefix.Object);
}
""";

const String HAS_RUNTIME_TYPE_6 = r"""
class A {
  static var foo;
}
main() {
  (A).foo;
}
""";

void test(String code, void check(CompilerImpl compiler)) {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(code, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        check(compiler);
      }));
}

void testHasRuntimeType(String code) {
  test(code, (compiler) {
    var element = compiler.commonElements.createRuntimeType;
    Expect.isTrue(
        compiler.enqueuer.resolution.processedEntities.contains(element));
  });
}

main() {
  test(NO_RUNTIME_TYPE, (compiler) {
    var element = compiler.commonElements.createRuntimeType;
    Expect.isFalse(
        compiler.enqueuer.resolution.processedEntities.contains(element));
  });

  testHasRuntimeType(HAS_RUNTIME_TYPE_1);
  testHasRuntimeType(HAS_RUNTIME_TYPE_2);
  testHasRuntimeType(HAS_RUNTIME_TYPE_3);
  testHasRuntimeType(HAS_RUNTIME_TYPE_4);
  testHasRuntimeType(HAS_RUNTIME_TYPE_5);
  testHasRuntimeType(HAS_RUNTIME_TYPE_6);
}
