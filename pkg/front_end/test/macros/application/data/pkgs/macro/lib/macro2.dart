// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'macro1.dart';

@Macro1()
macro

class Macro2 implements ClassDeclarationsMacro {
  const Macro2();

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) {
    if (isMacro) {
      builder.declareInClass(new DeclarationCode.fromString('''
  hasMacro() => true;
'''));
    }
  }
}
