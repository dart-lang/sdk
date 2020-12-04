// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class FieldRef extends ObjectRef {
  /// The name of this field.
  String? get name;

  /// The owner of this field, which can be either a Library or a
  /// Class.
  ObjectRef? get dartOwner;

  /// The declared type of this field.
  ///
  /// The value will always be of one of the kinds:
  /// Type, TypeRef, TypeParameter.
  InstanceRef? get declaredType;

  /// Is this field const?
  bool? get isConst;

  /// Is this field final?
  bool? get isFinal;

  /// Is this field static?
  bool? get isStatic;
}

enum GuardClassKind { unknown, single, dynamic }

abstract class Field extends Object implements FieldRef {
  /// [optional] The value of this field, if the field is static.
  ObjectRef? get staticValue;

  /// [optional] The location of this field in the source code.
  SourceLocation? get location;

  GuardClassKind? get guardClassKind;
  ClassRef? get guardClass;
  bool? get guardNullable;
}
