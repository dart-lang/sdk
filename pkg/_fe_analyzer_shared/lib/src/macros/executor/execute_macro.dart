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
  // Must be assigned, used for error reporting.
  late final TypeBuilderBase builder;

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    // Shared code for most branches. If we do create it, assign it to
    // `builder`.
    late final TypeBuilderImpl typeBuilder =
        builder = new TypeBuilderImpl(introspector);
    switch ((target, macro)) {
      case (Library target, LibraryTypesMacro macro):
        await macro.buildTypesForLibrary(target, typeBuilder);
      case (ConstructorDeclaration target, ConstructorTypesMacro macro):
        await macro.buildTypesForConstructor(target, typeBuilder);
      case (MethodDeclaration target, MethodTypesMacro macro):
        await macro.buildTypesForMethod(target, typeBuilder);
      case (FunctionDeclaration target, FunctionTypesMacro macro):
        await macro.buildTypesForFunction(target, typeBuilder);
      case (FieldDeclaration target, FieldTypesMacro macro):
        await macro.buildTypesForField(target, typeBuilder);
      case (VariableDeclaration target, VariableTypesMacro macro):
        await macro.buildTypesForVariable(target, typeBuilder);
      case (ClassDeclaration target, ClassTypesMacro macro):
        await macro.buildTypesForClass(
            target,
            builder = new ClassTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (EnumDeclaration target, EnumTypesMacro macro):
        await macro.buildTypesForEnum(
            target,
            builder = new EnumTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (ExtensionDeclaration target, ExtensionTypesMacro macro):
        await macro.buildTypesForExtension(target, typeBuilder);
      case (MixinDeclaration target, MixinTypesMacro macro):
        await macro.buildTypesForMixin(
            target,
            builder = new MixinTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (EnumValueDeclaration target, EnumValueTypesMacro macro):
        await macro.buildTypesForEnumValue(target, typeBuilder);
      default:
        throw new UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    builder.report(new Diagnostic(
        new DiagnosticMessage('Unhandled error: $e\n' 'Stack trace:\n$s'),
        Severity.error));
  }
  return builder.result;
}

/// Runs [macro] in the declaration phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDeclarationsMacro(Macro macro,
    Object target, DeclarationPhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting.
  late final DeclarationBuilderBase builder;

  // At most one of these will be used below.
  late MemberDeclarationBuilderImpl memberBuilder =
      builder = new MemberDeclarationBuilderImpl(
          switch (target) {
            MemberDeclaration() => target.definingType as IdentifierImpl,
            TypeDeclarationImpl() => target.identifier,
            _ => throw new StateError(
                'Can only create member declaration builders for types or '
                'member declarations, but got $target'),
          },
          introspector);
  late DeclarationBuilderImpl topLevelBuilder =
      builder = new DeclarationBuilderImpl(introspector);
  late EnumDeclarationBuilderImpl enumBuilder =
      builder = new EnumDeclarationBuilderImpl(
          switch (target) {
            EnumDeclarationImpl() => target.identifier,
            EnumValueDeclarationImpl() => target.definingEnum,
            _ => throw new StateError(
                'Can only create enum declaration builders for enum or enum '
                'value declarations, but got $target'),
          },
          introspector);

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    switch ((target, macro)) {
      case (Library target, LibraryDeclarationsMacro macro):
        await macro.buildDeclarationsForLibrary(target, topLevelBuilder);
      case (ClassDeclaration target, ClassDeclarationsMacro macro):
        if (target is! IntrospectableClassDeclarationImpl) {
          throw new ArgumentError(
              'Class declarations annotated with a macro should be '
              'introspectable in the declarations phase.');
        }
        await macro.buildDeclarationsForClass(target, memberBuilder);
      case (EnumDeclaration target, EnumDeclarationsMacro macro):
        if (target is! IntrospectableEnumDeclarationImpl) {
          throw new ArgumentError(
              'Enum declarations annotated with a macro should be '
              'introspectable in the declarations phase.');
        }

        await macro.buildDeclarationsForEnum(target, enumBuilder);
      case (ExtensionDeclaration target, ExtensionDeclarationsMacro macro):
        if (target is! IntrospectableExtensionDeclarationImpl) {
          throw new ArgumentError(
              'Extension declarations annotated with a macro should be '
              'introspectable in the declarations phase.');
        }
        await macro.buildDeclarationsForExtension(target, memberBuilder);
      case (MixinDeclaration target, MixinDeclarationsMacro macro):
        if (target is! IntrospectableMixinDeclarationImpl) {
          throw new ArgumentError(
              'Mixin declarations annotated with a macro should be '
              'introspectable in the declarations phase.');
        }
        await macro.buildDeclarationsForMixin(target, memberBuilder);
      case (EnumValueDeclaration target, EnumValueDeclarationsMacro macro):
        await macro.buildDeclarationsForEnumValue(target, enumBuilder);
      case (ConstructorDeclaration target, ConstructorDeclarationsMacro macro):
        await macro.buildDeclarationsForConstructor(target, memberBuilder);
      case (MethodDeclaration target, MethodDeclarationsMacro macro):
        await macro.buildDeclarationsForMethod(target, memberBuilder);
      case (FieldDeclaration target, FieldDeclarationsMacro macro):
        await macro.buildDeclarationsForField(target, memberBuilder);
      case (FunctionDeclaration target, FunctionDeclarationsMacro macro):
        await macro.buildDeclarationsForFunction(target, topLevelBuilder);
      case (VariableDeclaration target, VariableDeclarationsMacro macro):
        await macro.buildDeclarationsForVariable(target, topLevelBuilder);
      default:
        throw new UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    builder.report(new Diagnostic(
        new DiagnosticMessage('Unhandled error: $e\n' 'Stack trace:\n$s'),
        Severity.error));
  }
  return builder.result;
}

/// Runs [macro] in the definition phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDefinitionMacro(Macro macro, Object target,
    DefinitionPhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting and returning a value.
  late final DefinitionBuilderBase builder;

  // At most one of these will be used below.
  late FunctionDefinitionBuilderImpl functionBuilder = builder =
      new FunctionDefinitionBuilderImpl(
          target as FunctionDeclarationImpl, introspector);
  late VariableDefinitionBuilderImpl variableBuilder = builder =
      new VariableDefinitionBuilderImpl(
          target as VariableDeclaration, introspector);
  late TypeDefinitionBuilderImpl typeBuilder = builder =
      new TypeDefinitionBuilderImpl(target as IntrospectableType, introspector);

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    switch ((target, macro)) {
      case (Library target, LibraryDefinitionMacro macro):
        LibraryDefinitionBuilderImpl libraryBuilder =
            builder = new LibraryDefinitionBuilderImpl(target, introspector);
        await macro.buildDefinitionForLibrary(target, libraryBuilder);
      case (ClassDeclaration target, ClassDefinitionMacro macro):
        if (target is! IntrospectableClassDeclaration) {
          throw new ArgumentError(
              'Class declarations annotated with a macro should be '
              'introspectable in the definitions phase.');
        }
        await macro.buildDefinitionForClass(target, typeBuilder);
      case (EnumDeclaration target, EnumDefinitionMacro macro):
        if (target is! IntrospectableEnumDeclaration) {
          throw new ArgumentError(
              'Enum declarations annotated with a macro should be '
              'introspectable in the definitions phase.');
        }
        EnumDefinitionBuilderImpl enumBuilder =
            builder = new EnumDefinitionBuilderImpl(target, introspector);
        await macro.buildDefinitionForEnum(target, enumBuilder);
      case (ExtensionDeclaration target, ExtensionDefinitionMacro macro):
        if (target is! IntrospectableExtensionDeclaration) {
          throw new ArgumentError(
              'Extension declarations annotated with a macro should be '
              'introspectable in the definitions phase.');
        }
        await macro.buildDefinitionForExtension(target, typeBuilder);
      case (MixinDeclaration target, MixinDefinitionMacro macro):
        if (target is! IntrospectableMixinDeclaration) {
          throw new ArgumentError(
              'Mixin declarations annotated with a macro should be '
              'introspectable in the definitions phase.');
        }
        await macro.buildDefinitionForMixin(target, typeBuilder);
      case (EnumValueDeclaration target, EnumValueDefinitionMacro macro):
        EnumValueDefinitionBuilderImpl enumValueBuilder = builder =
            new EnumValueDefinitionBuilderImpl(
                target as EnumValueDeclarationImpl, introspector);
        await macro.buildDefinitionForEnumValue(target, enumValueBuilder);
      case (ConstructorDeclaration target, ConstructorDefinitionMacro macro):
        ConstructorDefinitionBuilderImpl constructorBuilder = builder =
            new ConstructorDefinitionBuilderImpl(
                target as ConstructorDeclarationImpl, introspector);
        await macro.buildDefinitionForConstructor(target, constructorBuilder);
      case (MethodDeclaration target, MethodDefinitionMacro macro):
        await macro.buildDefinitionForMethod(
            target as MethodDeclarationImpl, functionBuilder);
      case (FieldDeclaration target, FieldDefinitionMacro macro):
        await macro.buildDefinitionForField(target, variableBuilder);
      case (FunctionDeclaration target, FunctionDefinitionMacro macro):
        await macro.buildDefinitionForFunction(target, functionBuilder);
      case (VariableDeclaration target, VariableDefinitionMacro macro):
        await macro.buildDefinitionForVariable(target, variableBuilder);
      default:
        throw new UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    builder.report(new Diagnostic(
        new DiagnosticMessage('Unhandled error: $e\n' 'Stack trace:\n$s'),
        Severity.error));
  }
  return builder.result;
}
