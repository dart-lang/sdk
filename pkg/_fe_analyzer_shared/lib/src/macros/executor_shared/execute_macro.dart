// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/builder_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// Runs [macro] in the declaration phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDeclarationsMacro(
    Macro macro,
    Declaration declaration,
    ClassIntrospector classIntrospector,
    TypeResolver typeResolver) async {
  if (declaration is FunctionDeclaration) {
    if (macro is ConstructorDeclarationsMacro &&
        declaration is ConstructorDeclaration) {
      ClassMemberDeclarationBuilderImpl builder =
          new ClassMemberDeclarationBuilderImpl(
              declaration.definingClass, classIntrospector, typeResolver);
      await macro.buildDeclarationsForConstructor(declaration, builder);
      return builder.result;
    } else if (macro is MethodDeclarationsMacro &&
        declaration is MethodDeclaration) {
      ClassMemberDeclarationBuilderImpl builder =
          new ClassMemberDeclarationBuilderImpl(
              declaration.definingClass, classIntrospector, typeResolver);
      await macro.buildDeclarationsForMethod(declaration, builder);
      return builder.result;
    } else if (macro is FunctionDeclarationsMacro) {
      DeclarationBuilderImpl builder =
          new DeclarationBuilderImpl(classIntrospector, typeResolver);
      await macro.buildDeclarationsForFunction(declaration, builder);
      return builder.result;
    }
  } else if (declaration is VariableDeclaration) {
    if (macro is FieldDeclarationsMacro && declaration is FieldDeclaration) {
      ClassMemberDeclarationBuilderImpl builder =
          new ClassMemberDeclarationBuilderImpl(
              declaration.definingClass, classIntrospector, typeResolver);
      await macro.buildDeclarationsForField(declaration, builder);
      return builder.result;
    } else if (macro is VariableDeclarationsMacro) {
      DeclarationBuilderImpl builder =
          new DeclarationBuilderImpl(classIntrospector, typeResolver);
      await macro.buildDeclarationsForVariable(declaration, builder);
      return builder.result;
    }
  } else if (macro is ClassDeclarationsMacro &&
      declaration is ClassDeclaration) {
    ClassMemberDeclarationBuilderImpl builder =
        new ClassMemberDeclarationBuilderImpl(
            declaration.type, classIntrospector, typeResolver);
    await macro.buildDeclarationsForClass(declaration, builder);
    return builder.result;
  }
  throw new UnsupportedError('Unsupported macro type or invalid declaration:\n'
      'macro: $macro\ndeclaration: $declaration');
}

/// Runs [macro] in the definition phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDefinitionMacro(
    Macro macro,
    Declaration declaration,
    ClassIntrospector classIntrospector,
    TypeResolver typeResolver,
    TypeDeclarationResolver typeDeclarationResolver) async {
  if (declaration is FunctionDeclaration) {
    if (macro is ConstructorDefinitionMacro &&
        declaration is ConstructorDeclaration) {
      ConstructorDefinitionBuilderImpl builder =
          new ConstructorDefinitionBuilderImpl(declaration, classIntrospector,
              typeResolver, typeDeclarationResolver);
      await macro.buildDefinitionForConstructor(declaration, builder);
      return builder.result;
    } else if (macro is MethodDefinitionMacro &&
        declaration is MethodDeclaration) {
      MethodDefinitionBuilderImpl builder = new MethodDefinitionBuilderImpl(
          declaration,
          classIntrospector,
          typeResolver,
          typeDeclarationResolver);
      await macro.buildDefinitionForMethod(declaration, builder);
      return builder.result;
    } else if (macro is FunctionDefinitionMacro) {
      FunctionDefinitionBuilderImpl builder = new FunctionDefinitionBuilderImpl(
          declaration,
          classIntrospector,
          typeResolver,
          typeDeclarationResolver);
      await macro.buildDefinitionForFunction(declaration, builder);
      return builder.result;
    }
  } else if (declaration is VariableDeclaration) {
    if (macro is FieldDefinitionMacro && declaration is FieldDeclaration) {
      FieldDefinitionBuilderImpl builder = new FieldDefinitionBuilderImpl(
          declaration,
          classIntrospector,
          typeResolver,
          typeDeclarationResolver);
      await macro.buildDefinitionForField(declaration, builder);
      return builder.result;
    } else if (macro is VariableDefinitionMacro) {
      VariableDefinitionBuilderImpl builder = new VariableDefinitionBuilderImpl(
          declaration,
          classIntrospector,
          typeResolver,
          typeDeclarationResolver);
      await macro.buildDefinitionForVariable(declaration, builder);
      return builder.result;
    }
  } else if (macro is ClassDefinitionMacro && declaration is ClassDeclaration) {
    ClassDefinitionBuilderImpl builder = new ClassDefinitionBuilderImpl(
        declaration, classIntrospector, typeResolver, typeDeclarationResolver);
    await macro.buildDefinitionForClass(declaration, builder);
    return builder.result;
  }
  throw new UnsupportedError('Unsupported macro type or invalid declaration:\n'
      'macro: $macro\ndeclaration: $declaration');
}
