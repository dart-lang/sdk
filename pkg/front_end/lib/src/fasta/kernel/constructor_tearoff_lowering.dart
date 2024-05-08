// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/constructor_tearoff_lowering.dart';
import 'package:kernel/type_algebra.dart';

import '../builder/library_builder.dart';
import '../source/name_scheme.dart';
import '../source/source_library_builder.dart';
import 'kernel_helper.dart';

// TODO(johnniwinther): move all lowering predicates to `package:kernel`.
export 'package:kernel/constructor_tearoff_lowering.dart';

/// Creates the [Procedure] for the lowering of a generative constructor of
/// the given [name] in [compilationUnit].
///
/// If constructor tear off lowering is not enabled, `null` is returned.
Procedure? createConstructorTearOffProcedure(
    MemberName tearOffName,
    SourceLibraryBuilder compilationUnit,
    Uri fileUri,
    int fileOffset,
    Reference? reference,
    {required bool forAbstractClassOrEnumOrMixin,
    bool forceCreateLowering = false}) {
  if (!forAbstractClassOrEnumOrMixin &&
      (forceCreateLowering ||
          compilationUnit.loader.target.backendTarget
              .isConstructorTearOffLoweringEnabled)) {
    return _createTearOffProcedure(
        compilationUnit, tearOffName, fileUri, fileOffset, reference);
  }
  return null;
}

/// Creates the [Procedure] for the lowering of a non-redirecting factory of
/// the given [name] in [compilationUnit].
///
/// If constructor tear off lowering is not enabled, `null` is returned.
Procedure? createFactoryTearOffProcedure(
    MemberName tearOffName,
    SourceLibraryBuilder compilationUnit,
    Uri fileUri,
    int fileOffset,
    Reference? reference,
    {bool forceCreateLowering = false}) {
  if (forceCreateLowering ||
      compilationUnit
          .loader.target.backendTarget.isFactoryTearOffLoweringEnabled) {
    return _createTearOffProcedure(
        compilationUnit, tearOffName, fileUri, fileOffset, reference);
  }
  return null;
}

/// Creates the [Procedure] for the lowering of a typedef tearoff of a
/// constructor of the given [name] in with the typedef defined in
/// [libraryBuilder].
Procedure createTypedefTearOffProcedure(
    String typedefName,
    String name,
    SourceLibraryBuilder libraryBuilder,
    Uri fileUri,
    int fileOffset,
    Reference? reference) {
  MemberName tearOffName = new MemberName(
      libraryBuilder.libraryName, typedefTearOffName(typedefName, name));
  return _createTearOffProcedure(
      libraryBuilder, tearOffName, fileUri, fileOffset, reference);
}

/// Creates the parameters and body for [tearOff] based on
/// [declarationConstructor].
/// [enclosingDeclarationTypeParameters].
///
/// The [declarationConstructor] is the origin constructor and
/// [implementationConstructor] is the augmentation constructor, if augmented,
/// otherwise it is the [declarationConstructor].
DelayedDefaultValueCloner buildConstructorTearOffProcedure(
    {required Procedure tearOff,
    required Member declarationConstructor,
    required Member implementationConstructor,
    List<TypeParameter>? enclosingDeclarationTypeParameters,
    required SourceLibraryBuilder libraryBuilder}) {
  assert(
      declarationConstructor is Constructor ||
          (declarationConstructor is Procedure &&
              declarationConstructor.isFactory) ||
          (declarationConstructor is Procedure &&
              declarationConstructor.isStatic),
      "Unexpected constructor tear off target $declarationConstructor "
      "(${declarationConstructor.runtimeType}).");
  assert(
      declarationConstructor is Constructor ||
          (declarationConstructor is Procedure &&
              declarationConstructor.isFactory) ||
          (declarationConstructor is Procedure &&
              declarationConstructor.isStatic),
      "Unexpected constructor tear off target $declarationConstructor "
      "(${declarationConstructor.runtimeType}).");

  FunctionNode function = implementationConstructor.function!;

  int fileOffset = tearOff.fileOffset;

  // Generative constructors implicitly have the type parameters of the
  // enclosing class.
  // Factory constructors explicitly copy over the type parameters of the
  // enclosing class.
  List<TypeParameter> declarationTypeParameters =
      enclosingDeclarationTypeParameters ?? function.typeParameters;

  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(declarationTypeParameters, tearOff.function);

  List<DartType> typeArguments = freshTypeParameters.freshTypeArguments;
  Substitution substitution = freshTypeParameters.substitution;
  DelayedDefaultValueCloner delayedDefaultValueCloner = _createParameters(
      tearOff,
      implementationConstructor,
      function,
      substitution,
      libraryBuilder);
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  _createTearOffBody(tearOff, declarationConstructor, arguments);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  return delayedDefaultValueCloner;
}

