// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro

class Macro1 implements ClassDeclarationsMacro {
  const Macro1();

  @override
  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      MemberDeclarationBuilder builder) {
    builder.declareInType(new DeclarationCode.fromString('''
  get isMacro => true;
'''));
  }
}
