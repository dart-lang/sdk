// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.expression_generator_helper;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/unresolved_type.dart';

import '../constant_context.dart' show ConstantContext;
import '../fasta_codes.dart' show LocatedMessage;
import '../messages.dart' show Message;
import '../scope.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../type_inference/inference_helper.dart' show InferenceHelper;

import 'constness.dart' show Constness;
import 'forest.dart' show Forest;
import 'internal_ast.dart';
import 'kernel_ast_api.dart'
    show
        Arguments,
        Constructor,
        DartType,
        Expression,
        FunctionNode,
        Initializer,
        InterfaceType,
        Member,
        Name,
        Procedure,
        StaticGet,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        Typedef,
        VariableDeclaration;

abstract class ExpressionGeneratorHelper implements InferenceHelper {
  SourceLibraryBuilder get libraryBuilder;

  ConstantContext get constantContext;

  Forest get forest;

  Constructor? lookupConstructor(Name name, {bool isSuper: false});

  Expression toValue(Object? node);

  Member? lookupInstanceMember(Name name, {bool isSetter, bool isSuper});

  /// `true` if we are in the type of an as expression.
  bool get inIsOrAsOperatorType;

  bool get enableExtensionTypesInLibrary;

  bool get enableConstFunctionsInLibrary;

  bool get enableConstructorTearOffsInLibrary;

  /* Generator | Expression | Builder */ scopeLookup(
      Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder? prefix});

  /* Expression | Generator | Initializer */ finishSend(Object receiver,
      List<UnresolvedType>? typeArguments, Arguments arguments, int offset,
      {bool isTypeArgumentsInForest = false});

  Initializer buildInvalidInitializer(Expression expression,
      [int offset = TreeNode.noOffset]);

  List<Initializer> buildFieldInitializer(String name, int fieldNameOffset,
      int assignmentOffset, Expression expression,
      {FormalParameterBuilder? formal});

  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int offset = TreeNode.noOffset]);

  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = TreeNode.noOffset]);

  Expression buildStaticInvocation(Member target, Arguments arguments,
      {Constness constness: Constness.implicit,
      int charOffset: TreeNode.noOffset});

  Expression buildExtensionMethodInvocation(
      int fileOffset, Procedure target, Arguments arguments,
      {required bool isTearOff});

  Expression throwNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {Member candidate,
      bool isSuper,
      bool isGetter,
      bool isSetter,
      bool isStatic,
      LocatedMessage message});

  LocatedMessage? checkArgumentsForFunction(FunctionNode function,
      Arguments arguments, int offset, List<TypeParameter> typeParameters);

  StaticGet makeStaticGet(Member readTarget, Token token);

  Expression wrapInDeferredCheck(
      Expression expression, PrefixBuilder prefix, int charOffset);

  bool isIdentical(Member? member);

  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression: false,
      bool isNullAware: false,
      bool isSuper: false});

  Expression buildConstructorInvocation(
      TypeDeclarationBuilder type,
      Token nameToken,
      Token nameLastToken,
      Arguments? arguments,
      String name,
      List<UnresolvedType>? typeArguments,
      int charOffset,
      Constness constness,
      {bool isTypeArgumentsInForest = false,
      TypeDeclarationBuilder? typeAliasBuilder});

  UnresolvedType validateTypeUse(UnresolvedType unresolved,
      {required bool nonInstanceAccessIsError,
      required bool allowPotentiallyConstantType});

  void addProblemErrorIfConst(Message message, int charOffset, int length);

  Expression buildProblemErrorIfConst(
      Message message, int charOffset, int length);

  Message warnUnresolvedGet(Name name, int charOffset, {bool isSuper: false});

  Message warnUnresolvedSet(Name name, int charOffset, {bool isSuper: false});

  Message warnUnresolvedMethod(Name name, int charOffset,
      {bool isSuper: false});

  void warnTypeArgumentsMismatch(String name, int expected, int charOffset);

  Expression wrapInLocatedProblem(Expression expression, LocatedMessage message,
      {List<LocatedMessage>? context});

  Expression evaluateArgumentsBefore(
      Arguments arguments, Expression expression);

  DartType buildDartType(UnresolvedType unresolvedType,
      {bool nonInstanceAccessIsError: false});

  DartType buildTypeLiteralDartType(UnresolvedType unresolvedType,
      {bool nonInstanceAccessIsError});

  List<DartType> buildDartTypeArguments(List<UnresolvedType>? unresolvedTypes);

  void reportDuplicatedDeclaration(
      Builder existing, String name, int charOffset);

  /// Creates a synthetic variable declaration for the value of [expression].
  VariableDeclarationImpl createVariableDeclarationForValue(
      Expression expression);

  /// Creates a [VariableGet] of the [variable] using [charOffset] as the file
  /// offset of the created node.
  Expression createVariableGet(VariableDeclaration variable, int charOffset,
      {bool forNullGuardedAccess: false});

  /// Registers that [variable] is assigned to.
  ///
  /// This is needed for type promotion.
  void registerVariableAssignment(VariableDeclaration variable);

  TypeEnvironment get typeEnvironment;
}

/// Checks that a generic [typedef] for a generic class.
bool isProperRenameForClass(TypeEnvironment typeEnvironment, Typedef typedef) {
  DartType? rhsType = typedef.type;
  if (rhsType is! InterfaceType) {
    return false;
  }

  List<TypeParameter> fromParameters = typedef.typeParameters;
  List<TypeParameter> toParameters = rhsType.classNode.typeParameters;
  List<DartType> typeArguments = rhsType.typeArguments;
  if (fromParameters.length != typeArguments.length) {
    return false;
  }
  for (int i = 0; i < fromParameters.length; ++i) {
    if (typeArguments[i] !=
        new TypeParameterType.withDefaultNullabilityForLibrary(
            fromParameters[i], typedef.enclosingLibrary)) {
      return false;
    }
  }

  Map<TypeParameter, DartType> substitutionMap = {};
  for (int i = 0; i < fromParameters.length; ++i) {
    substitutionMap[fromParameters[i]] = new TypeParameterType.forAlphaRenaming(
        fromParameters[i], toParameters[i]);
  }
  Substitution substitution = Substitution.fromMap(substitutionMap);
  for (int i = 0; i < fromParameters.length; ++i) {
    if (!typeEnvironment.areMutualSubtypes(
        toParameters[i].bound,
        substitution.substituteType(fromParameters[i].bound),
        SubtypeCheckMode.withNullabilities)) {
      return false;
    }
  }

  return true;
}
