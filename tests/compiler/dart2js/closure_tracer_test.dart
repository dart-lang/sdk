// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'compiler_helper.dart';
import 'parser_helper.dart';
import 'type_mask_test_helper.dart';

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
  static foo(a) => topLevel3 = a;
}

testStoredInInstance() {
  var res;
  closure(a) => res = a;
  var a = new A(closure);
  a.field(42);
  return res;
}

testStoredInMapOfList() {
  var res;
  closure(a) => res = a;
  var a = [closure];
  var b = {'foo' : 1};
  b['bar'] = a;
  b['bar'][0](42);
  return res;
}

testStoredInListOfList() {
  var res;
  closure(a) => res = a;
  var a = [closure];
  var b = [0, 1, 2];
  b[1] = a;
  b[1][0](42);
  return res;
}

testStoredInListOfListUsingInsert() {
  var res;
  closure(a) => res = a;
  var a = [closure];
  var b = [0, 1, 2];
  b.insert(1, a);
  b[1][0](42);
  return res;
}

testStoredInListOfListUsingAdd() {
  var res;
  closure(a) => res = a;
  var a = [closure];
  var b = [0, 1, 2];
  b.add(a);
  b[3][0](42);
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

var topLevel1;
foo2(a) => topLevel1 = a;
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

var topLevel2;
bar(a) => topLevel2 = a;
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

var topLevel3;
testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

var topLevel4;
testStaticClosure4Helper(a) => topLevel4 = a;
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

main() {
  testFunctionStatement();
  testFunctionExpression();
  testStoredInStatic();
  testStoredInInstance();
  testStoredInMapOfList();
  testStoredInListOfList();
  testStoredInListOfListUsingInsert();
  testStoredInListOfListUsingAdd();
  testPassedInParameter();
  testStaticClosure1();
  testStaticClosure2();
  testStaticClosure3();
  testStaticClosure4();
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
      Expect.equals(type.nullable(), simplify(mask, compiler), name);
    }

    checkType('testFunctionStatement', typesTask.uint31Type);
    checkType('testFunctionExpression', typesTask.uint31Type);
    checkType('testStoredInInstance', typesTask.uint31Type);
    checkType('testStoredInStatic', typesTask.uint31Type);
    checkType('testStoredInMapOfList', typesTask.uint31Type);
    checkType('testStoredInListOfList', typesTask.uint31Type);
    checkType('testStoredInListOfListUsingInsert', typesTask.uint31Type);
    checkType('testStoredInListOfListUsingAdd', typesTask.uint31Type);
    checkType('testPassedInParameter', typesTask.uint31Type);
    checkType('testStaticClosure1', typesTask.uint31Type);
    checkType('testStaticClosure2', typesTask.numType);
    checkType('testStaticClosure3', typesTask.uint31Type);
    checkType('testStaticClosure4', typesTask.numType);
  }));
}
