// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for a record type.
///
/// This models that type aspect of the record using only the structure of the
/// record type. This means that the type for `(Object, String)` and
/// `(String, int)` will be subtypes of each other.
///
/// This is necessary to avoid invalid conclusions on the disjointness of
/// spaces base on the their types. For instance in
///
///     method((String, Object) o) {
///       if (o case (Object _, String s)) {}
///     }
///
/// the case is not empty even though `(String, Object)` and `(Object, String)`
/// are not related type-wise.
///
/// Not that the fields of the record types _are_ using the type, so that
/// the `$1` field of `(String, Object)` is known to contain only `String`s.
class RecordStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  RecordStaticType(super.typeOperations, super.fieldLookup, super.type)
      : super(isImplicitlyNullable: false);

  @override
  bool get isRecord => true;

  @override
  bool isSubtypeOfInternal(StaticType other) {
    if (other is! RecordStaticType<Type>) {
      return false;
    }
    if (fields.length != other.fields.length) {
      return false;
    }
    for (MapEntry<Key, StaticType> field in fields.entries) {
      StaticType? type = other.fields[field.key];
      if (type == null) {
        return false;
      }
    }
    return true;
  }

  @override
  String spaceToText(Map<Key, Space> spaceProperties,
      Map<Key, Space> additionalSpaceProperties) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('(');
    String comma = '';
    fields.forEach((Key key, StaticType staticType) {
      if (key is RecordIndexKey) {
        buffer.write(comma);
        comma = ', ';
        buffer.write('${spaceProperties[key] ?? staticType}');
      } else if (key is RecordNameKey) {
        buffer.write(comma);
        comma = ', ';
        buffer.write('${key.name}: ${spaceProperties[key] ?? staticType}');
      }
    });
    buffer.write(')');
    String additionalStart = '(';
    String additionalEnd = '';
    comma = '';
    spaceProperties.forEach((Key key, Space value) {
      if (key is! RecordKey) {
        buffer.write(additionalStart);
        additionalStart = '';
        additionalEnd = ')';
        buffer.write(comma);
        comma = ', ';
        buffer.write('${key.name}: $value');
      }
    });
    additionalSpaceProperties.forEach((Key key, Space value) {
      if (key is! RecordKey) {
        buffer.write(additionalStart);
        additionalStart = '';
        additionalEnd = ')';
        buffer.write(comma);
        comma = ', ';
        buffer.write('${key.name}: ${value}');
      }
    });
    buffer.write(additionalEnd);
    return buffer.toString();
  }

  @override
  void witnessToDart(DartTemplateBuffer buffer, PropertyWitness witness,
      Map<Key, PropertyWitness> witnessFields,
      {required bool forCorrection}) {
    buffer.write('(');
    String comma = '';
    for (Key key in fields.keys) {
      if (key is RecordIndexKey) {
        buffer.write(comma);
        comma = ', ';

        PropertyWitness? field = witnessFields[key];
        if (field != null) {
          field.witnessToDart(buffer, forCorrection: forCorrection);
        } else {
          buffer.write('_');
        }
      } else if (key is RecordNameKey) {
        buffer.write(comma);
        comma = ', ';

        buffer.write(key.name);
        buffer.write(': ');
        PropertyWitness? field = witnessFields[key];
        if (field != null) {
          field.witnessToDart(buffer, forCorrection: forCorrection);
        } else {
          buffer.write('_');
        }
      }
    }
    buffer.write(')');

    // If we have restrictions on the record type we create an and pattern.
    String additionalStart = ' && Object(';
    String additionalEnd = '';
    comma = '';
    for (MapEntry<Key, PropertyWitness> entry in witnessFields.entries) {
      Key key = entry.key;
      if (key is! RecordKey) {
        buffer.write(additionalStart);
        additionalStart = '';
        additionalEnd = ')';
        buffer.write(comma);
        comma = ', ';

        buffer.write(key.name);
        buffer.write(': ');
        PropertyWitness field = entry.value;
        field.witnessToDart(buffer, forCorrection: forCorrection);
      }
    }
    buffer.write(additionalEnd);
  }
}
