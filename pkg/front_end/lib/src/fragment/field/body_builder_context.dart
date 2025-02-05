// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

class _FieldFragmentBodyBuilderContext extends BodyBuilderContext {
  final FieldFragment _fragment;

  _FieldFragmentBodyBuilderContext(
      this._fragment,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      {required bool isDeclarationInstanceMember})
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember);

  @override
  // Coverage-ignore(suite): Not run.
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  bool get isLateField => _fragment.modifiers.isLate;

  @override
  bool get isAbstractField => _fragment.modifiers.isAbstract;

  @override
  bool get isExternalField => _fragment.modifiers.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameOffset => _fragment.nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameLength => _fragment.name.length;

  @override
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    if (_fragment.builder.isExtensionMember && !isExternalField) {
      return InstanceTypeParameterAccessState.Invalid;
    } else {
      return super.instanceTypeParameterAccessState;
    }
  }

  @override
  void registerSuperCall() {
    _fragment.registerSuperCall();
  }

  @override
  // Coverage-ignore(suite): Not run.
  AugmentSuperTarget? get augmentSuperTarget {
    if (_fragment.builder.isAugmentation) {
      return _fragment.builder.augmentSuperTarget;
    }
    return null;
  }

  @override
  ConstantContext get constantContext {
    return _fragment.modifiers.isConst
        ? ConstantContext.inferred
        : !_fragment._isStatic && declarationDeclaresConstConstructor
            ? ConstantContext.required
            : ConstantContext.none;
  }
}
