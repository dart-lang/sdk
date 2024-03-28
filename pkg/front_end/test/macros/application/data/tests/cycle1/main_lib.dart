// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart';
import 'main.dart';

macro class Macro implements FunctionDeclarationsMacro {
  const Macro();

  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder) {}
}
