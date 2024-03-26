// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:macros/macros.dart' as macro;

macro class LibraryTypesMacro implements macro.LibraryTypesMacro {
  const LibraryTypesMacro();

  FutureOr<void> buildTypesForLibrary(
      macro.Library library, macro.TypeBuilder builder) {}
}

macro class LibraryDeclarationsMacro implements macro.LibraryDeclarationsMacro {
  const LibraryDeclarationsMacro();

  FutureOr<void> buildDeclarationsForLibrary(
      macro.Library library, macro.DeclarationBuilder builder) {}
}

macro class LibraryDefinitionMacro implements macro.LibraryDefinitionMacro {
  const LibraryDefinitionMacro();

  FutureOr<void> buildDefinitionForLibrary(
      macro.Library library, macro.LibraryDefinitionBuilder builder) {}
}

macro class FunctionTypesMacro implements macro.FunctionTypesMacro {
  const FunctionTypesMacro();

  FutureOr<void> buildTypesForFunction(
      macro.FunctionDeclaration function, macro.TypeBuilder builder) {}
}

macro class FunctionDeclarationsMacro
    implements macro.FunctionDeclarationsMacro {
  const FunctionDeclarationsMacro();

  FutureOr<void> buildDeclarationsForFunction(
      macro.FunctionDeclaration function, macro.DeclarationBuilder builder) {}
}

macro class FunctionDefinitionMacro
    implements macro.FunctionDefinitionMacro {
  const FunctionDefinitionMacro();

  FutureOr<void> buildDefinitionForFunction(
      macro.FunctionDeclaration function,
      macro.FunctionDefinitionBuilder builder) {}
}

macro class VariableTypesMacro implements macro.VariableTypesMacro {
  const VariableTypesMacro();

  FutureOr<void> buildTypesForVariable(
      macro.VariableDeclaration variable, macro.TypeBuilder builder) {}
}

macro class VariableDeclarationsMacro
    implements macro.VariableDeclarationsMacro {
  const VariableDeclarationsMacro();

  FutureOr<void> buildDeclarationsForVariable(
      macro.VariableDeclaration variable, macro.DeclarationBuilder builder) {}
}

macro class VariableDefinitionMacro implements macro.VariableDefinitionMacro {
  const VariableDefinitionMacro();

  FutureOr<void> buildDefinitionForVariable(
      macro.VariableDeclaration variable,
      macro.VariableDefinitionBuilder builder) {}
}

macro class ClassTypesMacro implements macro.ClassTypesMacro {
  const ClassTypesMacro();

  FutureOr<void> buildTypesForClass(
      macro.ClassDeclaration clazz, macro.ClassTypeBuilder builder) {}
}

macro class ClassDeclarationsMacro implements macro.ClassDeclarationsMacro {
  const ClassDeclarationsMacro();

  FutureOr<void> buildDeclarationsForClass(
      macro.ClassDeclaration clazz, macro.MemberDeclarationBuilder builder) {}
}

macro class ClassDefinitionMacro implements macro.ClassDefinitionMacro {
  const ClassDefinitionMacro();

  FutureOr<void> buildDefinitionForClass(
      macro.ClassDeclaration clazz, macro.TypeDefinitionBuilder builder) {}
}

macro class EnumTypesMacro implements macro.EnumTypesMacro {
  const EnumTypesMacro();

  FutureOr<void> buildTypesForEnum(
      macro.EnumDeclaration enuum, macro.EnumTypeBuilder builder) {}
}

macro class EnumDeclarationsMacro implements macro.EnumDeclarationsMacro {
  const EnumDeclarationsMacro();

  FutureOr<void> buildDeclarationsForEnum(
      macro.EnumDeclaration enuum, macro.EnumDeclarationBuilder builder) {}
}

macro class EnumDefinitionMacro implements macro.EnumDefinitionMacro {
  const EnumDefinitionMacro();

  FutureOr<void> buildDefinitionForEnum(
      macro.EnumDeclaration enuum, macro.EnumDefinitionBuilder builder) {}
}

macro class EnumValueTypesMacro implements macro.EnumValueTypesMacro {
  const EnumValueTypesMacro();

  FutureOr<void> buildTypesForEnumValue(
      macro.EnumValueDeclaration entry, macro.TypeBuilder builder) {}
}

macro class EnumValueDeclarationsMacro
    implements macro.EnumValueDeclarationsMacro {
  const EnumValueDeclarationsMacro();

  FutureOr<void> buildDeclarationsForEnumValue(
      macro.EnumValueDeclaration entry, macro.EnumDeclarationBuilder builder) {}
}

macro class EnumValueDefinitionMacro implements macro.EnumValueDefinitionMacro {
  const EnumValueDefinitionMacro();

  FutureOr<void> buildDefinitionForEnumValue(
      macro.EnumValueDeclaration entry,
      macro.EnumValueDefinitionBuilder builder) {}
}

macro class FieldTypesMacro implements macro.FieldTypesMacro {
  const FieldTypesMacro();

  FutureOr<void> buildTypesForField(
      macro.FieldDeclaration field, macro.TypeBuilder builder) {}
}

macro class FieldDeclarationsMacro implements macro.FieldDeclarationsMacro {
  const FieldDeclarationsMacro();

  FutureOr<void> buildDeclarationsForField(
      macro.FieldDeclaration field, macro.MemberDeclarationBuilder builder) {}
}

