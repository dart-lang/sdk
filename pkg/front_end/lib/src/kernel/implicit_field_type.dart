// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/printer.dart';

import '../base/problems.dart' show unsupported;
import '../builder/inferable_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart';
import '../source/source_library_builder.dart';

abstract class InferredType extends AuxiliaryType {
  Uri? get fileUri;
  int? get charOffset;

  InferredType._();

  factory InferredType(
      {required SourceLibraryBuilder libraryBuilder,
      required TypeBuilder typeBuilder,
      required InferTypeFunction inferType,
      required ComputeTypeFunction computeType,
      required Uri fileUri,
      required String name,
      required int nameOffset,
      required int nameLength,
      required Token? token}) = _ImplicitType;

  factory InferredType.fromInferableTypeUse(InferableTypeUse inferableTypeUse) =
      _InferredTypeUse;

  @override
  // Coverage-ignore(suite): Not run.
  Nullability get declaredNullability =>
      unsupported("declaredNullability", charOffset ?? -1, fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  Nullability get nullability {
    unsupported("nullability", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType get nonTypeParameterBound {
    throw unsupported("nonTypeParameterBound", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasNonObjectMemberAccess {
    throw unsupported("hasNonObjectMemberAccess", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(DartTypeVisitor<R> v) {
    throw unsupported("accept", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) {
    throw unsupported("accept1", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never visitChildren(Visitor<dynamic> v) {
    unsupported("visitChildren", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InferredType withDeclaredNullability(Nullability nullability) {
    return unsupported("withNullability", charOffset ?? -1, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  InferredType toNonNull() {
    return unsupported("toNonNullable", charOffset ?? -1, fileUri);
  }

  DartType inferType(ClassHierarchyBase hierarchy);

  DartType computeType(ClassHierarchyBase hierarchy);
}

/// Signature for function called to trigger the inference of the type of
/// [_ImplicitType], if it hasn't already been computed.
typedef InferTypeFunction = DartType Function(ClassHierarchyBase hierarchy);

/// Signature for function called to compute the type for [_ImplicitType]
typedef ComputeTypeFunction = DartType Function(
    ClassHierarchyBase hierarchy, Token? token);

/// [InferredType] implementation that infers the type of [_typeBuilder] using
/// [_computeType] and [_token].
class _ImplicitType extends InferredType {
  final SourceLibraryBuilder _libraryBuilder;
  final TypeBuilder _typeBuilder;
  final InferTypeFunction _inferType;
  final ComputeTypeFunction _computeType;
  final Uri _fileUri;
  final String _name;
  final int _nameOffset;
  final int _nameLength;
  Token? _token;

  bool isStarted = false;

  _ImplicitType(
      {required SourceLibraryBuilder libraryBuilder,
      required TypeBuilder typeBuilder,
      required InferTypeFunction inferType,
      required ComputeTypeFunction computeType,
      required Uri fileUri,
      required String name,
      required int nameOffset,
      required int nameLength,
      required Token? token})
      : _libraryBuilder = libraryBuilder,
        _typeBuilder = typeBuilder,
        _inferType = inferType,
        _computeType = computeType,
        _fileUri = fileUri,
        _name = name,
        _nameOffset = nameOffset,
        _nameLength = nameLength,
        _token = token,
        super._();

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  int get charOffset => _nameOffset;

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    return _inferType(hierarchy);
  }

  @override
  DartType computeType(ClassHierarchyBase hierarchy) {
    if (isStarted) {
      _libraryBuilder.addProblem(
          codeCantInferTypeDueToCircularity.withArguments(_name),
          _nameOffset,
          _nameLength,
          _fileUri);
      DartType type = const InvalidType();
      _typeBuilder.registerInferredType(type);
      return type;
    }
    isStarted = true;
    Token? token = _token;
    _token = null;
    return _computeType(hierarchy, token);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<implicit-type:$_name>');
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    return other is _ImplicitType && _typeBuilder == other._typeBuilder;
  }

  @override
  int get hashCode => _typeBuilder.hashCode;

  @override
  String toString() => '_ImplicitType(${toStringInternal()})';
}

class _InferredTypeUse extends InferredType {
  final InferableTypeUse inferableTypeUse;

  _InferredTypeUse(this.inferableTypeUse) : super._();

  @override
  // Coverage-ignore(suite): Not run.
  int? get charOffset => inferableTypeUse.typeBuilder.charOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri? get fileUri => inferableTypeUse.typeBuilder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  DartType computeType(ClassHierarchyBase hierarchy) {
    return inferType(hierarchy);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType inferType(ClassHierarchyBase hierarchy) {
    return inferableTypeUse.inferType(hierarchy);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<inferred-type:${inferableTypeUse.typeBuilder}>');
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool equals(Object other, Assumptions? assumptions) {
    if (identical(this, other)) return true;
    return other is _InferredTypeUse &&
        inferableTypeUse.typeBuilder == other.inferableTypeUse.typeBuilder;
  }

  @override
  int get hashCode => inferableTypeUse.typeBuilder.hashCode;

  @override
  String toString() => 'InferredTypeUse(${toStringInternal()})';
}