/// Creates the parameters and body for [tearOff] for a typedef tearoff of
/// [declarationConstructor] in [enclosingTypeDeclaration] with [typeParameters]
/// as the typedef parameters and [typeArguments] as the arguments passed to the
/// [enclosingTypeDeclaration].
///
/// The [declarationConstructor] is the origin constructor and
/// [implementationConstructor] is the augmentation constructor, if augmented,
/// otherwise it is the [declarationConstructor].
DelayedDefaultValueCloner buildTypedefTearOffProcedure(
    {required Procedure tearOff,
    required Member declarationConstructor,
    required Member implementationConstructor,
    required TypeDeclaration enclosingTypeDeclaration,
    required List<TypeParameter> typeParameters,
    required List<DartType> typeArguments,
    required SourceLibraryBuilder libraryBuilder}) {
  assert(
      declarationConstructor is Constructor ||
          (declarationConstructor is Procedure &&
              declarationConstructor.isFactory) ||
          (declarationConstructor is Procedure &&
              declarationConstructor.isStatic),
      "Unexpected constructor tear off target $declarationConstructor "
      "(${declarationConstructor.runtimeType}).");
  assert(
      implementationConstructor is Constructor ||
          (implementationConstructor is Procedure &&
              implementationConstructor.isFactory) ||
          (implementationConstructor is Procedure &&
              implementationConstructor.isStatic),
      "Unexpected constructor tear off target $implementationConstructor "
      "(${declarationConstructor.runtimeType}).");

  FunctionNode function = implementationConstructor.function!;

  int fileOffset = tearOff.fileOffset;

  List<TypeParameter> declarationTypeParameters;
  if (declarationConstructor is Constructor) {
    // Generative constructors implicitly have the type parameters of the
    // enclosing class.
    declarationTypeParameters = enclosingTypeDeclaration.typeParameters;
  } else {
    // Factory constructors explicitly copy over the type parameters of the
    // enclosing class.
    declarationTypeParameters = function.typeParameters;
  }

  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(typeParameters, tearOff.function);

  Substitution substitution = freshTypeParameters.substitution;
  if (!substitution.isEmpty) {
    if (typeArguments.isNotEmpty) {
      // Translate [typeArgument] into the context of the synthesized procedure.
      typeArguments = new List<DartType>.generate(typeArguments.length,
          (int index) => substitution.substituteType(typeArguments[index]));
    }
  }
  DelayedDefaultValueCloner delayedDefaultValueCloner = _createParameters(
      tearOff,
      implementationConstructor,
      function,
      Substitution.fromPairs(declarationTypeParameters, typeArguments),
      libraryBuilder);
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  _createTearOffBody(tearOff, declarationConstructor, arguments);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  return delayedDefaultValueCloner;
}

/// Creates the parameters for the redirecting factory [tearOff] based on the
/// [declarationConstructor] declaration.
///
/// The [declarationConstructor] is the [Procedure] for the origin constructor
/// and [implementationConstructorFunctionNode] is the [FunctionNode] for the
/// implementation constructor. If the constructor is augmented, these are not
/// connected until [Builder.buildBodyNodes].
FreshTypeParameters buildRedirectingFactoryTearOffProcedureParameters(
    {required Procedure tearOff,
    required Procedure implementationConstructor,
    required SourceLibraryBuilder libraryBuilder,
    List<DelayedDefaultValueCloner>? delayedDefaultValueCloners}) {
  FunctionNode function = implementationConstructor.function;
  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(function.typeParameters, tearOff.function);
  Substitution substitution = freshTypeParameters.substitution;
  DelayedDefaultValueCloner delayedDefaultValueCloner = _createParameters(
      tearOff,
      implementationConstructor,
      function,
      substitution,
      libraryBuilder);
  delayedDefaultValueCloners?.add(delayedDefaultValueCloner);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  return freshTypeParameters;
}

/// Creates the body for the redirecting factory [tearOff] with the [target]
/// constructor and [typeArguments].
///
/// Returns the [DelayedDefaultValueCloner] object need to perform default value
/// computation.
DelayedDefaultValueCloner buildRedirectingFactoryTearOffBody(
    Procedure tearOff,
    Member target,
    List<DartType> typeArguments,
    FreshTypeParameters freshTypeParameters,
    LibraryBuilder libraryBuilder) {
  int fileOffset = tearOff.fileOffset;

  List<TypeParameter> typeParameters;
  if (target is Constructor) {
    typeParameters = target.enclosingClass.typeParameters;
  } else {
    typeParameters = target.function!.typeParameters;
  }

  if (!freshTypeParameters.substitution.isEmpty) {
    if (typeArguments.length != typeParameters.length) {
      // Error case: Use default types as type arguments.
      typeArguments = new List<DartType>.generate(typeParameters.length,
          (int index) => typeParameters[index].defaultType);
    }
    if (typeArguments.isNotEmpty) {
      // Translate [typeArgument] into the context of the synthesized procedure.
      typeArguments = new List<DartType>.generate(
          typeArguments.length,
          (int index) => freshTypeParameters.substitution
              .substituteType(typeArguments[index]));
    }
  }
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  _createTearOffBody(tearOff, target, arguments);
  return new DelayedDefaultValueCloner(target, tearOff,
      identicalSignatures: false, libraryBuilder: libraryBuilder);
}

