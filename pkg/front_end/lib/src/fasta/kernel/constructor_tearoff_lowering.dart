// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import 'kernel_helper.dart';

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

/// Creates the synthesized name to use for the lowering of the tear off of a
/// constructor or factory by the given [constructorName] in [library].
Name typedefTearOffName(
    String typedefName, String constructorName, Library library) {
  return new Name(
      '$_tearOffNamePrefix'
      '$typedefName#'
      '${constructorName.isEmpty ? 'new' : constructorName}'
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
    if (text.contains('#')) {
      return null;
    }
    return text == 'new' ? '' : text;
  }
  return null;
}

/// If [name] is the synthesized name of a lowering of a typedef tear off, a
/// list containing the [String] name of the typedef and the [Name] name of the
/// corresponding constructor or factory is returned. Returns `null` otherwise.
List<Object>? extractTypedefNameFromTearOff(Name name) {
  if (name.text.startsWith(_tearOffNamePrefix) &&
      name.text.endsWith(_tearOffNameSuffix) &&
      name.text.length >
          _tearOffNamePrefix.length + _tearOffNameSuffix.length) {
    String text =
        name.text.substring(0, name.text.length - _tearOffNameSuffix.length);
    text = text.substring(_tearOffNamePrefix.length);
    int hashIndex = text.indexOf('#');
    if (hashIndex == -1) {
      return null;
    }
    String typedefName = text.substring(0, hashIndex);
    String constructorName = text.substring(hashIndex + 1);
    constructorName = constructorName == 'new' ? '' : constructorName;
    return [typedefName, new Name(constructorName, name.library)];
  }
  return null;
}

/// Returns `true` if [member] is a lowered constructor, factory or typedef tear
/// off.
bool isTearOffLowering(Member member) {
  return member is Procedure &&
      (isConstructorTearOffLowering(member) ||
          isTypedefTearOffLowering(member));
}

/// Returns `true` if [procedure] is a lowered constructor or factory tear off.
bool isConstructorTearOffLowering(Procedure procedure) {
  return extractConstructorNameFromTearOff(procedure.name) != null;
}

/// Returns `true` if [procedure] is a lowered typedef tear off.
bool isTypedefTearOffLowering(Procedure procedure) {
  return extractTypedefNameFromTearOff(procedure.name) != null;
}

/// Creates the [Procedure] for the lowering of a generative constructor of
/// the given [name] in [compilationUnit].
///
/// If constructor tear off lowering is not enabled, `null` is returned.
Procedure? createConstructorTearOffProcedure(
    String name,
    SourceLibraryBuilder compilationUnit,
    Uri fileUri,
    int fileOffset,
    Reference? reference,
    {required bool forAbstractClassOrEnum}) {
  if (!forAbstractClassOrEnum &&
      compilationUnit
          .loader.target.backendTarget.isConstructorTearOffLoweringEnabled) {
    return _createTearOffProcedure(
        compilationUnit,
        constructorTearOffName(name, compilationUnit.library),
        fileUri,
        fileOffset,
        reference);
  }
  return null;
}

