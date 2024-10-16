// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/record_shape.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

main() {
  runTest() async {
    TypeEnvironment env = await TypeEnvironment.create(r"""
      class A {}
      class B extends A {}
      main() {
        final a = (1, 2);
        final b = (3,);
        final c = (1, foo: 2).runtimeType;
        final d = ().hashCode;
        print(A());
        print(B());
      }
      """, testBackendWorld: true);
    JClosedWorld world = env.jClosedWorld;
    final domain = world.abstractValueDomain as CommonMasks;

    TypeMask unionOf(List<FlatTypeMask> masks) =>
        UnionTypeMask.unionOf(masks, domain);

    void expectRecordMask(TypeMask actual, List<TypeMask> expectedTypes,
        {bool expectNullable = false, bool expectHasLateSentinel = false}) {
      Expect.type<RecordTypeMask>(actual);
      actual as RecordTypeMask;
      Expect.listEquals(actual.types, expectedTypes);
      Expect.equals(expectNullable, actual.isNullable);
      Expect.equals(expectHasLateSentinel, actual.hasLateSentinel);
    }

    void expectUnionMask(TypeMask actual, List<TypeMask> expectedTypes,
        {bool expectNullable = false, bool expectHasLateSentinel = false}) {
      Expect.type<UnionTypeMask>(actual);
      actual as UnionTypeMask;
      Expect.setEquals(actual.disjointMasks.toSet(), expectedTypes.toSet());
      Expect.equals(expectNullable, actual.isNullable);
      Expect.equals(expectHasLateSentinel, actual.hasLateSentinel);
    }

    void expectFlatRecordMask(TypeMask actual, ClassEntity recordClass,
        {bool expectNullable = false, bool expectHasLateSentinel = false}) {
      Expect.type<FlatTypeMask>(actual);
      actual as FlatTypeMask;
      Expect.equals(actual.base, recordClass);
      Expect.equals(expectNullable, actual.isNullable);
      Expect.equals(expectHasLateSentinel, actual.hasLateSentinel);
    }

    void expectDynamicMask(TypeMask actual,
        {bool expectHasLateSentinel = false}) {
      Expect.type<FlatTypeMask>(actual);
      actual as FlatTypeMask;
      Expect.isTrue(domain.containsAll(actual).isPotentiallyTrue);
      Expect.equals(expectHasLateSentinel, actual.hasLateSentinel);
    }

    void expectEmptyMask(TypeMask actual,
        {bool expectNullable = false, bool expectHasLateSentinel = false}) {
      Expect.type<FlatTypeMask>(actual);
      actual as FlatTypeMask;
      Expect.isTrue(actual.isEmptyOrFlagged);
      Expect.equals(expectNullable, actual.isNullable);
      Expect.equals(expectHasLateSentinel, actual.hasLateSentinel);
    }

    // Base types
    final aMask = FlatTypeMask.nonNullSubclass(env.getClass('A'), world);
    final bMask = FlatTypeMask.nonNullExact(env.getClass('B'), world);
    final stringMask =
        FlatTypeMask.nonNullExact(world.commonElements.jsStringClass, world);

    // General record classes
    final record0ArityMask =
        FlatTypeMask.nonNullExact(world.commonElements.emptyRecordClass, world);
    final record1ArityMask = FlatTypeMask.nonNullExact(
        world.commonElements.recordArityClass(1), world);
    final record2ArityMask = FlatTypeMask.nonNullExact(
        world.commonElements.recordArityClass(2), world);
    final record3ArityMask = FlatTypeMask.nonNullExact(
        world.commonElements.recordArityClass(3), world);
    final recordBaseFlatMask = FlatTypeMask.nonNullSubclass(
        world.commonElements.recordBaseClass, world);
    final recordFlatMask =
        FlatTypeMask.nonNullSubtype(world.commonElements.recordClass, world);

    // Shapes
    final shape0 = RecordShape(0, []);
    final shape0Class = world.recordData.representationForShape(shape0)!.cls;
    final shape0Mask = FlatTypeMask.nonNullExact(shape0Class, world);
    final shape1 = RecordShape(1, []);
    final shape1Class = world.recordData.representationForShape(shape1)!.cls;
    final shape1Mask = FlatTypeMask.nonNullExact(shape1Class, world);
    final shape2 = RecordShape(2, []);
    final shape2Class = world.recordData.representationForShape(shape2)!.cls;
    final shape2Mask = FlatTypeMask.nonNullExact(shape2Class, world);
    final shape1Foo = RecordShape(1, ["foo"]);
    final shape1FooClass =
        world.recordData.representationForShape(shape1Foo)!.cls;
    final shape1FooMask = FlatTypeMask.nonNullExact(shape1FooClass, world);
    final uninstantiatedShape = RecordShape(2, ["bar"]);

    // Record types
    final emptyRecordMask =
        RecordTypeMask.createRecord(domain, [], shape0) as RecordTypeMask;
    final recordAMask =
        RecordTypeMask.createRecord(domain, [aMask], shape1) as RecordTypeMask;
    final recordBMask =
        RecordTypeMask.createRecord(domain, [bMask], shape1) as RecordTypeMask;
    final recordStringMask =
        RecordTypeMask.createRecord(domain, [stringMask], shape1)
            as RecordTypeMask;
    final recordAStringMask =
        RecordTypeMask.createRecord(domain, [aMask, stringMask], shape2)
            as RecordTypeMask;
    final recordStringBMask =
        RecordTypeMask.createRecord(domain, [stringMask, bMask], shape2)
            as RecordTypeMask;
    final recordAFooStringMask =
        RecordTypeMask.createRecord(domain, [aMask, stringMask], shape1Foo)
            as RecordTypeMask;
    final recordBStringMask =
        RecordTypeMask.createRecord(domain, [bMask, stringMask], shape2)
            as RecordTypeMask;
    final uninstantiatedRecordMask = RecordTypeMask.createRecord(
        domain, [aMask, aMask, aMask], uninstantiatedShape) as RecordTypeMask;

    // Record member names
    final position1GetterName = Name('\$1', null);
    final position2GetterName = Name('\$2', null);
    final fooGetterName = Name('foo', null);

    // ---createRecord tests---
    expectEmptyMask(
        RecordTypeMask.createRecord(domain, [aMask, domain.emptyType], shape2));
    expectRecordMask(
        RecordTypeMask.createRecord(domain,
            [aMask, domain.emptyType.withFlags(isNullable: true)], shape2),
        [aMask, domain.emptyType.withFlags(isNullable: true)]);
    expectRecordMask(
        RecordTypeMask.createRecord(domain,
            [aMask, domain.emptyType.withFlags(hasLateSentinel: true)], shape2),
        [aMask, domain.emptyType.withFlags(hasLateSentinel: true)]);
    expectRecordMask(
        RecordTypeMask.createRecord(domain, [aMask, bMask], shape2),
        [aMask, bMask]);

    // ---union tests---
    // (A) | (A) => (A)
    expectRecordMask(recordAMask.union(recordAMask, domain), [aMask]);
    // (A) | [(A)|null] => [(A)|null]
    expectRecordMask(
        recordAMask.union(recordAMask.withFlags(isNullable: true), domain),
        [aMask],
        expectNullable: true);
    // [(A)|null] | (A)  => [(A)|null]
    expectRecordMask(
        recordAMask.withFlags(isNullable: true).union(recordAMask, domain),
        [aMask],
        expectNullable: true);
    // (A) | [(A)|late] => [(A)|late]
    expectRecordMask(
        recordAMask.union(recordAMask.withFlags(hasLateSentinel: true), domain),
        [aMask],
        expectHasLateSentinel: true);
    // [(A)|late] | (A)  => [(A)|late]
    expectRecordMask(
        recordAMask.withFlags(hasLateSentinel: true).union(recordAMask, domain),
        [aMask],
        expectHasLateSentinel: true);
    // (B) | (A) => (A)
    expectRecordMask(recordBMask.union(recordAMask, domain), [aMask]);
    // (A) | (B) => (A)
    expectRecordMask(recordAMask.union(recordBMask, domain), [aMask]);
    // (string) | (B) => (Union[string, B])
    expectRecordMask(recordStringMask.union(recordBMask, domain), [
      unionOf([stringMask, bMask])
    ]);
    // (B) | (string) => (Union[string, B])
    expectRecordMask(recordBMask.union(recordStringMask, domain), [
      unionOf([stringMask, bMask])
    ]);
    // (A, string) | (string, B) => (Union[B, string], Union[string, B])
    expectRecordMask(recordAStringMask.union(recordStringBMask, domain), [
      unionOf([aMask, stringMask]),
      unionOf([bMask, stringMask])
    ]);
    // (A, string) | (string) => Union[[subclass=_Record_2],[subclass=_Record_1]]]
    expectUnionMask(recordAStringMask.union(recordStringMask, domain),
        [shape2Mask, shape1Mask]);
    // (A, string) | (A, foo: string) => Union[[subclass=_Record_2],[subclass=_Record_2_foo]]]
    expectUnionMask(recordAStringMask.union(recordAFooStringMask, domain),
        [shape2Mask, shape1FooMask]);
    // (A, string) | [subclass=_Record2] => [subclass=_Record2]
    expectFlatRecordMask(recordAStringMask.union(record2ArityMask, domain),
        world.commonElements.recordArityClass(2));
    // (A, string) | [subclass=_Record1] => Union[[subclass=_Record1, subclass=_Record_2]]
    expectUnionMask(recordAStringMask.union(record1ArityMask, domain),
        [record1ArityMask, shape2Mask]);
    // (A, string) | [subclass=_Record] => [subclass=_Record]
    expectFlatRecordMask(recordAStringMask.union(recordBaseFlatMask, domain),
        world.commonElements.recordBaseClass);
    // (A, string) | [subtype=Record] => [subtype=Record]
    expectFlatRecordMask(recordAStringMask.union(recordFlatMask, domain),
        world.commonElements.recordClass);
    // (A, string) | [subclass=_Record|null] => [subclass=_Record|null]
    expectFlatRecordMask(
        recordAStringMask.union(
            recordBaseFlatMask.withFlags(isNullable: true), domain),
        world.commonElements.recordBaseClass,
        expectNullable: true);
    // (A, string) | [subclass=_Record|late] => [subclass=_Record|late]
    expectFlatRecordMask(
        recordAStringMask.union(
            recordBaseFlatMask.withFlags(hasLateSentinel: true), domain),
        world.commonElements.recordBaseClass,
        expectHasLateSentinel: true);
    // (A, string) | [dynamic] => [dynamic]
    expectDynamicMask(recordAStringMask.union(domain.dynamicType, domain));
    // (A, string) | [empty] => (A, string)
    expectRecordMask(
        recordAStringMask.union(domain.emptyType, domain), [aMask, stringMask]);
    // (A, string) | [empty|null] => [(A, string)|null]
    expectRecordMask(
        recordAStringMask.union(
            domain.emptyType.withFlags(isNullable: true), domain),
        [aMask, stringMask],
        expectNullable: true);
    // [(A, string)|null] | [empty] => [(A, string)|null]
    expectRecordMask(
        recordAStringMask
            .withFlags(isNullable: true)
            .union(domain.emptyType, domain),
        [aMask, stringMask],
        expectNullable: true);
    // (A, string) | [empty|late] => [(A, string)|late]
    expectRecordMask(
        recordAStringMask.union(
            domain.emptyType.withFlags(hasLateSentinel: true), domain),
        [aMask, stringMask],
        expectHasLateSentinel: true);
    // [(A, string)|late] | [empty] => [(A, string)|late]
    expectRecordMask(
        recordAStringMask
            .withFlags(hasLateSentinel: true)
            .union(domain.emptyType, domain),
        [aMask, stringMask],
        expectHasLateSentinel: true);
    // (A) | string => Union[[subclass=_Record_1], string]
    expectUnionMask(
        recordAMask.union(stringMask, domain), [shape1Mask, stringMask]);
    // (A, A, bar: A) | (A, string) => Union[[subclass=_Record3], [subclass=_Record_2]]
    expectUnionMask(uninstantiatedRecordMask.union(recordAStringMask, domain),
        [record3ArityMask, shape2Mask]);
    // () | (A, string) => Union[[subclass=_EmptyRecord],[subclass=_Record_2]]
    expectUnionMask(emptyRecordMask.union(recordAStringMask, domain),
        [record0ArityMask, shape2Mask]);
    // () | () => ()
    expectRecordMask(emptyRecordMask.union(emptyRecordMask, domain), []);

    // ---intersection tests---
    // (A) & (A) => (A)
    expectRecordMask(recordAMask.intersection(recordAMask, domain), [aMask]);
    // (A) & [(A)|null] => (A)
    expectRecordMask(
        recordAMask.intersection(
            recordAMask.withFlags(isNullable: true), domain),
        [aMask]);
    // [(A)|null] & (A)  => (A)
    expectRecordMask(
        recordAMask
            .withFlags(isNullable: true)
            .intersection(recordAMask, domain),
        [aMask]);
    // [(A)|null] & [(A)|null] => [(A)|null]
    expectRecordMask(
        recordAMask
            .withFlags(isNullable: true)
            .intersection(recordAMask.withFlags(isNullable: true), domain),
        [aMask],
        expectNullable: true);
    // (A) & [(A)|late] => (A)
    expectRecordMask(
        recordAMask.intersection(
            recordAMask.withFlags(hasLateSentinel: true), domain),
        [aMask]);
    // [(A)|late] & (A)  => (A)
    expectRecordMask(
        recordAMask
            .withFlags(hasLateSentinel: true)
            .intersection(recordAMask, domain),
        [aMask]);
    // [(A)|late] & [(A)|late]  => ([(A)|late]
    expectRecordMask(
        recordAMask
            .withFlags(hasLateSentinel: true)
            .intersection(recordAMask.withFlags(hasLateSentinel: true), domain),
        [aMask],
        expectHasLateSentinel: true);
    // (B) & (A) => (B)
    expectRecordMask(recordBMask.intersection(recordAMask, domain), [bMask]);
    // (A) & (B) => (B)
    expectRecordMask(recordAMask.intersection(recordBMask, domain), [bMask]);
    // (string) & (B) => [empty]
    expectEmptyMask(recordStringMask.intersection(recordBMask, domain));
    // (B) & (string) => [empty]
    expectEmptyMask(recordBMask.intersection(recordStringMask, domain));
    // (A, string) & (string, B) => [empty]
    expectEmptyMask(recordAStringMask.intersection(recordStringBMask, domain));
    // (A, string) & (string) => [empty]
    expectEmptyMask(recordAStringMask.intersection(recordStringMask, domain));
    // (A, string) & (A, foo: string) => [empty]
    expectEmptyMask(
        recordAStringMask.intersection(recordAFooStringMask, domain));
    // (A, string) & [subclass=_Record2] => (A, string)
    expectRecordMask(recordAStringMask.intersection(record2ArityMask, domain),
        [aMask, stringMask]);
    // (A, string) & [subclass=_Record1] => [empty]
    expectEmptyMask(recordAStringMask.intersection(record1ArityMask, domain));
    // (A, string) & [subclass=_Record] => (A, string)
    expectRecordMask(recordAStringMask.intersection(recordBaseFlatMask, domain),
        [aMask, stringMask]);
    // (A, string) & [subtype=Record] => (A, string)
    expectRecordMask(recordAStringMask.intersection(recordFlatMask, domain),
        [aMask, stringMask]);
    // (A, string) & [subclass=_Record|null] => (A, string)
    expectRecordMask(
        recordAStringMask.intersection(
            recordBaseFlatMask.withFlags(isNullable: true), domain),
        [aMask, stringMask]);
    // [(A, string)|null] & [subclass=_Record|null] => [(A, string)|null]
    expectRecordMask(
        recordAStringMask.withFlags(isNullable: true).intersection(
            recordBaseFlatMask.withFlags(isNullable: true), domain),
        [aMask, stringMask],
        expectNullable: true);
    // (A, string) & [subclass=_Record|late] => (A, string)
    expectRecordMask(
        recordAStringMask.intersection(
            recordBaseFlatMask.withFlags(hasLateSentinel: true), domain),
        [aMask, stringMask]);
    // [(A, string)|late] & [subclass=_Record|late] => [(A, string)|late]
    expectRecordMask(
        recordAStringMask.withFlags(hasLateSentinel: true).intersection(
            recordBaseFlatMask.withFlags(hasLateSentinel: true), domain),
        [aMask, stringMask],
        expectHasLateSentinel: true);
    // (A, string) & [dynamic] => (A, string)
    expectRecordMask(recordAStringMask.intersection(domain.dynamicType, domain),
        [aMask, stringMask]);
    // (A, string) & [empty] => [empty]
    expectEmptyMask(recordAStringMask.intersection(domain.emptyType, domain));
    // (A, string) & [empty|null] => [empty]
    expectEmptyMask(recordAStringMask.intersection(
        domain.emptyType.withFlags(isNullable: true), domain));
    // [(A, string)|null] & [empty] => [empty]
    expectEmptyMask(recordAStringMask
        .withFlags(isNullable: true)
        .intersection(domain.emptyType, domain));
    // [(A, string)|null] & [empty|null] => [empty|null]
    expectEmptyMask(
        recordAStringMask
            .withFlags(isNullable: true)
            .intersection(domain.emptyType.withFlags(isNullable: true), domain),
        expectNullable: true);
    // (A, string) & [empty|late] => [empty]
    expectEmptyMask(recordAStringMask.intersection(
        domain.emptyType.withFlags(hasLateSentinel: true), domain));
    // [(A, string)|late] & [empty] => [empty]
    expectEmptyMask(recordAStringMask
        .withFlags(hasLateSentinel: true)
        .intersection(domain.emptyType, domain));
    // [(A, string)|late] & [empty|late] => [empty|late]
    expectEmptyMask(
        recordAStringMask.withFlags(hasLateSentinel: true).intersection(
            domain.emptyType.withFlags(hasLateSentinel: true), domain),
        expectHasLateSentinel: true);
    // (A) & string => [empty]
    expectEmptyMask(recordAMask.intersection(stringMask, domain));
    // (A, A, bar: A) & (A, string) => [empty]
    expectEmptyMask(
        uninstantiatedRecordMask.intersection(recordAStringMask, domain));
    // () & (A, string) => [empty]
    expectEmptyMask(emptyRecordMask.intersection(recordAStringMask, domain));
    // () & () => ()
    expectRecordMask(emptyRecordMask.intersection(emptyRecordMask, domain), []);

    // ---needsNoSuchMethodHandling tests---
    Expect.isTrue(emptyRecordMask.needsNoSuchMethodHandling(
        Selector.getter(position1GetterName), world));
    Expect.isFalse(recordAStringMask.needsNoSuchMethodHandling(
        Selector.getter(position1GetterName), world));
    Expect.isFalse(recordAStringMask.needsNoSuchMethodHandling(
        Selector.getter(position2GetterName), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.getter(Name('\$3', null)), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.getter(fooGetterName), world));
    Expect.isFalse(recordAFooStringMask.needsNoSuchMethodHandling(
        Selector.getter(fooGetterName), world));
    Expect.isFalse(recordAStringMask.needsNoSuchMethodHandling(
        Selector.call(position1GetterName, CallStructure.NO_ARGS), world));
    Expect.isFalse(recordAStringMask.needsNoSuchMethodHandling(
        Selector.call(position2GetterName, CallStructure.NO_ARGS), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.call(Name('\$3', null), CallStructure.NO_ARGS), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.call(fooGetterName, CallStructure.NO_ARGS), world));
    Expect.isFalse(recordAFooStringMask.needsNoSuchMethodHandling(
        Selector.call(fooGetterName, CallStructure.NO_ARGS), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.setter(position1GetterName), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.setter(position2GetterName), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.setter(Name('\$3', null)), world));
    Expect.isTrue(recordAStringMask.needsNoSuchMethodHandling(
        Selector.setter(fooGetterName), world));
    Expect.isTrue(recordAFooStringMask.needsNoSuchMethodHandling(
        Selector.setter(fooGetterName), world));
    for (final selector in Selectors.objectSelectors) {
      Expect.isFalse(
          recordAStringMask.needsNoSuchMethodHandling(selector, world));
    }

    // ---contains tests---
    Expect.isTrue(emptyRecordMask.contains(shape0Class, world));
    Expect.isFalse(emptyRecordMask.contains(shape1Class, world));
    Expect.isTrue(recordAMask.contains(shape1Class, world));
    Expect.isTrue(recordAStringMask.contains(shape2Class, world));
    Expect.isFalse(recordAStringMask.contains(shape1Class, world));
    Expect.isFalse(recordAStringMask.contains(shape1FooClass, world));
    Expect.isFalse(recordAMask.contains(shape2Class, world));
    Expect.isFalse(
        recordAMask.contains(world.commonElements.recordArityClass(1), world));
    Expect.isFalse(
        recordAMask.contains(world.commonElements.recordArityClass(2), world));
    Expect.isFalse(
        recordAMask.contains(world.commonElements.recordBaseClass, world));
    Expect.isFalse(uninstantiatedRecordMask.contains(
        world.commonElements.recordBaseClass, world));

    // ---satisfies tests---
    Expect.isTrue(emptyRecordMask.satisfies(shape0Class, world));
    Expect.isFalse(emptyRecordMask.satisfies(shape1Class, world));
    Expect.isTrue(recordAMask.satisfies(shape1Class, world));
    Expect.isTrue(recordAStringMask.satisfies(shape2Class, world));
    Expect.isFalse(recordAStringMask.satisfies(shape1Class, world));
    Expect.isFalse(recordAStringMask.satisfies(shape1FooClass, world));
    Expect.isFalse(recordAMask.satisfies(shape2Class, world));
    Expect.isTrue(
        recordAMask.satisfies(world.commonElements.recordArityClass(1), world));
    Expect.isFalse(
        recordAMask.satisfies(world.commonElements.recordArityClass(2), world));
    Expect.isTrue(
        recordAMask.satisfies(world.commonElements.recordBaseClass, world));
    Expect.isTrue(
        recordAMask.satisfies(world.commonElements.recordClass, world));
    Expect.isFalse(uninstantiatedRecordMask.satisfies(
        world.commonElements.recordBaseClass, world));

    // ---containsMask tests---
    // () > () => true
    Expect.isTrue(emptyRecordMask.containsMask(emptyRecordMask, world));
    // (A) > (A) => true
    Expect.isTrue(recordAMask.containsMask(recordAMask, world));
    // (A) > (B) => true
    Expect.isTrue(recordAMask.containsMask(recordBMask, world));
    // (B) > (A) => false
    Expect.isFalse(recordBMask.containsMask(recordAMask, world));
    // (A) > (string) => false
    Expect.isFalse(recordAMask.containsMask(recordStringMask, world));
    // (A, string) > (A) => false
    Expect.isFalse(recordAStringMask.containsMask(recordAMask, world));
    // (A, string) > (string) => false
    Expect.isFalse(recordAStringMask.containsMask(recordStringBMask, world));
    // (A, string) > (B, string) => true
    Expect.isTrue(recordAStringMask.containsMask(recordBStringMask, world));
    // (B, string) > (A, string) => false
    Expect.isFalse(recordBStringMask.containsMask(recordAStringMask, world));
    // (A, string) > (A, foo: string) => false
    Expect.isFalse(recordAStringMask.containsMask(recordAFooStringMask, world));
    // [(A)|null] > (A) => true
    Expect.isTrue(recordAMask
        .withFlags(isNullable: true)
        .containsMask(recordAMask, world));
    // (A) > [(A)|null] => false
    Expect.isFalse(recordAMask.containsMask(
        recordAMask.withFlags(isNullable: true), world));
    // [(A)|null] > [(A)|null] => true
    Expect.isTrue(recordAMask
        .withFlags(isNullable: true)
        .containsMask(recordAMask.withFlags(isNullable: true), world));
    // [(A)|late] > (A) => true
    Expect.isTrue(recordAMask
        .withFlags(hasLateSentinel: true)
        .containsMask(recordAMask, world));
    // (A) > [(A)|late] => false
    Expect.isFalse(recordAMask.containsMask(
        recordAMask.withFlags(hasLateSentinel: true), world));
    // [(A)|late] > [(A)|late] => true
    Expect.isTrue(recordAMask
        .withFlags(hasLateSentinel: true)
        .containsMask(recordAMask.withFlags(hasLateSentinel: true), world));
    // (A) > [subclass=_Record_1] => false
    Expect.isFalse(recordAMask.containsMask(shape1Mask, world));
    // (A) > [subclass=_Record1] => false
    Expect.isFalse(recordAMask.containsMask(record1ArityMask, world));
    // (A) > [subclass=_Record] => false
    Expect.isFalse(recordAMask.containsMask(recordBaseFlatMask, world));
    // (A) > [subtype=Record] => false
    Expect.isFalse(recordAMask.containsMask(recordFlatMask, world));
    // (A) > [dynamic] => false
    Expect.isFalse(recordAMask.containsMask(domain.dynamicType, world));
    // (A) > [empty] => true
    Expect.isTrue(recordAMask.containsMask(domain.emptyType, world));
    // (A) > string => false
    Expect.isFalse(recordAMask.containsMask(stringMask, world));
    // (A, A, bar: A) > (A) => false
    Expect.isFalse(uninstantiatedRecordMask.containsMask(recordAMask, world));

    // ---isInMask tests---
    // () < () => true
    Expect.isTrue(emptyRecordMask.isInMask(emptyRecordMask, world));
    // (A) < (A) => true
    Expect.isTrue(recordAMask.isInMask(recordAMask, world));
    // (A) < (B) => false
    Expect.isFalse(recordAMask.isInMask(recordBMask, world));
    // (B) < (A) => true
    Expect.isTrue(recordBMask.isInMask(recordAMask, world));
    // (A) < (string) => false
    Expect.isFalse(recordAMask.isInMask(recordStringMask, world));
    // (A, string) < (A) => false
    Expect.isFalse(recordAStringMask.isInMask(aMask, world));
    // (A, string) < (string) => false
    Expect.isFalse(recordAStringMask.isInMask(stringMask, world));
    // (A, string) < (B, string) => false
    Expect.isFalse(recordAStringMask.isInMask(recordBStringMask, world));
    // (B, string) < (A, string) => true
    Expect.isTrue(recordBStringMask.isInMask(recordAStringMask, world));
    // (A, string) < (A, foo: string) => false
    Expect.isFalse(recordAStringMask.isInMask(recordAFooStringMask, world));
    // [(A)|null] < (A) => false
    Expect.isFalse(
        recordAMask.withFlags(isNullable: true).isInMask(recordAMask, world));
    // (A) < [(A)|null] => true
    Expect.isTrue(
        recordAMask.isInMask(recordAMask.withFlags(isNullable: true), world));
    // [(A)|null] < [(A)|null] => true
    Expect.isTrue(recordAMask
        .withFlags(isNullable: true)
        .isInMask(recordAMask.withFlags(isNullable: true), world));
    // [(A)|late] < (A) => false
    Expect.isFalse(recordAMask
        .withFlags(hasLateSentinel: true)
        .isInMask(recordAMask, world));
    // (A) < [(A)|late] => true
    Expect.isTrue(recordAMask.isInMask(
        recordAMask.withFlags(hasLateSentinel: true), world));
    // [(A)|late] < [(A)|late] => true
    Expect.isTrue(recordAMask
        .withFlags(hasLateSentinel: true)
        .isInMask(recordAMask.withFlags(hasLateSentinel: true), world));
    // (A) < [subclass=_Record_1] => true
    Expect.isTrue(recordAMask.isInMask(shape1Mask, world));
    // (A) < [subclass=_Record1] => true
    Expect.isTrue(recordAMask.isInMask(record1ArityMask, world));
    // (A) < [subclass=_Record2] => false
    Expect.isFalse(recordAMask.isInMask(record2ArityMask, world));
    // (A) < [subclass=_Record] => true
    Expect.isTrue(recordAMask.isInMask(recordBaseFlatMask, world));
    // (A) < [subtype=Record] => true
    Expect.isTrue(recordAMask.isInMask(recordFlatMask, world));
    // (A) < [dynamic] => true
    Expect.isTrue(recordAMask.isInMask(domain.dynamicType, world));
    // (A) < [empty] => false
    Expect.isFalse(recordAMask.isInMask(domain.emptyType, world));
    // (A) < string => false
    Expect.isFalse(recordAMask.isInMask(stringMask, world));
    // (A, A, bar: A) < (A) => false
    Expect.isFalse(uninstantiatedRecordMask.isInMask(recordAMask, world));

    // ---isDisjoint tests---
    // () ^ () => true
    Expect.isFalse(emptyRecordMask.isDisjoint(emptyRecordMask, world));
    // (A) ^ (A) => false
    Expect.isFalse(recordAMask.isDisjoint(recordAMask, world));
    // (A) ^ (B) => false
    Expect.isFalse(recordAMask.isDisjoint(recordBMask, world));
    // (B) ^ (A) => false
    Expect.isFalse(recordBMask.isDisjoint(recordAMask, world));
    // (A) ^ (string) => true
    Expect.isTrue(recordAMask.isDisjoint(recordStringMask, world));
    // (A, string) ^ (A) => true
    Expect.isTrue(recordAStringMask.isDisjoint(aMask, world));
    // (A, string) ^ (string) => true
    Expect.isTrue(recordAStringMask.isDisjoint(stringMask, world));
    // (A, string) ^ (B, string) => false
    Expect.isFalse(recordAStringMask.isDisjoint(recordBStringMask, world));
    // (B, string) ^ (A, string) => false
    Expect.isFalse(recordBStringMask.isDisjoint(recordAStringMask, world));
    // (A, string) ^ (A, foo: string) => true
    Expect.isTrue(recordAStringMask.isDisjoint(recordAFooStringMask, world));
    // [(A)|null] ^ (A) => false
    Expect.isFalse(
        recordAMask.withFlags(isNullable: true).isDisjoint(recordAMask, world));
    // (A) ^ [(A)|null] => false
    Expect.isFalse(
        recordAMask.isDisjoint(recordAMask.withFlags(isNullable: true), world));
    // [(A)|null] ^ [(A)|null] => false
    Expect.isFalse(recordAMask
        .withFlags(isNullable: true)
        .isDisjoint(recordAMask.withFlags(isNullable: true), world));
    // [(A)|late] ^ (A) => false
    Expect.isFalse(recordAMask
        .withFlags(hasLateSentinel: true)
        .isDisjoint(recordAMask, world));
    // (A) ^ [(A)|late] => false
    Expect.isFalse(recordAMask.isDisjoint(
        recordAMask.withFlags(hasLateSentinel: true), world));
    // [(A)|late] ^ [(A)|late] => false
    Expect.isFalse(recordAMask
        .withFlags(hasLateSentinel: true)
        .isDisjoint(recordAMask.withFlags(hasLateSentinel: true), world));
    // (A) ^ [subclass=_Record_1] => false
    Expect.isFalse(recordAMask.isDisjoint(shape1Mask, world));
    // (A) ^ [subclass=_Record1] => false
    Expect.isFalse(recordAMask.isDisjoint(record1ArityMask, world));
    // (A) ^ [subclass=_Record2] => true
    Expect.isTrue(recordAMask.isDisjoint(record2ArityMask, world));
    // (A) ^ [subclass=_Record] => false
    Expect.isFalse(recordAMask.isDisjoint(recordBaseFlatMask, world));
    // (A) ^ [subtype=Record] => false
    Expect.isFalse(recordAMask.isDisjoint(recordFlatMask, world));
    // (A) ^ [dynamic] => false
    Expect.isFalse(recordAMask.isDisjoint(domain.dynamicType, world));
    // (A) ^ [empty] => true
    Expect.isTrue(recordAMask.isDisjoint(domain.emptyType, world));
    // (A) ^ string => true
    Expect.isTrue(recordAMask.isDisjoint(stringMask, world));
    // (A, A, bar: A) ^ (A) => true
    Expect.isTrue(uninstantiatedRecordMask.isDisjoint(recordAMask, world));

    // ---toFlatTypeMask tests---
    Expect.equals(shape0Mask, emptyRecordMask.toFlatTypeMask(world));
    Expect.equals(shape1Mask, recordAMask.toFlatTypeMask(world));
    Expect.equals(shape2Mask, recordBStringMask.toFlatTypeMask(world));
    Expect.equals(
        record3ArityMask, uninstantiatedRecordMask.toFlatTypeMask(world));
    Expect.equals(shape1Mask.withFlags(isNullable: true),
        recordAMask.withFlags(isNullable: true).toFlatTypeMask(world));
    Expect.equals(shape1Mask.withFlags(hasLateSentinel: true),
        recordAMask.withFlags(hasLateSentinel: true).toFlatTypeMask(world));

    // ---canHit tests---
    void expectCanHit(TypeMask mask, ClassEntity cls, Name name) {
      Expect.isTrue(mask.canHit(
          env.elementEnvironment.lookupClassMember(cls, name)!, name, world));
    }

    void expectCannotHit(TypeMask mask, ClassEntity cls, Name name) {
      Expect.isFalse(mask.canHit(
          env.elementEnvironment.lookupClassMember(cls, name)!, name, world));
    }

    expectCanHit(recordAMask, shape1Class, position1GetterName);
    expectCannotHit(recordAMask, shape2Class, position1GetterName);
    expectCannotHit(recordAMask, shape2Class, position2GetterName);
    expectCannotHit(recordAMask, shape1FooClass, fooGetterName);

    expectCannotHit(recordBStringMask, shape1Class, position1GetterName);
    expectCanHit(recordBStringMask, shape2Class, position1GetterName);
    expectCanHit(recordBStringMask, shape2Class, position2GetterName);
    expectCannotHit(recordBStringMask, shape1FooClass, fooGetterName);

    expectCannotHit(recordAStringMask, shape1Class, position1GetterName);
    expectCanHit(recordAStringMask, shape2Class, position1GetterName);
    expectCanHit(recordAStringMask, shape2Class, position2GetterName);
    expectCannotHit(recordAStringMask, shape1FooClass, fooGetterName);

    expectCannotHit(recordAFooStringMask, shape1Class, position1GetterName);
    expectCannotHit(recordAFooStringMask, shape2Class, position2GetterName);
    expectCanHit(recordAFooStringMask, shape1FooClass, position1GetterName);
    expectCanHit(recordAFooStringMask, shape1FooClass, fooGetterName);

    for (final selector in Selectors.objectSelectors) {
      expectCanHit(emptyRecordMask, shape0Class, selector.memberName);
      expectCanHit(recordAMask, shape1Class, selector.memberName);
    }

    // ---locateSingleMember tests---
    void expectSingleMember(
        TypeMask mask, Name name, ClassEntity cls, Selector selector) {
      Expect.equals(env.elementEnvironment.lookupClassMember(cls, name),
          mask.locateSingleMember(selector, domain));
    }

    void expectGetterMember(TypeMask mask, Name name, ClassEntity cls) {
      expectSingleMember(mask, name, cls, Selector.getter(name));
    }

    void expectCallMember(TypeMask mask, Name name, ClassEntity cls) {
      expectSingleMember(
          mask, name, cls, Selector.call(name, CallStructure.NO_ARGS));
    }

    void expectNoMember(TypeMask mask, Name name) {
      Expect.isNull(mask.locateSingleMember(Selector.getter(name), domain));
    }

    expectGetterMember(recordAMask, position1GetterName, shape1Class);
    expectCallMember(recordAMask, position1GetterName, shape1Class);
    expectNoMember(recordAMask, position2GetterName);
    expectNoMember(recordAMask, fooGetterName);

    expectGetterMember(recordAStringMask, position1GetterName, shape2Class);
    expectCallMember(recordAStringMask, position1GetterName, shape2Class);
    expectGetterMember(recordAStringMask, position2GetterName, shape2Class);
    expectCallMember(recordAStringMask, position2GetterName, shape2Class);
    expectNoMember(recordAStringMask, fooGetterName);

    expectGetterMember(
        recordAFooStringMask, position1GetterName, shape1FooClass);
    expectCallMember(recordAFooStringMask, position1GetterName, shape1FooClass);
    expectGetterMember(
        recordAFooStringMask, position2GetterName, shape1FooClass);
    expectCallMember(recordAFooStringMask, position2GetterName, shape1FooClass);
    expectGetterMember(recordAFooStringMask, fooGetterName, shape1FooClass);
    expectCallMember(recordAFooStringMask, fooGetterName, shape1FooClass);
    expectNoMember(recordAFooStringMask, position2GetterName);

    for (final selector in Selectors.objectSelectors) {
      expectSingleMember(
          recordAMask, selector.memberName, shape1Class, selector);
    }

    // ---singleClass tests---
    Expect.equals(shape0Class, emptyRecordMask.singleClass(world));
    Expect.equals(shape1Class, recordAMask.singleClass(world));
    Expect.equals(shape1Class, recordBMask.singleClass(world));
    Expect.equals(shape2Class, recordAStringMask.singleClass(world));
    Expect.equals(shape2Class, recordStringBMask.singleClass(world));
    Expect.equals(shape1FooClass, recordAFooStringMask.singleClass(world));
    Expect.isNull(uninstantiatedRecordMask.singleClass(world));

    // ---== tests---
    Expect.isTrue(emptyRecordMask == emptyRecordMask);
    Expect.isFalse(emptyRecordMask == recordAMask);
    Expect.isTrue(recordAMask == recordAMask);
    Expect.isTrue(
        recordAMask.withFlags(isNullable: true, hasLateSentinel: false) ==
            recordAMask.withFlags(isNullable: true, hasLateSentinel: false));
    Expect.isTrue(
        recordAMask.withFlags(isNullable: false, hasLateSentinel: true) ==
            recordAMask.withFlags(isNullable: false, hasLateSentinel: true));
    Expect.isFalse(
        recordAMask.withFlags(isNullable: true, hasLateSentinel: false) ==
            recordAMask.withFlags(isNullable: false, hasLateSentinel: false));
    Expect.isFalse(
        recordAMask.withFlags(isNullable: false, hasLateSentinel: true) ==
            recordAMask.withFlags(isNullable: false, hasLateSentinel: false));
    Expect.isFalse(recordAMask == recordBMask);
    Expect.isFalse(recordAMask == stringMask);
    Expect.isFalse(recordAStringMask == recordAFooStringMask);

    // ---isExact tests---
    Expect.isTrue(emptyRecordMask.isExact);
    Expect.isFalse(recordAMask.isExact);
    Expect.isTrue(recordBMask.isExact);
    Expect.isFalse(recordAStringMask.isExact);
    Expect.isTrue(recordBStringMask.isExact);

    // ---isEmpty tests---
    Expect.isFalse(recordAMask.isEmpty);
    Expect.isFalse(recordAMask.isEmpty);

    // ---isEmptyOrFlagged tests---
    Expect.isFalse(recordAMask.isEmptyOrFlagged);
    Expect.isFalse(recordAMask.isEmptyOrFlagged);

    // ---isLateSentinel tests---
    Expect.equals(AbstractBool.False, recordAMask.isLateSentinel);
    Expect.equals(AbstractBool.Maybe,
        recordAMask.withFlags(hasLateSentinel: true).isLateSentinel);
    Expect.equals(
        AbstractBool.Maybe,
        recordAMask
            .withFlags(isNullable: true, hasLateSentinel: true)
            .isLateSentinel);

    // ---isNull tests---
    Expect.isFalse(recordAMask.isNull);
    Expect.isFalse(recordAMask.withFlags(isNullable: true).isNull);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
