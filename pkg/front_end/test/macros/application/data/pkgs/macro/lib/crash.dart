// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart';

macro class CrashTypesMacro implements ClassTypesMacro {
  const CrashTypesMacro();

  FutureOr<void> buildTypesForClass(
      ClassDeclaration clazz, ClassTypeBuilder builder) async {
    throw 'Error in buildTypesForClass';
  }
}

macro class CrashDeclarationsMacro implements ClassDeclarationsMacro {
  const CrashDeclarationsMacro();

  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {
    throw 'Error in buildDeclarationsForClass';
  }
}

macro class CrashDefinitionMacro implements ClassDefinitionMacro {
  const CrashDefinitionMacro();

  FutureOr<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    throw 'Error in buildDefinitionForClass';
  }
}