/// Creates the synthesized [Procedure] node for a tear off lowering by the
/// given [name].
Procedure _createTearOffProcedure(SourceLibraryBuilder libraryBuilder,
    MemberName tearOffName, Uri fileUri, int fileOffset, Reference? reference) {
  Procedure tearOff = new Procedure(
      dummyName, ProcedureKind.Method, new FunctionNode(null),
      fileUri: fileUri, isStatic: true, isSynthetic: true, reference: reference)
    ..fileStartOffset = fileOffset
    ..fileOffset = fileOffset
    ..fileEndOffset = fileOffset
    ..isNonNullableByDefault = libraryBuilder.isNonNullableByDefault;
  tearOffName.attachMember(tearOff);
  return tearOff;
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
/// in [constructor] and using the [substitution] to compute the parameter and
/// return types.
DelayedDefaultValueCloner _createParameters(
    Procedure tearOff,
    Member constructor,
    FunctionNode function,
    Substitution substitution,
    SourceLibraryBuilder libraryBuilder) {
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
  libraryBuilder.loader.registerTypeDependency(
      tearOff,
      new TypeDependency(tearOff, constructor, substitution,
          copyReturnType: true));
  return new DelayedDefaultValueCloner(constructor, tearOff,
      identicalSignatures: true, libraryBuilder: libraryBuilder);
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

/// Creates the tear of body for [tearOff] which calls [target] with
/// [arguments].
void _createTearOffBody(Procedure tearOff, Member target, Arguments arguments) {
  assert(target is Constructor ||
      (target is Procedure && target.isFactory) ||
      (target is Procedure && target.isStatic));
  Expression constructorInvocation;
  if (target is Constructor) {
    constructorInvocation = new ConstructorInvocation(target, arguments)
      ..fileOffset = tearOff.fileOffset;
  } else {
    constructorInvocation = new StaticInvocation(target as Procedure, arguments)
      ..fileOffset = tearOff.fileOffset;
  }
  tearOff.function.body = new ReturnStatement(constructorInvocation)
    ..fileOffset = tearOff.fileOffset
    ..parent = tearOff.function;
}

/// Reverse engineered typedef tear off information.
class LoweredTypedefTearOff {
  Procedure typedefTearOff;
  Expression targetTearOff;
  List<DartType> typeArguments;

  LoweredTypedefTearOff(
      this.typedefTearOff, this.targetTearOff, this.typeArguments);

  /// Reverse engineers [expression] to a [LoweredTypedefTearOff] if
  /// [expression] is the encoding of a lowered typedef tear off.
  static LoweredTypedefTearOff? fromExpression(Expression expression) {
    if (expression is StaticTearOff &&
        isTypedefTearOffLowering(expression.target)) {
      Procedure typedefTearOff = expression.target;
      Statement? body = typedefTearOff.function.body;
      if (body is ReturnStatement) {
        Expression? constructorInvocation = body.expression;
        Member? target;
        List<DartType>? typeArguments;
        if (constructorInvocation is ConstructorInvocation) {
          target = constructorInvocation.target;
          typeArguments = constructorInvocation.arguments.types;
        } else if (constructorInvocation is StaticInvocation) {
          target = constructorInvocation.target;
          typeArguments = constructorInvocation.arguments.types;
        }
        if (target != null) {
          Class cls = target.enclosingClass!;
          Name tearOffName = new Name(
              constructorTearOffName(target.name.text), cls.enclosingLibrary);
          for (Procedure procedure in cls.procedures) {
            if (procedure.name == tearOffName) {
              target = procedure;
              break;
            }
          }
          Expression targetTearOff;
          if (target is Constructor ||
              target is Procedure && target.isFactory) {
            targetTearOff = new ConstructorTearOff(target!);
          } else {
            targetTearOff = new StaticTearOff(target as Procedure);
          }
          return new LoweredTypedefTearOff(
              typedefTearOff, targetTearOff, typeArguments!);
        }
      }
    }
    return null;
  }
}
