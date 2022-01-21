// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../executor.dart';
import '../api.dart';
import 'response_impls.dart';

class TypeBuilderBase {
  /// The final result, will be built up over `augment` calls.
  final List<DeclarationCode> _augmentations;

  /// Creates and returns a [MacroExecutionResult] out of the [_augmentations]
  /// created by this builder.
  MacroExecutionResult get result => new MacroExecutionResultImpl(
        augmentations: _augmentations,
        // TODO: Implement `imports`, or possibly drop it?
        imports: [],
      );

  TypeBuilderBase({List<DeclarationCode>? parentAugmentations})
      : _augmentations = parentAugmentations ?? [];
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
  Future<StaticType> resolve(TypeAnnotation typeAnnotation) =>
      typeResolver.resolve(typeAnnotation);
}

class DeclarationBuilderImpl extends DeclarationBuilderBase
    implements DeclarationBuilder {
  DeclarationBuilderImpl(
      ClassIntrospector classIntrospector, TypeResolver typeResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver,
            parentAugmentations: parentAugmentations);

  @override
  void declareInLibrary(DeclarationCode declaration) {
    _augmentations.add(declaration);
  }
}

class ClassMemberDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements ClassMemberDeclarationBuilder {
  final TypeAnnotation definingClass;

  ClassMemberDeclarationBuilderImpl(this.definingClass,
      ClassIntrospector classIntrospector, TypeResolver typeResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(classIntrospector, typeResolver,
            parentAugmentations: parentAugmentations);

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
  Future<TypeDeclaration> declarationOf(NamedStaticType annotation) =>
      typeDeclarationResolver.declarationOf(annotation);
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
  Future<ConstructorDefinitionBuilder> buildConstructor(String name) async {
    ConstructorDeclaration constructor =
        (await classIntrospector.constructorsOf(declaration))
            .firstWhere((constructor) => constructor.name == name);
    return new ConstructorDefinitionBuilderImpl(
        constructor, classIntrospector, typeResolver, typeDeclarationResolver,
        parentAugmentations: _augmentations);
  }

  @override
  Future<VariableDefinitionBuilder> buildField(String name) async {
    FieldDeclaration field = (await classIntrospector.fieldsOf(declaration))
        .firstWhere((field) => field.name == name);
    return new FieldDefinitionBuilderImpl(
        field, classIntrospector, typeResolver, typeDeclarationResolver,
        parentAugmentations: _augmentations);
  }

  @override
  Future<FunctionDefinitionBuilder> buildMethod(String name) async {
    MethodDeclaration method = (await classIntrospector.methodsOf(declaration))
        .firstWhere((method) => method.name == name);
    return new MethodDefinitionBuilderImpl(
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
    _augmentations.add(_buildFunctionAugmentation(body, declaration));
  }
}

/// Implementation of [MethodDefinitionBuilderImpl].
class MethodDefinitionBuilderImpl extends FunctionDefinitionBuilderImpl {
  @override
  final MethodDeclaration declaration;

  MethodDefinitionBuilderImpl(
      this.declaration,
      ClassIntrospector classIntrospector,
      TypeResolver typeResolver,
      TypeDeclarationResolver typeDeclarationResolver,
      {List<DeclarationCode>? parentAugmentations})
      : super(declaration, classIntrospector, typeResolver,
            typeDeclarationResolver,
            parentAugmentations: parentAugmentations);

  @override
  void augment(FunctionBodyCode body) {
    _augmentations.add(_buildClassAugmentation(
      declaration.definingClass,
      [_buildFunctionAugmentation(body, declaration)],
    ));
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
    _augmentations.addAll(_buildVariableAugmentations(declaration,
        getter: getter, setter: setter, initializer: initializer));
  }
}

class FieldDefinitionBuilderImpl extends DefinitionBuilderBase
    implements VariableDefinitionBuilder {
  final FieldDeclaration declaration;

  FieldDefinitionBuilderImpl(
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
    _augmentations.add(_buildClassAugmentation(
        declaration.definingClass,
        _buildVariableAugmentations(declaration,
            getter: getter, setter: setter, initializer: initializer)));
  }
}

/// Creates an augmentation of [clazz] with member [augmentations].
DeclarationCode _buildClassAugmentation(
        TypeAnnotation clazz, List<DeclarationCode> augmentations) =>
    new DeclarationCode.fromParts([
      'augment class ',
      clazz,
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
      declaration.type,
      ' ',
      declaration.name,
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
      if (declaration.name.isNotEmpty) '.',
    ] else ...[
      declaration.returnType.code,
      ' ',
    ],
    declaration.name,
    if (declaration.typeParameters.isNotEmpty) ...[
      '<',
      for (TypeParameterDeclaration typeParam
          in declaration.typeParameters) ...[
        typeParam.name,
        if (typeParam.bounds != null) ...['extends ', typeParam.bounds!.code],
        if (typeParam != declaration.typeParameters.last) ', ',
      ],
      '>',
    ],
    '(',
    for (ParameterDeclaration positionalRequired
        in declaration.positionalParameters.where((p) => p.isRequired)) ...[
      new ParameterCode.fromParts([
        positionalRequired.type.code,
        ' ',
        positionalRequired.name,
      ]),
      ', '
    ],
    if (declaration.positionalParameters.any((p) => !p.isRequired)) ...[
      '[',
      for (ParameterDeclaration positionalOptional
          in declaration.positionalParameters.where((p) => !p.isRequired)) ...[
        new ParameterCode.fromParts([
          positionalOptional.type.code,
          ' ',
          positionalOptional.name,
        ]),
        ', ',
      ],
      ']',
    ],
    if (declaration.namedParameters.isNotEmpty) ...[
      '{',
      for (ParameterDeclaration named in declaration.namedParameters) ...[
        new ParameterCode.fromParts([
          if (named.isRequired) 'required ',
          named.type.code,
          ' ',
          named.name,
          if (named.defaultValue != null) ...[
            ' = ',
            named.defaultValue!,
          ],
        ]),
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
