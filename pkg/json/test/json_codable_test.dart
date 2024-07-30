// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros

import 'package:json/json.dart';
import 'package:test/test.dart';

void main() {
  group('Can encode and decode', () {
    test('non-nullable fields', () {
      var json = {
        'boolField': true,
        'stringField': 'hello',
        'intField': 10,
        'doubleField': 12.5,
        'numField': 11,
        'listOfSerializableField': [
          {'x': 1},
        ],
        'setOfSerializableField': [
          {'x': 2},
        ],
        'mapOfSerializableField': {
          'c': {'x': 3}
        },
      };

      var a = A.fromJson(json);
      expect(a.boolField, true);
      expect(a.stringField, 'hello');
      expect(a.intField, 10);
      expect(a.doubleField, 12.5);
      expect(a.numField, 11);
      expect(a.listOfSerializableField.single.x, 1);
      expect(a.setOfSerializableField.single.x, 2);
      expect(a.mapOfSerializableField['c']!.x, 3);

      expect(a.toJson(), equals(json));
    });

    test('nullable fields with non-null values', () {
      var json = {
        'nullableBoolField': false,
        'nullableStringField': 'world',
        'nullableIntField': 9,
        'nullableDoubleField': 11.5,
        'nullableNumField': 11.1,
        'nullableListOfSerializableField': [
          {'x': 1},
        ],
        'nullableSetOfSerializableField': [
          {'x': 2},
        ],
        'nullableMapOfSerializableField': {
          'd': {'x': 3},
        },
      };

      var b = B.fromJson(json);
      expect(b.nullableBoolField, false);
      expect(b.nullableStringField, 'world');
      expect(b.nullableIntField, 9);
      expect(b.nullableDoubleField, 11.5);
      expect(b.nullableNumField, 11.1);
      expect(b.nullableListOfSerializableField!.single.x, 1);
      expect(b.nullableSetOfSerializableField!.single.x, 2);
      expect(b.nullableMapOfSerializableField!['d']!.x, 3);

      expect(b.toJson(), equals(json));
    });

    test('nullable fields with explicit null values', () {
      var b = B.fromJson({
        'nullableBoolField': null,
        'nullableStringField': null,
        'nullableIntField': null,
        'nullableDoubleField': null,
        'nullableNumField': null,
        'nullableListOfSerializableField': null,
        'nullableSetOfSerializableField': null,
        'nullableMapOfSerializableField': null,
      });
      expect(b.nullableBoolField, null);
      expect(b.nullableStringField, null);
      expect(b.nullableIntField, null);
      expect(b.nullableDoubleField, null);
      expect(b.nullableNumField, null);
      expect(b.nullableListOfSerializableField, null);
      expect(b.nullableMapOfSerializableField, null);
      expect(b.nullableSetOfSerializableField, null);

      expect(b.toJson(), isEmpty);
    });

    test('nullable fields with missing values', () {
      var b = B.fromJson({});
      expect(b.nullableBoolField, null);
      expect(b.nullableStringField, null);
      expect(b.nullableIntField, null);
      expect(b.nullableDoubleField, null);
      expect(b.nullableNumField, null);
      expect(b.nullableListOfSerializableField, null);
      expect(b.nullableMapOfSerializableField, null);
      expect(b.nullableSetOfSerializableField, null);

      expect(b.toJson(), isEmpty);
    });

    test('class hierarchies', () {
      var json = {
        'x': 1,
        'y': 'z',
      };
      var d = D.fromJson(json);
      expect(d.x, 1);
      expect(d.y, 'z');

      expect(d.toJson(), equals(json));
    });

    test('collections of nullable objects', () {
      var json = {
        'listOfNullableInts': [null, 1],
        'listOfNullableSerializables': [
          {'x': 1},
          null
        ],
        'listOfNullableMapsOfNullableInts': [
          null,
          {'a': 1, 'b': null},
        ],
        'setOfNullableInts': [
          null,
          2,
        ],
        'setOfNullableSerializables': [
          {'x': 2},
          null,
        ],
        'setOfNullableMapsOfNullableInts': [
          null,
          {
            'a': 2,
            'b': null,
          },
        ],
        'mapOfNullableInts': {
          'a': 3,
          'b': null,
        },
        'mapOfNullableSerializables': {
          'a': {'x': 3},
          'b': null
        },
        'mapOfNullableSetsOfNullableInts': {
          'a': [null, 3],
          'b': null,
        },
      };

      var e = E.fromJson(json);
      expect(e.listOfNullableInts, equals([null, 1]));
      expect(e.listOfNullableSerializables.first!.x, 1);
      expect(e.listOfNullableSerializables[1], null);
      expect(
          e.listOfNullableMapsOfNullableInts,
          equals([
            null,
            {'a': 1, 'b': null},
          ]));
      expect(e.setOfNullableInts, equals({null, 2}));
      expect(e.setOfNullableSerializables.first!.x, 2);
      expect(e.setOfNullableSerializables.elementAt(1), null);
      expect(
          e.setOfNullableMapsOfNullableInts,
          equals({
            null,
            {
              'a': 2,
              'b': null,
            },
          }));
      expect(
          e.mapOfNullableInts,
          equals({
            'a': 3,
            'b': null,
          }));
      expect(e.mapOfNullableSerializables['a']!.x, 3);
      expect(e.mapOfNullableSerializables.containsKey('b'), true);
      expect(e.mapOfNullableSerializables['b'], null);
      expect(e.mapOfNullableSetsOfNullableInts, {
        'a': {null, 3},
        'b': null,
      });

      expect(e.toJson(), equals(json));
    });

    test(r'field with dollar sign $', () {
      var json = {
        r'fieldWithDollarSign$': 1,
      };
      var f = F.fromJson(json);
      expect(f.fieldWithDollarSign$, 1);

      expect(f.toJson(), equals(json));
    });
  });
}

@JsonCodable()
class A {
  final bool boolField;

  final String stringField;

  final int intField;

  final double doubleField;

  final num numField;

  final List<C> listOfSerializableField;

  final Set<C> setOfSerializableField;

  final Map<String, C> mapOfSerializableField;
}

@JsonCodable()
class B {
  final bool? nullableBoolField;

  final String? nullableStringField;

  final int? nullableIntField;

  final double? nullableDoubleField;

  final num? nullableNumField;

  final List<C>? nullableListOfSerializableField;

  final Set<C>? nullableSetOfSerializableField;

  final Map<String, C>? nullableMapOfSerializableField;
}

@JsonCodable()
class C {
  final int x;
}

@JsonCodable()
class D extends C {
  final String y;
}

@JsonCodable()
class E {
  final List<int?> listOfNullableInts;

  final List<C?> listOfNullableSerializables;

  final List<Map<String, int?>?> listOfNullableMapsOfNullableInts;

  final Set<int?> setOfNullableInts;

  final Set<C?> setOfNullableSerializables;

  final Set<Map<String, int?>?> setOfNullableMapsOfNullableInts;

  final Map<String, int?> mapOfNullableInts;

  final Map<String, C?> mapOfNullableSerializables;

  final Map<String, Set<int?>?> mapOfNullableSetsOfNullableInts;
}

@JsonCodable()
class F {
  final int fieldWithDollarSign$;
}
