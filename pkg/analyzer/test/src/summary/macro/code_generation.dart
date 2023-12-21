// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

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

/*macro*/ class DefineToStringAsTypeName
    implements ClassDefinitionMacro, MethodDefinitionMacro {
  const DefineToStringAsTypeName();

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final methods = await builder.methodsOf(clazz);
    final toString = methods.firstWhereOrNull(
      (e) => e.identifier.name == 'toString',
    );
    if (toString == null) {
      throw StateError('No toString() declaration');
    }

    final toStringBuilder = await builder.buildMethod(
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
    final uri = Uri.parse(uriStr);

    // ignore: deprecated_member_use
    var identifier = await builder.resolveIdentifier(uri, topName);

    if (memberName case final memberName?) {
      final type = await builder.typeDeclarationOf(identifier);
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
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
