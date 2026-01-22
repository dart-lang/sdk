// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/transformations/flags.dart';

import '../../base/local_scope.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../source/source_library_builder.dart';
import '../../type_inference/context_allocation_strategy.dart';
import '../../type_inference/type_schema.dart';
import '../fragment.dart';
import 'declaration.dart';

class MethodFragmentBodyBuilderContext extends BodyBuilderContext {
  final MethodFragment _fragment;
  final MethodFragmentDeclaration _declaration;

  MethodFragmentBodyBuilderContext(
    this._fragment,
    this._declaration,
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder, {
    required bool isDeclarationInstanceMember,
  }) : super(
         libraryBuilder,
         declarationBuilder,
         isDeclarationInstanceMember: isDeclarationInstanceMember,
       );

  @override
  List<FormalParameterBuilder>? get formals => _declaration.formals;

  @override
  FunctionNode get function => _declaration.function;

  @override
  bool get isExternalFunction => _fragment.modifiers.isExternal;

  @override
  int get memberNameLength => _fragment.name.length;

  @override
  int get memberNameOffset => _fragment.nameOffset;

  @override
  TypeBuilder get returnType => _fragment.returnType;

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        _fragment.returnType is OmittedTypeBuilder &&
        function.returnType is DynamicType;
    return isReturnTypeUndeclared ? const UnknownType() : function.returnType;
  }

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) =>
      _declaration.getTearOffParameter(index);

  @override
  void registerFunctionBody(
    Statement? body,
    ScopeProviderInfo? scopeProviderInfo,
  ) {
    if (body != null) {
      function.body = body..parent = function;
    }
    function.scope = scopeProviderInfo?.scope;
  }

  @override
  void registerSuperCall() {
    // TODO(johnniwinther): This should be set on the member built from this
    // fragment and copied to the origin if necessary.
    _fragment.builder.invokeTarget.transformerFlags |=
        TransformerFlag.superCalls;
  }

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    assert(
      asyncModifier == _fragment.asyncModifier,
      "Unexpected change in async modifier on $_fragment from "
      "${_fragment.asyncModifier} to $asyncModifier.",
    );
  }
}
