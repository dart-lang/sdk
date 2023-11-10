// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// There is no public API exposed yet, the in-progress API lives here.
import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class Observable implements FieldDeclarationsMacro {
  const Observable();

  @override
  Future<void> buildDeclarationsForField(
      FieldDeclaration field, MemberDeclarationBuilder builder) async {
    final name = field.identifier.name;
    if (!name.startsWith('_')) {
      throw ArgumentError(
          '@observable can only annotate private fields, and it will create '
          'public getters and setters for them, but the public field '
          '$name was annotated.');
    }
    var publicName = name.substring(1);
    var getter = DeclarationCode.fromParts([
      '  ',
      field.type.code,
      ' get $publicName => ',
      field.identifier,
      ';',
    ]);
    builder.declareInType(getter);

    var print =
        // ignore: deprecated_member_use
        await builder.resolveIdentifier(Uri.parse('dart:core'), 'print');
    var setter = DeclarationCode.fromParts([
      '  set $publicName(',
      field.type.code,
      ' val) {\n    ',
      print,
      "('Setting $publicName to \${val}');\n    ",
      field.identifier,
      ' = val;\n  }',
    ]);
    builder.declareInType(setter);
  }
}
