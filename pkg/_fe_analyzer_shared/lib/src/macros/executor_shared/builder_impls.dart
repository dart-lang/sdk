// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';

import '../executor.dart';
import '../api.dart';
import 'response_impls.dart';

class TypeBuilderBase {
  /// The final result, will be built up over `augment` calls.
  final List<DeclarationCode> _augmentations;

  /// The names of any new types added in [_augmentations].
  final List<String> _newTypeNames;

  /// Creates and returns a [MacroExecutionResult] out of the [_augmentations]
  /// created by this builder.
  MacroExecutionResult get result => new MacroExecutionResultImpl(
        augmentations: _augmentations,
        newTypeNames: _newTypeNames,
      );

  TypeBuilderBase({List<DeclarationCode>? parentAugmentations})
      : _augmentations = parentAugmentations ?? [],
        _newTypeNames = [];
}

class TypeBuilderImpl extends TypeBuilderBase implements TypeBuilder {
  @override
  void declareType(String name, DeclarationCode typeDeclaration) {
    _newTypeNames.add(name);
    _augmentations.add(typeDeclaration);
  }
}

/// Base class for all [DeclarationBuilder]s.
class DeclarationBuilderBase extends TypeBuilderBase
    implements ClassIntrospector, TypeResolver {
  final ClassIntrospector classIntrospector;
  final TypeResolver typeResolver;

  DeclarationBuilderBase(this.classIntrospector, this.typeResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(parentAugmentations: parentAugmentations);

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(ClassDeclaration clazz) =>
      classIntrospector.constructorsOf(clazz);

  @override
  Future<List<FieldDeclaration>> fieldsOf(ClassDeclaration clazz) =>
      classIntrospector.fieldsOf(clazz);

  @override
  Future<List<ClassDeclaration>> interfacesOf(ClassDeclaration clazz) =>
      classIntrospector.interfacesOf(clazz);

  @override
  Future<List<MethodDeclaration>> methodsOf(ClassDeclaration clazz) =>
      classIntrospector.methodsOf(clazz);

  @override
  Future<List<ClassDeclaration>> mixinsOf(ClassDeclaration clazz) =>
      classIntrospector.mixinsOf(clazz);

  @override
  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) =>
      classIntrospector.superclassOf(clazz);

  @override
  Future<StaticType> resolve(TypeAnnotationCode code) =>
      typeResolver.resolve(code);
}

class DeclarationBuilderImpl extends DeclarationBuilderBase
    implements DeclarationBuilder {
  DeclarationBuilderImpl(
      ClassIntrospector classIntrospector, TypeResolver typeResolver)
      : super(classIntrospector, typeResolver);

  @override
  void declareInLibrary(DeclarationCode declaration) {
    _augmentations.add(declaration);
  }
}

class ClassMemberDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements ClassMemberDeclarationBuilder {
  final Identifier definingClass;

  ClassMemberDeclarationBuilderImpl(this.definingClass,
      ClassIntrospector classIntrospector, TypeResolver typeResolver)
      : super(classIntrospector, typeResolver);

  @override
  void declareInClass(DeclarationCode declaration) {
    _augmentations.add(_buildClassAugmentation(definingClass, [declaration]));
  }
}

/// Base class for all [DefinitionBuilder]s.
class DefinitionBuilderBase extends DeclarationBuilderBase
    implements TypeDeclarationResolver {
  final TypeDeclarationResolver typeDeclarationResolver;

  DefinitionBuilderBase(ClassIntrospector classIntrospector,
      TypeResolver typeResolver, this.typeDeclarationResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver,
            parentAugmentations: parentAugmentations);

  @override
  Future<TypeDeclaration> declarationOf(IdentifierImpl identifier) =>
      typeDeclarationResolver.declarationOf(identifier);
}

class ClassDefinitionBuilderImpl extends DefinitionBuilderBase
    implements ClassDefinitionBuilder {
  /// The declaration this is a builder for.
  final ClassDeclaration declaration;

  ClassDefinitionBuilderImpl(
      this.declaration,
      ClassIntrospector classIntrospector,
      TypeResolver typeResolver,
      TypeDeclarationResolver typeDeclarationResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver, typeDeclarationResolver,
            parentAugmentations: parentAugmentations);

  @override
  Future<ConstructorDefinitionBuilder> buildConstructor(
      Identifier identifier) async {
    ConstructorDeclaration constructor =
        (await classIntrospector.constructorsOf(declaration))
            .firstWhere((constructor) => constructor.identifier == identifier);
    return new ConstructorDefinitionBuilderImpl(
        constructor, classIntrospector, typeResolver, typeDeclarationResolver,
        parentAugmentations: _augmentations);
  }

  @override
  Future<VariableDefinitionBuilder> buildField(Identifier identifier) async {
    FieldDeclaration field = (await classIntrospector.fieldsOf(declaration))
        .firstWhere((field) => field.identifier == identifier);
    return new VariableDefinitionBuilderImpl(
        field, classIntrospector, typeResolver, typeDeclarationResolver,
        parentAugmentations: _augmentations);
  }

  @override
  Future<FunctionDefinitionBuilder> buildMethod(Identifier identifier) async {
    MethodDeclaration method = (await classIntrospector.methodsOf(declaration))
        .firstWhere((method) => method.identifier == identifier);
    return new FunctionDefinitionBuilderImpl(
        method, classIntrospector, typeResolver, typeDeclarationResolver,
        parentAugmentations: _augmentations);
  }
}

