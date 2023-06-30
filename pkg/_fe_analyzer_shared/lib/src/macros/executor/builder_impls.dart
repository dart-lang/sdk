// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';

import '../executor.dart';
import '../api.dart';
import 'response_impls.dart';

class TypeBuilderBase implements IdentifierResolver {
  /// The final result, will be built up over `augment` calls.
  final Map<IdentifierImpl, List<DeclarationCode>> _enumValueAugmentations;

  /// The final result, will be built up over `augment` calls.
  final List<DeclarationCode> _libraryAugmentations;

  /// The names of any new types added in [_libraryAugmentations].
  final List<String> _newTypeNames = [];

  /// The final result, will be built up over `augment` calls.
  final Map<IdentifierImpl, List<DeclarationCode>> _typeAugmentations;

  final IdentifierResolver identifierResolver;

  /// Creates and returns a [MacroExecutionResult] out of the [_augmentations]
  /// created by this builder.
  MacroExecutionResult get result => new MacroExecutionResultImpl(
        enumValueAugmentations: _enumValueAugmentations,
        libraryAugmentations: _libraryAugmentations,
        newTypeNames: _newTypeNames,
        typeAugmentations: _typeAugmentations,
      );

  TypeBuilderBase(this.identifierResolver,
      {Map<IdentifierImpl, List<DeclarationCode>>? parentTypeAugmentations,
      Map<IdentifierImpl, List<DeclarationCode>>? parentEnumValueAugmentations,
      List<DeclarationCode>? parentLibraryAugmentations})
      : _typeAugmentations = parentTypeAugmentations ?? {},
        _enumValueAugmentations = parentEnumValueAugmentations ?? {},
        _libraryAugmentations = parentLibraryAugmentations ?? [];

  @override
  Future<Identifier> resolveIdentifier(Uri library, String identifier) =>
      // ignore: deprecated_member_use_from_same_package
      identifierResolver.resolveIdentifier(library, identifier);
}

class TypeBuilderImpl extends TypeBuilderBase implements TypeBuilder {
  TypeBuilderImpl(super.identifierResolver);

  @override
  void declareType(String name, DeclarationCode typeDeclaration) {
    _newTypeNames.add(name);
    _libraryAugmentations.add(typeDeclaration);
  }
}

/// Base class for all [DeclarationBuilder]s.
class DeclarationBuilderBase extends TypeBuilderBase
    implements TypeIntrospector, TypeDeclarationResolver, TypeResolver {
  final TypeIntrospector typeIntrospector;
  final TypeDeclarationResolver typeDeclarationResolver;
  final TypeResolver typeResolver;

  DeclarationBuilderBase(super.identifierResolver, this.typeIntrospector,
      this.typeDeclarationResolver, this.typeResolver,
      {super.parentTypeAugmentations,
      super.parentEnumValueAugmentations,
      super.parentLibraryAugmentations});

  @override
  Future<TypeDeclaration> declarationOf(IdentifierImpl identifier) =>
      typeDeclarationResolver.declarationOf(identifier);

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(
          IntrospectableType type) =>
      typeIntrospector.constructorsOf(type);

  @override
  Future<List<EnumValueDeclaration>> valuesOf(
          covariant IntrospectableEnumDeclaration enuum) =>
      typeIntrospector.valuesOf(enuum);

  @override
  Future<List<FieldDeclaration>> fieldsOf(IntrospectableType type) =>
      typeIntrospector.fieldsOf(type);

  @override
  Future<List<MethodDeclaration>> methodsOf(IntrospectableType type) =>
      typeIntrospector.methodsOf(type);

  @override
  Future<StaticType> resolve(TypeAnnotationCode code) =>
      typeResolver.resolve(code);

  @override
  Future<List<TypeDeclaration>> typesOf(Library library) =>
      typeIntrospector.typesOf(library);
}

class DeclarationBuilderImpl extends DeclarationBuilderBase
    implements DeclarationBuilder {
  DeclarationBuilderImpl(
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
  );

  @override
  void declareInLibrary(DeclarationCode declaration) {
    _libraryAugmentations.add(declaration);
  }
}

class MemberDeclarationBuilderImpl extends DeclarationBuilderImpl
    implements MemberDeclarationBuilder {
  final IdentifierImpl definingType;

  MemberDeclarationBuilderImpl(
    this.definingType,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
  );

  @override
  void declareInType(DeclarationCode declaration) {
    _typeAugmentations.update(definingType, (value) => value..add(declaration),
        ifAbsent: () => [declaration]);
  }
}

