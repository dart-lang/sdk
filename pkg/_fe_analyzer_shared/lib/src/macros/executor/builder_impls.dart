// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';

import '../executor.dart';
import '../api.dart';
import 'response_impls.dart';

abstract class TypeBuilderBase implements TypePhaseIntrospector {
  /// All the enum values to be added, indexed by the identifier for the
  /// augmented enum declaration.
  final Map<IdentifierImpl, List<DeclarationCode>> _enumValueAugmentations;

  /// All the interfaces to be added, indexed by the identifier for the
  /// augmented type declaration.
  final Map<IdentifierImpl, List<TypeAnnotationCode>> _interfaceAugmentations;

  /// All the top level declarations to add to the current library.
  final List<DeclarationCode> _libraryAugmentations;

  /// All the mixins to be added, indexed by the identifier for the
  /// augmented type declaration.
  final Map<IdentifierImpl, List<TypeAnnotationCode>> _mixinAugmentations;

  /// The names of any new types added in [_libraryAugmentations].
  final List<String> _newTypeNames = [];

  /// All the declarations to be added to types, indexed by the identifier for
  /// the augmented type.
  final Map<IdentifierImpl, List<DeclarationCode>> _typeAugmentations;

  TypePhaseIntrospector get introspector;

  /// Creates and returns a [MacroExecutionResult] out of the [_augmentations]
  /// created by this builder.
  MacroExecutionResult get result => new MacroExecutionResultImpl(
        enumValueAugmentations: _enumValueAugmentations,
        interfaceAugmentations: _interfaceAugmentations,
        libraryAugmentations: _libraryAugmentations,
        mixinAugmentations: _mixinAugmentations,
        newTypeNames: _newTypeNames,
        typeAugmentations: _typeAugmentations,
      );

  TypeBuilderBase({
    Map<IdentifierImpl, List<DeclarationCode>>? parentEnumValueAugmentations,
    Map<IdentifierImpl, List<TypeAnnotationCode>>? parentInterfaceAugmentations,
    List<DeclarationCode>? parentLibraryAugmentations,
    Map<IdentifierImpl, List<TypeAnnotationCode>>? parentMixinAugmentations,
    Map<IdentifierImpl, List<DeclarationCode>>? parentTypeAugmentations,
  })  : _enumValueAugmentations = parentEnumValueAugmentations ?? {},
        _interfaceAugmentations = parentInterfaceAugmentations ?? {},
        _libraryAugmentations = parentLibraryAugmentations ?? [],
        _mixinAugmentations = parentMixinAugmentations ?? {},
        _typeAugmentations = parentTypeAugmentations ?? {};

  @override
  Future<Identifier> resolveIdentifier(Uri library, String identifier) =>
      // ignore: deprecated_member_use_from_same_package
      introspector.resolveIdentifier(library, identifier);
}

class TypeBuilderImpl extends TypeBuilderBase implements TypeBuilder {
  @override
  final TypePhaseIntrospector introspector;

  TypeBuilderImpl(this.introspector);

  @override
  void declareType(String name, DeclarationCode typeDeclaration) {
    _newTypeNames.add(name);
    _libraryAugmentations.add(typeDeclaration);
  }
}

mixin InterfaceTypesBuilderImpl on TypeBuilderImpl
    implements InterfaceTypesBuilder {
  /// The type that we are going to be adding interfaces to.
  IdentifierImpl get originalType;

  /// Appends [interfaces] to the list of interfaces for this type.
  @override
  void appendInterfaces(Iterable<TypeAnnotationCode> interfaces) {
    _interfaceAugmentations
        .putIfAbsent(originalType, () => [])
        .addAll(interfaces);
  }
}

mixin MixinTypesBuilderImpl on TypeBuilderImpl implements MixinTypesBuilder {
  /// The type that we are going to be adding mixins to.
  IdentifierImpl get originalType;

  /// Appends [mixins] to the list of mixins for this type.
  @override
  void appendMixins(Iterable<TypeAnnotationCode> mixins) {
    (_mixinAugmentations[originalType] ??= []).addAll(mixins);
  }
}

