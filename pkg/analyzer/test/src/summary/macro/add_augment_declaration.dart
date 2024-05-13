// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macros/macros.dart';

import 'append.dart';

/*macro*/ class AddConstructor extends _AddMacroClass {
  const AddConstructor();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(builder, r'''
  @{{package:test/a.dart@AugmentConstructor}}()
  A.named();
''');
  }
}

/*macro*/ class AddField extends _AddMacroClass {
  const AddField();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(builder, r'''
  @{{package:test/a.dart@AugmentField}}()
  {{dart:core@int}} foo;
''');
  }
}

/*macro*/ class AddGetter extends _AddMacroClass {
  const AddGetter();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(builder, r'''
  @{{package:test/a.dart@AugmentGetter}}()
  external {{dart:core@int}} get foo;
''');
  }
}

/*macro*/ class AddMethod extends _AddMacroClass {
  const AddMethod();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(builder, r'''
  @{{package:test/a.dart@AugmentMethod}}()
  external {{dart:core@int}} foo();
''');
  }
}

/*macro*/ class AddSetter extends _AddMacroClass {
  const AddSetter();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    await _declareInType(builder, r'''
  @{{package:test/a.dart@AugmentSetter}}()
  external void set foo({{dart:core@int}} value);
''');
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

/*macro*/ class AugmentField implements FieldDefinitionMacro {
  const AugmentField();

  @override
  buildDefinitionForField(constructor, builder) {
    builder.augment(
      initializer: ExpressionCode.fromString('42'),
    );
  }
}

/*macro*/ class AugmentGetter implements MethodDefinitionMacro {
  const AugmentGetter();

  @override
  buildDefinitionForMethod(constructor, builder) {
    builder.augment(
      FunctionBodyCode.fromString('=> 42;'),
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

/*macro*/ class AugmentSetter implements MethodDefinitionMacro {
  const AugmentSetter();

  @override
  buildDefinitionForMethod(constructor, builder) {
    builder.augment(
      FunctionBodyCode.fromString('{ print(42); }'),
    );
  }
}

class _AddMacro {
  const _AddMacro();

  Future<void> _declareInType(
    MemberDeclarationBuilder builder,
    String withIdentifiers,
  ) async {
    var withoutEOL = withIdentifiers.trimRight();
    var parts = await resolveIdentifiers(builder, withoutEOL);
    var code = DeclarationCode.fromParts(parts);
    builder.declareInType(code);
  }
}

abstract class _AddMacroClass extends _AddMacro
    implements ClassDeclarationsMacro {
  const _AddMacroClass();
}
