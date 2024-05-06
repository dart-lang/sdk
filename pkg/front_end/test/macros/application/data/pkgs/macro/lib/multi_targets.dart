// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart' as macro;

macro class FieldAndMethodTypesMacro
    implements macro.FieldTypesMacro, macro.MethodDeclarationsMacro {
  const FieldAndMethodTypesMacro();

  FutureOr<void> buildTypesForField(
      macro.FieldDeclaration field, macro.TypeBuilder builder) {}

  FutureOr<void> buildDeclarationsForMethod(
      macro.MethodDeclaration method, macro.MemberDeclarationBuilder builder) {}
}

macro class VariableAndFunctionTypesMacro
    implements macro.FunctionTypesMacro, macro.VariableTypesMacro {
  const VariableAndFunctionTypesMacro();

  FutureOr<void> buildTypesForFunction(
      macro.FunctionDeclaration function, macro.TypeBuilder builder) {}

  FutureOr<void> buildTypesForVariable(
      macro.VariableDeclaration variable, macro.TypeBuilder builder) {}
}
