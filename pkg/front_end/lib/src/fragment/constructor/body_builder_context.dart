// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../../base/constant_context.dart';
import '../../base/local_scope.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_property_builder.dart';
import '../../source/stack_listener_impl.dart' show AsyncModifier;
import '../../type_inference/context_allocation_strategy.dart';
import '../../type_inference/type_inferrer.dart';
import '../../util/helpers.dart';
import 'declaration.dart';

class ConstructorBodyBuilderContext extends BodyBuilderContext {
  final SourceConstructorBuilder _builder;

  final ConstructorFragmentDeclaration _declaration;

  final Member _member;

  @override
  final ConstructorContext constructorContext;

  new(this._builder, this._declaration, this._member, this.constructorContext)
    : super(
        _builder.libraryBuilder,
        _builder.declarationBuilder,
        isDeclarationInstanceMember: false,
      );

  @override
  int get memberNameOffset => _declaration.fileOffset;

  @override
  void registerSuperCall() {
    _member.containsSuperCalls = true;
  }

  @override
  FunctionParameter? getTearOffParameter(int index) {
    return _declaration.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnTypeBuilder => _declaration.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _declaration.formals;

  @override
  int get memberNameLength => _builder.name.length;

  @override
  bool get isFactory => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNativeMethod {
    return _declaration.isNative;
  }

  @override
  bool get isExternalFunction => _declaration.isExternal;

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _builder.substituteFieldType(fieldType);
  }

  @override
  void registerInitializedField(
    SourcePropertyBuilder builder,
    FieldInitialization fieldInitialization,
  ) {
    _builder.registerInitializedField(builder, fieldInitialization);
  }

  @override
  void prepareInitializers() {
    _builder.prepareInitializers();
  }

  @override
  void registerInitializers(
    List<Initializer> initializers, {
    required bool isErroneous,
  }) {
    _builder.registerInitializers(initializers, isErroneous: isErroneous);
  }

  @override
  void markAsErroneous() {
    _builder.markAsErroneous();
  }

  @override
  DartType get returnTypeContext {
    return const DynamicType();
  }

  @override
  bool get isConstructor => true;

  @override
  bool get isConstConstructor {
    return _declaration.isConst;
  }

  @override
  bool get isExternalConstructor {
    return _declaration.isExternal;
  }

  @override
  ConstantContext get constantContext {
    return isConstConstructor ? ConstantContext.required : ConstantContext.none;
  }

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    return _declaration.computeFormalParameterInitializerScope(parent);
  }

  @override
  void registerFunctionBody({
    required Statement? body,
    required ScopeProviderInfo? scopeProviderInfo,
    required AsyncModifier asyncModifier,
    required DartType? emittedValueType,
  }) {
    // Constructors can only be sync.
    _declaration.registerFunctionBody(
      body,
      scopeProviderInfo?.scope,
      thisVariable: scopeProviderInfo?.thisVariable,
    );
  }

  @override
  void registerNoBodyConstructor({required ThisVariable? thisVariable}) {
    _declaration.registerNoBodyConstructor(thisVariable: thisVariable);
  }

  @override
  bool isConstructorCyclic(String name) {
    return declarationContext.isConstructorCyclic(_builder.name, name);
  }

  @override
  bool needsImplicitSuperInitializer(CoreTypes coreTypes) {
    return _builder.isClassMember &&
        !declarationContext.isObjectClass(coreTypes) &&
        !isExternalConstructor;
  }
}
