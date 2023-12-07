// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

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

/*macro*/ class ReferenceDartCorePrint implements ClassDeclarationsMacro {
  const ReferenceDartCorePrint();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    // ignore: deprecated_member_use
    final print2 = await builder.resolveIdentifier(
      Uri.parse('dart:core'),
      'print',
    );

    builder.declareInType(DeclarationCode.fromParts([
      '  void foo() {\n    ',
      print2,
      '();\n  }',
    ]));
  }
}

/*macro*/ class ReferenceField implements FieldDeclarationsMacro {
  const ReferenceField();

  @override
  FutureOr<void> buildDeclarationsForField(
    FieldDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    builder.declareInType(
      DeclarationCode.fromParts([
        '  void foo() {\n    ',
        declaration.identifier,
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
