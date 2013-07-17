// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = """
var a = '';
class A {
  operator+(other) => other;
}

foo() {
  // The following '+' call will first say that it may call A::+,
  // String::+, or int::+. After all methods have been analyzed, we know
  // that a is of type String, and therefore, this method cannot call
  // A::+. Therefore, the type of the parameter of A::+ will be the
  // one given by the other calls.
  return a + 'foo';
}

main() {
  new A() + 42;
  foo();
}
""";


void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturnInClass(String className, String methodName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(methodName));
    Expect.equals(type, typesInferrer.getReturnTypeOfElement(element));
  }

  checkReturnInClass('A', '+', compiler.typesTask.intType);
}
