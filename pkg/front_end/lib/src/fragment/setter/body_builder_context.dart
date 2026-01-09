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
import '../../type_inference/type_schema.dart';
import 'declaration.dart';

class SetterBodyBuilderContext extends BodyBuilderContext {
  final SourcePropertyBuilder _builder;
  final SetterFragmentDeclaration _declaration;

  SetterBodyBuilderContext(
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
  FunctionNode get function => _declaration.function;

  @override
  bool get isExternalFunction => _declaration.isExternal;

  @override
  int get memberNameLength => _declaration.name.length;

  @override
  int get memberNameOffset => _declaration.nameOffset;

  @override
  TypeBuilder get returnType => _declaration.returnType;

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        _declaration.returnType is OmittedTypeBuilder &&
        // Coverage-ignore(suite): Not run.
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
  VariableDeclaration? getTearOffParameter(int index) => null;

  @override
  void registerFunctionBody(Statement? body) {
    _declaration.registerFunctionBody(
      compilerContext: _builder.libraryBuilder.loader.target.context,
      problemReporting: _builder.libraryBuilder,
      body: body,
    );
  }

  @override
  void registerSuperCall() {
    // TODO(johnniwinther): This should be set on the member built from this
    // fragment and copied to the origin if necessary.
    _builder.writeTarget!.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    assert(
      asyncModifier == _declaration.asyncModifier,
      "Unexpected change in async modifier on $_declaration from "
      "${_declaration.asyncModifier} to $asyncModifier.",
    );
  }
}
