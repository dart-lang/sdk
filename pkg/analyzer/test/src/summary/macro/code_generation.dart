// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

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
