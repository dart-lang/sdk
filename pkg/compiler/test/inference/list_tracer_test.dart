// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:expect/expect.dart';

import 'type_mask_test_helper.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';

String generateTest(String listAllocation) {
  return """
dynamic anInt = 42;
dynamic aDouble = 42.5;

class A {
  final field;
  var nonFinalField;

  A(this.field);

  A.bar(list) : field = null {
    nonFinalField = list;
  }

  receiveIt(list) {
    list[0] = aDouble;
  }

  returnIt() {
    return listReturnedFromSelector;
  }

  useField() {
    field[0] = aDouble;
  }

  set callSetter(list) {
    list[0] = aDouble;
  }

  operator[](index) {
    index[0] = aDouble;
  }

  operator[]=(index, value) {
    index[0] = anInt;
    if (value == listEscapingTwiceInIndexSet) {
      value[0] = aDouble;
    }
  }
}

class B extends A {
  B(list) : super.bar(list);

  set nonFinalField(value) {
    value[0] = aDouble;
  }
}

var listInField = $listAllocation;
var listPassedToClosure = $listAllocation;
var listReturnedFromClosure = $listAllocation;
var listPassedToMethod = $listAllocation;
var listReturnedFromMethod = $listAllocation;
var listUsedWithCascade = $listAllocation;
var listUsedInClosure = $listAllocation;
var listPassedToSelector = $listAllocation;
var listReturnedFromSelector = $listAllocation;
var listUsedWithAddAndInsert = $listAllocation;
var listUsedWithNonOkSelector = $listAllocation;
var listUsedWithConstraint = $listAllocation;
var listEscapingFromSetter = $listAllocation;
var listUsedInLocal = $listAllocation;
var listUnset = $listAllocation;
var listOnlySetWithConstraint = $listAllocation;
var listEscapingInSetterValue = $listAllocation;
var listEscapingInIndex = $listAllocation;
var listEscapingInIndexSet = $listAllocation;
var listEscapingTwiceInIndexSet = $listAllocation;
var listPassedAsOptionalParameter = $listAllocation;
var listPassedAsNamedParameter = $listAllocation;
var listSetInNonFinalField = $listAllocation;
var listWithChangedLength = $listAllocation;
var listStoredInList = $listAllocation;
var listStoredInListButEscapes = $listAllocation;

foo(list) {
  list[0] = aDouble;
}

bar() {
  return listReturnedFromMethod;
}

takeOptional([list]) {
  list[0] = aDouble;
}

takeNamed({list}) {
  list[0] = aDouble;
}

main() {
  listReturnedFromMethod[0] = anInt;
  bar()[0] = aDouble;

  listPassedToMethod[0] = anInt;
  foo(listPassedToMethod);

  listPassedToClosure[0] = anInt;
  ((a) => a[0] = aDouble)(listPassedToClosure);

  listReturnedFromClosure[0] = anInt;
  (() => listReturnedFromClosure)()[0] = aDouble;

  listInField[0] = anInt;
  new A(listInField).useField();

  listUsedWithCascade[0] = anInt;
  listUsedWithCascade..[0] = aDouble;

  listUsedInClosure[0] = anInt;
  (() => listUsedInClosure[0] = aDouble)();

  listPassedToSelector[0] = anInt;
  new A(null).receiveIt(listPassedToSelector);

  listReturnedFromSelector[0] = anInt;
  new A(null).returnIt()[0] = aDouble;

  listUsedWithAddAndInsert.add(anInt);
  listUsedWithAddAndInsert.insert(0, aDouble);

  listUsedWithNonOkSelector[0] = anInt;
  listUsedWithNonOkSelector.addAll(listPassedToClosure);

  listUsedWithConstraint[0] = anInt;
  listUsedWithConstraint[0]++;
  listUsedWithConstraint[0] += anInt;

  listEscapingFromSetter[0] = anInt;
  foo((new A(null) as dynamic).field = listEscapingFromSetter);

  listUsedInLocal[0] = anInt;
  dynamic a = listUsedInLocal;
  listUsedInLocal[1] = aDouble;

  // At least use [listUnused] in a local to pretend it's used.
  dynamic b = listUnset;

  listOnlySetWithConstraint[0]++;

  listEscapingInSetterValue[0] = anInt;
  new A(null).callSetter = listEscapingInSetterValue;

  listEscapingInIndex[0] = anInt;
  new A(null)[listEscapingInIndex];

  new A(null)[listEscapingInIndexSet] = 42;

  new A(null)[listEscapingTwiceInIndexSet] = listEscapingTwiceInIndexSet;

  listPassedAsOptionalParameter[0] = anInt;
  takeOptional(listPassedAsOptionalParameter);

  listPassedAsNamedParameter[0] = anInt;
  takeNamed(list: listPassedAsNamedParameter);

  listSetInNonFinalField[0] = anInt;
  new B(listSetInNonFinalField);

  listWithChangedLength[0] = anInt;
  listWithChangedLength.length = 54;

  a = [listStoredInList];
  a[0][0] = 42;

  a = [listStoredInListButEscapes];
  a[0][0] = 42;
  a.forEach((e) => print(e));
}
""";
}

