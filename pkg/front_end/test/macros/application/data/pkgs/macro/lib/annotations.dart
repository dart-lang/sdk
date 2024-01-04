// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro

class AnnotationsMacro
    implements ClassDeclarationsMacro, FunctionDeclarationsMacro {
  final Object? object;

  const AnnotationsMacro(this.object);

  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) {}

  FutureOr<void> buildDeclarationsForFunction(FunctionDeclaration function,
      DeclarationBuilder builder) {}
}
