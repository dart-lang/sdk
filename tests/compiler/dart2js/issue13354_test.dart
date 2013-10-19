// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = """
bar() => 42;
baz() => bar;

class A {
  foo() => 42;
}

class B extends A {
  foo() => super.foo;
}

main() {
  baz();
  new B().foo();
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var typesTask = compiler.typesTask;
    var typesInferrer = typesTask.typesInferrer;

    checkReturn(String name, type) {
      var element = findElement(compiler, name);
      Expect.equals(
          type,
          typesInferrer.getReturnTypeOfElement(element).simplify(compiler),
          name);
    }

    checkReturnInClass(String className, String methodName, type) {
      var cls = findElement(compiler, className);
      var element = cls.lookupLocalMember(methodName);
      Expect.equals(type,
          typesInferrer.getReturnTypeOfElement(element).simplify(compiler));
    }

    checkReturn('bar', typesTask.intType);
    checkReturn('baz', typesTask.functionType);

    checkReturnInClass('A', 'foo', typesTask.intType);
    checkReturnInClass('B', 'foo', typesTask.functionType);
  }));
}