class ClassTypeBuilderImpl extends TypeBuilderImpl
    with InterfaceTypesBuilderImpl, MixinTypesBuilderImpl
    implements ClassTypeBuilder {
  @override
  final IdentifierImpl originalType;

  ClassTypeBuilderImpl(this.originalType, super.introspector);
}

class EnumTypeBuilderImpl extends TypeBuilderImpl
    with InterfaceTypesBuilderImpl, MixinTypesBuilderImpl
    implements EnumTypeBuilder {
  @override
  final IdentifierImpl originalType;

  EnumTypeBuilderImpl(this.originalType, super.introspector);
}

class MixinTypeBuilderImpl extends TypeBuilderImpl
    with InterfaceTypesBuilderImpl
    implements MixinTypeBuilder {
  @override
  final IdentifierImpl originalType;

  MixinTypeBuilderImpl(this.originalType, super.introspector);
}

/// Base class for all [DeclarationBuilder]s.
abstract class DeclarationBuilderBase extends TypeBuilderBase
    implements DeclarationPhaseIntrospector {
  @override
  DeclarationPhaseIntrospector get introspector;

  DeclarationBuilderBase({
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentTypeAugmentations,
    super.parentMixinAugmentations,
  });

  @override
  Future<TypeDeclaration> typeDeclarationOf(IdentifierImpl identifier) =>
      introspector.typeDeclarationOf(identifier);

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(
          IntrospectableType type) =>
      introspector.constructorsOf(type);

  @override
  Future<List<EnumValueDeclaration>> valuesOf(
          covariant IntrospectableEnumDeclaration enuum) =>
      introspector.valuesOf(enuum);

  @override
  Future<List<FieldDeclaration>> fieldsOf(IntrospectableType type) =>
      introspector.fieldsOf(type);

  @override
  Future<List<MethodDeclaration>> methodsOf(IntrospectableType type) =>
      introspector.methodsOf(type);

  @override
  Future<StaticType> resolve(TypeAnnotationCode code) =>
      introspector.resolve(code);

  @override
  Future<List<TypeDeclaration>> typesOf(Library library) =>
      introspector.typesOf(library);
}

class DeclarationBuilderImpl extends DeclarationBuilderBase
    implements DeclarationBuilder {
  @override
  final DeclarationPhaseIntrospector introspector;

  DeclarationBuilderImpl(this.introspector);

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
    super.introspector,
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
    super.introspector,
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
    implements DefinitionPhaseIntrospector {
  @override
  final DefinitionPhaseIntrospector introspector;

  DefinitionBuilderBase(
    this.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentTypeAugmentations,
    super.parentMixinAugmentations,
  });

  @override
  Future<Declaration> declarationOf(Identifier identifier) =>
      introspector.declarationOf(identifier);

  @override
  Future<TypeAnnotation> inferType(OmittedTypeAnnotationImpl omittedType) =>
      introspector.inferType(omittedType);

  @override
  Future<List<Declaration>> topLevelDeclarationsOf(Library library) =>
      introspector.topLevelDeclarationsOf(library);

  @override
  Future<IntrospectableType> typeDeclarationOf(Identifier identifier) =>
      introspector.typeDeclarationOf(identifier);
}

