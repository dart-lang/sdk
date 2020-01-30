// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.implicit_type;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart'
    show DartType, DartTypeVisitor, DartTypeVisitor1, Nullability, Visitor;

import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/legacy_erasure.dart';

import '../builder/field_builder.dart';

import '../problems.dart' show unsupported;

abstract class ImplicitFieldType extends DartType {
  SourceFieldBuilder get fieldBuilder;
  Token get initializerToken;
  void set initializerToken(Token value);
  bool get isStarted;
  void set isStarted(bool value);

  ImplicitFieldType._();

  factory ImplicitFieldType(
          SourceFieldBuilder fieldBuilder, Token initializerToken) =
      _ImplicitFieldTypeRoot;

  @override
  Nullability get nullability =>
      unsupported("nullability", fieldBuilder.charOffset, fieldBuilder.fileUri);

  @override
  R accept<R>(DartTypeVisitor<R> v) {
    throw unsupported("accept", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) {
    throw unsupported("accept1", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  visitChildren(Visitor<Object> v) {
    unsupported("visitChildren", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  @override
  ImplicitFieldType withNullability(Nullability nullability) {
    return unsupported(
        "withNullability", fieldBuilder.charOffset, fieldBuilder.fileUri);
  }

  ImplicitFieldType createAlias(SourceFieldBuilder target) =>
      new _ImplicitFieldTypeAlias(this, target);

  @override
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions assumptions) {
    if (identical(this, other)) return true;
    return other is ImplicitFieldType && fieldBuilder == other.fieldBuilder;
  }

  @override
  int get hashCode => fieldBuilder.hashCode;

  DartType inferType();
}

class _ImplicitFieldTypeRoot extends ImplicitFieldType {
  final SourceFieldBuilder fieldBuilder;
  Token initializerToken;
  bool isStarted = false;

  _ImplicitFieldTypeRoot(this.fieldBuilder, this.initializerToken) : super._();

  DartType inferType() => fieldBuilder.inferType();
}

class _ImplicitFieldTypeAlias extends ImplicitFieldType {
  final ImplicitFieldType _root;
  final SourceFieldBuilder _targetFieldBuilder;

  _ImplicitFieldTypeAlias(this._root, this._targetFieldBuilder)
      : assert(_root.fieldBuilder != _targetFieldBuilder),
        super._();

  SourceFieldBuilder get fieldBuilder => _root.fieldBuilder;

  Token get initializerToken => _root.initializerToken;

  void set initializerToken(Token value) {
    _root.initializerToken = value;
  }

  bool get isStarted => _root.isStarted;

  void set isStarted(bool value) {
    _root.isStarted = value;
  }

  DartType inferType() {
    DartType type = _root.inferType();
    if (!_targetFieldBuilder.library.isNonNullableByDefault) {
      type = legacyErasure(_targetFieldBuilder.library.loader.coreTypes, type);
    }
    return _targetFieldBuilder.fieldType = type;
  }
}
