// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = '''
testFunctionStatement() {
  var res;
  closure(a) => res = a;
  closure(42);
  return res;
}

testFunctionExpression() {
  var res;
  var closure = (a) => res = a;
  closure(42);
  return res;
}

var staticField;

testStoredInStatic() {
  var res;
  closure(a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  var field;
  A(this.field);
}

testStoredInInstance() {
  var res;
  closure(a) => res = a;
  var a = new A(closure);
  a.field(42);
  return res;
}

foo(closure) {
  closure(42);
}

testPassedInParameter() {
  var res;
  closure(a) => res = a;
  foo(closure);
  return res;
}

main() {
  testFunctionStatement();
  testFunctionExpression();
  testStoredInStatic();
  testStoredInInstance();
  testPassedInParameter();
}
''';

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.runCompiler(uri).then((_) {
    var typesTask = compiler.typesTask;
    var typesInferrer = typesTask.typesInferrer;

    checkType(String name, type) {
      var element = findElement(compiler, name);
      var mask = typesInferrer.getReturnTypeOfElement(element);
      Expect.equals(type.nullable(), mask.simplify(compiler), name);
    }

    checkType('testFunctionStatement', typesTask.uint31Type);
    checkType('testFunctionExpression', typesTask.uint31Type);
    checkType('testStoredInInstance', typesTask.uint31Type);
    checkType('testStoredInStatic', typesTask.uint31Type);
    checkType('testPassedInParameter', typesTask.uint31Type);
  }));
}