void main() {
  runTest() async {
    // Test literal list.
    await doTest('<dynamic>[]', nullify: false);
    // Test growable list.
    await doTest('new List<dynamic>()', nullify: false);
    // Test fixed list.
    await doTest('new List<dynamic>(1)', nullify: true);
    // Test List.filled.
    await doTest('new List<dynamic>.filled(1, 0)', nullify: false);
    // Test List.filled.
    await doTest('new List<dynamic>.filled(1, null)', nullify: true);
  }

  asyncTest(() async {
    await runTest();
  });
}

doTest(String allocation, {bool nullify}) async {
  String source = generateTest(allocation);
  var result = await runCompiler(memorySourceFiles: {'main.dart': source});
  Expect.isTrue(result.isSuccess);
  var compiler = result.compiler;
  var results = compiler.globalInference.resultsForTesting;
  var closedWorld = results.closedWorld;
  var commonMasks = closedWorld.abstractValueDomain;

  checkType(String name, type) {
    var element = findMember(closedWorld, name);
    ContainerTypeMask mask = results.resultOfMember(element).type;
    if (nullify) type = type.nullable();
    Expect.equals(type, simplify(mask.elementType, commonMasks), name);
  }

  checkType('listInField', commonMasks.numType);
  checkType('listPassedToMethod', commonMasks.numType);
  checkType('listReturnedFromMethod', commonMasks.numType);
  checkType('listUsedWithCascade', commonMasks.numType);
  checkType('listUsedInClosure', commonMasks.numType);
  checkType('listPassedToSelector', commonMasks.numType);
  checkType('listReturnedFromSelector', commonMasks.numType);
  checkType('listUsedWithAddAndInsert', commonMasks.numType);
  checkType('listUsedWithConstraint', commonMasks.positiveIntType);
  checkType('listEscapingFromSetter', commonMasks.numType);
  checkType('listUsedInLocal', commonMasks.numType);
  checkType('listEscapingInSetterValue', commonMasks.numType);
  checkType('listEscapingInIndex', commonMasks.numType);
  checkType('listEscapingInIndexSet', commonMasks.uint31Type);
  checkType('listEscapingTwiceInIndexSet', commonMasks.numType);
  checkType('listSetInNonFinalField', commonMasks.numType);
  checkType('listWithChangedLength', commonMasks.uint31Type.nullable());

  checkType('listPassedToClosure', commonMasks.dynamicType);
  checkType('listReturnedFromClosure', commonMasks.dynamicType);
  checkType('listUsedWithNonOkSelector', commonMasks.dynamicType);
  checkType('listPassedAsOptionalParameter', commonMasks.numType);
  checkType('listPassedAsNamedParameter', commonMasks.numType);
  checkType('listStoredInList', commonMasks.uint31Type);
  checkType('listStoredInListButEscapes', commonMasks.dynamicType);

  if (!allocation.contains('filled')) {
    checkType('listUnset', new TypeMask.nonNullEmpty());
    checkType('listOnlySetWithConstraint', new TypeMask.nonNullEmpty());
  }
}
