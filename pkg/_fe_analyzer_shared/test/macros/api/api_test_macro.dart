// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: experiment_not_enabled

import 'dart:async';
import 'package:macros/macros.dart';
import 'api_test_expectations.dart';

macro class ClassMacro
    implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const ClassMacro();

  @override
  FutureOr<void> buildTypesForClass(ClassDeclaration clazz,
      TypeBuilder builder) async {
    await checkClassDeclaration(clazz);
  }

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz,
      MemberDeclarationBuilder builder) async {
    await checkClassDeclaration(
        clazz, introspector: builder);
  }

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz,
      TypeDefinitionBuilder builder) async {
    await checkClassDeclaration(clazz, introspector: builder);
    await checkIdentifierResolver(builder);
    await checkTypeDeclarationResolver(builder,
        {clazz.identifier: clazz.identifier.name});
  }
}

macro class MixinMacro
    implements MixinTypesMacro, MixinDeclarationsMacro, MixinDefinitionMacro {
  const MixinMacro();

  @override
  FutureOr<void> buildTypesForMixin(MixinDeclaration mixin,
      MixinTypeBuilder builder) async {
    await checkMixinDeclaration(mixin);
  }

  @override
  FutureOr<void> buildDeclarationsForMixin(MixinDeclaration mixin,
      MemberDeclarationBuilder builder) async {
    await checkMixinDeclaration(
        mixin, introspector: builder);
  }

  @override
  FutureOr<void> buildDefinitionForMixin(MixinDeclaration mixin,
      TypeDefinitionBuilder builder) async {
    await checkMixinDeclaration(mixin, introspector: builder);
    await checkIdentifierResolver(builder);
    await checkTypeDeclarationResolver(builder,
        {mixin.identifier: mixin.identifier.name});
  }
}

macro class ExtensionTypeMacro
    implements
        ExtensionTypeTypesMacro,
        ExtensionTypeDeclarationsMacro,
        ExtensionTypeDefinitionMacro {
  const ExtensionTypeMacro();

  @override
  FutureOr<void> buildTypesForExtensionType(
      ExtensionTypeDeclaration extensionType,
      TypeBuilder builder) async {
    await checkExtensionTypeDeclaration(extensionType);
  }

  @override
  FutureOr<void> buildDeclarationsForExtensionType(
      ExtensionTypeDeclaration extensionType,
      MemberDeclarationBuilder builder) async {
    await checkExtensionTypeDeclaration(
        extensionType, introspector: builder);
  }

  @override
  FutureOr<void> buildDefinitionForExtensionType(
      ExtensionTypeDeclaration extensionType,
      TypeDefinitionBuilder builder) async {
    await checkExtensionTypeDeclaration(extensionType, introspector: builder);
    await checkIdentifierResolver(builder);
    await checkTypeDeclarationResolver(builder,
        {extensionType.identifier: extensionType.identifier.name});
  }
}

macro class FunctionMacro
    implements
        FunctionTypesMacro,
        FunctionDeclarationsMacro,
        FunctionDefinitionMacro {
  const FunctionMacro();

  @override
  FutureOr<void> buildTypesForFunction(FunctionDeclaration function,
      TypeBuilder builder) async {
    checkFunctionDeclaration(function);
    await checkIdentifierResolver(builder);
  }

  @override
  FutureOr<void> buildDeclarationsForFunction(FunctionDeclaration function,
      DeclarationBuilder builder) async {
    checkFunctionDeclaration(function);
    await checkIdentifierResolver(builder);
  }

  @override
  FutureOr<void> buildDefinitionForFunction(FunctionDeclaration function,
      FunctionDefinitionBuilder builder) async {
    checkFunctionDeclaration(function);
    await checkIdentifierResolver(builder);
    await checkTypeDeclarationResolver(builder, {function.identifier: null});
  }
}
