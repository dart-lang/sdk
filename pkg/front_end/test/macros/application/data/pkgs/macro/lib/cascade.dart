// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart';

macro class CreateMacro implements ClassDeclarationsMacro {
  const CreateMacro();

  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {

    Uri myUri = Uri.parse('package:macro/cascade.dart');

    builder.declareInType(DeclarationCode.fromParts([
      '  @',
      await builder.resolveIdentifier(myUri, 'CreateMethodMacro'),
      '()\n  external ',
      NamedTypeAnnotationCode(name: clazz.identifier),
      ' create();',
    ]));
  }
}

macro class CreateMethodMacro implements MethodDefinitionMacro {
  const CreateMethodMacro();

  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) {
    builder.augment(FunctionBodyCode.fromParts([
      ' => ',
      method.definingType,
      '();'
    ]));
  }
}
