// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:expect/expect.dart';

import 'impl.dart';

macro class AssertInDeclarationsPhase
    implements ClassDeclarationsMacro {
  final String? targetLibrary;
  final String targetName;
  final List? constructorsOf;
  final List? fieldsOf;
  final List? methodsOf;

  const AssertInDeclarationsPhase(
      {this.targetLibrary,
      required this.targetName,
      this.constructorsOf,
      this.fieldsOf,
      this.methodsOf});

  @override
  Future<void> buildDeclarationsForClass(
          ClassDeclaration clazz, MemberDeclarationBuilder builder) =>
      _assert(clazz, builder);

  // TODO(davidmorgan): support asserting in more places.

  Future<void> _assert(TypeDeclaration typeDeclaration,
      DeclarationPhaseIntrospector builder) async {
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
  }
}
