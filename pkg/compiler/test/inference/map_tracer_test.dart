// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';

import 'type_mask_test_helper.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';

String generateTest(String mapAllocation) {
  return """
dynamic anInt = 42;
dynamic aDouble = 42.5;
String aKey = 'aKey';
String anotherKey = 'anotherKey';
String presetKey = 'presetKey';

class A {
  final field;
  var nonFinalField;

  A(this.field);

  A.bar(map) : field = null {
    nonFinalField = map;
  }

  receiveIt(map) {
    map[aKey] = aDouble;
  }

  returnIt() {
    return mapReturnedFromSelector;
  }

  useField() {
    field[aKey] = aDouble;
  }

  set callSetter(map) {
    map[aKey] = aDouble;
  }

  operator[](key) {
    key[aKey] = aDouble;
  }

  operator[]=(index, value) {
    index[aKey] = anInt;
    if (value == mapEscapingTwiceInIndexSet) {
      value[aKey] = aDouble;
    }
  }
}

class B extends A {
  B(map) : super.bar(map);

  set nonFinalField(value) {
    value[aKey] = aDouble;
  }
}

class C {
  C();

  operator[]=(index, value) {
    index[aKey] = anInt;
    value[aKey] = aDouble;
  }
}

var mapInField = $mapAllocation;
var mapPassedToClosure = $mapAllocation;
var mapReturnedFromClosure = $mapAllocation;
var mapPassedToMethod = $mapAllocation;
var mapReturnedFromMethod = $mapAllocation;
var mapUsedWithCascade = $mapAllocation;
var mapUsedInClosure = $mapAllocation;
var mapPassedToSelector = $mapAllocation;
var mapReturnedFromSelector = $mapAllocation;
var mapUsedWithNonOkSelector = $mapAllocation;
var mapUsedWithConstraint = $mapAllocation;
var mapEscapingFromSetter = $mapAllocation;
var mapUsedInLocal = $mapAllocation;
var mapUnset = $mapAllocation;
var mapOnlySetWithConstraint = $mapAllocation;
var mapEscapingInSetterValue = $mapAllocation;
var mapEscapingInIndex = $mapAllocation;
var mapEscapingInIndexSet = $mapAllocation;
var mapEscapingTwiceInIndexSet = $mapAllocation;
var mapPassedAsOptionalParameter = $mapAllocation;
var mapPassedAsNamedParameter = $mapAllocation;
var mapSetInNonFinalField = $mapAllocation;
var mapStoredInList = $mapAllocation;
var mapStoredInListButEscapes = $mapAllocation;
var mapStoredInMap = $mapAllocation;
var mapStoredInMapButEscapes = $mapAllocation;

foo(map) {
  map[aKey] = aDouble;
}

bar() {
  return mapReturnedFromMethod;
}

takeOptional([map]) {
  map[aKey] = aDouble;
}

takeNamed({map}) {
  map[aKey] = aDouble;
}

main() {
  anInt++;

  mapReturnedFromMethod[aKey] = anInt;
  bar()[aKey] = aDouble;

  mapPassedToMethod[aKey] = anInt;
  foo(mapPassedToMethod);

  mapPassedToClosure[aKey] = anInt;
  ((a) => a[aKey] = aDouble)(mapPassedToClosure);

  mapReturnedFromClosure[aKey] = anInt;
  (() => mapReturnedFromClosure)()[aKey] = aDouble;

  mapInField[aKey] = anInt;
  new A(mapInField).useField();

  mapUsedWithCascade[aKey] = anInt;
  mapUsedWithCascade..[aKey] = aDouble;

  mapUsedInClosure[aKey] = anInt;
  (() => mapUsedInClosure[aKey] = aDouble)();

  mapPassedToSelector[aKey] = anInt;
  new A(null).receiveIt(mapPassedToSelector);

  mapReturnedFromSelector[aKey] = anInt;
  new A(null).returnIt()[aKey] = aDouble;

  mapUsedWithNonOkSelector[aKey] = anInt;
  mapUsedWithNonOkSelector.map((k,v) => v);

  mapUsedWithConstraint[aKey] = anInt;
  mapUsedWithConstraint[aKey]++;
  mapUsedWithConstraint[aKey] += anInt;

  mapEscapingFromSetter[aKey] = anInt;
  foo((new A(null) as dynamic).field = mapEscapingFromSetter);

  mapUsedInLocal[aKey] = anInt;
  dynamic a = mapUsedInLocal;
  mapUsedInLocal[anotherKey] = aDouble;

  // At least use [mapUnset] in a local to pretend it's used.
  dynamic b = mapUnset;

  mapOnlySetWithConstraint[aKey]++;

  mapEscapingInSetterValue[aKey] = anInt;
  new A(null).callSetter = mapEscapingInSetterValue;

  mapEscapingInIndex[aKey] = anInt;
  new A(null)[mapEscapingInIndex];

  new A(null)[mapEscapingInIndexSet] = 42;

  new C()[mapEscapingTwiceInIndexSet] = mapEscapingTwiceInIndexSet;

  mapPassedAsOptionalParameter[aKey] = anInt;
  takeOptional(mapPassedAsOptionalParameter);

  mapPassedAsNamedParameter[aKey] = anInt;
  takeNamed(map: mapPassedAsNamedParameter);

  mapSetInNonFinalField[aKey] = anInt;
  new B(mapSetInNonFinalField);

  a = [mapStoredInList];
  a[0][aKey] = 42;

  a = [mapStoredInListButEscapes];
  a[0][aKey] = 42;
  a.forEach((e) => print(e));

  a = {aKey: mapStoredInMap};
  a[aKey][aKey] = 42;

  a = {aKey: mapStoredInMapButEscapes};
  a[aKey][aKey] = 42;
  a.forEach((k,v) => print(v));
}
""";
}

