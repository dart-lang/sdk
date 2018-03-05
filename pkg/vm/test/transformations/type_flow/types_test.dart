// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Type;

import 'package:kernel/ast.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/types.dart';

class TestTypeHierarchy implements TypeHierarchy {
  final Map<DartType, List<DartType>> subtypes;
  final Map<DartType, Type> specializations;

  TestTypeHierarchy(this.subtypes, this.specializations);

  @override
  bool isSubtype(DartType subType, DartType superType) {
    return subtypes[superType].contains(subType);
  }

  @override
  Type specializeTypeCone(DartType base) {
    Type result = specializations[base];
    expect(result, isNotNull,
        reason: "specializeTypeCone($base) is not defined");
    return result;
  }
}

main() {
  test('factory-constructors', () {
    Class c1 = new Class(name: 'C1');
    Class c2 = new Class(name: 'C2', typeParameters: [new TypeParameter('E')]);
    InterfaceType t1 = new InterfaceType(c1);
    InterfaceType t2Raw = new InterfaceType(c2);
    InterfaceType t2Generic = new InterfaceType(c2, [t1]);
    FunctionType f1 = new FunctionType([t1], const VoidType());

    expect(new Type.empty(), equals(const EmptyType()));

    expect(new Type.cone(const DynamicType()), equals(const AnyType()));
    expect(new Type.cone(t1), equals(new ConeType(t1)));
    expect(new Type.cone(t2Raw), equals(new ConeType(t2Raw)));
    expect(new Type.cone(t2Generic), equals(new ConeType(t2Raw)));
    expect(new Type.cone(f1), equals(const AnyType()));

    expect(new Type.nullable(new Type.empty()),
        equals(new NullableType(new EmptyType())));
    expect(new Type.nullable(new Type.cone(t1)),
        equals(new NullableType(new ConeType(t1))));

    expect(new Type.nullableAny(), equals(new NullableType(new AnyType())));

    expect(new Type.fromStatic(const DynamicType()),
        equals(new NullableType(new AnyType())));
    expect(new Type.fromStatic(const DynamicType()),
        equals(new Type.nullableAny()));
    expect(new Type.fromStatic(const BottomType()),
        equals(new NullableType(new EmptyType())));
    expect(new Type.fromStatic(t1), equals(new NullableType(new ConeType(t1))));
    expect(new Type.fromStatic(t2Raw),
        equals(new NullableType(new ConeType(t2Raw))));
    expect(new Type.fromStatic(t2Generic),
        equals(new NullableType(new ConeType(t2Raw))));
  });

  test('union-intersection', () {
    // T1 <: T3, T2 <: T3

    InterfaceType t1 = new InterfaceType(new Class(name: 'T1'));
    InterfaceType t2 = new InterfaceType(new Class(name: 'T2'));
    InterfaceType t3 = new InterfaceType(new Class(name: 'T3'));
    InterfaceType t4 = new InterfaceType(new Class(name: 'T4'));

    final empty = new EmptyType();
    final any = new AnyType();
    final concreteT1 = new ConcreteType(const IntClassId(1), t1);
    final concreteT2 = new ConcreteType(const IntClassId(2), t2);
    final concreteT3 = new ConcreteType(const IntClassId(3), t3);
    final concreteT4 = new ConcreteType(const IntClassId(4), t4);
    final coneT1 = new ConeType(t1);
    final coneT2 = new ConeType(t2);
    final coneT3 = new ConeType(t3);
    final coneT4 = new ConeType(t4);
    final setT12 = new SetType([concreteT1, concreteT2]);
    final setT14 = new SetType([concreteT1, concreteT4]);
    final setT23 = new SetType([concreteT2, concreteT3]);
    final setT34 = new SetType([concreteT3, concreteT4]);
    final setT123 = new SetType([concreteT1, concreteT2, concreteT3]);
    final setT124 = new SetType([concreteT1, concreteT2, concreteT4]);
    final setT1234 =
        new SetType([concreteT1, concreteT2, concreteT3, concreteT4]);
    final nullableEmpty = new Type.nullable(empty);
    final nullableAny = new Type.nullable(any);
    final nullableConcreteT1 = new Type.nullable(concreteT1);
    final nullableConcreteT2 = new Type.nullable(concreteT2);
    final nullableConcreteT3 = new Type.nullable(concreteT3);
    final nullableConeT1 = new Type.nullable(coneT1);
    final nullableConeT3 = new Type.nullable(coneT3);
    final nullableConeT4 = new Type.nullable(coneT4);
    final nullableSetT12 = new Type.nullable(setT12);
    final nullableSetT14 = new Type.nullable(setT14);
    final nullableSetT23 = new Type.nullable(setT23);
    final nullableSetT34 = new Type.nullable(setT34);
    final nullableSetT123 = new Type.nullable(setT123);
    final nullableSetT124 = new Type.nullable(setT124);
    final nullableSetT1234 = new Type.nullable(setT1234);

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
        // subtypes
        {
          t1: [t1],
          t2: [t2],
          t3: [t1, t2, t3],
          t4: [t4],
        },
        // specializations
        {
          t1: concreteT1,
          t2: concreteT2,
          t3: setT123,
          t4: concreteT4
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
    final c1 = new Class(name: 'C1');
    final c2 = new Class(name: 'C2');
    final c3 = new Class(name: 'C3');

    final t1a = new InterfaceType(c1);
    final t1b = new InterfaceType(c1);
    final t2 = new InterfaceType(c2);
    final t3 = new InterfaceType(c3);
    final f1a = new FunctionType([t1a], const VoidType());
    final f1b = new FunctionType([t1b], const VoidType());
    final f2 = new FunctionType([t1a, t1a], const VoidType());

    final cid1 = const IntClassId(1);
    final cid2 = const IntClassId(2);
    final cid3 = const IntClassId(3);

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
    eq(f1a, f1b);
    ne(f1a, f2);
    ne(t1a, f1a);

    eq(new EmptyType(), new EmptyType());
    ne(new EmptyType(), new AnyType());
    ne(new EmptyType(), new ConcreteType(cid1, t1a));
    ne(new EmptyType(), new ConeType(t1a));
    ne(new EmptyType(),
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]));
    ne(new EmptyType(), new NullableType(new EmptyType()));

    eq(new AnyType(), new AnyType());
    ne(new AnyType(), new ConcreteType(cid1, t1a));
    ne(new AnyType(), new ConeType(t1a));
    ne(new AnyType(),
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]));
    ne(new AnyType(), new NullableType(new EmptyType()));

    eq(new ConcreteType(cid1, t1a), new ConcreteType(cid1, t1b));
    ne(new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2));
    ne(new ConcreteType(cid1, t1a), new ConeType(t1a));
    ne(new ConcreteType(cid1, t1a), new ConeType(t2));
    ne(new ConcreteType(cid1, t1a),
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]));
    ne(new ConcreteType(cid1, t1a),
        new NullableType(new ConcreteType(cid1, t1a)));

    eq(new ConeType(t1a), new ConeType(t1b));
    eq(new ConeType(f1a), new ConeType(f1b));
    ne(new ConeType(t1a), new ConeType(t2));
    ne(new ConeType(f1a), new ConeType(f2));
    ne(new ConeType(t1a), new ConeType(f1a));
    ne(new ConeType(t1a),
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]));
    ne(new ConeType(t1a), new NullableType(new ConeType(t1a)));

    eq(new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]),
        new SetType([new ConcreteType(cid1, t1b), new ConcreteType(cid2, t2)]));
    eq(
        new SetType([
          new ConcreteType(cid1, t1a),
          new ConcreteType(cid2, t2),
          new ConcreteType(cid3, t3)
        ]),
        new SetType([
          new ConcreteType(cid1, t1b),
          new ConcreteType(cid2, t2),
          new ConcreteType(cid3, t3)
        ]));
    ne(
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]),
        new SetType([
          new ConcreteType(cid1, t1a),
          new ConcreteType(cid2, t2),
          new ConcreteType(cid3, t3)
        ]));
    ne(new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]),
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid3, t3)]));
    ne(
        new SetType([new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)]),
        new NullableType(new SetType(
            [new ConcreteType(cid1, t1a), new ConcreteType(cid2, t2)])));
  });
}
