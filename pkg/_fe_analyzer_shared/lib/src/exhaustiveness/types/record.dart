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
  RecordStaticType(super.typeOperations, super.fieldLookup, super.type);

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
    for (MapEntry<String, StaticType> field in fields.entries) {
      StaticType? type = other.fields[field.key];
      if (type == null) {
        return false;
      }
    }
    return true;
  }

  @override
  String spaceToText(
      Map<String, Space> spaceFields, Map<Key, Space> additionalSpaceFields) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('(');
    bool first = true;
    fields.forEach((String name, StaticType staticType) {
      if (!first) buffer.write(', ');
      // TODO(johnniwinther): Ensure using Dart syntax for positional fields.
      buffer.write('$name: ${spaceFields[name] ?? staticType}');
      first = false;
    });

    buffer.write(')');
    return buffer.toString();
  }
}
