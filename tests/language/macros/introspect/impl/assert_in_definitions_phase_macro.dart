// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:macros/macros.dart';
import 'package:expect/expect.dart';

import 'impl.dart';

macro class AssertInDefinitionsPhase implements ClassDefinitionMacro {
  final String? targetLibrary;
  final String targetName;
  final List? constructorsOf;
  final List? fieldsOf;
  final List? methodsOf;

  const AssertInDefinitionsPhase(
      {this.targetLibrary,
      required this.targetName,
      this.constructorsOf,
      this.fieldsOf,
      this.methodsOf});

  @override
  Future<void> buildDefinitionForClass(
          ClassDeclaration clazz, TypeDefinitionBuilder builder) =>
      _assert(clazz, builder);

  // TODO(davidmorgan): support asserting in more places.

  Future<void> _assert(TypeDeclaration typeDeclaration,
      DefinitionPhaseIntrospector builder) async {
    final targetIdentifier = await builder.resolveIdentifier(
        targetLibrary == null
            ? typeDeclaration.library.uri
            : Uri.parse(targetLibrary!),
        targetName);
    final declaration = await builder.typeDeclarationOf(targetIdentifier);

    if (constructorsOf != null) {
      Expect.deepEquals(
          constructorsOf, stringify(await builder.constructorsOf(declaration)));
    }
    if (fieldsOf != null) {
      Expect.deepEquals(
          fieldsOf, stringify(await builder.fieldsOf(declaration)));
    }
    if (methodsOf != null) {
      Expect.deepEquals(
          methodsOf, stringify(await builder.methodsOf(declaration)));
    }
    // TODO(davidmorgan): cover typeDeclarationsOf, typesOf, valuesOf.
    // TODO(davidmorgan): cover DefinitionPhaseIntrospector methods.
  }
}
