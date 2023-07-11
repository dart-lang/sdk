// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/types.dart';

class TestTypeHierarchy extends TypeHierarchy {
  final Map<Class, TFClass> classes = <Class, TFClass>{};
  final Map<Class, List<Class>> subtypes;
  final Map<Class, Type> specializations;
  int classIdCounter = 0;

  TestTypeHierarchy(CoreTypes coreTypes, this.subtypes, this.specializations)
      : super(coreTypes, /*nullSafety=*/ false);

  @override
  bool isSubtype(Class sub, Class sup) {
    return subtypes[sup]!.contains(sub);
  }

  @override
  Type specializeTypeCone(TFClass base, {bool allowWideCone = false}) {
    return specializations[base.classNode]!;
  }

  @override
  TFClass getTFClass(Class c) =>
      classes[c] ??= new TFClass(++classIdCounter, c, null);

  @override
  List<DartType> flattenedTypeArgumentsFor(Class klass) =>
      throw "flattenedTypeArgumentsFor is not supported in the types test.";

  @override
  int genericInterfaceOffsetFor(Class klass, Class iface) =>
      throw "genericInterfaceOffsetFor is not supported in the types test.";

  @override
  List<Type> flattenedTypeArgumentsForNonGeneric(Class klass) =>
      throw "flattenedTypeArgumentsFor is not supported in the types test.";
}

