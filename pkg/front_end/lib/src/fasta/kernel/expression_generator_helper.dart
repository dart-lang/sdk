// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.expression_generator_helper;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import '../builder/builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/unresolved_type.dart';

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' show LocatedMessage;

import '../messages.dart' show Message;

import '../scope.dart' show Scope;

import '../type_inference/inference_helper.dart' show InferenceHelper;

import 'constness.dart' show Constness;

import 'forest.dart' show Forest;

import '../scope.dart';

import 'kernel_ast_api.dart'
    show
        Arguments,
        Constructor,
        DartType,
        Expression,
        FunctionNode,
        Initializer,
        Member,
        Name,
        Procedure,
        StaticGet,
        TypeParameter,
        VariableDeclaration;

abstract class ExpressionGeneratorHelper implements InferenceHelper {
  LibraryBuilder get libraryBuilder;

  ConstantContext get constantContext;

  Forest get forest;

  Constructor lookupConstructor(Name name, {bool isSuper});

  Expression toValue(node);

  Member lookupInstanceMember(Name name, {bool isSetter, bool isSuper});

  /// `true` if we are in the type of an as expression.
  bool get inIsOrAsOperatorType;

  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix});

  finishSend(Object receiver, List<UnresolvedType> typeArguments,
      Arguments arguments, int offset,
      {bool isTypeArgumentsInForest = false});

  Initializer buildInvalidInitializer(Expression expression, [int offset]);

  List<Initializer> buildFieldInitializer(String name, int fieldNameOffset,
      int assignmentOffset, Expression expression,
      {FormalParameterBuilder formal});

  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int offset]);

  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]);

  Expression buildStaticInvocation(Procedure target, Arguments arguments,
      {Constness constness, int charOffset});

  Expression buildExtensionMethodInvocation(
      int fileOffset, Procedure target, Arguments arguments,
      {bool isTearOff});

  Expression throwNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {Member candidate,
      bool isSuper,
      bool isGetter,
      bool isSetter,
      bool isStatic,
      LocatedMessage message});

  LocatedMessage checkArgumentsForFunction(FunctionNode function,
      Arguments arguments, int offset, List<TypeParameter> typeParameters);

  StaticGet makeStaticGet(Member readTarget, Token token);

  Expression wrapInDeferredCheck(
      Expression expression, PrefixBuilder prefix, int charOffset);

  bool isIdentical(Member member);

  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression, bool isNullAware, bool isSuper});

  Expression buildConstructorInvocation(
      TypeDeclarationBuilder type,
      Token nameToken,
      Token nameLastToken,
      Arguments arguments,
      String name,
      List<UnresolvedType> typeArguments,
      int charOffset,
      Constness constness,
      {bool isTypeArgumentsInForest = false});

  UnresolvedType validateTypeUse(UnresolvedType unresolved,
      {bool nonInstanceAccessIsError, bool allowPotentiallyConstantType});

  void addProblemErrorIfConst(Message message, int charOffset, int length);

  Expression buildProblemErrorIfConst(
      Message message, int charOffset, int length);

  Message warnUnresolvedGet(Name name, int charOffset, {bool isSuper});

  Message warnUnresolvedSet(Name name, int charOffset, {bool isSuper});

  Message warnUnresolvedMethod(Name name, int charOffset, {bool isSuper});

  void warnTypeArgumentsMismatch(String name, int expected, int charOffset);

  Expression wrapInLocatedProblem(Expression expression, LocatedMessage message,
      {List<LocatedMessage> context});

  Expression evaluateArgumentsBefore(
      Arguments arguments, Expression expression);

  DartType buildDartType(UnresolvedType unresolvedType,
      {bool nonInstanceAccessIsError});

  List<DartType> buildDartTypeArguments(List<UnresolvedType> unresolvedTypes);

  void reportDuplicatedDeclaration(
      Builder existing, String name, int charOffset);

  /// Creates a [VariableGet] of the [variable] using [charOffset] as the file
  /// offset of the created node.
  Expression createVariableGet(VariableDeclaration variable, int charOffset,
      {bool forNullGuardedAccess: false});

  /// Registers that [variable] is assigned to.
  ///
  /// This is needed for type promotion.
  void registerVariableAssignment(VariableDeclaration variable);
}
