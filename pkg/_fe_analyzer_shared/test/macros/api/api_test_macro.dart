// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'api_test_expectations.dart';



macro class ClassMacro
    implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const ClassMacro();

  FutureOr<void> buildTypesForClass(
      ClassDeclaration clazz, TypeBuilder builder) {
    checkClassDeclaration(clazz);
  }

  FutureOr<void> buildDeclarationsForClass(
      ClassDeclaration clazz, ClassMemberDeclarationBuilder builder) {
    checkClassDeclaration(clazz);
  }

  FutureOr<void> buildDefinitionForClass(
      ClassDeclaration clazz, ClassDefinitionBuilder builder) {
    checkClassDeclaration(clazz);
  }
}

macro class FunctionMacro
    implements
        FunctionTypesMacro,
        FunctionDeclarationsMacro,
        FunctionDefinitionMacro {
  const FunctionMacro();

  FutureOr<void> buildTypesForFunction(
      FunctionDeclaration function, TypeBuilder builder) {
    checkFunctionDeclaration(function);
  }

  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder) {
    checkFunctionDeclaration(function);
  }

  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder) {
    checkFunctionDeclaration(function);
  }
}
