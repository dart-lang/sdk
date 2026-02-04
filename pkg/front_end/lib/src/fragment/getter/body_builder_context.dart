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
import '../../source/source_property_builder.dart';
import '../../type_inference/context_allocation_strategy.dart';
import 'declaration.dart';

class GetterFragmentBodyBuilderContext extends BodyBuilderContext {
  final SourcePropertyBuilder _builder;
  final GetterFragmentDeclaration _declaration;

  GetterFragmentBodyBuilderContext(
    this._builder,
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
  bool get isExternalFunction => _declaration.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameLength => _declaration.name.length;

  @override
  int get memberNameOffset => _declaration.nameOffset;

  @override
  TypeBuilder get returnTypeBuilder => _declaration.returnType;

  @override
  DartType get returnTypeContext => _declaration.returnTypeContext;

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) => null;

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
  bool get isNoSuchMethodForwarder => _declaration.isNoSuchMethodForwarder;

  @override
  void registerSuperCall() {
    // TODO(johnniwinther): This should be set on the member built from this
    // fragment and copied to the origin if necessary.
    _builder.readTarget!.transformerFlags |= TransformerFlag.superCalls;
  }
}
