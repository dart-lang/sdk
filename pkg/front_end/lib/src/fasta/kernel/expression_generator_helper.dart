// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.expression_generator_helper;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' show LocatedMessage;

import '../messages.dart' show Message;

import '../scope.dart' show ProblemBuilder, Scope;

import '../type_inference/inference_helper.dart' show InferenceHelper;

import '../type_inference/type_promotion.dart' show TypePromoter;

import 'constness.dart' show Constness;

import 'forest.dart' show Forest;

import 'kernel_builder.dart' show PrefixBuilder;

import 'kernel_ast_api.dart'
    show
        Constructor,
        DartType,
        FunctionNode,
        FunctionType,
        Initializer,
        Member,
        Name,
        Procedure,
        StaticGet,
        TypeParameter,
        TypeParameterType;

import 'kernel_builder.dart'
    show
        KernelPrefixBuilder,
        LibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder;

abstract class ExpressionGeneratorHelper<Expression, Statement, Arguments>
    implements InferenceHelper<Expression, Statement, Arguments> {
  LibraryBuilder get library;

  Uri get uri;

  TypePromoter get typePromoter;

  int get functionNestingLevel;

  ConstantContext get constantContext;

  Forest<Expression, Statement, Token, Arguments> get forest;

  Constructor lookupConstructor(Name name, {bool isSuper});

  Expression toValue(node);

  Member lookupInstanceMember(Name name, {bool isSetter, bool isSuper});

  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix});

  finishSend(Object receiver, Arguments arguments, int offset);

  Expression buildCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context});

  Expression wrapInCompileTimeError(Expression expression, Message message);

  Expression deprecated_buildCompileTimeError(String error, [int offset]);

  Initializer buildInvalidInitializer(Expression expression, [int offset]);

  Initializer buildFieldInitializer(
      bool isSynthetic, String name, int offset, Expression expression);

  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int offset]);

  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]);

  Expression buildStaticInvocation(Procedure target, Arguments arguments,
      {Constness constness, int charOffset, Member initialTarget});

  Expression buildProblemExpression(
      ProblemBuilder builder, int offset, int length);

  Expression throwNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int offset,
      {Member candidate,
      bool isSuper,
      bool isGetter,
      bool isSetter,
      bool isStatic,
      LocatedMessage argMessage});

  LocatedMessage checkArgumentsForFunction(FunctionNode function,
      Arguments arguments, int offset, List<TypeParameter> typeParameters);

  LocatedMessage checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset);

  StaticGet makeStaticGet(Member readTarget, Token token);

  Expression wrapInDeferredCheck(
      Expression expression, KernelPrefixBuilder prefix, int charOffset);

  dynamic deprecated_addCompileTimeError(int charOffset, String message);

  bool isIdentical(Member member);

  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression,
      bool isNullAware,
      bool isImplicitCall,
      bool isSuper,
      Member interfaceTarget});

  Expression buildConstructorInvocation(
      TypeDeclarationBuilder type,
      Token nameToken,
      Arguments arguments,
      String name,
      List<DartType> typeArguments,
      int charOffset,
      Constness constness);

  DartType validatedTypeVariableUse(
      TypeParameterType type, int offset, bool nonInstanceAccessIsError);

  void addProblem(Message message, int charOffset, int length);

  void addProblemErrorIfConst(Message message, int charOffset, int length);

  Message warnUnresolvedGet(Name name, int charOffset, {bool isSuper});

  Message warnUnresolvedSet(Name name, int charOffset, {bool isSuper});

  Message warnUnresolvedMethod(Name name, int charOffset, {bool isSuper});

  void warnTypeArgumentsMismatch(String name, int expected, int charOffset);

  T storeOffset<T>(T node, int offset);
}
