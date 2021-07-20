// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import '../builder/member_builder.dart';
import '../source/source_library_builder.dart';

const String _constructorTearOffNamePrefix = '_#';
const String _constructorTearOffNameSuffix = '#tearOff';

/// Creates the synthesized name to use for the lowering of the tear off of a
/// constructor or factory by the given [name] in [library].
Name constructorTearOffName(String name, Library library) {
  return new Name(
      '$_constructorTearOffNamePrefix'
      '${name.isEmpty ? 'new' : name}'
      '$_constructorTearOffNameSuffix',
      library);
}

/// Returns the name of the corresponding constructor or factory if [name] is
/// the synthesized name of a lowering of the tear off of a constructor or
/// factory. Returns `null` otherwise.
String? extractConstructorNameFromTearOff(Name name) {
  if (name.text.startsWith(_constructorTearOffNamePrefix) &&
      name.text.endsWith(_constructorTearOffNameSuffix) &&
      name.text.length >
          _constructorTearOffNamePrefix.length +
              _constructorTearOffNameSuffix.length) {
    String text = name.text
        .substring(0, name.text.length - _constructorTearOffNameSuffix.length);
    text = text.substring(_constructorTearOffNamePrefix.length);
    return text == 'new' ? '' : text;
  }
  return null;
}

/// Creates the [Procedure] for the lowering of a generative constructor of
/// the given [name] in [compilationUnit].
///
/// If constructor tear off lowering is not enabled, `null` is returned.
Procedure? createConstructorTearOffProcedure(String name,
    SourceLibraryBuilder compilationUnit, Uri fileUri, int fileOffset,
    {required bool forAbstractClassOrEnum}) {
  if (!forAbstractClassOrEnum &&
      compilationUnit
          .loader.target.backendTarget.isConstructorTearOffLoweringEnabled) {
    return new Procedure(constructorTearOffName(name, compilationUnit.library),
        ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri, isStatic: true)
      ..startFileOffset = fileOffset
      ..fileOffset = fileOffset
      ..fileEndOffset = fileOffset
      ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault;
  }
  return null;
}

/// Creates the parameters and body for [tearOff] based on [constructor].
void buildConstructorTearOffProcedure(Procedure tearOff, Member constructor,
    Class enclosingClass, SourceLibraryBuilder libraryBuilder) {
  assert(constructor is Constructor ||
      (constructor is Procedure && constructor.kind == ProcedureKind.Factory));

  int fileOffset = tearOff.fileOffset;

  FunctionNode function = constructor.function!;
  List<TypeParameter> classTypeParameters;
  if (constructor is Constructor) {
    // Generative constructors implicitly have the type parameters of the
    // enclosing class.
    classTypeParameters = enclosingClass.typeParameters;
  } else {
    // Factory constructors explicitly copy over the type parameters of the
    // enclosing class.
    classTypeParameters = function.typeParameters;
  }

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
      in function.positionalParameters) {
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
  for (VariableDeclaration constructorParameter in function.namedParameters) {
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
      substitution.substituteType(function.returnType);
  tearOff.function.requiredParameterCount = function.requiredParameterCount;

  Arguments arguments = new Arguments(positionalArguments,
      named: namedArguments, types: typeArguments)
    ..fileOffset = tearOff.fileOffset;
  Expression constructorInvocation;
  if (constructor is Constructor) {
    constructorInvocation = new ConstructorInvocation(constructor, arguments)
      ..fileOffset = tearOff.fileOffset;
  } else {
    constructorInvocation =
        new StaticInvocation(constructor as Procedure, arguments)
          ..fileOffset = tearOff.fileOffset;
  }
  tearOff.function.body = new ReturnStatement(constructorInvocation)
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
