// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/macro/api/code.dart';
import 'package:analyzer/src/macro/api/macro.dart';

class ObservableMacro implements FieldDeclarationMacro {
  const ObservableMacro();

  @override
  void visitFieldDeclaration(
    ast.FieldDeclaration node,
    ClassDeclarationBuilder builder,
  ) {
    var typeNode = node.fields.type;
    if (typeNode == null) {
      throw ArgumentError('@observable can only annotate typed fields.');
    }
    var typeCode = builder.typeAnnotationCode(typeNode);

    var fields = node.fields.variables;
    for (var field in fields) {
      var name = field.name.name;
      if (!name.startsWith('_')) {
        throw ArgumentError(
          '@observable can only annotate private fields, and it will create '
          'public getters and setters for them, but the public field '
          '$name was annotated.',
        );
      }
      var publicName = name.substring(1);

      var getter = Declaration(
        '  $typeCode get $publicName => $name;',
      );
      builder.addToClass(getter);

      var setter = Declaration('''
  set $publicName($typeCode val) {
    print('Setting $publicName to \${val}');
    $name = val;
  }
''');
      builder.addToClass(setter);
    }
  }
}
