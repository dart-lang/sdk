// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class AddConstructor extends _AddMacroClass {
  const AddConstructor();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(
      builder: builder,
      augmentMacroName: 'AugmentConstructor',
      code: '  A.named();',
    );
  }
}

/*macro*/ class AddMethod extends _AddMacroClass {
  const AddMethod();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(
      builder: builder,
      augmentMacroName: 'AugmentMethod',
      code: '  external int foo();',
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

/*macro*/ class AugmentMethod implements MethodDefinitionMacro {
  const AugmentMethod();

  @override
  buildDefinitionForMethod(constructor, builder) {
    builder.augment(
      FunctionBodyCode.fromString('=> 42;'),
    );
  }
}

class _AddMacro {
  const _AddMacro();

  Future<void> _declareInType({
    required MemberDeclarationBuilder builder,
    required String augmentMacroName,
    required String code,
  }) async {
    // ignore: deprecated_member_use
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      augmentMacroName,
    );
    builder.declareInType(
      DeclarationCode.fromParts([
        '  @',
        identifier,
        '()\n$code',
      ]),
    );
  }
}

abstract class _AddMacroClass extends _AddMacro
    implements ClassDeclarationsMacro {
  const _AddMacroClass();
}
