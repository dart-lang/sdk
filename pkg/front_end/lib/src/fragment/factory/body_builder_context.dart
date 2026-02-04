// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/transformations/flags.dart';

import '../../base/local_scope.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../source/source_factory_builder.dart';
import '../../type_inference/context_allocation_strategy.dart';
import 'declaration.dart';

class FactoryBodyBuilderContext extends BodyBuilderContext {
  final SourceFactoryBuilder _builder;

  final FactoryFragmentDeclaration _declaration;

  final Member _member;

  FactoryBodyBuilderContext(this._builder, this._declaration, this._member)
    : super(
        _builder.libraryBuilder,
        _builder.declarationBuilder,
        isDeclarationInstanceMember: _builder.isDeclarationInstanceMember,
      );

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _declaration.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnTypeBuilder => _declaration.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _declaration.formals;

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameLength => _builder.name.length;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFactory => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNativeMethod {
    return _declaration.isNative;
  }

  @override
  bool get isExternalFunction {
    return _declaration.isExternal;
  }

  @override
  int get memberNameOffset => _declaration.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  void registerSuperCall() {
    _member.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  void registerFunctionBody({
    required Statement? body,
    required ScopeProviderInfo? scopeProviderInfo,
    required AsyncMarker asyncMarker,
    required DartType? emittedValueType,
  }) {
    _declaration.registerFunctionBody(
      body: body,
      scope: scopeProviderInfo
          // Coverage-ignore(suite): Not run.
          ?.scope,
      asyncMarker: asyncMarker,
      emittedValueType: emittedValueType,
    );
  }

  @override
  bool get isRedirectingFactory => _declaration.redirectionTarget != null;

  @override
  DartType get returnTypeContext => _declaration.returnTypeContext;

  @override
  String get redirectingFactoryTargetName {
    return _declaration.redirectionTarget!.fullNameForErrors;
  }
}
