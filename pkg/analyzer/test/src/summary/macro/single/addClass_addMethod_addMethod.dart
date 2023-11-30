// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class AddClassB implements ClassTypesMacro {
  const AddClassB();

  @override
  buildTypesForClass(clazz, builder) async {
    // ignore: deprecated_member_use
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'AddMethodFoo',
    );
    builder.declareType(
      'MyClass',
      DeclarationCode.fromParts([
        '@',
        identifier,
        '()\nclass B {}\n',
      ]),
    );
  }
}

/*macro*/ class AddMethodBar implements MethodDeclarationsMacro {
  const AddMethodBar();

  @override
  buildDeclarationsForMethod(method, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  void bar() {}'),
    );
  }
}

/*macro*/ class AddMethodFoo implements ClassDeclarationsMacro {
  const AddMethodFoo();

  @override
  buildDeclarationsForClass(clazz, builder) async {
    // ignore: deprecated_member_use
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'AddMethodBar',
    );
    builder.declareInType(
      DeclarationCode.fromParts([
        '  @',
        identifier,
        '()\n  void foo() {}',
      ]),
    );
  }
}