void main() {
  runTests() async {
    // Test empty literal map
    await doTest('<dynamic, dynamic>{}');
    // Test preset map of <String,uint32>
    await doTest('<dynamic, dynamic>{presetKey : anInt}',
        keyElementName: "presetKey", valueElementName: "anInt");
    // Test preset map of <Double,uint32>
    await doTest('<dynamic, dynamic>{aDouble : anInt}',
        keyElementName: "aDouble", valueElementName: "anInt");
  }

  asyncTest(() async {
    await runTests();
  });
}

doTest(String allocation,
    {String keyElementName, String valueElementName}) async {
  String source = generateTest(allocation);
  var result = await runCompiler(memorySourceFiles: {'main.dart': source});
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  TypeMask keyType, valueType;
  GlobalTypeInferenceResults results =
      compiler.globalInference.resultsForTesting;
  JClosedWorld closedWorld = results.closedWorld;
  AbstractValueDomain commonMasks = closedWorld.abstractValueDomain;
  TypeMask emptyType = new TypeMask.nonNullEmpty();
  MemberEntity aKey = findMember(closedWorld, 'aKey');
  TypeMask aKeyType = results.resultOfMember(aKey).type;
  if (keyElementName != null) {
    MemberEntity keyElement = findMember(closedWorld, keyElementName);
    keyType = results.resultOfMember(keyElement).type;
  }
  if (valueElementName != null) {
    MemberEntity valueElement = findMember(closedWorld, valueElementName);
    valueType = results.resultOfMember(valueElement).type;
  }
  if (keyType == null) keyType = emptyType;
  if (valueType == null) valueType = emptyType;

  checkType(String name, keyType, valueType) {
    MemberEntity element = findMember(closedWorld, name);
    MapTypeMask mask = results.resultOfMember(element).type;
    Expect.equals(keyType, simplify(mask.keyType, commonMasks), name);
    Expect.equals(valueType, simplify(mask.valueType, commonMasks), name);
  }

  K(TypeMask other) => simplify(keyType.union(other, commonMasks), commonMasks);
  V(TypeMask other) =>
      simplify(valueType.union(other, commonMasks).nullable(), commonMasks);

  checkType('mapInField', K(aKeyType), V(commonMasks.numType));
  checkType('mapPassedToMethod', K(aKeyType), V(commonMasks.numType));
  checkType('mapReturnedFromMethod', K(aKeyType), V(commonMasks.numType));
  checkType('mapUsedWithCascade', K(aKeyType), V(commonMasks.numType));
  checkType('mapUsedInClosure', K(aKeyType), V(commonMasks.numType));
  checkType('mapPassedToSelector', K(aKeyType), V(commonMasks.numType));
  checkType('mapReturnedFromSelector', K(aKeyType), V(commonMasks.numType));
  checkType(
      'mapUsedWithConstraint', K(aKeyType), V(commonMasks.positiveIntType));
  checkType('mapEscapingFromSetter', K(aKeyType), V(commonMasks.numType));
  checkType('mapUsedInLocal', K(aKeyType), V(commonMasks.numType));
  checkType('mapEscapingInSetterValue', K(aKeyType), V(commonMasks.numType));
  checkType('mapEscapingInIndex', K(aKeyType), V(commonMasks.numType));
  checkType(
      'mapEscapingInIndexSet', K(aKeyType), V(commonMasks.positiveIntType));
  // TODO(johnniwinther): Reenable this when we don't bail out due to
  // (benign) JS calls.
  //checkType('mapEscapingTwiceInIndexSet', K(aKeyType), V(commonMasks.numType));
  checkType('mapSetInNonFinalField', K(aKeyType), V(commonMasks.numType));

  checkType('mapPassedToClosure', K(commonMasks.dynamicType),
      V(commonMasks.dynamicType));
  checkType('mapReturnedFromClosure', K(commonMasks.dynamicType),
      V(commonMasks.dynamicType));
  checkType('mapUsedWithNonOkSelector', K(commonMasks.dynamicType),
      V(commonMasks.dynamicType));
  checkType(
      'mapPassedAsOptionalParameter', K(aKeyType), V(commonMasks.numType));
  checkType('mapPassedAsNamedParameter', K(aKeyType), V(commonMasks.numType));
  checkType('mapStoredInList', K(aKeyType), V(commonMasks.uint31Type));
  checkType('mapStoredInListButEscapes', K(commonMasks.dynamicType),
      V(commonMasks.dynamicType));
  checkType('mapStoredInMap', K(aKeyType), V(commonMasks.uint31Type));
  checkType('mapStoredInMapButEscapes', K(commonMasks.dynamicType),
      V(commonMasks.dynamicType));

  checkType('mapUnset', K(emptyType), V(emptyType));
  checkType('mapOnlySetWithConstraint', K(aKeyType), V(emptyType));
}