class EnumDeclarationBuilderImpl extends MemberDeclarationBuilderImpl
    implements EnumDeclarationBuilder {
  EnumDeclarationBuilderImpl(
    super.definingType,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
  );

  @override
  void declareEnumValue(DeclarationCode declaration) {
    _enumValueAugmentations.update(
        definingType, (value) => value..add(declaration),
        ifAbsent: () => [declaration]);
  }
}

/// Base class for all [DefinitionBuilder]s.
class DefinitionBuilderBase extends DeclarationBuilderBase
    implements TypeInferrer, LibraryDeclarationsResolver {
  final TypeInferrer typeInferrer;

  final LibraryDeclarationsResolver libraryDeclarationsResolver;

  DefinitionBuilderBase(
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    this.typeInferrer,
    this.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  Future<TypeAnnotation> inferType(OmittedTypeAnnotationImpl omittedType) =>
      typeInferrer.inferType(omittedType);

  @override
  Future<List<Declaration>> topLevelDeclarationsOf(Library library) =>
      libraryDeclarationsResolver.topLevelDeclarationsOf(library);
}

class TypeDefinitionBuilderImpl extends DefinitionBuilderBase
    implements TypeDefinitionBuilder {
  /// The declaration this is a builder for.
  final IntrospectableType declaration;

  TypeDefinitionBuilderImpl(
    this.declaration,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    super.typeInferrer,
    super.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  Future<ConstructorDefinitionBuilder> buildConstructor(
      Identifier identifier) async {
    ConstructorDeclarationImpl constructor = (await typeIntrospector
                .constructorsOf(declaration))
            .firstWhere((constructor) => constructor.identifier == identifier)
        as ConstructorDeclarationImpl;
    return new ConstructorDefinitionBuilderImpl(
        constructor,
        identifierResolver,
        typeIntrospector,
        typeDeclarationResolver,
        typeResolver,
        typeInferrer,
        libraryDeclarationsResolver,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }

  @override
  Future<VariableDefinitionBuilder> buildField(Identifier identifier) async {
    FieldDeclaration field = (await typeIntrospector.fieldsOf(declaration))
        .firstWhere((field) => field.identifier == identifier);
    return new VariableDefinitionBuilderImpl(
        field,
        identifierResolver,
        typeIntrospector,
        typeDeclarationResolver,
        typeResolver,
        typeInferrer,
        libraryDeclarationsResolver,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }

  @override
  Future<FunctionDefinitionBuilder> buildMethod(Identifier identifier) async {
    MethodDeclarationImpl method =
        (await typeIntrospector.methodsOf(declaration))
                .firstWhere((method) => method.identifier == identifier)
            as MethodDeclarationImpl;
    return new FunctionDefinitionBuilderImpl(
        method,
        identifierResolver,
        typeIntrospector,
        typeDeclarationResolver,
        typeResolver,
        typeInferrer,
        libraryDeclarationsResolver,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }
}

class EnumDefinitionBuilderImpl extends TypeDefinitionBuilderImpl
    implements EnumDefinitionBuilder {
  @override
  IntrospectableEnumDeclaration get declaration =>
      super.declaration as IntrospectableEnumDeclaration;

  EnumDefinitionBuilderImpl(
    IntrospectableEnumDeclaration super.declaration,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    super.typeInferrer,
    super.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  Future<EnumValueDefinitionBuilder> buildEnumValue(
      Identifier identifier) async {
    EnumValueDeclarationImpl entry =
        (await typeIntrospector.valuesOf(declaration))
                .firstWhere((entry) => entry.identifier == identifier)
            as EnumValueDeclarationImpl;
    return new EnumValueDefinitionBuilderImpl(
        entry,
        identifierResolver,
        typeIntrospector,
        typeDeclarationResolver,
        typeResolver,
        typeInferrer,
        libraryDeclarationsResolver,
        parentTypeAugmentations: _typeAugmentations,
        parentEnumValueAugmentations: _enumValueAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }
}

class EnumValueDefinitionBuilderImpl extends DefinitionBuilderBase
    implements EnumValueDefinitionBuilder {
  final EnumValueDeclarationImpl declaration;

  EnumValueDefinitionBuilderImpl(
    this.declaration,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    super.typeInferrer,
    super.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  void augment(DeclarationCode entry) {
    _enumValueAugmentations.update(
        declaration.definingEnum, (value) => value..add(entry),
        ifAbsent: () => [entry]);
  }
}

/// Implementation of [FunctionDefinitionBuilder].
class FunctionDefinitionBuilderImpl extends DefinitionBuilderBase
    implements FunctionDefinitionBuilder {
  final FunctionDeclarationImpl declaration;

  FunctionDefinitionBuilderImpl(
    this.declaration,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    super.typeInferrer,
    super.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  void augment(FunctionBodyCode body, {CommentCode? docComments}) {
    DeclarationCode augmentation =
        _buildFunctionAugmentation(body, declaration, docComments: docComments);
    if (declaration is MemberDeclaration) {
      _typeAugmentations.update(
          (declaration as MethodDeclarationImpl).definingType,
          (value) => value..add(augmentation),
          ifAbsent: () => [augmentation]);
    } else {
      _libraryAugmentations.add(augmentation);
    }
  }
}

class ConstructorDefinitionBuilderImpl extends DefinitionBuilderBase
    implements ConstructorDefinitionBuilder {
  final ConstructorDeclarationImpl declaration;

  ConstructorDefinitionBuilderImpl(
    this.declaration,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    super.typeInferrer,
    super.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  void augment(
      {FunctionBodyCode? body,
      List<Code>? initializers,
      CommentCode? docComments}) {
    body ??= new FunctionBodyCode.fromString('''{
      augment super();
    }''');
    DeclarationCode augmentation = _buildFunctionAugmentation(body, declaration,
        initializers: initializers, docComments: docComments);
    _typeAugmentations.update(
        declaration.definingType, (value) => value..add(augmentation),
        ifAbsent: () => [augmentation]);
  }
}

class VariableDefinitionBuilderImpl extends DefinitionBuilderBase
    implements VariableDefinitionBuilder {
  final VariableDeclaration declaration;

  VariableDefinitionBuilderImpl(
    this.declaration,
    super.identifierResolver,
    super.typeIntrospector,
    super.typeDeclarationResolver,
    super.typeResolver,
    super.typeInferrer,
    super.libraryDeclarationsResolver, {
    super.parentTypeAugmentations,
    super.parentEnumValueAugmentations,
    super.parentLibraryAugmentations,
  });

  @override
  void augment(
      {DeclarationCode? getter,
      DeclarationCode? setter,
      ExpressionCode? initializer,
      CommentCode? initializerDocComments}) {
    List<DeclarationCode> augmentations = _buildVariableAugmentations(
        declaration,
        getter: getter,
        setter: setter,
        initializer: initializer,
        initializerDocComments: initializerDocComments);
    if (declaration is MemberDeclaration) {
      _typeAugmentations.update(
          (declaration as FieldDeclarationImpl).definingType,
          (value) => value..addAll(augmentations),
          ifAbsent: () => augmentations);
    } else {
      _libraryAugmentations.addAll(augmentations);
    }
  }
}

/// Builds all the possible augmentations for a variable.
List<DeclarationCode> _buildVariableAugmentations(
    VariableDeclaration declaration,
    {DeclarationCode? getter,
    DeclarationCode? setter,
    ExpressionCode? initializer,
    CommentCode? initializerDocComments}) {
  if (initializerDocComments != null && initializer == null) {
    throw new ArgumentError(
        'initializerDocComments cannot be provided if an initializer is not '
        'provided.');
  }
  List<DeclarationCode> augmentations = [];
  if (getter != null) {
    augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      if (declaration is FieldDeclaration && declaration.isStatic) 'static ',
      getter,
    ]));
  }
  if (setter != null) {
    augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      if (declaration is FieldDeclaration && declaration.isStatic) 'static ',
      setter,
    ]));
  }
  if (initializer != null) {
    augmentations.add(new DeclarationCode.fromParts([
      if (initializerDocComments != null) initializerDocComments,
      'augment ',
      if (declaration is FieldDeclaration && declaration.isStatic) 'static ',
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
    {List<Code>? initializers, CommentCode? docComments}) {
  assert(initializers == null || declaration is ConstructorDeclaration);

  return new DeclarationCode.fromParts([
    if (docComments != null) docComments,
    'augment ',
    if (declaration is ConstructorDeclaration) ...[
      declaration.definingType.name,
      if (declaration.identifier.name.isNotEmpty) '.',
    ] else ...[
      if (declaration is MethodDeclaration && declaration.isStatic) 'static ',
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
