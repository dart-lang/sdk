// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'compiler_helper.dart';
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
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;

        checkType(String name, type) {
          MemberElement element = findElement(compiler, name);
          var mask = typesInferrer.getReturnTypeOfMember(element);
          Expect.equals(type.nullable(), simplify(mask, closedWorld), name);
        }

        checkType('testFunctionStatement', commonMasks.uint31Type);
        checkType('testFunctionExpression', commonMasks.uint31Type);
        checkType('testStoredInInstance', commonMasks.uint31Type);
        checkType('testStoredInStatic', commonMasks.uint31Type);
        checkType('testStoredInMapOfList', commonMasks.uint31Type);
        checkType('testStoredInListOfList', commonMasks.uint31Type);
        checkType('testStoredInListOfListUsingInsert', commonMasks.uint31Type);
        checkType('testStoredInListOfListUsingAdd', commonMasks.uint31Type);
        checkType('testPassedInParameter', commonMasks.uint31Type);
        checkType('testStaticClosure1', commonMasks.uint31Type);
        checkType('testStaticClosure2', commonMasks.numType);
        checkType('testStaticClosure3', commonMasks.uint31Type);
        checkType('testStaticClosure4', commonMasks.numType);
      }));
}
