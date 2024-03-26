// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

/*macro*/ class AutoToString implements MethodDefinitionMacro {
  const AutoToString();

  @override
  Future<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    var clazz = await builder.typeDeclarationOf(method.definingType);
    var fields = await builder.fieldsOf(clazz);
    builder.augment(FunctionBodyCode.fromParts([
      '=> """\n${clazz.identifier.name} {\n',
      for (var field in fields) ...[
        '  ${field.identifier.name}: \${', // e.g., `age: `
        field.identifier, // e.g., `${this.age}`
        '}\n',
      ],
      '}""";',
    ]));
  }
}
