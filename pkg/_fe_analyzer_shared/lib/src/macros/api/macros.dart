// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The marker interface for all types of macros.
abstract interface class Macro {}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and want to contribute new type
/// declarations to the program.
abstract interface class FunctionTypesMacro implements Macro {
  FutureOr<void> buildTypesForFunction(
      FunctionDeclaration function, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and want to contribute new non-type
/// declarations to the program.
abstract interface class FunctionDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level function,
/// instance method, or static method, and want to augment the function
/// definition.
abstract interface class FunctionDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable or
/// instance field, and want to contribute new type declarations to the
/// program.
abstract interface class VariableTypesMacro implements Macro {
  FutureOr<void> buildTypesForVariable(
      VariableDeclaration variable, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable or
/// instance field and want to contribute new non-type declarations to the
/// program.
abstract interface class VariableDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForVariable(
      VariableDeclaration variable, DeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any top level variable
/// or instance field, and want to augment the variable definition.
abstract interface class VariableDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForVariable(
      VariableDeclaration variable, VariableDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and want to
/// contribute new type declarations to the program.
abstract interface class ClassTypesMacro implements Macro {
  FutureOr<void> buildTypesForClass(
      ClassDeclaration clazz, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and want to
/// contribute new non-type declarations to the program.
abstract interface class ClassDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForClass(
      IntrospectableClassDeclaration clazz, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any class, and want to
/// augment the definitions of the members of that class.
abstract interface class ClassDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForClass(
      IntrospectableClassDeclaration clazz, TypeDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new type declarations to the program.
abstract interface class EnumTypesMacro implements Macro {
  FutureOr<void> buildTypesForEnum(EnumDeclaration enuum, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new non-type declarations to the program.
abstract interface class EnumDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForEnum(
      IntrospectableEnumDeclaration enuum, EnumDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// augment the definitions of members or values of that enum.
abstract interface class EnumDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForEnum(
      IntrospectableEnumDeclaration enuum, EnumDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new type declarations to the program.
abstract interface class EnumValueTypesMacro implements Macro {
  FutureOr<void> buildTypesForEnumValue(
      EnumValueDeclaration entry, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// contribute new non-type declarations to the program.
abstract interface class EnumValueDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForEnumValue(
      EnumValueDeclaration entry, EnumDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any enum, and want to
/// augment the definitions of members or values of that enum.
abstract interface class EnumValueDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForEnumValue(
      EnumValueDeclaration entry, EnumValueDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and want to
/// contribute new type declarations to the program.
abstract interface class FieldTypesMacro implements Macro {
  FutureOr<void> buildTypesForField(
      FieldDeclaration field, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and want to
/// contribute new type declarations to the program.
abstract interface class FieldDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForField(
      FieldDeclaration field, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any field, and want to
/// augment the field definition.
abstract interface class FieldDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForField(
      FieldDeclaration field, VariableDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and want to
/// contribute new type declarations to the program.
abstract interface class MethodTypesMacro implements Macro {
  FutureOr<void> buildTypesForMethod(
      MethodDeclaration method, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and want to
/// contribute new non-type declarations to the program.
abstract interface class MethodDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForMethod(
      MethodDeclaration method, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any method, and want to
/// augment the function definition.
abstract interface class MethodDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructor, and want
/// to contribute new type declarations to the program.
abstract interface class ConstructorTypesMacro implements Macro {
  FutureOr<void> buildTypesForConstructor(
      ConstructorDeclaration constructor, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructors, and
/// want to contribute new non-type declarations to the program.
abstract interface class ConstructorDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any constructor, and want
/// to augment the function definition.
abstract interface class ConstructorDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForConstructor(
      ConstructorDeclaration constructor, ConstructorDefinitionBuilder builder);
}

/// The interface for [Macro]s that can be applied to any mixin declaration, and
/// want to contribute new type declarations to the program.
abstract interface class MixinTypesMacro implements Macro {
  FutureOr<void> buildTypesForMixin(
      MixinDeclaration mixin, TypeBuilder builder);
}

/// The interface for [Macro]s that can be applied to any mixin declaration, and
/// want to contribute new non-type declarations to the program.
abstract interface class MixinDeclarationsMacro implements Macro {
  FutureOr<void> buildDeclarationsForMixin(
      IntrospectableMixinDeclaration mixin, MemberDeclarationBuilder builder);
}

/// The interface for [Macro]s that can be applied to any mixin declaration, and
/// want to augment the definitions of the members of that mixin.
abstract interface class MixinDefinitionMacro implements Macro {
  FutureOr<void> buildDefinitionForMixin(
      IntrospectableMixinDeclaration clazz, TypeDefinitionBuilder builder);
}
