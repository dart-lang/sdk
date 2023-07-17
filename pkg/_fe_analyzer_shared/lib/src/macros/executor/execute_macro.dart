// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/builder_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// Runs [macro] in the types phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeTypesMacro(
    Macro macro, Object target, TypePhaseIntrospector introspector) async {
  TypeBuilderImpl builder = new TypeBuilderImpl(introspector);
  switch ((target, macro)) {
    case (Library target, LibraryTypesMacro macro):
      await macro.buildTypesForLibrary(target, builder);
    case (ConstructorDeclaration target, ConstructorTypesMacro macro):
      await macro.buildTypesForConstructor(target, builder);
    case (MethodDeclaration target, MethodTypesMacro macro):
      await macro.buildTypesForMethod(target, builder);
    case (FunctionDeclaration target, FunctionTypesMacro macro):
      await macro.buildTypesForFunction(target, builder);
    case (FieldDeclaration target, FieldTypesMacro macro):
      await macro.buildTypesForField(target, builder);
    case (VariableDeclaration target, VariableTypesMacro macro):
      await macro.buildTypesForVariable(target, builder);
    case (ClassDeclaration target, ClassTypesMacro macro):
      await macro.buildTypesForClass(target, builder);
    case (EnumDeclaration target, EnumTypesMacro macro):
      await macro.buildTypesForEnum(target, builder);
    case (MixinDeclaration target, MixinTypesMacro macro):
      await macro.buildTypesForMixin(target, builder);
    case (EnumValueDeclaration target, EnumValueTypesMacro macro):
      await macro.buildTypesForEnumValue(target, builder);
    default:
      throw new UnsupportedError('Unsupported macro type or invalid target:\n'
          'macro: $macro\ntarget: $target');
  }
  return builder.result;
}

/// Runs [macro] in the declaration phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDeclarationsMacro(Macro macro,
    Object target, DeclarationPhaseIntrospector introspector) async {
  // At most one of these will be used below.
  late MemberDeclarationBuilderImpl memberBuilder =
      new MemberDeclarationBuilderImpl(
          switch (target) {
            MemberDeclaration() => target.definingType as IdentifierImpl,
            TypeDeclarationImpl() => target.identifier,
            _ => throw new StateError(
                'Can only create member declaration builders for types or '
                'member declarations, but got $target'),
          },
          introspector);
  late DeclarationBuilderImpl topLevelBuilder =
      new DeclarationBuilderImpl(introspector);
  late EnumDeclarationBuilderImpl enumBuilder = new EnumDeclarationBuilderImpl(
      switch (target) {
        EnumDeclarationImpl() => target.identifier,
        EnumValueDeclarationImpl() => target.definingEnum,
        _ => throw new StateError(
            'Can only create enum declaration builders for enum or enum '
            'value declarations, but got $target'),
      },
      introspector);

  switch ((target, macro)) {
    case (Library target, LibraryDeclarationsMacro macro):
      await macro.buildDeclarationsForLibrary(target, topLevelBuilder);
      return topLevelBuilder.result;
    case (ClassDeclaration target, ClassDeclarationsMacro macro):
      if (target is! IntrospectableClassDeclarationImpl) {
        throw new ArgumentError(
            'Class declarations annotated with a macro should be '
            'introspectable in the declarations phase.');
      }
      await macro.buildDeclarationsForClass(target, memberBuilder);
      return memberBuilder.result;
    case (EnumDeclaration target, EnumDeclarationsMacro macro):
      if (target is! IntrospectableEnumDeclarationImpl) {
        throw new ArgumentError(
            'Enum declarations annotated with a macro should be introspectable '
            'in the declarations phase.');
      }

      await macro.buildDeclarationsForEnum(target, enumBuilder);
      return enumBuilder.result;
    case (MixinDeclaration target, MixinDeclarationsMacro macro):
      if (target is! IntrospectableMixinDeclarationImpl) {
        throw new ArgumentError(
            'Mixin declarations annotated with a macro should be '
            'introspectable in the declarations phase.');
      }
      await macro.buildDeclarationsForMixin(target, memberBuilder);
      return memberBuilder.result;
    case (EnumValueDeclaration target, EnumValueDeclarationsMacro macro):
      await macro.buildDeclarationsForEnumValue(target, enumBuilder);
      return enumBuilder.result;
    case (ConstructorDeclaration target, ConstructorDeclarationsMacro macro):
      await macro.buildDeclarationsForConstructor(target, memberBuilder);
      return memberBuilder.result;
    case (MethodDeclaration target, MethodDeclarationsMacro macro):
      await macro.buildDeclarationsForMethod(target, memberBuilder);
      return memberBuilder.result;
    case (FieldDeclaration target, FieldDeclarationsMacro macro):
      await macro.buildDeclarationsForField(target, memberBuilder);
      return memberBuilder.result;
    case (FunctionDeclaration target, FunctionDeclarationsMacro macro):
      await macro.buildDeclarationsForFunction(target, topLevelBuilder);
      return topLevelBuilder.result;
    case (VariableDeclaration target, VariableDeclarationsMacro macro):
      await macro.buildDeclarationsForVariable(target, topLevelBuilder);
      return topLevelBuilder.result;
    default:
      throw new UnsupportedError('Unsupported macro type or invalid target:\n'
          'macro: $macro\ntarget: $target');
  }
}

