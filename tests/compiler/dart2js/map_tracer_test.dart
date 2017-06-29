// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/types/types.dart' show MapTypeMask, TypeMask;

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

String generateTest(String mapAllocation) {
  return """
int anInt = 42;
double aDouble = 42.5;
String aKey = 'aKey';
String anotherKey = 'anotherKey';
String presetKey = 'presetKey';

class A {
  final field;
  var nonFinalField;

  A(this.field);

  A.bar(map) {
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
  foo(new A(null).field = mapEscapingFromSetter);

  mapUsedInLocal[aKey] = anInt;
  var a = mapUsedInLocal;
  mapUsedInLocal[anotherKey] = aDouble;

  // At least use [mapUnset] in a local to pretend it's used.
  var b = mapUnset;

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
  // Test empty literal map
  doTest('{}');
  // Test preset map of <String,uint32>
  doTest('{presetKey : anInt}', "presetKey", "anInt");
  // Test preset map of <Double,uint32>
  doTest('{aDouble : anInt}', "aDouble", "anInt");
}

void doTest(String allocation, [String keyElement, String valueElement]) {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(generateTest(allocation), uri,
      expectedErrors: 0, expectedWarnings: 1);
  asyncTest(() => compiler.run(uri).then((_) {
        var keyType, valueType;
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;
        var emptyType = new TypeMask.nonNullEmpty();
        var aKeyType =
            typesInferrer.getTypeOfMember(findElement(compiler, 'aKey'));
        if (keyElement != null) {
          keyType =
              typesInferrer.getTypeOfMember(findElement(compiler, keyElement));
        }
        if (valueElement != null) {
          valueType = typesInferrer
              .getTypeOfMember(findElement(compiler, valueElement));
        }
        if (keyType == null) keyType = emptyType;
        if (valueType == null) valueType = emptyType;

        checkType(String name, keyType, valueType) {
          var element = findElement(compiler, name);
          MapTypeMask mask = typesInferrer.getTypeOfMember(element);
          Expect.equals(keyType, simplify(mask.keyType, closedWorld), name);
          Expect.equals(valueType, simplify(mask.valueType, closedWorld), name);
        }

        K(TypeMask other) =>
            simplify(keyType.union(other, closedWorld), closedWorld);
        V(TypeMask other) =>
            simplify(valueType.union(other, closedWorld), closedWorld)
                .nullable();

        checkType('mapInField', K(aKeyType), V(commonMasks.numType));
        checkType('mapPassedToMethod', K(aKeyType), V(commonMasks.numType));
        checkType('mapReturnedFromMethod', K(aKeyType), V(commonMasks.numType));
        checkType('mapUsedWithCascade', K(aKeyType), V(commonMasks.numType));
        checkType('mapUsedInClosure', K(aKeyType), V(commonMasks.numType));
        checkType('mapPassedToSelector', K(aKeyType), V(commonMasks.numType));
        checkType(
            'mapReturnedFromSelector', K(aKeyType), V(commonMasks.numType));
        checkType(
            'mapUsedWithConstraint', K(aKeyType), V(commonMasks.uint31Type));
        checkType('mapEscapingFromSetter', K(aKeyType), V(commonMasks.numType));
        checkType('mapUsedInLocal', K(aKeyType), V(commonMasks.numType));
        checkType(
            'mapEscapingInSetterValue', K(aKeyType), V(commonMasks.numType));
        checkType('mapEscapingInIndex', K(aKeyType), V(commonMasks.numType));
        checkType(
            'mapEscapingInIndexSet', K(aKeyType), V(commonMasks.uint31Type));
        checkType(
            'mapEscapingTwiceInIndexSet', K(aKeyType), V(commonMasks.numType));
        checkType('mapSetInNonFinalField', K(aKeyType), V(commonMasks.numType));

        checkType('mapPassedToClosure', K(commonMasks.dynamicType),
            V(commonMasks.dynamicType));
        checkType('mapReturnedFromClosure', K(commonMasks.dynamicType),
            V(commonMasks.dynamicType));
        checkType('mapUsedWithNonOkSelector', K(commonMasks.dynamicType),
            V(commonMasks.dynamicType));
        checkType('mapPassedAsOptionalParameter', K(aKeyType),
            V(commonMasks.numType));
        checkType(
            'mapPassedAsNamedParameter', K(aKeyType), V(commonMasks.numType));
        checkType('mapStoredInList', K(aKeyType), V(commonMasks.uint31Type));
        checkType('mapStoredInListButEscapes', K(commonMasks.dynamicType),
            V(commonMasks.dynamicType));
        checkType('mapStoredInMap', K(aKeyType), V(commonMasks.uint31Type));
        checkType('mapStoredInMapButEscapes', K(commonMasks.dynamicType),
            V(commonMasks.dynamicType));

        checkType('mapUnset', K(emptyType), V(emptyType));
        checkType('mapOnlySetWithConstraint', K(aKeyType), V(emptyType));
      }));
}
