// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart';
import 'main.dart';
import 'main_lib2.dart';

macro class Macro1 implements FunctionDeclarationsMacro {
  const Macro1();

  @Macro2() // Ok
  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder) {}
}