class TypeDefinitionBuilderImpl extends DefinitionBuilderBase
    implements TypeDefinitionBuilder {
  /// The declaration this is a builder for.
  final IntrospectableType declaration;

  TypeDefinitionBuilderImpl(
    this.declaration,
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentTypeAugmentations,
    super.parentMixinAugmentations,
  });

  @override
  Future<ConstructorDefinitionBuilder> buildConstructor(
      Identifier identifier) async {
    ConstructorDeclarationImpl constructor = (await introspector
                .constructorsOf(declaration))
            .firstWhere((constructor) => constructor.identifier == identifier)
        as ConstructorDeclarationImpl;
    return new ConstructorDefinitionBuilderImpl(constructor, introspector,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }

  @override
  Future<VariableDefinitionBuilder> buildField(Identifier identifier) async {
    FieldDeclaration field = (await introspector.fieldsOf(declaration))
        .firstWhere((field) => field.identifier == identifier);
    return new VariableDefinitionBuilderImpl(field, introspector,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }

  @override
  Future<FunctionDefinitionBuilder> buildMethod(Identifier identifier) async {
    MethodDeclarationImpl method = (await introspector.methodsOf(declaration))
            .firstWhere((method) => method.identifier == identifier)
        as MethodDeclarationImpl;
    return new FunctionDefinitionBuilderImpl(method, introspector,
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
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentTypeAugmentations,
    super.parentMixinAugmentations,
  });

  @override
  Future<EnumValueDefinitionBuilder> buildEnumValue(
      Identifier identifier) async {
    EnumValueDeclarationImpl entry = (await introspector.valuesOf(declaration))
            .firstWhere((entry) => entry.identifier == identifier)
        as EnumValueDeclarationImpl;
    return new EnumValueDefinitionBuilderImpl(
      entry,
      introspector,
      parentEnumValueAugmentations: _enumValueAugmentations,
      parentInterfaceAugmentations: _interfaceAugmentations,
      parentLibraryAugmentations: _libraryAugmentations,
      parentMixinAugmentations: _mixinAugmentations,
      parentTypeAugmentations: _typeAugmentations,
    );
  }
}

class EnumValueDefinitionBuilderImpl extends DefinitionBuilderBase
    implements EnumValueDefinitionBuilder {
  final EnumValueDeclarationImpl declaration;

  EnumValueDefinitionBuilderImpl(
    this.declaration,
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentMixinAugmentations,
    super.parentTypeAugmentations,
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
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentMixinAugmentations,
    super.parentTypeAugmentations,
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
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentMixinAugmentations,
    super.parentTypeAugmentations,
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
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentMixinAugmentations,
    super.parentTypeAugmentations,
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

class LibraryDefinitionBuilderImpl extends DefinitionBuilderBase
    implements LibraryDefinitionBuilder {
  final Library library;

  LibraryDefinitionBuilderImpl(
    this.library,
    super.introspector, {
    super.parentEnumValueAugmentations,
    super.parentInterfaceAugmentations,
    super.parentLibraryAugmentations,
    super.parentMixinAugmentations,
    super.parentTypeAugmentations,
  });

  @override
  Future<FunctionDefinitionBuilder> buildFunction(Identifier identifier) async {
    FunctionDeclarationImpl function = (await introspector
                .topLevelDeclarationsOf(library))
            .firstWhere((declaration) => declaration.identifier == identifier)
        as FunctionDeclarationImpl;
    return new FunctionDefinitionBuilderImpl(function, introspector,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }

  @override
  Future<TypeDefinitionBuilder> buildType(Identifier identifier) async {
    IntrospectableType type = (await introspector
                .topLevelDeclarationsOf(library))
            .firstWhere((declaration) => declaration.identifier == identifier)
        as IntrospectableType;
    return new TypeDefinitionBuilderImpl(type, introspector,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
  }

  @override
  Future<VariableDefinitionBuilder> buildVariable(Identifier identifier) async {
    VariableDeclarationImpl variable = (await introspector
                .topLevelDeclarationsOf(library))
            .firstWhere((declaration) => declaration.identifier == identifier)
        as VariableDeclarationImpl;
    return new VariableDefinitionBuilderImpl(variable, introspector,
        parentTypeAugmentations: _typeAugmentations,
        parentLibraryAugmentations: _libraryAugmentations);
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
    if (declaration.isGetter) 'get ',
    declaration.identifier.name,
    if (!declaration.isGetter) ...[
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
      for (ParameterDeclaration positionalRequired in declaration
          .positionalParameters
          .takeWhile((p) => p.isRequired)) ...[
        positionalRequired.code,
        ', ',
      ],
      if (declaration.positionalParameters.any((p) => !p.isRequired)) ...[
        '[',
        for (ParameterDeclaration positionalOptional in declaration
            .positionalParameters
            .where((p) => !p.isRequired)) ...[
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
      ')',
    ],
    ' ',
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
