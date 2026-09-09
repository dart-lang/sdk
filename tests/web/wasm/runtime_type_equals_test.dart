// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class NonGenericA(final int x) {
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is NonGenericA && other.x == x;
  }

  @override
  int get hashCode => x.hashCode;
}

class NonGenericSubA(super.x) extends NonGenericA;

class NonGenericB(final int x);

class GenericClass<T> {
  final T value;
  GenericClass(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GenericClass<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

// Scenario A: Interface explicitly declaring runtimeType getter
abstract class InterfaceWithRuntimeType {
  Type get runtimeType;
}

class ImplOfInterfaceWithRuntimeType implements InterfaceWithRuntimeType {
  // Inherits Object.runtimeType
}

// Scenario: Non-generic base class with generic subclasses
class NonGenericBaseWithGenericSub {}

class GenericSubOfNonGeneric<T> extends NonGenericBaseWithGenericSub {
  final T value;
  GenericSubOfNonGeneric(this.value);
}

// Scenario B: Class with custom overridden runtimeType getter
class CustomRuntimeTypeOverride {
  @override
  Type get runtimeType => NonGenericA;
}

class AnotherCustomOverride {
  @override
  Type get runtimeType => String;
}

@pragma('wasm:never-inline')
bool compareRuntimeTypes(Object? a, Object? b) {
  return a?.runtimeType == b?.runtimeType;
}

@pragma('wasm:never-inline')
bool compareWithNonGeneric(NonGenericA a, Object? b) {
  return a.runtimeType == b?.runtimeType;
}

@pragma('wasm:never-inline')
bool compareNonGenericLeft(Object? a, NonGenericA b) {
  return a?.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool compareInterfaceWithNonGeneric(
  InterfaceWithRuntimeType iface,
  NonGenericA b,
) {
  return iface.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool compareCustomWithNonGeneric(
  CustomRuntimeTypeOverride custom,
  NonGenericA b,
) {
  return custom.runtimeType == b.runtimeType;
}

void main() {
  final a1 = NonGenericA(1);
  final a2 = NonGenericA(1);
  final a3 = NonGenericA(2);
  final subA = NonGenericSubA(1);
  final b1 = NonGenericB(1);

  // Test NonGenericA.==
  Expect.isTrue(a1 == a2);
  Expect.isFalse(a1 == a3);
  Expect.isFalse(a1 == subA);
  Expect.isFalse(a1 == b1);
  Expect.isFalse(a1 == 'string');
  Expect.isFalse(a1 == 123);

  // Test compareWithNonGeneric (one side is statically NonGenericA)
  Expect.isTrue(compareWithNonGeneric(a1, a2));
  Expect.isTrue(compareWithNonGeneric(a1, a3));
  Expect.isFalse(compareWithNonGeneric(a1, subA));
  Expect.isFalse(compareWithNonGeneric(a1, b1));
  Expect.isFalse(compareWithNonGeneric(a1, null));
  Expect.isFalse(compareWithNonGeneric(a1, 'test'));
  Expect.isFalse(compareWithNonGeneric(a1, 42));

  // Test compareNonGenericLeft (right side is statically NonGenericA)
  Expect.isTrue(compareNonGenericLeft(a1, a2));
  Expect.isTrue(compareNonGenericLeft(a3, a2));
  Expect.isFalse(compareNonGenericLeft(subA, a2));
  Expect.isFalse(compareNonGenericLeft(b1, a2));
  Expect.isFalse(compareNonGenericLeft(null, a2));
  Expect.isFalse(compareNonGenericLeft('test', a2));

  // Test GenericClass
  final gInt1 = GenericClass<int>(10);
  final gInt2 = GenericClass<int>(10);
  final gString = GenericClass<String>('10');
  Expect.isTrue(gInt1 == gInt2);
  Expect.isFalse(gInt1 == gString);

  // Direct equality comparisons
  Expect.isTrue(a1.runtimeType == a2.runtimeType);
  Expect.isFalse(a1.runtimeType == b1.runtimeType);
  Expect.isFalse(a1.runtimeType == subA.runtimeType);

  // Nullable variables
  NonGenericA? nullableA1 = a1;
  NonGenericA? nullableA2 = a2;
  NonGenericA? nullableNull = null;
  Expect.isTrue(nullableA1.runtimeType == nullableA2.runtimeType);
  Expect.isFalse(nullableA1.runtimeType == nullableNull.runtimeType);
  Expect.isTrue(nullableNull.runtimeType == (null as Object?).runtimeType);

  // Test Scenario A: Interface declaring runtimeType
  final InterfaceWithRuntimeType iface1 = ImplOfInterfaceWithRuntimeType();
  final InterfaceWithRuntimeType iface2 = ImplOfInterfaceWithRuntimeType();
  Expect.isTrue(iface1.runtimeType == iface2.runtimeType, 'iface1 == iface2');
  Expect.isFalse(compareInterfaceWithNonGeneric(iface1, a1), 'iface1 != a1');

  // Test Non-generic base class with generic subclasses
  final NonGenericBaseWithGenericSub baseInt1 = GenericSubOfNonGeneric<int>(1);
  final NonGenericBaseWithGenericSub baseInt2 = GenericSubOfNonGeneric<int>(2);
  final NonGenericBaseWithGenericSub baseStr = GenericSubOfNonGeneric<String>(
    's',
  );
  Expect.isTrue(
    baseInt1.runtimeType == baseInt2.runtimeType,
    'baseInt1 == baseInt2',
  );
  Expect.isFalse(
    baseInt1.runtimeType == baseStr.runtimeType,
    'baseInt1 != baseStr',
  );

  // Test Scenario B: Custom overridden runtimeType
  final custom = CustomRuntimeTypeOverride();
  final anotherCustom = AnotherCustomOverride();
  // custom.runtimeType returns Type(NonGenericA), so it must equal a1.runtimeType
  Expect.isTrue(custom.runtimeType == a1.runtimeType, 'custom == a1');
  Expect.isTrue(a1.runtimeType == custom.runtimeType, 'a1 == custom');
  Expect.isTrue(
    compareCustomWithNonGeneric(custom, a1),
    'compareCustomWithNonGeneric',
  );
  Expect.isFalse(
    anotherCustom.runtimeType == a1.runtimeType,
    'anotherCustom != a1',
  );

  // Overridden runtimeType via Object reference
  Object customAsObject = custom;
  Expect.isTrue(
    customAsObject.runtimeType == a1.runtimeType,
    'customAsObject == a1',
  );
  Expect.isTrue(
    a1.runtimeType == customAsObject.runtimeType,
    'a1 == customAsObject',
  );

  // Dynamic access
  dynamic dynCustom = custom;
  Expect.isTrue(dynCustom.runtimeType == a1.runtimeType, 'dynCustom == a1');
  Expect.isTrue(a1.runtimeType == dynCustom.runtimeType, 'a1 == dynCustom');

  // Through non-inlined generic helper functions
  Expect.isTrue(
    compareWithNonGeneric(a1, custom),
    'compareWithNonGeneric(a1, custom)',
  );
  Expect.isTrue(
    compareNonGenericLeft(custom, a1),
    'compareNonGenericLeft(custom, a1)',
  );
  Expect.isTrue(
    compareRuntimeTypes(custom, a1),
    'compareRuntimeTypes(custom, a1)',
  );
  Expect.isTrue(
    compareRuntimeTypes(a1, custom),
    'compareRuntimeTypes(a1, custom)',
  );
}
