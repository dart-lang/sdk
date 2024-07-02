// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Types Order:
 org-dartlang-test:///a/b/c/main.dart:LibraryTypesMacro.new()
 function:VariableAndFunctionTypesMacro.new()
 function:FunctionTypesMacro.new()
 variable:VariableAndFunctionTypesMacro.new()
 variable:VariableTypesMacro.new()
 Class.field:VariableAndFunctionTypesMacro.new()
 Class.field:FieldAndMethodTypesMacro.new()
 Class.field:FieldTypesMacro.new()
 Class.field:VariableTypesMacro.new()
 Class.method:VariableAndFunctionTypesMacro.new()
 Class.method:MethodTypesMacro.new()
 Class.method:FunctionTypesMacro.new()
 Class.:ConstructorTypesMacro.new()
 Class:ClassTypesMacro.new()
 Enum.a:FieldTypesMacro.new()
 Enum.a:VariableTypesMacro.new()
 Enum:ClassTypesMacro.new()
 Mixin:MixinTypesMacro.new()
 ExtensionType:ExtensionTypeTypesMacro.new()
Declarations Order:
 Class.field:FieldDeclarationsMacro.new()
 Class.field:VariableDeclarationsMacro.new()
 Class.method:FieldAndMethodTypesMacro.new()
 Class.method:MethodDeclarationsMacro.new()
 Class.method:FunctionDeclarationsMacro.new()
 Class.:ConstructorDeclarationsMacro.new()
 Class:ClassDeclarationsMacro.new()
 Enum.a:FieldDeclarationsMacro.new()
 Enum.a:VariableDeclarationsMacro.new()
 Enum:ClassDeclarationsMacro.new()
 Mixin:MixinDeclarationsMacro.new()
 ExtensionType:ExtensionTypeDeclarationsMacro.new()
 org-dartlang-test:///a/b/c/main.dart:LibraryDeclarationsMacro.new()
 function:FunctionDeclarationsMacro.new()
 variable:VariableDeclarationsMacro.new()
Definition Order:
 org-dartlang-test:///a/b/c/main.dart:LibraryDefinitionMacro.new()
 function:FunctionDefinitionMacro.new()
 variable:VariableDefinitionMacro.new()
 Class.field:FieldDefinitionMacro.new()
 Class.field:VariableDefinitionMacro.new()
 Class.method:MethodDefinitionMacro.new()
 Class.method:FunctionDefinitionMacro.new()
 Class.:ConstructorDefinitionMacro.new()
 Class:ClassDefinitionMacro.new()
 Enum.a:FieldDefinitionMacro.new()
 Enum.a:VariableDefinitionMacro.new()
 Enum:ClassDefinitionMacro.new()
 Mixin:MixinDefinitionMacro.new()
 ExtensionType:ExtensionTypeDefinitionMacro.new()*/

@LibraryTypesMacro() // Ok
@LibraryDeclarationsMacro() // Ok
@LibraryDefinitionMacro() // Ok
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
library;

import 'package:macro/targets.dart';
import 'package:macro/multi_targets.dart';

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Ok
@ClassDeclarationsMacro() // Ok
@ClassDefinitionMacro() // Ok
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
class Class {
  @LibraryTypesMacro() // Error
  @LibraryDeclarationsMacro() // Error
  @LibraryDefinitionMacro() // Error
  @FunctionTypesMacro() // Error
  @FunctionDeclarationsMacro() // Error
  @FunctionDefinitionMacro() // Error
  @VariableTypesMacro() // Ok
  @VariableDeclarationsMacro() // Ok
  @VariableDefinitionMacro() // Ok
  @ClassTypesMacro() // Error
  @ClassDeclarationsMacro() // Error
  @ClassDefinitionMacro() // Error
  @EnumTypesMacro() // Error
  @EnumDeclarationsMacro() // Error
  @EnumDefinitionMacro() // Error
  @EnumValueTypesMacro() // Error
  @EnumValueDeclarationsMacro() // Error
  @EnumValueDefinitionMacro() // Error
  @FieldTypesMacro() // Ok
  @FieldDeclarationsMacro() // Ok
  @FieldDefinitionMacro() // Ok
  @MethodTypesMacro() // Error
  @MethodDeclarationsMacro() // Error
  @MethodDefinitionMacro() // Error
  @ConstructorTypesMacro() // Error
  @ConstructorDeclarationsMacro() // Error
  @ConstructorDefinitionMacro() // Error
  @MixinTypesMacro() // Error
  @MixinDeclarationsMacro() // Error
  @MixinDefinitionMacro() // Error
  @ExtensionTypesMacro() // Error
  @ExtensionDeclarationsMacro() // Error
  @ExtensionDefinitionMacro() // Error
  @ExtensionTypeTypesMacro() // Error
  @ExtensionTypeDeclarationsMacro() // Error
  @ExtensionTypeDefinitionMacro() // Error
  @TypeAliasTypesMacro() // Error
  @TypeAliasDeclarationsMacro() // Error
  @FieldAndMethodTypesMacro() // Ok
  @VariableAndFunctionTypesMacro() // Ok
  int field = 0;

