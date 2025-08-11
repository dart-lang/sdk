// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

class FieldFragmentBodyBuilderContext extends BodyBuilderContext {
  final SourcePropertyBuilder _builder;
  final FieldFragmentDeclaration _declaration;

  @override
  final bool isLateField;

  @override
  final bool isAbstractField;

  @override
  final bool isExternalField;

  final int _nameOffset;

  final int _nameLength;

  final bool _isConst;

  FieldFragmentBodyBuilderContext(this._builder, this._declaration,
      {required this.isLateField,
      required this.isAbstractField,
      required this.isExternalField,
      required int nameOffset,
      required int nameLength,
      required bool isConst})
      : this._nameOffset = nameOffset,
        this._nameLength = nameLength,
        this._isConst = isConst,
        super(_builder.libraryBuilder, _builder.declarationBuilder,
            isDeclarationInstanceMember: _builder.isDeclarationInstanceMember);

  @override
  // Coverage-ignore(suite): Not run.
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameOffset => _nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameLength => _nameLength;

  @override
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    if (_builder.isExtensionMember && !isExternalField) {
      return InstanceTypeParameterAccessState.Invalid;
    } else {
      return super.instanceTypeParameterAccessState;
    }
  }

  @override
  void registerSuperCall() {
    _declaration.registerSuperCall();
  }

  @override
  ConstantContext get constantContext {
    return _isConst
        ? ConstantContext.inferred
        : !_declaration.isStatic && declarationDeclaresConstConstructor
            ? ConstantContext.required
            : ConstantContext.none;
  }
}
