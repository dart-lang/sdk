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
  final SourceConstructorBuilder _builder;

  final ConstructorFragmentDeclaration _declaration;

  final Member _member;

  ConstructorBodyBuilderContext(this._builder, this._declaration, this._member)
    : super(
        _builder.libraryBuilder,
        _builder.declarationBuilder,
        isDeclarationInstanceMember: false,
      );

  @override
  int get memberNameOffset => _declaration.fileOffset;

  @override
  void registerSuperCall() {
    _member.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _declaration.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _declaration.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnType => _declaration.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _declaration.formals;

  @override
  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    return _declaration.getFormal(name);
  }

  @override
  int get memberNameLength => _builder.name.length;

  @override
  FunctionNode get function {
    return _declaration.function;
  }

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
  bool get isSetter => false;

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _builder.substituteFieldType(fieldType);
  }

  @override
  void registerInitializedField(SourcePropertyBuilder builder) {
    _builder.registerInitializedField(builder);
  }

  @override
  void prepareInitializers() {
    _builder.prepareInitializers();
  }

  @override
  void addInitializer(
    Initializer initializer,
    ExpressionGeneratorHelper helper,
  ) {
    _builder.addInitializer(
      initializer,
      helper,
      inferenceResult: null,
      parent: _member,
    );
  }

  @override
  void addInferredInitializer(
    InitializerInferenceResult inferenceResult,
    ExpressionGeneratorHelper helper,
  ) {
    _builder.addInitializer(
      inferenceResult.initializer,
      helper,
      inferenceResult: inferenceResult,
      parent: _member,
    );
  }

  @override
  InitializerInferenceResult inferInitializer(
    Initializer initializer,
    ExpressionGeneratorHelper helper,
    TypeInferrer typeInferrer,
  ) {
    return typeInferrer.inferInitializer(helper, _builder, initializer);
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
  void registerFunctionBody(Statement body) {
    _declaration.registerFunctionBody(body);
  }

  @override
  void registerNoBodyConstructor() {
    _declaration.registerNoBodyConstructor();
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
