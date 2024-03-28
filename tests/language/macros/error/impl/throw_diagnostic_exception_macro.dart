// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// ignore_for_file: deprecated_member_use
import 'package:macros/macros.dart';

macro class ThrowDiagnosticException implements ClassDeclarationsMacro {
  final String atTypeDeclaration;
  final String withMessage;

  const ThrowDiagnosticException(
      {required this.atTypeDeclaration, required this.withMessage});

  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final identifier =
        await builder.resolveIdentifier(clazz.library.uri, atTypeDeclaration);
    final declaration = await builder.typeDeclarationOf(identifier);
    throw DiagnosticException(Diagnostic(
        DiagnosticMessage(withMessage, target: declaration.asDiagnosticTarget),
        Severity.error));
  }
}