/// Implementation of [FunctionDefinitionBuilder].
class FunctionDefinitionBuilderImpl extends DefinitionBuilderBase
    implements FunctionDefinitionBuilder {
  final FunctionDeclaration declaration;

  FunctionDefinitionBuilderImpl(
      this.declaration,
      ClassIntrospector classIntrospector,
      TypeResolver typeResolver,
      TypeDeclarationResolver typeDeclarationResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver, typeDeclarationResolver,
            parentAugmentations: parentAugmentations);

  @override
  void augment(FunctionBodyCode body) {
    DeclarationCode augmentation =
        _buildFunctionAugmentation(body, declaration);
    if (declaration is ClassMemberDeclaration) {
      augmentation = _buildClassAugmentation(
          (declaration as ClassMemberDeclaration).definingClass,
          [augmentation]);
    }
    _augmentations.add(augmentation);
  }
}

class ConstructorDefinitionBuilderImpl extends DefinitionBuilderBase
    implements ConstructorDefinitionBuilder {
  final ConstructorDeclaration declaration;

  ConstructorDefinitionBuilderImpl(
      this.declaration,
      ClassIntrospector classIntrospector,
      TypeResolver typeResolver,
      TypeDeclarationResolver typeDeclarationResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver, typeDeclarationResolver,
            parentAugmentations: parentAugmentations);

  @override
  void augment({FunctionBodyCode? body, List<Code>? initializers}) {
    body ??= new FunctionBodyCode.fromString('''{
      augment super();
    }''');
    _augmentations.add(_buildClassAugmentation(declaration.definingClass, [
      _buildFunctionAugmentation(body, declaration, initializers: initializers)
    ]));
  }
}

class VariableDefinitionBuilderImpl extends DefinitionBuilderBase
    implements VariableDefinitionBuilder {
  final VariableDeclaration declaration;

  VariableDefinitionBuilderImpl(
      this.declaration,
      ClassIntrospector classIntrospector,
      TypeResolver typeResolver,
      TypeDeclarationResolver typeDeclarationResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver, typeDeclarationResolver,
            parentAugmentations: parentAugmentations);

  @override
  void augment(
      {DeclarationCode? getter,
      DeclarationCode? setter,
      ExpressionCode? initializer}) {
    List<DeclarationCode> augmentations = _buildVariableAugmentations(
        declaration,
        getter: getter,
        setter: setter,
        initializer: initializer);
    if (declaration is ClassMemberDeclaration) {
      augmentations = [
        _buildClassAugmentation(
            (declaration as ClassMemberDeclaration).definingClass,
            augmentations)
      ];
    }

    _augmentations.addAll(augmentations);
  }
}

/// Creates an augmentation of [clazz] with member [augmentations].
DeclarationCode _buildClassAugmentation(
        Identifier clazz, List<DeclarationCode> augmentations) =>
    new DeclarationCode.fromParts([
      'augment class ',
      clazz.name,
      ' {\n',
      ...augmentations.joinAsCode('\n'),
      '\n}',
    ]);

/// Builds all the possible augmentations for a variable.
List<DeclarationCode> _buildVariableAugmentations(
    VariableDeclaration declaration,
    {DeclarationCode? getter,
    DeclarationCode? setter,
    ExpressionCode? initializer}) {
  List<DeclarationCode> augmentations = [];
  if (getter != null) {
    augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      getter,
    ]));
  }
  if (setter != null) {
    augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      setter,
    ]));
  }
  if (initializer != null) {
    augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      if (declaration.isFinal) 'final ',
      declaration.type.code,
      ' ',
      declaration.identifier,
      ' = ',
      initializer,
      ';',
    ]));
  }

  return augmentations;
}

/// Builds the code to augment a function, method, or constructor with a new
/// body.
///
/// The [initializers] parameter can only be used if [declaration] is a
/// constructor.
DeclarationCode _buildFunctionAugmentation(
    FunctionBodyCode body, FunctionDeclaration declaration,
    {List<Code>? initializers}) {
  assert(initializers == null || declaration is ConstructorDeclaration);

  return new DeclarationCode.fromParts([
    'augment ',
    if (declaration is ConstructorDeclaration) ...[
      declaration.definingClass.name,
      if (declaration.identifier.name.isNotEmpty) '.',
    ] else ...[
      declaration.returnType.code,
      ' ',
      if (declaration.isOperator) 'operator ',
    ],
    declaration.identifier.name,
    if (declaration.typeParameters.isNotEmpty) ...[
      '<',
      for (TypeParameterDeclaration typeParam
          in declaration.typeParameters) ...[
        typeParam.identifier.name,
        if (typeParam.bound != null) ...[' extends ', typeParam.bound!.code],
        if (typeParam != declaration.typeParameters.last) ', ',
      ],
      '>',
    ],
    '(',
    for (ParameterDeclaration positionalRequired
        in declaration.positionalParameters.takeWhile((p) => p.isRequired)) ...[
      positionalRequired.code,
      ', ',
    ],
    if (declaration.positionalParameters.any((p) => !p.isRequired)) ...[
      '[',
      for (ParameterDeclaration positionalOptional
          in declaration.positionalParameters.where((p) => !p.isRequired)) ...[
        positionalOptional.code,
        ', ',
      ],
      ']',
    ],
    if (declaration.namedParameters.isNotEmpty) ...[
      '{',
      for (ParameterDeclaration named in declaration.namedParameters) ...[
        named.code,
        ', ',
      ],
      '}',
    ],
    ') ',
    if (initializers != null && initializers.isNotEmpty) ...[
      ' : ',
      initializers.first,
      for (Code initializer in initializers.skip(1)) ...[
        ',\n',
        initializer,
      ],
    ],
    body,
  ]);
}
