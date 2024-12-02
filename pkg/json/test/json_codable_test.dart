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
        'dateTimeField': '2024-11-11T03:42:29.108308',
        'listOfSerializableField': [
          {'x': 1},
        ],
        'setOfSerializableField': [
          {'x': 2},
        ],
        'mapOfSerializableField': {
          'c': {'x': 3}
        },
        'customStringSerializationField': 'hi',
        'customNullableStringSerialization': null,
        'customMapSerializationField': {
          'z': 'zzz',
        }
      };

      var a = A.fromJson(json);
      expect(a.boolField, true);
      expect(a.stringField, 'hello');
      expect(a.intField, 10);
      expect(a.doubleField, 12.5);
      expect(a.numField, 11);
      expect(a.dateTimeField, DateTime.parse('2024-11-11T03:42:29.108308'));
      expect(a.listOfSerializableField.single.x, 1);
      expect(a.setOfSerializableField.single.x, 2);
      expect(a.mapOfSerializableField['c']!.x, 3);
      expect(a.customStringSerializationField, CustomStringSerialization('hi'));
      expect(a.customNullableStringSerialization,
          equals(CustomNullableStringSerialization(null)));
      expect(
          a.customMapSerializationField, CustomMapSerialization({'z': 'zzz'}));

      expect(a.toJson(), equals(json));
    });

    test('nullable fields with non-null values', () {
      var json = {
        'nullableBoolField': false,
        'nullableStringField': 'world',
        'nullableIntField': 9,
        'nullableDoubleField': 11.5,
        'nullableNumField': 11.1,
        'nullableDateTimeField': '2024-11-11T03:42:29.108308',
        'nullableListOfSerializableField': [
          {'x': 1},
        ],
        'nullableSetOfSerializableField': [
          {'x': 2},
        ],
        'nullableMapOfSerializableField': {
          'd': {'x': 3},
        },
        'nullableCustomStringSerializationField': 'hi',
        'nullableCustomMapSerializationField': {'z': 'zzz'},
      };

      var b = B.fromJson(json);
      expect(b.nullableBoolField, false);
      expect(b.nullableStringField, 'world');
      expect(b.nullableIntField, 9);
      expect(b.nullableDoubleField, 11.5);
      expect(b.nullableNumField, 11.1);
      expect(b.nullableDateTimeField,
          DateTime.parse('2024-11-11T03:42:29.108308'));
      expect(b.nullableListOfSerializableField!.single.x, 1);
      expect(b.nullableSetOfSerializableField!.single.x, 2);
      expect(b.nullableMapOfSerializableField!['d']!.x, 3);
      expect(b.nullableCustomStringSerializationField,
          CustomStringSerialization('hi'));
      expect(b.nullableCustomMapSerializationField,
          CustomMapSerialization({'z': 'zzz'}));

      expect(b.toJson(), equals(json));
    });

    test('nullable fields with explicit null values', () {
      var b = B.fromJson({
        'nullableBoolField': null,
        'nullableStringField': null,
        'nullableIntField': null,
        'nullableDoubleField': null,
        'nullableNumField': null,
        'nullableDateTimeField': null,
        'nullableListOfSerializableField': null,
        'nullableSetOfSerializableField': null,
        'nullableMapOfSerializableField': null,
        'nullableCustomStringSerializationField': null,
        'nullableCustomMapSerializationField': null,
      });
      expect(b.nullableBoolField, null);
      expect(b.nullableStringField, null);
      expect(b.nullableIntField, null);
      expect(b.nullableDoubleField, null);
      expect(b.nullableNumField, null);
      expect(b.nullableDateTimeField, null);
      expect(b.nullableListOfSerializableField, null);
      expect(b.nullableMapOfSerializableField, null);
      expect(b.nullableSetOfSerializableField, null);
      expect(b.nullableCustomStringSerializationField, null);
      expect(b.nullableCustomMapSerializationField, null);

      expect(b.toJson(), isEmpty);
    });

    test('nullable fields with missing values', () {
      var b = B.fromJson({});
      expect(b.nullableBoolField, null);
      expect(b.nullableStringField, null);
      expect(b.nullableIntField, null);
      expect(b.nullableDoubleField, null);
      expect(b.nullableNumField, null);
      expect(b.nullableDateTimeField, null);
      expect(b.nullableListOfSerializableField, null);
      expect(b.nullableMapOfSerializableField, null);
      expect(b.nullableSetOfSerializableField, null);
      expect(b.nullableCustomStringSerializationField, null);
      expect(b.nullableCustomMapSerializationField, null);

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
        'listOfNullableDates': [null, '2024-11-11T03:42:29.108308'],
        'listOfNullableInts': [null, 1],
        'listOfNullableSerializables': [
          {'x': 1},
          null
        ],
        'listOfNullableMapsOfNullableInts': [
          null,
          {'a': 1, 'b': null},
        ],
        'listOfCustomStringSerializables': [null, 'hi'],
        'listOfCustomMapSerializables': [
          null,
          {'z': 'zzz'},
        ],
        'setOfNullableDates': [
          null,
          '2024-11-12T03:42:29.108308',
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
        'setOfCustomStringSerializables': [null, 'hi'],
        'setOfCustomMapSerializables': [
          null,
          {'z': 'zzz'}
        ],
        'mapOfNullableDates': {
          'a': '2024-11-13T03:42:29.108308',
          'b': null,
        },
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
        'mapOfCustomStringSerializables': {
          'a': null,
          'b': 'hi',
        },
        'mapOfCustomMapSerializables': {
          'a': null,
          'b': {'z': 'zzz'},
        },
      };

      var e = E.fromJson(json);
      expect(e.listOfNullableDates,
          equals([null, DateTime.parse('2024-11-11T03:42:29.108308')]));
      expect(e.listOfNullableInts, equals([null, 1]));
      expect(e.listOfNullableSerializables.first!.x, 1);
      expect(e.listOfNullableSerializables[1], null);
      expect(
          e.listOfNullableMapsOfNullableInts,
          equals([
            null,
            {'a': 1, 'b': null},
          ]));
      expect(e.listOfCustomStringSerializables.first, null);
      expect(e.listOfCustomStringSerializables[1],
          CustomStringSerialization('hi'));
      expect(e.listOfCustomMapSerializables.first, null);
      expect(e.listOfCustomMapSerializables[1],
          CustomMapSerialization({'z': 'zzz'}));

      expect(e.setOfNullableDates,
          equals([null, DateTime.parse('2024-11-12T03:42:29.108308')]));
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
      expect(e.setOfCustomStringSerializables.first, null);
      expect(e.setOfCustomStringSerializables.toList()[1],
          CustomStringSerialization('hi'));
      expect(e.setOfCustomMapSerializables.first, null);
      expect(e.setOfCustomMapSerializables.toList()[1],
          CustomMapSerialization({'z': 'zzz'}));

      expect(
          e.mapOfNullableDates,
          equals({
            'a': DateTime.parse('2024-11-13T03:42:29.108308'),
            'b': null,
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
      expect(e.mapOfCustomStringSerializables['a'], null);
      expect(e.mapOfCustomStringSerializables['b'],
          CustomStringSerialization('hi'));
      expect(e.mapOfCustomMapSerializables['a'], null);
      expect(e.mapOfCustomMapSerializables['b'],
          CustomMapSerialization({'z': 'zzz'}));

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

  final DateTime dateTimeField;

  final List<C> listOfSerializableField;

  final Set<C> setOfSerializableField;

  final Map<String, C> mapOfSerializableField;

  final CustomStringSerialization customStringSerializationField;

  final CustomMapSerialization customMapSerializationField;

  final CustomNullableStringSerialization customNullableStringSerialization;
}

@JsonCodable()
class B {
  final bool? nullableBoolField;

  final String? nullableStringField;

  final int? nullableIntField;

  final double? nullableDoubleField;

  final num? nullableNumField;

  final DateTime? nullableDateTimeField;

  final List<C>? nullableListOfSerializableField;

  final Set<C>? nullableSetOfSerializableField;

  final Map<String, C>? nullableMapOfSerializableField;

  final CustomStringSerialization? nullableCustomStringSerializationField;

  final CustomMapSerialization? nullableCustomMapSerializationField;
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
  final List<DateTime?> listOfNullableDates;

  final List<int?> listOfNullableInts;

  final List<C?> listOfNullableSerializables;

  final List<Map<String, int?>?> listOfNullableMapsOfNullableInts;

  final List<CustomStringSerialization?> listOfCustomStringSerializables;

  final List<CustomMapSerialization?> listOfCustomMapSerializables;

  final Set<DateTime?> setOfNullableDates;

  final Set<int?> setOfNullableInts;

  final Set<C?> setOfNullableSerializables;

  final Set<Map<String, int?>?> setOfNullableMapsOfNullableInts;

  final Set<CustomStringSerialization?> setOfCustomStringSerializables;

  final Set<CustomMapSerialization?> setOfCustomMapSerializables;

  final Map<String, DateTime?> mapOfNullableDates;

  final Map<String, int?> mapOfNullableInts;

  final Map<String, C?> mapOfNullableSerializables;

  final Map<String, Set<int?>?> mapOfNullableSetsOfNullableInts;

  final Map<String, CustomStringSerialization?> mapOfCustomStringSerializables;

  final Map<String, CustomMapSerialization?> mapOfCustomMapSerializables;
}

@JsonCodable()
class F {
  final int fieldWithDollarSign$;
}

class CustomStringSerialization {
  final String a;

  CustomStringSerialization(this.a);

  String toJson() => a;

  factory CustomStringSerialization.fromJson(String a) =>
      CustomStringSerialization(a);

  @override
  bool operator ==(Object other) =>
      other is CustomStringSerialization && a == other.a;

  @override
  int get hashCode => a.hashCode;
}

class CustomNullableStringSerialization {
  final String? a;

  CustomNullableStringSerialization(this.a);

  String? toJson() => a;

  factory CustomNullableStringSerialization.fromJson(String? a) =>
      CustomNullableStringSerialization(a);

  @override
  bool operator ==(Object other) =>
      other is CustomNullableStringSerialization && a == other.a;

  @override
  int get hashCode => a.hashCode;
}

class CustomMapSerialization {
  final Map<String, dynamic> a;

  CustomMapSerialization(this.a);

  Map<String, dynamic> toJson() => a;

  factory CustomMapSerialization.fromJson(Map<String, dynamic> a) =>
      CustomMapSerialization(a);

  @override
  bool operator ==(Object other) {
    return other is CustomMapSerialization &&
        a.toString() == other.a.toString();
  }

  @override
  int get hashCode => a.hashCode;
}
