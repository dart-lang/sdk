// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'meta_model.dart';

/// Helper to create a field.
Field field(
  String name, {
  String? comment,
  required String type,
  bool array = false,
  bool literal = false,
  bool canBeNull = false,
  bool canBeUndefined = false,
}) {
  var fieldType = array
      ? ArrayType(TypeReference(type))
      : literal
      ? LiteralType(TypeReference.string, type)
      : TypeReference(type);

  return Field(
    name: name,
    comment: comment,
    type: fieldType,
    allowsNull: canBeNull,
    allowsUndefined: canBeUndefined,
  );
}

/// Helper to create an interface type.
Interface interface(
  String name,
  List<Member> fields, {
  String? baseType,
  List<String>? baseTypes,
  String? comment,
  bool abstract = false,
}) {
  return Interface(
    name: name,
    abstract: abstract,
    comment: comment,
    baseTypes: [
      if (baseType != null) TypeReference(baseType),
      ...?baseTypes?.map(TypeReference.new),
    ],
    members: fields,
  );
}
