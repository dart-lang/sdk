// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/transformations/flags.dart';

import '../../base/constant_context.dart';
import '../../base/identifiers.dart';
import '../../base/local_scope.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/expression_generator_helper.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_property_builder.dart';
import '../../type_inference/inference_results.dart';
import '../../type_inference/type_inferrer.dart';
import 'declaration.dart';

class ConstructorBodyBuilderContext extends BodyBuilderContext {
  final SourceConstructorBuilderImpl _member;

  final ConstructorDeclaration _constructorDeclaration;

  final Member _builtMember;

  ConstructorBodyBuilderContext(
      this._member, this._constructorDeclaration, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: false);

  @override
  int get memberNameOffset => _member.fileOffset;

  @override
  void registerSuperCall() {
    _builtMember.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _constructorDeclaration.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _constructorDeclaration.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnType => _constructorDeclaration.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _constructorDeclaration.formals;

  @override
  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    return _constructorDeclaration.getFormal(name);
  }

  @override
  int get memberNameLength => _member.name.length;

  @override
  FunctionNode get function {
    return _constructorDeclaration.function;
  }

  @override
  bool get isFactory => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNativeMethod {
    return _member.isNative;
  }

  @override
  bool get isExternalFunction => _constructorDeclaration.isExternal;

  @override
  bool get isSetter => false;

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _member.substituteFieldType(fieldType);
  }

  @override
  void registerInitializedField(SourcePropertyBuilder builder) {
    _member.registerInitializedField(builder);
  }

  @override
  void prepareInitializers() {
    _member.prepareInitializers();
  }

  @override
  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    _member.addInitializer(initializer, helper,
        inferenceResult: inferenceResult, parent: _builtMember);
  }

  @override
  InitializerInferenceResult inferInitializer(Initializer initializer,
      ExpressionGeneratorHelper helper, TypeInferrer typeInferrer) {
    return typeInferrer.inferInitializer(helper, _member, initializer);
  }

  @override
  DartType get returnTypeContext {
    return const DynamicType();
  }

  @override
  bool get isConstructor => true;

  @override
  bool get isConstConstructor {
    return _constructorDeclaration.isConst;
  }

  @override
  bool get isExternalConstructor {
    return _constructorDeclaration.isExternal;
  }

  @override
  ConstantContext get constantContext {
    return isConstConstructor ? ConstantContext.required : ConstantContext.none;
  }

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    return _constructorDeclaration
        .computeFormalParameterInitializerScope(parent);
  }

  @override
  void registerFunctionBody(Statement body) {
    _constructorDeclaration.registerFunctionBody(body);
  }

  @override
  void registerNoBodyConstructor() {
    _constructorDeclaration.registerNoBodyConstructor();
  }

  @override
  bool isConstructorCyclic(String name) {
    return declarationContext.isConstructorCyclic(_member.name, name);
  }

  @override
  bool needsImplicitSuperInitializer(CoreTypes coreTypes) {
    return _member.isClassMember &&
        !declarationContext.isObjectClass(coreTypes) &&
        !isExternalConstructor;
  }
}
