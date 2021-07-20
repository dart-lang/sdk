// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import '../builder/member_builder.dart';
import '../source/source_library_builder.dart';
import 'kernel_api.dart';
import 'kernel_target.dart';

const String _tearOffNamePrefix = '_#';
const String _tearOffNameSuffix = '#tearOff';

/// Creates the synthesized name to use for the lowering of the tear off of a
/// constructor or factory by the given [name] in [library].
Name constructorTearOffName(String name, Library library) {
  return new Name(
      '$_tearOffNamePrefix'
      '${name.isEmpty ? 'new' : name}'
      '$_tearOffNameSuffix',
      library);
}

/// Returns the name of the corresponding constructor or factory if [name] is
/// the synthesized name of a lowering of the tear off of a constructor or
/// factory. Returns `null` otherwise.
String? extractConstructorNameFromTearOff(Name name) {
  if (name.text.startsWith(_tearOffNamePrefix) &&
      name.text.endsWith(_tearOffNameSuffix) &&
      name.text.length >
          _tearOffNamePrefix.length + _tearOffNameSuffix.length) {
    String text =
        name.text.substring(0, name.text.length - _tearOffNameSuffix.length);
    text = text.substring(_tearOffNamePrefix.length);
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
    return _createTearOffProcedure(
        compilationUnit,
        constructorTearOffName(name, compilationUnit.library),
        fileUri,
        fileOffset);
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

  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(classTypeParameters, tearOff.function);

  List<DartType> typeArguments = freshTypeParameters.freshTypeArguments;
  Substitution substitution = freshTypeParameters.substitution;
  _createParameters(tearOff, function, substitution);
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);

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

void copyTearOffDefaultValues(Procedure tearOff, FunctionNode function) {
  CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
  for (int i = 0; i < function.positionalParameters.length; i++) {
    VariableDeclaration tearOffParameter =
        tearOff.function.positionalParameters[i];
    VariableDeclaration constructorParameter = function.positionalParameters[i];
    tearOffParameter.initializer =
        cloner.cloneOptional(constructorParameter.initializer);
    tearOffParameter.initializer?.parent = tearOffParameter;
  }
  for (int i = 0; i < function.namedParameters.length; i++) {
    VariableDeclaration tearOffParameter = tearOff.function.namedParameters[i];
    VariableDeclaration constructorParameter = function.namedParameters[i];
    tearOffParameter.initializer =
        cloner.cloneOptional(constructorParameter.initializer);
    tearOffParameter.initializer?.parent = tearOffParameter;
  }
}

/// Creates the parameters for the redirecting factory [tearOff] based on the
/// [redirectingConstructor] declaration.
FreshTypeParameters buildRedirectingFactoryTearOffProcedure(
    Procedure tearOff,
    Procedure redirectingConstructor,
    SourceLibraryBuilder libraryBuilder) {
  assert(redirectingConstructor.isRedirectingFactory);
  FunctionNode function = redirectingConstructor.function;
  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(function.typeParameters, tearOff.function);
  Substitution substitution = freshTypeParameters.substitution;
  _createParameters(tearOff, function, substitution);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  updatePrivateMemberName(tearOff, libraryBuilder);
  return freshTypeParameters;
}

/// Creates the body for the redirecting factory [tearOff] with the target
/// [constructor] and [typeArguments].
///
/// Returns the [ClonedFunctionNode] object need to perform default value
/// computation.
ClonedFunctionNode buildRedirectingFactoryTearOffBody(
    Procedure tearOff,
    Constructor constructor,
    List<DartType> typeArguments,
    FreshTypeParameters freshTypeParameters) {
  int fileOffset = tearOff.fileOffset;

  if (!freshTypeParameters.substitution.isEmpty) {
    if (typeArguments.isNotEmpty) {
      // Translate [typeArgument] into the context of the synthesized procedure.
      typeArguments = new List<DartType>.generate(
          typeArguments.length,
          (int index) => freshTypeParameters.substitution
              .substituteType(typeArguments[index]));
    }
  }

  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  Expression constructorInvocation =
      new ConstructorInvocation(constructor, arguments)
        ..fileOffset = tearOff.fileOffset;
  tearOff.function.body = new ReturnStatement(constructorInvocation)
    ..fileOffset = tearOff.fileOffset
    ..parent = tearOff.function;

  return new ClonedFunctionNode(
      new Map<TypeParameter, DartType>.fromIterables(
          constructor.enclosingClass.typeParameters, typeArguments),
      constructor.function,
      tearOff.function);
}

/// Creates the synthesized name to use for the lowering of the tear off of a
/// typedef in [library] using [index] for a unique name within the library.
Name typedefTearOffName(int index, Library library) {
  return new Name(
      '$_tearOffNamePrefix'
      '${index}'
      '$_tearOffNameSuffix',
      library);
}

/// Creates a top level procedure to be used as the lowering for the typedef
/// tear off [node] of a target of type [targetType]. [fileUri] together with
/// the `fileOffset` of [node] is used as the location for the procedure.
/// [index] is used to create a unique name for the procedure within
/// [libraryBuilder].
Procedure createTypedefTearOffLowering(SourceLibraryBuilder libraryBuilder,
    TypedefTearOff node, FunctionType targetType, Uri fileUri, int index) {
  int fileOffset = node.fileOffset;
  Procedure tearOff = _createTearOffProcedure(
      libraryBuilder,
      typedefTearOffName(index, libraryBuilder.library),
      fileUri,
      node.fileOffset);
  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(node.typeParameters, tearOff.function);
  Substitution substitution = freshTypeParameters.substitution;

  List<DartType> typeArguments = node.typeArguments;
  if (typeArguments.isNotEmpty) {
    if (!substitution.isEmpty) {
      // Translate [typeArgument] into the context of the synthesized procedure.
      typeArguments = new List<DartType>.generate(typeArguments.length,
          (int index) => substitution.substituteType(typeArguments[index]));
    }
    // Instantiate [targetType] with [typeArguments].
    targetType =
        Substitution.fromPairs(targetType.typeParameters, typeArguments)
            .substituteType(targetType.withoutTypeParameters) as FunctionType;
  }

  for (DartType constructorParameter in targetType.positionalParameters) {
    VariableDeclaration tearOffParameter = new VariableDeclaration(null,
        type: substitution.substituteType(constructorParameter))
      ..fileOffset = fileOffset;
    tearOff.function.positionalParameters.add(tearOffParameter);
    tearOffParameter.parent = tearOff.function;
  }
  for (NamedType constructorParameter in targetType.namedParameters) {
    VariableDeclaration tearOffParameter = new VariableDeclaration(
        constructorParameter.name,
        type: substitution.substituteType(constructorParameter.type),
        isRequired: constructorParameter.isRequired)
      ..fileOffset = fileOffset;
    tearOff.function.namedParameters.add(tearOffParameter);
    tearOffParameter.parent = tearOff.function;
  }
  tearOff.function.returnType =
      substitution.substituteType(targetType.returnType);
  tearOff.function.requiredParameterCount = targetType.requiredParameterCount;

  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  Expression constructorInvocation = new FunctionInvocation(
      FunctionAccessKind.FunctionType, node.expression, arguments,
      functionType: targetType)
    ..fileOffset = tearOff.fileOffset;
  tearOff.function.body = new ReturnStatement(constructorInvocation)
    ..fileOffset = tearOff.fileOffset
    ..parent = tearOff.function;
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  return tearOff;
}

/// Creates the synthesized [Procedure] node for a tear off lowering by the
/// given [name].
Procedure _createTearOffProcedure(SourceLibraryBuilder libraryBuilder,
    Name name, Uri fileUri, int fileOffset) {
  return new Procedure(name, ProcedureKind.Method, new FunctionNode(null),
      fileUri: fileUri, isStatic: true)
    ..startFileOffset = fileOffset
    ..fileOffset = fileOffset
    ..fileEndOffset = fileOffset
    ..isNonNullableByDefault = libraryBuilder.isNonNullableByDefault;
}

/// Creates the synthesized type parameters for a tear off lowering. The type
/// parameters are based [originalTypeParameters] and are inserted into
/// [newFunctionNode]. The created [FreshTypeParameters] is returned.
FreshTypeParameters _createFreshTypeParameters(
    List<TypeParameter> originalTypeParameters, FunctionNode newFunctionNode) {
  FreshTypeParameters freshTypeParameters;
  if (originalTypeParameters.isNotEmpty) {
    freshTypeParameters = getFreshTypeParameters(originalTypeParameters);
    List<TypeParameter> typeParameters =
        freshTypeParameters.freshTypeParameters;
    newFunctionNode.typeParameters.addAll(typeParameters);
    setParents(typeParameters, newFunctionNode);
  } else {
    freshTypeParameters = new FreshTypeParameters([], [], Substitution.empty);
  }
  return freshTypeParameters;
}

/// Creates the parameters for the [tearOff] lowering based of the parameters
/// in [function] and using the [substitution] to compute the parameter and
/// return types.
void _createParameters(
    Procedure tearOff, FunctionNode function, Substitution substitution) {
  for (VariableDeclaration constructorParameter
      in function.positionalParameters) {
    VariableDeclaration tearOffParameter = new VariableDeclaration(
        constructorParameter.name,
        type: substitution.substituteType(constructorParameter.type))
      ..fileOffset = constructorParameter.fileOffset;
    tearOff.function.positionalParameters.add(tearOffParameter);
    tearOffParameter.parent = tearOff.function;
  }
  for (VariableDeclaration constructorParameter in function.namedParameters) {
    VariableDeclaration tearOffParameter = new VariableDeclaration(
        constructorParameter.name,
        type: substitution.substituteType(constructorParameter.type),
        isRequired: constructorParameter.isRequired)
      ..fileOffset = constructorParameter.fileOffset;
    tearOff.function.namedParameters.add(tearOffParameter);
    tearOffParameter.parent = tearOff.function;
  }
  tearOff.function.returnType =
      substitution.substituteType(function.returnType);
  tearOff.function.requiredParameterCount = function.requiredParameterCount;
}

/// Creates the [Arguments] for passing the parameters from [tearOff] to its
/// target, using [typeArguments] as the passed type arguments.
Arguments _createArguments(
    Procedure tearOff, List<DartType> typeArguments, int fileOffset) {
  List<Expression> positionalArguments = [];
  for (VariableDeclaration tearOffParameter
      in tearOff.function.positionalParameters) {
    positionalArguments
        .add(new VariableGet(tearOffParameter)..fileOffset = fileOffset);
  }
  List<NamedExpression> namedArguments = [];
  for (VariableDeclaration tearOffParameter
      in tearOff.function.namedParameters) {
    namedArguments.add(new NamedExpression(tearOffParameter.name!,
        new VariableGet(tearOffParameter)..fileOffset = fileOffset)
      ..fileOffset = fileOffset);
  }
  Arguments arguments = new Arguments(positionalArguments,
      named: namedArguments, types: typeArguments)
    ..fileOffset = tearOff.fileOffset;
  return arguments;
}