/// Creates the [Procedure] for the lowering of a non-redirecting factory of
/// the given [name] in [compilationUnit].
///
/// If constructor tear off lowering is not enabled, `null` is returned.
Procedure? createFactoryTearOffProcedure(
    String name,
    SourceLibraryBuilder compilationUnit,
    Uri fileUri,
    int fileOffset,
    Reference? reference) {
  if (compilationUnit
      .loader.target.backendTarget.isFactoryTearOffLoweringEnabled) {
    return _createTearOffProcedure(
        compilationUnit,
        constructorTearOffName(name, compilationUnit.library),
        fileUri,
        fileOffset,
        reference);
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
  return _createTearOffProcedure(
      libraryBuilder,
      typedefTearOffName(typedefName, name, libraryBuilder.library),
      fileUri,
      fileOffset,
      reference);
}

/// Creates the parameters and body for [tearOff] based on [constructor] in
/// [enclosingClass].
void buildConstructorTearOffProcedure(Procedure tearOff, Member constructor,
    Class enclosingClass, SourceLibraryBuilder libraryBuilder) {
  assert(
      constructor is Constructor ||
          (constructor is Procedure && constructor.isFactory) ||
          (constructor is Procedure && constructor.isStatic),
      "Unexpected constructor tear off target $constructor "
      "(${constructor.runtimeType}).");

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
  _createParameters(tearOff, constructor, substitution, libraryBuilder);
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  _createTearOffBody(tearOff, constructor, arguments);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  updatePrivateMemberName(tearOff, libraryBuilder);
}

/// Creates the parameters and body for [tearOff] for a typedef tearoff of
/// [constructor] in [enclosingClass] with [typeParameters] as the typedef
/// parameters and [typeArguments] as the arguments passed to the
/// [enclosingClass].
void buildTypedefTearOffProcedure(
    Procedure tearOff,
    Member constructor,
    Class enclosingClass,
    List<TypeParameter> typeParameters,
    List<DartType> typeArguments,
    SourceLibraryBuilder libraryBuilder) {
  assert(
      constructor is Constructor ||
          (constructor is Procedure && constructor.isFactory) ||
          (constructor is Procedure && constructor.isStatic),
      "Unexpected constructor tear off target $constructor "
      "(${constructor.runtimeType}).");

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
      _createFreshTypeParameters(typeParameters, tearOff.function);

  Substitution substitution = freshTypeParameters.substitution;
  if (!substitution.isEmpty) {
    if (typeArguments.isNotEmpty) {
      // Translate [typeArgument] into the context of the synthesized procedure.
      typeArguments = new List<DartType>.generate(typeArguments.length,
          (int index) => substitution.substituteType(typeArguments[index]));
    }
  }
  _createParameters(
      tearOff,
      constructor,
      Substitution.fromPairs(classTypeParameters, typeArguments),
      libraryBuilder);
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  _createTearOffBody(tearOff, constructor, arguments);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  updatePrivateMemberName(tearOff, libraryBuilder);
}

/// Creates the parameters for the redirecting factory [tearOff] based on the
/// [redirectingConstructor] declaration.
FreshTypeParameters buildRedirectingFactoryTearOffProcedureParameters(
    Procedure tearOff,
    Procedure redirectingConstructor,
    SourceLibraryBuilder libraryBuilder) {
  assert(redirectingConstructor.isRedirectingFactory);
  FunctionNode function = redirectingConstructor.function;
  FreshTypeParameters freshTypeParameters =
      _createFreshTypeParameters(function.typeParameters, tearOff.function);
  Substitution substitution = freshTypeParameters.substitution;
  _createParameters(
      tearOff, redirectingConstructor, substitution, libraryBuilder);
  tearOff.function.fileOffset = tearOff.fileOffset;
  tearOff.function.fileEndOffset = tearOff.fileOffset;
  updatePrivateMemberName(tearOff, libraryBuilder);
  return freshTypeParameters;
}

/// Creates the body for the redirecting factory [tearOff] with the target
/// [constructor] and [typeArguments].
///
/// Returns the [SynthesizedFunctionNode] object need to perform default value
/// computation.
SynthesizedFunctionNode buildRedirectingFactoryTearOffBody(
    Procedure tearOff,
    Member target,
    List<DartType> typeArguments,
    FreshTypeParameters freshTypeParameters) {
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
  Map<TypeParameter, DartType> substitutionMap;
  if (typeParameters.length == typeArguments.length) {
    substitutionMap = new Map<TypeParameter, DartType>.fromIterables(
        typeParameters, typeArguments);
  } else {
    // Error case: Substitute type parameters with `dynamic`.
    substitutionMap = new Map<TypeParameter, DartType>.fromIterables(
        typeParameters,
        new List<DartType>.generate(
            typeParameters.length, (int index) => const DynamicType()));
  }
  Arguments arguments = _createArguments(tearOff, typeArguments, fileOffset);
  _createTearOffBody(tearOff, target, arguments);
  return new SynthesizedFunctionNode(
      substitutionMap, target.function!, tearOff.function,
      identicalSignatures: false);
}

/// Creates the synthesized [Procedure] node for a tear off lowering by the
/// given [name].
Procedure _createTearOffProcedure(SourceLibraryBuilder libraryBuilder,
    Name name, Uri fileUri, int fileOffset, Reference? reference) {
  return new Procedure(name, ProcedureKind.Method, new FunctionNode(null),
      fileUri: fileUri, isStatic: true, reference: reference)
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
/// in [constructor] and using the [substitution] to compute the parameter and
/// return types.
void _createParameters(Procedure tearOff, Member constructor,
    Substitution substitution, SourceLibraryBuilder libraryBuilder) {
  FunctionNode function = constructor.function!;
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
          Name tearOffName =
              constructorTearOffName(target.name.text, cls.enclosingLibrary);
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
