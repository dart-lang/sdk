// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class AddConstructor implements ClassDeclarationsMacro {
  const AddConstructor();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    // ignore: deprecated_member_use
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'AugmentConstructor',
    );
    builder.declareInType(
      DeclarationCode.fromParts([
        '  @',
        identifier,
        '()\n  A.named();',
      ]),
    );
  }
}

/*macro*/ class AugmentConstructor implements ConstructorDefinitionMacro {
  const AugmentConstructor();

  @override
  buildDefinitionForConstructor(constructor, builder) {
    builder.augment(
      body: FunctionBodyCode.fromString('{ print(42); }'),
    );
  }
}