main() {
  final Component component = createMockSdkComponent();
  final CoreTypes coreTypes = new CoreTypes(component);

  test('types-builder', () {
    final Class c1 = new Class(name: 'C1', fileUri: dummyUri);
    final Class c2 = new Class(
        name: 'C2',
        typeParameters: [new TypeParameter('E')],
        fileUri: dummyUri);

    final TypesBuilder tb = new TestTypeHierarchy(coreTypes, {}, {});
    final tfc1 = tb.getTFClass(c1);
    final tfc2 = tb.getTFClass(c2);
    final tfFunction = tb.getTFClass(coreTypes.functionClass);

    final InterfaceType t1 = new InterfaceType(c1, Nullability.legacy);
    final InterfaceType t2Raw = new InterfaceType(c2, Nullability.legacy);
    final InterfaceType t2Generic =
        new InterfaceType(c2, Nullability.legacy, [t1]);
    final DartType t3 = const NullType();
    final FunctionType f1 =
        new FunctionType([t1], const VoidType(), Nullability.legacy);

    expect(tb.fromStaticType(const NeverType.nonNullable(), false),
        equals(emptyType));
    expect(
        tb.fromStaticType(const DynamicType(), true), equals(nullableAnyType));
    expect(tb.fromStaticType(const VoidType(), true), equals(nullableAnyType));

    expect(tb.fromStaticType(t1, false), equals(tfc1.coneType));
    expect(tb.fromStaticType(t2Raw, false), equals(tfc2.coneType));
    expect(tb.fromStaticType(t2Generic, false), equals(tfc2.coneType));
    expect(tb.fromStaticType(t3, false), equals(emptyType));
    expect(tb.fromStaticType(f1, false), equals(tfFunction.coneType));

    expect(tb.fromStaticType(t1, true), equals(tfc1.coneType.nullable()));
    expect(tb.fromStaticType(t2Raw, true), equals(tfc2.coneType.nullable()));
    expect(
        tb.fromStaticType(t2Generic, true), equals(tfc2.coneType.nullable()));
    expect(tb.fromStaticType(t3, true), equals(nullableEmptyType));
    expect(tb.fromStaticType(f1, true), equals(tfFunction.coneType.nullable()));

    expect(nullableAnyType, equals(nullableAnyType));
  });

  test('union-intersection', () {
    // T1 <: T3, T2 <: T3

    final c1 = new Class(name: 'T1', fileUri: dummyUri)..parent = dummyLibrary;
    final c2 = new Class(name: 'T2', fileUri: dummyUri)..parent = dummyLibrary;
    final c3 = new Class(name: 'T3', fileUri: dummyUri)..parent = dummyLibrary;
    final c4 = new Class(name: 'T4', fileUri: dummyUri)..parent = dummyLibrary;

    final tfc1 = new TFClass(1, c1, null);
    final tfc2 = new TFClass(2, c2, null);
    final tfc3 = new TFClass(3, c3, null);
    final tfc4 = new TFClass(4, c4, null);

    final empty = emptyType;
    final any = anyInstanceType;
    final concreteT1 = tfc1.concreteType;
    final concreteT2 = tfc2.concreteType;
    final concreteT3 = tfc3.concreteType;
    final concreteT4 = tfc4.concreteType;
    final coneT1 = tfc1.coneType;
    final coneT2 = tfc2.coneType;
    final coneT3 = tfc3.coneType;
    final coneT4 = tfc4.coneType;
    final setT12 = SetType([concreteT1, concreteT2]);
    final setT14 = SetType([concreteT1, concreteT4]);
    final setT23 = SetType([concreteT2, concreteT3]);
    final setT34 = SetType([concreteT3, concreteT4]);
    final setT123 = SetType([concreteT1, concreteT2, concreteT3]);
    final setT124 = SetType([concreteT1, concreteT2, concreteT4]);
    final setT1234 = SetType([concreteT1, concreteT2, concreteT3, concreteT4]);
    final nullableEmpty = empty.nullable();
    final nullableAny = any.nullable();
    final nullableConcreteT1 = concreteT1.nullable();
    final nullableConcreteT2 = concreteT2.nullable();
    final nullableConcreteT3 = concreteT3.nullable();
    final nullableConeT1 = coneT1.nullable();
    final nullableConeT3 = coneT3.nullable();
    final nullableConeT4 = coneT4.nullable();
    final nullableSetT12 = setT12.nullable();
    final nullableSetT14 = setT14.nullable();
    final nullableSetT23 = setT23.nullable();
    final nullableSetT34 = setT34.nullable();
    final nullableSetT123 = setT123.nullable();
    final nullableSetT124 = setT124.nullable();
    final nullableSetT1234 = setT1234.nullable();

    // [A, B, union, intersection]
    final testCases = [
      // empty
      [empty, empty, empty, empty],
      [empty, any, any, empty],
      [empty, concreteT1, concreteT1, empty],
      [empty, coneT1, coneT1, empty],
      [empty, setT12, setT12, empty],
      [empty, nullableEmpty, nullableEmpty, empty],
      [empty, nullableAny, nullableAny, empty],
      [empty, nullableConcreteT1, nullableConcreteT1, empty],
      [empty, nullableConeT1, nullableConeT1, empty],
      [empty, nullableSetT12, nullableSetT12, empty],
      // any
      [any, any, any, any],
      [any, concreteT1, any, concreteT1],
      [any, coneT1, any, coneT1],
      [any, setT12, any, setT12],
      [any, nullableEmpty, nullableAny, empty],
      [any, nullableAny, nullableAny, any],
      [any, nullableConcreteT1, nullableAny, concreteT1],
      [any, nullableConeT1, nullableAny, coneT1],
      [any, nullableSetT12, nullableAny, setT12],
      // nullableEmpty
      [nullableEmpty, concreteT1, nullableConcreteT1, empty],
      [nullableEmpty, coneT1, nullableConeT1, empty],
      [nullableEmpty, setT12, nullableSetT12, empty],
      [nullableEmpty, nullableEmpty, nullableEmpty, nullableEmpty],
      [nullableEmpty, nullableAny, nullableAny, nullableEmpty],
      [nullableEmpty, nullableConcreteT1, nullableConcreteT1, nullableEmpty],
      [nullableEmpty, nullableConeT1, nullableConeT1, nullableEmpty],
      [nullableEmpty, nullableSetT12, nullableSetT12, nullableEmpty],
      // nullableAny
      [nullableAny, concreteT1, nullableAny, concreteT1],
      [nullableAny, coneT1, nullableAny, coneT1],
      [nullableAny, setT12, nullableAny, setT12],
      [nullableAny, nullableAny, nullableAny, nullableAny],
      [nullableAny, nullableConcreteT1, nullableAny, nullableConcreteT1],
      [nullableAny, nullableConeT1, nullableAny, nullableConeT1],
      [nullableAny, nullableSetT12, nullableAny, nullableSetT12],
      // concrete
      [concreteT1, concreteT1, concreteT1, concreteT1],
      [concreteT1, concreteT2, setT12, empty],
      [concreteT1, coneT1, coneT1, concreteT1],
      [concreteT1, coneT2, setT12, empty],
      [concreteT1, coneT3, coneT3, concreteT1],
      [concreteT1, coneT4, setT14, empty],
      [concreteT1, setT12, setT12, concreteT1],
      [concreteT1, setT23, setT123, empty],
      [concreteT1, nullableConcreteT1, nullableConcreteT1, concreteT1],
      [concreteT1, nullableConcreteT2, nullableSetT12, empty],
      [concreteT1, nullableConeT1, nullableConeT1, concreteT1],
      [concreteT1, nullableConeT3, nullableConeT3, concreteT1],
      [concreteT1, nullableConeT4, nullableSetT14, empty],
      [concreteT1, nullableSetT12, nullableSetT12, concreteT1],
      [concreteT1, nullableSetT23, nullableSetT123, empty],
      // cone
      [coneT1, coneT1, coneT1, coneT1],
      [coneT1, coneT2, setT12, empty],
      [coneT1, coneT3, coneT3, coneT1],
      [coneT3, coneT4, setT1234, empty],
      [coneT1, setT12, setT12, concreteT1],
      [coneT1, setT23, setT123, empty],
      [coneT3, setT12, setT123, setT12],
      [coneT3, setT1234, setT1234, setT123],
      [coneT1, nullableConcreteT1, nullableConeT1, concreteT1],
      [coneT1, nullableConcreteT2, nullableSetT12, empty],
      [coneT3, nullableConcreteT2, nullableConeT3, concreteT2],
      [coneT1, nullableConeT1, nullableConeT1, coneT1],
      [coneT1, nullableConeT3, nullableConeT3, coneT1],
      [coneT1, nullableConeT4, nullableSetT14, empty],
      [coneT1, nullableSetT12, nullableSetT12, concreteT1],
      [coneT3, nullableSetT23, nullableSetT123, setT23],
      // set
      [setT12, setT12, setT12, setT12],
      [setT12, setT123, setT123, setT12],
      [setT12, setT23, setT123, concreteT2],
      [setT12, setT34, setT1234, empty],
      [setT12, nullableConcreteT1, nullableSetT12, concreteT1],
      [setT12, nullableConcreteT3, nullableSetT123, empty],
      [setT12, nullableConeT1, nullableSetT12, concreteT1],
      [setT12, nullableConeT3, nullableSetT123, setT12],
      [setT12, nullableConeT4, nullableSetT124, empty],
      [setT12, nullableSetT12, nullableSetT12, setT12],
      [setT12, nullableSetT123, nullableSetT123, setT12],
      [setT12, nullableSetT23, nullableSetT123, concreteT2],
      [setT12, nullableSetT34, nullableSetT1234, empty],
      // nullableConcrete
      [
        nullableConcreteT1,
        nullableConcreteT1,
        nullableConcreteT1,
        nullableConcreteT1
      ],
      [nullableConcreteT1, nullableConcreteT2, nullableSetT12, nullableEmpty],
      [nullableConcreteT1, nullableConeT1, nullableConeT1, nullableConcreteT1],
      [nullableConcreteT1, nullableConeT3, nullableConeT3, nullableConcreteT1],
      [nullableConcreteT1, nullableConeT4, nullableSetT14, nullableEmpty],
      [nullableConcreteT1, nullableSetT12, nullableSetT12, nullableConcreteT1],
      [nullableConcreteT1, nullableSetT23, nullableSetT123, nullableEmpty],
      // nullableCone
      [nullableConeT1, nullableConeT1, nullableConeT1, nullableConeT1],
      [nullableConeT1, nullableConeT3, nullableConeT3, nullableConeT1],
      [nullableConeT1, nullableConeT4, nullableSetT14, nullableEmpty],
      [nullableConeT1, nullableSetT12, nullableSetT12, nullableConcreteT1],
      [nullableConeT1, nullableSetT23, nullableSetT123, nullableEmpty],
      [nullableConeT3, nullableSetT14, nullableSetT1234, nullableConcreteT1],
      // nullableSet
      [nullableSetT12, nullableSetT12, nullableSetT12, nullableSetT12],
      [nullableSetT12, nullableSetT23, nullableSetT123, nullableConcreteT2],
      [nullableSetT12, nullableSetT34, nullableSetT1234, nullableEmpty],
    ];

    final hierarchy = new TestTypeHierarchy(
        coreTypes,
        // subtypes
        {
          c1: [c1],
          c2: [c2],
          c3: [c1, c2, c3],
          c4: [c4],
        },
        // specializations
        {
          c1: concreteT1,
          c2: concreteT2,
          c3: setT123,
          c4: concreteT4
        });

    for (List testCase in testCases) {
      Type a = testCase[0] as Type;
      Type b = testCase[1] as Type;
      Type union = testCase[2] as Type;
      Type intersection = testCase[3] as Type;

      expect(a.union(b, hierarchy), equals(union),
          reason: "Test case: UNION($a, $b) = $union");
      expect(b.union(a, hierarchy), equals(union),
          reason: "Test case: UNION($b, $a) = $union");
      expect(a.intersection(b, hierarchy), equals(intersection),
          reason: "Test case: INTERSECTION($a, $b) = $intersection");
      expect(b.intersection(a, hierarchy), equals(intersection),
          reason: "Test case: INTERSECTION($b, $a) = $intersection");
    }
  });

  test('hashcode-equals', () {
    final c1 = new Class(name: 'C1', fileUri: dummyUri)..parent = dummyLibrary;
    final c2 = new Class(name: 'C2', fileUri: dummyUri)..parent = dummyLibrary;
    final c3 = new Class(name: 'C3', fileUri: dummyUri)..parent = dummyLibrary;

    final tfc1 = new TFClass(1, c1, null);
    final tfc2 = new TFClass(2, c2, null);
    final tfc3 = new TFClass(3, c3, null);

    final t1a = new InterfaceType(c1, Nullability.legacy);
    final t1b = new InterfaceType(c1, Nullability.legacy);
    final t2 = new InterfaceType(c2, Nullability.legacy);

    void eq(dynamic a, dynamic b) {
      expect(a == b, isTrue, reason: "Test case: $a == $b");
      expect(a.hashCode == b.hashCode, isTrue,
          reason: "Test case: ${a}.hashCode == ${b}.hashCode");
    }

    void ne(dynamic a, dynamic b) {
      expect(a == b, isFalse, reason: "Test case: $a != $b");

      // Hash codes can be the same, but it is unlikely.
      expect(a.hashCode == b.hashCode, isFalse,
          reason: "Test case: ${a}.hashCode != ${b}.hashCode");
    }

    eq(t1a, t1b);
    ne(t1a, t2);

    eq(emptyType, emptyType);
    ne(emptyType, anyInstanceType);
    ne(emptyType, tfc1.concreteType);
    ne(emptyType, tfc1.coneType);
    ne(emptyType, SetType([tfc1.concreteType, tfc2.concreteType]));
    ne(emptyType, nullableEmptyType);

    eq(anyInstanceType, anyInstanceType);
    ne(anyInstanceType, tfc1.concreteType);
    ne(anyInstanceType, tfc1.coneType);
    ne(anyInstanceType, SetType([tfc1.concreteType, tfc2.concreteType]));
    ne(anyInstanceType, nullableEmptyType);

    eq(tfc1.concreteType, tfc1.concreteType);
    ne(tfc1.concreteType, tfc2.concreteType);
    ne(tfc1.concreteType, tfc1.coneType);
    ne(tfc1.concreteType, tfc2.coneType);
    ne(tfc1.concreteType, SetType([tfc1.concreteType, tfc2.concreteType]));
    ne(tfc1.concreteType, tfc1.concreteType.nullable());

    eq(tfc1.coneType, tfc1.coneType);
    ne(tfc1.coneType, tfc2.coneType);
    ne(tfc1.coneType, SetType([tfc1.concreteType, tfc2.concreteType]));
    ne(tfc1.coneType, tfc1.coneType.nullable());

    eq(SetType([tfc1.concreteType, tfc2.concreteType]),
        SetType([tfc1.concreteType, tfc2.concreteType]));
    eq(SetType([tfc1.concreteType, tfc2.concreteType, tfc3.concreteType]),
        SetType([tfc1.concreteType, tfc2.concreteType, tfc3.concreteType]));
    ne(SetType([tfc1.concreteType, tfc2.concreteType]),
        SetType([tfc1.concreteType, tfc2.concreteType, tfc3.concreteType]));
    ne(SetType([tfc1.concreteType, tfc2.concreteType]),
        SetType([tfc1.concreteType, tfc3.concreteType]));
    ne(SetType([tfc1.concreteType, tfc2.concreteType]),
        SetType([tfc1.concreteType, tfc2.concreteType]).nullable());
  });
}
