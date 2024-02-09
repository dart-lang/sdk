// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// ignore_for_file: deprecated_member_use
import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'impl.dart';

macro class ClassDefinitionBuildConstructor implements ClassDefinitionMacro {
  final String name;
  final String? body;
  final List? initializers;
  final String? comments;

  const ClassDefinitionBuildConstructor(
      {required this.name, this.body, this.initializers, this.comments});

  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final nameIdentifier =
        await builder.resolveIdentifier(clazz.library.uri, name);
    (await builder.buildConstructor(nameIdentifier)).augment(
        body: await builder.code(body),
        initializers: initializers == null
            ? null
            : initializers!.map((s) => DeclarationCode.fromString(s)).toList(),
        docComments: await builder.code(comments));
  }
}

macro class ClassDefinitionBuildField implements ClassDefinitionMacro {
  final String name;
  final String? getter;
  final String? setter;
  final String? initializer;
  final String? initializerComments;

  const ClassDefinitionBuildField(
      {required this.name,
      this.getter,
      this.setter,
      this.initializer,
      this.initializerComments});

  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final nameIdentifier =
        await builder.resolveIdentifier(clazz.library.uri, name);
    (await builder.buildField(nameIdentifier)).augment(
      getter: await builder.code(getter),
      setter: await builder.code(setter),
      initializer: await builder.code(initializer),
      initializerDocComments: await builder.code(initializerComments),
    );
  }
}

macro class ClassDefinitionBuildMethod implements ClassDefinitionMacro {
  final String name;
  final String body;
  final String? comments;

  const ClassDefinitionBuildMethod(
      {required this.name, required this.body, this.comments});

  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final nameIdentifier =
        await builder.resolveIdentifier(clazz.library.uri, name);
    (await builder.buildMethod(nameIdentifier)).augment(
      await builder.code(body),
      docComments: await builder.code(comments),
    );
  }
}
