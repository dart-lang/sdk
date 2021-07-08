// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import '../builder/member_builder.dart';
import '../source/source_library_builder.dart';

/// Creates the synthesized name to use for the lowering of a generative
/// constructor by the given [constructorName] in [library].
Name constructorTearOffName(String constructorName, Library library) {
  return new Name(
      '_#${constructorName.isEmpty ? 'new' : constructorName}#tearOff',
      library);
}

/// Creates the [Procedure] for the lowering of a generative constructor of
/// the given [name] in [compilationUnit].
///
/// If constructor tear off lowering is not enabled, `null` is returned.
Procedure? createConstructorTearOffProcedure(
    String name, SourceLibraryBuilder compilationUnit, int fileOffset) {
  if (compilationUnit
      .loader.target.backendTarget.isConstructorTearOffLoweringEnabled) {
    return new Procedure(constructorTearOffName(name, compilationUnit.library),
        ProcedureKind.Method, new FunctionNode(null),
        fileUri: compilationUnit.fileUri, isStatic: true)
      ..startFileOffset = fileOffset
      ..fileOffset = fileOffset
      ..fileEndOffset = fileOffset
      ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault;
  }
  return null;
}

/// Creates the parameters and body for [tearOff] based on [constructor].
void buildConstructorTearOffProcedure(
    Procedure tearOff,
    Constructor constructor,
    Class enclosingClass,
    SourceLibraryBuilder libraryBuilder) {
  int fileOffset = tearOff.fileOffset;

  List<TypeParameter> classTypeParameters = enclosingClass.typeParameters;

  List<TypeParameter> typeParameters;
  List<DartType> typeArguments;
  Substitution substitution = Substitution.empty;
  if (classTypeParameters.isNotEmpty) {
    FreshTypeParameters freshTypeParameters =
        getFreshTypeParameters(classTypeParameters);
    typeParameters = freshTypeParameters.freshTypeParameters;
    typeArguments = freshTypeParameters.freshTypeArguments;
    substitution = freshTypeParameters.substitution;
    tearOff.function.typeParameters.addAll(typeParameters);
    setParents(typeParameters, tearOff.function);
  } else {
    typeParameters = [];
    typeArguments = [];
    substitution = Substitution.empty;
  }

  List<Expression> positionalArguments = [];
  for (VariableDeclaration constructorParameter
      in constructor.function.positionalParameters) {
    VariableDeclaration tearOffParameter = new VariableDeclaration(
        constructorParameter.name,
        type: substitution.substituteType(constructorParameter.type))
      ..fileOffset = constructorParameter.fileOffset;
    tearOff.function.positionalParameters.add(tearOffParameter);
    positionalArguments
        .add(new VariableGet(tearOffParameter)..fileOffset = fileOffset);
    tearOffParameter.parent = tearOff.function;
  }
  List<NamedExpression> namedArguments = [];
  for (VariableDeclaration constructorParameter
      in constructor.function.namedParameters) {
    VariableDeclaration tearOffParameter = new VariableDeclaration(
        constructorParameter.name,
        type: substitution.substituteType(constructorParameter.type),
        isRequired: constructorParameter.isRequired)
      ..fileOffset = constructorParameter.fileOffset;
    tearOff.function.namedParameters.add(tearOffParameter);
    tearOffParameter.parent = tearOff.function;
    namedArguments.add(new NamedExpression(tearOffParameter.name!,
        new VariableGet(tearOffParameter)..fileOffset = fileOffset)
      ..fileOffset = fileOffset);
  }
  tearOff.function.returnType =
      substitution.substituteType(constructor.function.returnType);
  tearOff.function.requiredParameterCount =
      constructor.function.requiredParameterCount;
  tearOff.function.body = new ReturnStatement(
      new ConstructorInvocation(
          constructor,
          new Arguments(positionalArguments,
              named: namedArguments, types: typeArguments)
            ..fileOffset = tearOff.fileOffset)
        ..fileOffset = tearOff.fileOffset)
    ..fileOffset = tearOff.fileOffset
    ..parent = tearOff.function;
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  updatePrivateMemberName(tearOff, libraryBuilder);
}

/// Copies the parameter types from [constructor] to [tearOff].
///
/// These might have been inferred and therefore not available when the
/// parameters were created.
// TODO(johnniwinther): Add tests for inferred parameter types.
// TODO(johnniwinther): Avoid doing this when parameter types are not inferred.
void buildConstructorTearOffOutline(
    Procedure tearOff, Constructor constructor, Class enclosingClass) {
  List<TypeParameter> classTypeParameters = enclosingClass.typeParameters;
  Substitution substitution = Substitution.empty;
  if (classTypeParameters.isNotEmpty) {
    List<DartType> typeArguments = [];
    for (TypeParameter typeParameter in tearOff.function.typeParameters) {
      typeArguments.add(new TypeParameterType(typeParameter,
          TypeParameterType.computeNullabilityFromBound(typeParameter)));
    }
    substitution = Substitution.fromPairs(classTypeParameters, typeArguments);
  }
  for (int i = 0; i < constructor.function.positionalParameters.length; i++) {
    VariableDeclaration tearOffParameter =
        tearOff.function.positionalParameters[i];
    VariableDeclaration constructorParameter =
        constructor.function.positionalParameters[i];
    tearOffParameter.type =
        substitution.substituteType(constructorParameter.type);
  }
  for (int i = 0; i < constructor.function.namedParameters.length; i++) {
    VariableDeclaration tearOffParameter = tearOff.function.namedParameters[i];
    VariableDeclaration constructorParameter =
        constructor.function.namedParameters[i];
    tearOffParameter.type =
        substitution.substituteType(constructorParameter.type);
  }
}

void buildConstructorTearOffDefaultValues(
    Procedure tearOff, Constructor constructor, Class enclosingClass) {
  CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
  for (int i = 0; i < constructor.function.positionalParameters.length; i++) {
    VariableDeclaration tearOffParameter =
        tearOff.function.positionalParameters[i];
    VariableDeclaration constructorParameter =
        constructor.function.positionalParameters[i];
    tearOffParameter.initializer =
        cloner.cloneOptional(constructorParameter.initializer);
    tearOffParameter.initializer?.parent = tearOffParameter;
  }
  for (int i = 0; i < constructor.function.namedParameters.length; i++) {
    VariableDeclaration tearOffParameter = tearOff.function.namedParameters[i];
    VariableDeclaration constructorParameter =
        constructor.function.namedParameters[i];
    tearOffParameter.initializer =
        cloner.cloneOptional(constructorParameter.initializer);
    tearOffParameter.initializer?.parent = tearOffParameter;
  }
}