/// Runs [macro] in the definition phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDefinitionMacro(Macro macro, Object target,
    DefinitionPhaseIntrospector introspector) async {
  // At most one of these will be used below.
  late FunctionDefinitionBuilderImpl functionBuilder =
      new FunctionDefinitionBuilderImpl(
          target as FunctionDeclarationImpl, introspector);
  late VariableDefinitionBuilderImpl variableBuilder =
      new VariableDefinitionBuilderImpl(
          target as VariableDeclaration, introspector);
  late TypeDefinitionBuilderImpl typeBuilder =
      new TypeDefinitionBuilderImpl(target as IntrospectableType, introspector);

  switch ((target, macro)) {
    case (Library target, LibraryDefinitionMacro macro):
      LibraryDefinitionBuilderImpl builder =
          new LibraryDefinitionBuilderImpl(target, introspector);
      await macro.buildDefinitionForLibrary(target, builder);
      return builder.result;
    case (ClassDeclaration target, ClassDefinitionMacro macro):
      if (target is! IntrospectableClassDeclaration) {
        throw new ArgumentError(
            'Class declarations annotated with a macro should be '
            'introspectable in the definitions phase.');
      }
      await macro.buildDefinitionForClass(target, typeBuilder);
      return typeBuilder.result;
    case (EnumDeclaration target, EnumDefinitionMacro macro):
      if (target is! IntrospectableEnumDeclaration) {
        throw new ArgumentError(
            'Enum declarations annotated with a macro should be introspectable '
            'in the definitions phase.');
      }
      EnumDefinitionBuilderImpl builder =
          new EnumDefinitionBuilderImpl(target, introspector);
      await macro.buildDefinitionForEnum(target, builder);
      return builder.result;
    case (MixinDeclaration target, MixinDefinitionMacro macro):
      if (target is! IntrospectableMixinDeclaration) {
        throw new ArgumentError(
            'Mixin declarations annotated with a macro should be '
            'introspectable in the definitions phase.');
      }
      await macro.buildDefinitionForMixin(target, typeBuilder);
      return typeBuilder.result;
    case (EnumValueDeclaration target, EnumValueDefinitionMacro macro):
      EnumValueDefinitionBuilderImpl builder =
          new EnumValueDefinitionBuilderImpl(
              target as EnumValueDeclarationImpl, introspector);
      await macro.buildDefinitionForEnumValue(target, builder);
      return builder.result;
    case (ConstructorDeclaration target, ConstructorDefinitionMacro macro):
      ConstructorDefinitionBuilderImpl builder =
          new ConstructorDefinitionBuilderImpl(
              target as ConstructorDeclarationImpl, introspector);
      await macro.buildDefinitionForConstructor(target, builder);
      return builder.result;
    case (MethodDeclaration target, MethodDefinitionMacro macro):
      await macro.buildDefinitionForMethod(
          target as MethodDeclarationImpl, functionBuilder);
      return functionBuilder.result;
    case (FieldDeclaration target, FieldDefinitionMacro macro):
      await macro.buildDefinitionForField(target, variableBuilder);
      return variableBuilder.result;
    case (FunctionDeclaration target, FunctionDefinitionMacro macro):
      await macro.buildDefinitionForFunction(target, functionBuilder);
      return functionBuilder.result;
    case (VariableDeclaration target, VariableDefinitionMacro macro):
      await macro.buildDefinitionForVariable(target, variableBuilder);
      return variableBuilder.result;
    default:
      throw new UnsupportedError('Unsupported macro type or invalid target:\n'
          'macro: $macro\ntarget: $target');
  }
}
