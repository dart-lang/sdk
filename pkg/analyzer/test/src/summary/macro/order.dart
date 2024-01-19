// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class AddClass
    implements
        ClassTypesMacro,
        EnumTypesMacro,
        EnumValueTypesMacro,
        MethodTypesMacro,
        MixinTypesMacro {
  final String name;

  const AddClass(this.name);

  @override
  buildTypesForClass(clazz, builder) async {
    _add(builder);
  }

  @override
  buildTypesForEnum(declaration, builder) async {
    _add(builder);
  }

  @override
  buildTypesForEnumValue(declaration, builder) async {
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

/*macro*/ class DeclarationsIntrospectConstructors
    extends _DeclarationsIntrospect {
  const DeclarationsIntrospectConstructors(super.targetName);

  @override
  Future<Iterable<String>> getMemberNames(
    DeclarationPhaseIntrospector introspector,
    TypeDeclaration type,
  ) async {
    final constructors = await introspector.constructorsOf(type);
    return constructors.map((constructor) => constructor.identifier.name);
  }
}

/*macro*/ class DeclarationsIntrospectFields extends _DeclarationsIntrospect {
  const DeclarationsIntrospectFields(super.targetName);

  @override
  Future<Iterable<String>> getMemberNames(
    DeclarationPhaseIntrospector introspector,
    TypeDeclaration type,
  ) async {
    final fields = await introspector.fieldsOf(type);
    return fields.map((field) => field.identifier.name);
  }
}

/*macro*/ class DeclarationsIntrospectMethods extends _DeclarationsIntrospect {
  const DeclarationsIntrospectMethods(super.targetName);

  @override
  Future<Iterable<String>> getMemberNames(
    DeclarationPhaseIntrospector introspector,
    TypeDeclaration type,
  ) async {
    final methods = await introspector.methodsOf(type);
    return methods.map((method) => method.identifier.name);
  }
}

abstract class _DeclarationsIntrospect implements ClassDeclarationsMacro {
  final String targetName;

  const _DeclarationsIntrospect(this.targetName);

  @override
  Future<void> buildDeclarationsForClass(declaration, builder) async {
    // ignore: deprecated_member_use
    final identifier = await builder.resolveIdentifier(
      declaration.library.uri,
      targetName,
    );
    final type = await builder.typeDeclarationOf(identifier);
    final memberNames = await getMemberNames(builder, type);
    for (final memberName in memberNames) {
      builder.declareInType(
        DeclarationCode.fromString(
          '  void introspected_'
          '${type.identifier.name}_'
          '$memberName();',
        ),
      );
    }
  }

  Future<Iterable<String>> getMemberNames(
    DeclarationPhaseIntrospector introspector,
    TypeDeclaration type,
  );
}
