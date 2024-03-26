// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart';

macro

class AnnotationsMacro
    implements ClassDeclarationsMacro, FunctionDeclarationsMacro {
  final Object? object;
  final Object? additional;

  const AnnotationsMacro(this.object, [this.additional]);

  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) {}

  FutureOr<void> buildDeclarationsForFunction(FunctionDeclaration function,
      DeclarationBuilder builder) {}
}
