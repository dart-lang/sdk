// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';

import '../executor.dart';
import '../api.dart';
import 'introspection_impls.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';

/// Implementation of [MacroClassIdentifier].
class MacroClassIdentifierImpl implements MacroClassIdentifier {
  final String id;

  MacroClassIdentifierImpl(Uri library, String name) : id = '$library#$name';

  MacroClassIdentifierImpl.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectString();

  void serialize(Serializer serializer) => serializer.addString(id);

  operator ==(other) => other is MacroClassIdentifierImpl && id == other.id;

  int get hashCode => id.hashCode;
}

/// Implementation of [MacroInstanceIdentifier].
class MacroInstanceIdentifierImpl implements MacroInstanceIdentifier {
  static int _next = 0;

  final int id;

  MacroInstanceIdentifierImpl() : id = _next++;

  MacroInstanceIdentifierImpl.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectNum();

  void serialize(Serializer serializer) => serializer.addNum(id);

  operator ==(other) => other is MacroInstanceIdentifierImpl && id == other.id;

  int get hashCode => id;
}

/// Implementation of [MacroExecutionResult].
class MacroExecutionResultImpl implements MacroExecutionResult {
  @override
  final List<DeclarationCode> augmentations;

  @override
  final List<DeclarationCode> imports;

  MacroExecutionResultImpl({
    List<DeclarationCode>? augmentations,
    List<DeclarationCode>? imports,
  })  : augmentations = augmentations ?? [],
        imports = imports ?? [];

  factory MacroExecutionResultImpl.deserialize(Deserializer deserializer) {
    deserializer.moveNext();
    deserializer.expectList();
    List<DeclarationCode> augmentations = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectCode()
    ];
    deserializer.moveNext();
    deserializer.expectList();
    List<DeclarationCode> imports = [
      for (bool hasNext = deserializer.moveNext();
          hasNext;
          hasNext = deserializer.moveNext())
        deserializer.expectCode()
    ];

    return new MacroExecutionResultImpl(
      augmentations: augmentations,
      imports: imports,
    );
  }

  void serialize(Serializer serializer) {
    serializer.startList();
    for (DeclarationCode augmentation in augmentations) {
      augmentation.serialize(serializer);
    }
    serializer.endList();
    serializer.startList();
    for (DeclarationCode import in imports) {
      import.serialize(serializer);
    }
    serializer.endList();
  }
}

/// Implementation of [FunctionDefinitionBuilder].
class FunctionDefinitionBuilderImpl implements FunctionDefinitionBuilder {
  final TypeResolver typeResolver;
  final TypeDeclarationResolver typeDeclarationResolver;
  final ClassIntrospector classIntrospector;

  /// The declaration this is a builder for.
  final FunctionDeclarationImpl declaration;

  /// The final result, will be built up over `augment` calls.
  final MacroExecutionResultImpl result;

  FunctionDefinitionBuilderImpl(this.declaration, this.typeResolver,
      this.typeDeclarationResolver, this.classIntrospector)
      : result = new MacroExecutionResultImpl();

  FunctionDefinitionBuilderImpl.deserialize(Deserializer deserializer,
      this.typeResolver, this.typeDeclarationResolver, this.classIntrospector)
      : declaration = RemoteInstance.deserialize(deserializer),
        result = new MacroExecutionResultImpl.deserialize(deserializer);

  void serialize(Serializer serializer) {
    // Note that the `typeResolver`, `typeDeclarationResolver`, and
    // `classIntrospector` are not serialized. These have custom implementations
    // on the client/server side.
    declaration.serialize(serializer);
    result.serialize(serializer);
  }

  @override
  void augment(FunctionBodyCode body) {
    result.augmentations.add(new DeclarationCode.fromParts([
      'augment ',
      declaration.returnType.code,
      ' ',
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
        for (ParameterDeclaration positionalOptional in declaration
            .positionalParameters
            .where((p) => !p.isRequired)) ...[
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
      body,
    ]));
  }

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
  Future<TypeDeclaration> declarationOf(NamedStaticType annotation) =>
      typeDeclarationResolver.declarationOf(annotation);

  @override
  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) =>
      classIntrospector.superclassOf(clazz);

  @override
  Future<StaticType> resolve(TypeAnnotation typeAnnotation) =>
      typeResolver.resolve(typeAnnotation);
}