  @LibraryTypesMacro() // Error
  @LibraryDeclarationsMacro() // Error
  @LibraryDefinitionMacro() // Error
  @FunctionTypesMacro() // Error
  @FunctionDeclarationsMacro() // Error
  @FunctionDefinitionMacro() // Error
  @VariableTypesMacro() // Error
  @VariableDeclarationsMacro() // Error
  @VariableDefinitionMacro() // Error
  @ClassTypesMacro() // Error
  @ClassDeclarationsMacro() // Error
  @ClassDefinitionMacro() // Error
  @EnumTypesMacro() // Error
  @EnumDeclarationsMacro() // Error
  @EnumDefinitionMacro() // Error
  @EnumValueTypesMacro() // Error
  @EnumValueDeclarationsMacro() // Error
  @EnumValueDefinitionMacro() // Error
  @FieldTypesMacro() // Error
  @FieldDeclarationsMacro() // Error
  @FieldDefinitionMacro() // Error
  @MethodTypesMacro() // Error
  @MethodDeclarationsMacro() // Error
  @MethodDefinitionMacro() // Error
  @ConstructorTypesMacro() // Ok
  @ConstructorDeclarationsMacro() // Ok
  @ConstructorDefinitionMacro() // Ok
  @MixinTypesMacro() // Error
  @MixinDeclarationsMacro() // Error
  @MixinDefinitionMacro() // Error
  @ExtensionTypesMacro() // Error
  @ExtensionDeclarationsMacro() // Error
  @ExtensionDefinitionMacro() // Error
  @ExtensionTypeTypesMacro() // Error
  @ExtensionTypeDeclarationsMacro() // Error
  @ExtensionTypeDefinitionMacro() // Error
  @TypeAliasTypesMacro() // Error
  @TypeAliasDeclarationsMacro() // Error
  @FieldAndMethodTypesMacro() // Error
  @VariableAndFunctionTypesMacro() // Error
  Class();

