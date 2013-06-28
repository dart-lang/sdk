// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart";
import "mock_compiler.dart";
import "parser_helper.dart";

String TEST_0 = '''
class Foo {
  Foo();
  Foo.named();
  factory Foo._internal() => null;
  operator+(other) => null;
}
''';

String TEST_1 = '''
class Bar {
  const Bar();
  const Bar.named();
  Map<int, List<int>> baz() => null;
}
''';

main() {
  MockCompiler compiler = new MockCompiler();
  testClass(TEST_0, compiler);
  testClass(TEST_1, compiler);
}

testClass(String code, MockCompiler compiler) {
  int skip = code.indexOf('{');
  ClassElement cls = parseUnit(code, compiler, compiler.mainApp).head;
  cls.parseNode(compiler);
  for (Element e in cls.localMembers) {
    String name = e.name.slowToString();
    if (e.isConstructor()) name = name.replaceFirst(r'$', '.');
    Expect.equals(code.indexOf(name, skip), e.position().charOffset);
  }
}
