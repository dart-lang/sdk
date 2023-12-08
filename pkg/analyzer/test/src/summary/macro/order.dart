// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class AddClass
    implements ClassTypesMacro, MethodTypesMacro, MixinTypesMacro {
  final String name;

  const AddClass(this.name);

  @override
  buildTypesForClass(clazz, builder) async {
    _add(builder);
  }

  @override
  buildTypesForMethod(method, builder) {
    _add(builder);
  }

  @override
  buildTypesForMixin(method, builder) {
    _add(builder);
  }

  void _add(TypeBuilder builder) {
    final code = 'class $name {}';
    builder.declareType(name, DeclarationCode.fromString(code));
  }
}

/*macro*/ class AddFunction
    implements
        ClassDeclarationsMacro,
        MethodDeclarationsMacro,
        MixinDeclarationsMacro {
  final String name;

  const AddFunction(this.name);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    _add(builder);
  }

  @override
  buildDeclarationsForMethod(method, builder) {
    _add(builder);
  }

  @override
  buildDeclarationsForMixin(method, builder) {
    _add(builder);
  }

  void _add(DeclarationBuilder builder) {
    final code = 'void $name() {}';
    final declaration = DeclarationCode.fromString(code);
    builder.declareInLibrary(declaration);
  }
}

/*macro*/ class AddMethod
    implements
        ClassDeclarationsMacro,
        MethodDeclarationsMacro,
        MixinDeclarationsMacro {
  final String name;

  const AddMethod(this.name);

  @override
  buildDeclarationsForClass(clazz, builder) async {
    _add(builder);
  }

  @override
  buildDeclarationsForMethod(method, builder) {
    _add(builder);
  }

  @override
  buildDeclarationsForMixin(method, builder) {
    _add(builder);
  }

  void _add(MemberDeclarationBuilder builder) {
    final code = '  void $name() {}';
    final declaration = DeclarationCode.fromString(code);
    builder.declareInType(declaration);
  }
}

/*macro*/ class DeclarationsIntrospectMethods
    implements ClassDeclarationsMacro {
  final String targetName;

  const DeclarationsIntrospectMethods(this.targetName);

  @override
  Future<void> buildDeclarationsForClass(declaration, builder) async {
    // ignore: deprecated_member_use
    final identifier = await builder.resolveIdentifier(
      declaration.library.uri,
      targetName,
    );
    final type = await builder.typeDeclarationOf(identifier);
    final methods = await builder.methodsOf(type);
    for (final method in methods) {
      builder.declareInType(
        DeclarationCode.fromString(
          '  void introspected_'
          '${type.identifier.name}_'
          '${method.identifier.name}();',
        ),
      );
    }
  }
}
