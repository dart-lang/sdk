// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These checks are not implemented in the analyzer. If we ever decide to
// implement the static checks in the analyzer, move this test into the
// static_checks subdir to prevent analyzer errors showing up in the IDE.

import 'dart:ffi';
import 'dart:typed_data';

void main() {
  testInstantiateDeeplyImmutable();
}

@pragma('vm:deeply-immutable')
final class EmptyClass {}

@pragma('vm:deeply-immutable')
final class Class1 {
  Class1(this.a);

  int a;
  //  ^
  // [cfe] Deeply immutable classes must only have final non-late instance fields.
}

@pragma('vm:deeply-immutable')
final class Class2 {
  late final int a;
  //             ^
  // [cfe] Deeply immutable classes must only have final non-late instance fields.
}

@pragma('vm:deeply-immutable')
final class Class3 {
  Class3(this.a);

  final int a;
}

@pragma('vm:deeply-immutable')
final class Class4 {
  // Static fields are not part of the instance.
  static late final int a;
}

@pragma('vm:deeply-immutable')
final class Class5 {
  // External fields are defined as setter/getter pairs.
  external int a;
}

final class NotDeeplyImmutable {
  late int a;
}

@pragma('vm:deeply-immutable')
final class Class6 {
  Class6(this.a);

  final NotDeeplyImmutable a;
  //                       ^
  // [cfe] Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', and classes annotated with `@pragma('vm:deeply-immutable')`.
}

void testInstantiateDeeplyImmutable() {
  Class7(
    someString: 'someString',
    someNullableString: 'someString',
    someInt: 3,
    someDouble: 3.3,
    someBool: false,
    someNull: null,
    someInt32x4: Int32x4(0, 1, 2, 3),
    someFloat32x4: Float32x4(0.0, 1.1, 2.2, 3.3),
    someFloat64x2: Float64x2(4.4, 5.5),
    someClass7: Class7(
      someString: 'someString',
      someInt: 3,
      someDouble: 3.3,
      someBool: false,
      someNull: null,
      someInt32x4: Int32x4(0, 1, 2, 3),
      someFloat32x4: Float32x4(0.0, 1.1, 2.2, 3.3),
      someFloat64x2: Float64x2(4.4, 5.5),
      someClass7: null,
      somePointer: Pointer.fromAddress(0x8badf00d),
    ),
    somePointer: Pointer.fromAddress(0xdeadbeef),
  );
}

@pragma('vm:deeply-immutable')
final class Class7 {
  final String someString;
  final String? someNullableString;
  final int someInt;
  final double someDouble;
  final bool someBool;
  final Null someNull;
  final Int32x4 someInt32x4;
  final Float32x4 someFloat32x4;
  final Float64x2 someFloat64x2;
  final Class7? someClass7;
  final Pointer somePointer;

  // Note that UnmodifiableUint8ListView has been deprecated. Which means there
  // currently is no way to intentionally have a typed data as a field in a
  // class which is deeply immutable.
  // See: https://github.com/dart-lang/sdk/issues/53218.

  // Note that RegExp, SendPort, and Capability can be implemented. So fields
  // are not allowed to be of these types either.

  Class7({
    required this.someString,
    this.someNullableString,
    required this.someInt,
    required this.someDouble,
    required this.someBool,
    required this.someNull,
    required this.someInt32x4,
    required this.someFloat32x4,
    required this.someFloat64x2,
    required this.someClass7,
    required this.somePointer,
  });
}

void testInstantiateImmutableHierarchy() {
  Class8(
    animal: Cat(
      numberOfLegs: 4,
      averageNumberOfMeowsPerDay: 42.0,
    ),
  );
  Class8(
    animal: Dog(
      numberOfLegs: 4,
      averageNumberOfWoofsPerDay: 1337.0,
    ),
  );
}

@pragma('vm:deeply-immutable')
final class Animal {
  final int numberOfLegs;

  Animal({
    required this.numberOfLegs,
  });
}

@pragma('vm:deeply-immutable')
final class Cat extends Animal {
  final double averageNumberOfMeowsPerDay;

  Cat({
    required super.numberOfLegs,
    required this.averageNumberOfMeowsPerDay,
  });
}

@pragma('vm:deeply-immutable')
final class Dog extends Animal {
  final double averageNumberOfWoofsPerDay;

  Dog({
    required super.numberOfLegs,
    required this.averageNumberOfWoofsPerDay,
  });
}

@pragma('vm:deeply-immutable')
final class Class8 {
  final Animal animal;

  Class8({
    required this.animal,
  });
}

@pragma('vm:deeply-immutable')
abstract final class DeeplyImmutableInterface {}

@pragma('vm:deeply-immutable')
final class Class9 implements DeeplyImmutableInterface {}

@pragma('vm:deeply-immutable')
final class Class10 implements DeeplyImmutableInterface {}

@pragma('vm:deeply-immutable')
sealed class Class11 {}

@pragma('vm:deeply-immutable')
class NotSealedOrFinalClass {}
//    ^^^^^^^^^^^^^^^^^^^^^
// [cfe] Deeply immutable classes must be final or sealed.

final class Class12 extends DeeplyImmutableInterface {}
//          ^^^^^^^
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.

final class Class13 implements DeeplyImmutableInterface {
//          ^^^^^^^
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
}

@pragma('vm:deeply-immutable')
final class Class14<T extends DeeplyImmutableInterface> {
  final T deeplyImmutable;

  Class14({required this.deeplyImmutable});
}

@pragma('vm:deeply-immutable')
final class Class15<T extends NotDeeplyImmutable> {
  final T notDeeplyImmutable;
  //      ^^^^^^^^^^^^^^^^^^
  // [cfe] Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', and classes annotated with `@pragma('vm:deeply-immutable')`.

  Class15({required this.notDeeplyImmutable});
}

@pragma('vm:deeply-immutable')
abstract mixin class Class17 {}
//                   ^^^^^^^
// [cfe] Deeply immutable classes must be final or sealed.
