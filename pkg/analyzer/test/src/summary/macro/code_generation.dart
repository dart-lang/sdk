// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:macros/macros.dart';

/// Does not do anything useful, just augments the target in the definitions
/// phase, so that any omitted types are written into the augmentation.
/*macro*/ class AugmentForOmittedTypes
    implements FieldDefinitionMacro, FunctionDefinitionMacro {
  const AugmentForOmittedTypes();

  @override
  FutureOr<void> buildDefinitionForField(declaration, builder) async {
    builder.augment(
      initializer: ExpressionCode.fromString('0'),
    );
  }

  @override
  FutureOr<void> buildDefinitionForFunction(declaration, builder) async {
    builder.augment(
      FunctionBodyCode.fromString('{}'),
    );
  }
}

/*macro*/ class DeclarationsPhaseAnnotationType
    implements
        ClassDeclarationsMacro,
        EnumDeclarationsMacro,
        ExtensionDeclarationsMacro,
        ExtensionTypeDeclarationsMacro,
        FieldDeclarationsMacro,
        FunctionDeclarationsMacro,
        ConstructorDeclarationsMacro,
        MethodDeclarationsMacro,
        MixinDeclarationsMacro,
        TypeAliasDeclarationsMacro,
        VariableDeclarationsMacro {
  const DeclarationsPhaseAnnotationType();

  @override
  buildDeclarationsForClass(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForConstructor(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForEnum(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForExtension(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForExtensionType(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForField(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForFunction(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  FutureOr<void> buildDeclarationsForMethod(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForMixin(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForTypeAlias(declaration, builder) {
    _build(declaration, builder);
  }

  @override
  buildDeclarationsForVariable(declaration, builder) {
    _build(declaration, builder);
  }

  void _build(Declaration declaration, DeclarationBuilder builder) {
    var commaClassNamePairs = declaration.metadata
        .map((annotation) {
          annotation as ConstructorMetadataAnnotation;
          return [', ', annotation.type.code];
        })
        .expand((elements) => elements)
        .skip(1)
        .toList();

    var code = DeclarationCode.fromParts([
      'var x = [',
      ...commaClassNamePairs,
      '];',
    ]);

    builder.declareInLibrary(code);
  }
}

/*macro*/ class DefineToStringAsTypeName
    implements ClassDefinitionMacro, MethodDefinitionMacro {
  const DefineToStringAsTypeName();

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    var methods = await builder.methodsOf(clazz);
    var toString = methods.firstWhereOrNull(
      (e) => e.identifier.name == 'toString',
    );
    if (toString == null) {
      throw StateError('No toString() declaration');
    }

    var toStringBuilder = await builder.buildMethod(
      toString.identifier,
    );

    toStringBuilder.augment(
      FunctionBodyCode.fromParts([
        '{\n    return \'${clazz.identifier.name}\';\n  }',
      ]),
    );
  }

  @override
  FutureOr<void> buildDefinitionForMethod(
    MethodDeclaration method,
    FunctionDefinitionBuilder builder,
  ) async {
    builder.augment(
      FunctionBodyCode.fromString("=> '${method.definingType.name}';"),
    );
  }
}

/*macro*/ class ReferenceFirstFormalParameter
    implements FunctionDefinitionMacro {
  const ReferenceFirstFormalParameter();

  @override
  Future<void> buildDefinitionForFunction(
    FunctionDeclaration function,
    FunctionDefinitionBuilder builder,
  ) async {
    builder.augment(
      FunctionBodyCode.fromParts([
        '{\n  ',
        function.positionalParameters.first.identifier,
        ';\n}',
      ]),
    );
  }
}

/*macro*/ class ReferenceFirstTypeParameter implements FunctionDefinitionMacro {
  const ReferenceFirstTypeParameter();

  @override
  Future<void> buildDefinitionForFunction(
    FunctionDeclaration function,
    FunctionDefinitionBuilder builder,
  ) async {
    builder.augment(
      FunctionBodyCode.fromParts([
        '{\n  ',
        function.typeParameters.first.identifier,
        ';\n}',
      ]),
    );
  }
}

/*macro*/ class ReferenceIdentifier implements ClassDeclarationsMacro {
  final String uriStr;
  final String topName;
  final String? memberName;
  final String parametersCode;
  final String leadCode;

  const ReferenceIdentifier(
    this.uriStr,
    this.topName, {
    this.memberName,
    this.parametersCode = '',
    this.leadCode = '',
  });

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    var uri = Uri.parse(uriStr);

    // ignore: deprecated_member_use
    var identifier = await builder.resolveIdentifier(uri, topName);

    if (memberName case var memberName?) {
      var type = await builder.typeDeclarationOf(identifier);
      identifier = [
        ...await builder.constructorsOf(type),
        ...await builder.fieldsOf(type),
        ...await builder.methodsOf(type),
      ].map((e) => e.identifier).firstWhere((e) => e.name == memberName);
    }

    builder.declareInType(
      DeclarationCode.fromParts([
        '  void doReference($parametersCode) {\n    ',
        leadCode,
        identifier,
        ';\n  }',
      ]),
    );
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