  @LibraryTypesMacro() // Error
  @LibraryDeclarationsMacro() // Error
  @LibraryDefinitionMacro() // Error
  @FunctionTypesMacro() // Ok
  @FunctionDeclarationsMacro() // Ok
  @FunctionDefinitionMacro() // Ok
  @VariableTypesMacro() // Ok
  @VariableDeclarationsMacro() // Error
  @VariableDefinitionMacro() // Error
  @ClassTypesMacro() // Error
  @ClassDeclarationsMacro() // Error
  @ClassDefinitionMacro() // Error
  @EnumTypesMacro() // Error
  @EnumDeclarationsMacro() // Error
  @EnumDefinitionMacro() // Error
  @EnumValueTypesMacro() // Error
  @EnumValueDeclarationsMacro() // Error
  @EnumValueDefinitionMacro() // Error
  @FieldTypesMacro() // Error
  @FieldDeclarationsMacro() // Error
  @FieldDefinitionMacro() // Error
  @MethodTypesMacro() // Ok
  @MethodDeclarationsMacro() // Ok
  @MethodDefinitionMacro() // Ok
  @ConstructorTypesMacro() // Error
  @ConstructorDeclarationsMacro() // Error
  @ConstructorDefinitionMacro() // Error
  @MixinTypesMacro() // Error
  @MixinDeclarationsMacro() // Error
  @MixinDefinitionMacro() // Error
  @ExtensionTypesMacro() // Error
  @ExtensionDeclarationsMacro() // Error
  @ExtensionDefinitionMacro() // Error
  @ExtensionTypeTypesMacro() // Error
  @ExtensionTypeDeclarationsMacro() // Error
  @ExtensionTypeDefinitionMacro() // Error
  @TypeAliasTypesMacro() // Error
  @TypeAliasDeclarationsMacro() // Error
  @FieldAndMethodTypesMacro() // Ok
  @VariableAndFunctionTypesMacro() // Ok
  void method() {}
}

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Ok
@FunctionDeclarationsMacro() // Ok
@FunctionDefinitionMacro() // Ok
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Ok
void function() {}

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Ok
@VariableDeclarationsMacro() // Ok
@VariableDefinitionMacro() // Ok
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Ok
int variable = 0;

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Ok
@EnumDeclarationsMacro() // Ok
@EnumDefinitionMacro() // Ok
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
enum Enum {
  @LibraryTypesMacro() // Error
  @LibraryDeclarationsMacro() // Error
  @LibraryDefinitionMacro() // Error
  @FunctionTypesMacro() // Error
  @FunctionDeclarationsMacro() // Error
  @FunctionDefinitionMacro() // Error
  @VariableTypesMacro() // Error
  @VariableDeclarationsMacro() // Error
  @VariableDefinitionMacro() // Error
  @ClassTypesMacro() // Error
  @ClassDeclarationsMacro() // Error
  @ClassDefinitionMacro() // Error
  @EnumTypesMacro() // Error
  @EnumDeclarationsMacro() // Error
  @EnumDefinitionMacro() // Error
  @EnumValueTypesMacro() // Ok
  @EnumValueDeclarationsMacro() // Ok
  @EnumValueDefinitionMacro() // Ok
  @FieldTypesMacro() // Error
  @FieldDeclarationsMacro() // Error
  @FieldDefinitionMacro() // Error
  @MethodTypesMacro() // Error
  @MethodDeclarationsMacro() // Error
  @MethodDefinitionMacro() // Error
  @ConstructorTypesMacro() // Error
  @ConstructorDeclarationsMacro() // Error
  @ConstructorDefinitionMacro() // Error
  @MixinTypesMacro() // Error
  @MixinDeclarationsMacro() // Error
  @MixinDefinitionMacro() // Error
  @ExtensionTypesMacro() // Error
  @ExtensionDeclarationsMacro() // Error
  @ExtensionDefinitionMacro() // Error
  @ExtensionTypeTypesMacro() // Error
  @ExtensionTypeDeclarationsMacro() // Error
  @ExtensionTypeDefinitionMacro() // Error
  @TypeAliasTypesMacro() // Error
  @TypeAliasDeclarationsMacro() // Error
  a,
}

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Ok
@MixinDeclarationsMacro() // Ok
@MixinDefinitionMacro() // Ok
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
mixin Mixin {}

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Ok
@ExtensionDeclarationsMacro() // Ok
@ExtensionDefinitionMacro() // Ok
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
extension Extension on int {}

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Ok
@ExtensionTypeDeclarationsMacro() // Ok
@ExtensionTypeDefinitionMacro() // Ok
@TypeAliasTypesMacro() // Error
@TypeAliasDeclarationsMacro() // Error
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
extension type ExtensionType(int it) {}

@LibraryTypesMacro() // Error
@LibraryDeclarationsMacro() // Error
@LibraryDefinitionMacro() // Error
@FunctionTypesMacro() // Error
@FunctionDeclarationsMacro() // Error
@FunctionDefinitionMacro() // Error
@VariableTypesMacro() // Error
@VariableDeclarationsMacro() // Error
@VariableDefinitionMacro() // Error
@ClassTypesMacro() // Error
@ClassDeclarationsMacro() // Error
@ClassDefinitionMacro() // Error
@EnumTypesMacro() // Error
@EnumDeclarationsMacro() // Error
@EnumDefinitionMacro() // Error
@EnumValueTypesMacro() // Error
@EnumValueDeclarationsMacro() // Error
@EnumValueDefinitionMacro() // Error
@FieldTypesMacro() // Error
@FieldDeclarationsMacro() // Error
@FieldDefinitionMacro() // Error
@MethodTypesMacro() // Error
@MethodDeclarationsMacro() // Error
@MethodDefinitionMacro() // Error
@ConstructorTypesMacro() // Error
@ConstructorDeclarationsMacro() // Error
@ConstructorDefinitionMacro() // Error
@MixinTypesMacro() // Error
@MixinDeclarationsMacro() // Error
@MixinDefinitionMacro() // Error
@ExtensionTypesMacro() // Error
@ExtensionDeclarationsMacro() // Error
@ExtensionDefinitionMacro() // Error
@ExtensionTypeTypesMacro() // Error
@ExtensionTypeDeclarationsMacro() // Error
@ExtensionTypeDefinitionMacro() // Error
@TypeAliasTypesMacro() // Ok
@TypeAliasDeclarationsMacro() // Ok
@FieldAndMethodTypesMacro() // Error
@VariableAndFunctionTypesMacro() // Error
typedef TypeAlias = int;