macro class FieldDefinitionMacro implements macro.FieldDefinitionMacro {
  const FieldDefinitionMacro();

  FutureOr<void> buildDefinitionForField(
      macro.FieldDeclaration field, macro.VariableDefinitionBuilder builder) {}
}

macro class MethodTypesMacro implements macro.MethodTypesMacro {
  const MethodTypesMacro();

  FutureOr<void> buildTypesForMethod(
      macro.MethodDeclaration method, macro.TypeBuilder builder) {}
}

macro class MethodDeclarationsMacro implements macro.MethodDeclarationsMacro {
  const MethodDeclarationsMacro();

  FutureOr<void> buildDeclarationsForMethod(
      macro.MethodDeclaration method, macro.MemberDeclarationBuilder builder) {}
}

macro class MethodDefinitionMacro implements macro.MethodDefinitionMacro {
  const MethodDefinitionMacro();

  FutureOr<void> buildDefinitionForMethod(
      macro.MethodDeclaration method,
      macro.FunctionDefinitionBuilder builder) {}
}

macro class ConstructorTypesMacro implements macro.ConstructorTypesMacro {
  const ConstructorTypesMacro();

  FutureOr<void> buildTypesForConstructor(
      macro.ConstructorDeclaration constructor, macro.TypeBuilder builder) {}
}

macro class ConstructorDeclarationsMacro
    implements macro.ConstructorDeclarationsMacro {
  const ConstructorDeclarationsMacro();

  FutureOr<void> buildDeclarationsForConstructor(
      macro.ConstructorDeclaration constructor,
      macro.MemberDeclarationBuilder builder) {}
}

macro class ConstructorDefinitionMacro
    implements macro.ConstructorDefinitionMacro {
  const ConstructorDefinitionMacro();

  FutureOr<void> buildDefinitionForConstructor(
      macro.ConstructorDeclaration constructor,
      macro.ConstructorDefinitionBuilder builder) {}
}

macro class MixinTypesMacro implements macro.MixinTypesMacro {
  const MixinTypesMacro();

  FutureOr<void> buildTypesForMixin(
      macro.MixinDeclaration mixin, macro.MixinTypeBuilder builder) {}
}

macro class MixinDeclarationsMacro implements macro.MixinDeclarationsMacro {
  const MixinDeclarationsMacro();

  FutureOr<void> buildDeclarationsForMixin(
      macro.MixinDeclaration mixin, macro.MemberDeclarationBuilder builder) {}
}

macro class MixinDefinitionMacro implements macro.MixinDefinitionMacro {
  const MixinDefinitionMacro();

  FutureOr<void> buildDefinitionForMixin(
      macro.MixinDeclaration mixin, macro.TypeDefinitionBuilder builder) {}
}

macro class ExtensionTypesMacro implements macro.ExtensionTypesMacro {
  const ExtensionTypesMacro();

  FutureOr<void> buildTypesForExtension(
      macro.ExtensionDeclaration extension, macro.TypeBuilder builder) {}
}

macro class ExtensionDeclarationsMacro
    implements macro.ExtensionDeclarationsMacro {
  const ExtensionDeclarationsMacro();

  FutureOr<void> buildDeclarationsForExtension(
      macro.ExtensionDeclaration extension,
      macro.MemberDeclarationBuilder builder) {}
}

macro class ExtensionDefinitionMacro implements macro.ExtensionDefinitionMacro {
  const ExtensionDefinitionMacro();

  FutureOr<void> buildDefinitionForExtension(
      macro.ExtensionDeclaration extension,
      macro.TypeDefinitionBuilder builder) {}
}

macro class ExtensionTypeTypesMacro implements macro.ExtensionTypeTypesMacro {
  const ExtensionTypeTypesMacro();

  FutureOr<void> buildTypesForExtensionType(
      macro.ExtensionTypeDeclaration extension, macro.TypeBuilder builder) {}
}

macro class ExtensionTypeDeclarationsMacro
    implements macro.ExtensionTypeDeclarationsMacro {
  const ExtensionTypeDeclarationsMacro();

  FutureOr<void> buildDeclarationsForExtensionType(
      macro.ExtensionTypeDeclaration extension,
      macro.MemberDeclarationBuilder builder) {}
}

macro class ExtensionTypeDefinitionMacro
    implements macro.ExtensionTypeDefinitionMacro {
  const ExtensionTypeDefinitionMacro();

  FutureOr<void> buildDefinitionForExtensionType(
      macro.ExtensionTypeDeclaration extension,
      macro.TypeDefinitionBuilder builder) {}
}

macro class TypeAliasTypesMacro implements macro.TypeAliasTypesMacro {
  const TypeAliasTypesMacro();

  FutureOr<void> buildTypesForTypeAlias(
      macro.TypeAliasDeclaration declaration,
      macro.TypeBuilder builder,
      ) {}
}

macro class TypeAliasDeclarationsMacro
    implements macro.TypeAliasDeclarationsMacro {
  const TypeAliasDeclarationsMacro();

  FutureOr<void> buildDeclarationsForTypeAlias(
      macro.TypeAliasDeclaration declaration,
      macro.DeclarationBuilder builder,
      ) {}
}
