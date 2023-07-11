// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for a record type.
class RecordStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  RecordStaticType(super.typeOperations, super.fieldLookup, super.type)
      : super(isImplicitlyNullable: false);

  @override
  bool get isRecord => true;

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
