// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.expression_generator_helper;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' show LocatedMessage;

import '../messages.dart' show Message;

import '../scope.dart' show Scope;

import '../type_inference/inference_helper.dart' show InferenceHelper;

import '../type_inference/type_promotion.dart' show TypePromoter;

import 'constness.dart' show Constness;

import 'forest.dart' show Forest;

import 'kernel_builder.dart' show Builder, PrefixBuilder, UnresolvedType;

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

import 'kernel_builder.dart'
    show PrefixBuilder, LibraryBuilder, TypeDeclarationBuilder;

abstract class ExpressionGeneratorHelper implements InferenceHelper {
  LibraryBuilder get library;

  TypePromoter get typePromoter;

  int get functionNestingLevel;

  ConstantContext get constantContext;

  Forest get forest;

  bool get legacyMode;

  Constructor lookupConstructor(Name name, {bool isSuper});

  Expression toValue(node);

  Member lookupInstanceMember(Name name, {bool isSetter, bool isSuper});

  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix});

  finishSend(Object receiver, Arguments arguments, int offset);

  Initializer buildInvalidInitializer(Expression expression, [int offset]);

  Initializer buildFieldInitializer(bool isSynthetic, String name,
      int fieldNameOffset, int assignmentOffset, Expression expression,
      {DartType formalType});

  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int offset]);

  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]);

  Expression buildStaticInvocation(Procedure target, Arguments arguments,
      {Constness constness, int charOffset});

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
      {bool isConstantExpression,
      bool isNullAware,
      bool isImplicitCall,
      bool isSuper,
      Member interfaceTarget});

  Expression buildConstructorInvocation(
      TypeDeclarationBuilder type,
      Token nameToken,
      Token nameLastToken,
      Arguments arguments,
      String name,
      List<UnresolvedType> typeArguments,
      int charOffset,
      Constness constness);

  UnresolvedType validateTypeUse(
      UnresolvedType unresolved, bool nonInstanceAccessIsError);

  void addProblemErrorIfConst(Message message, int charOffset, int length);

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

  Expression wrapSyntheticExpression(Expression node, int charOffset);

  Expression wrapInvalidConstructorInvocation(Expression desugared,
      Member constructor, Arguments arguments, int charOffset);

  Expression wrapInvalidWrite(
      Expression desugared, Expression expression, int charOffset);

  Expression wrapUnresolvedTargetInvocation(
      Expression desugared, Arguments arguments, int charOffset);

  Expression wrapUnresolvedVariableAssignment(
      Expression desugared, bool isCompound, Expression rhs, int charOffset);

  /// Creates a [VariableGet] of the [variable] using [charOffset] as the file
  /// offset of the created node.
  Expression createVariableGet(VariableDeclaration variable, int charOffset);

  /// Creates a tear off of the extension instance method [procedure].
  ///
  /// The tear off is created as a function expression that captures the
  /// current `this` value from [extensionThis] and [extensionTypeParameters]
  /// synthetically copied to the extension instance method.
  ///
  /// For instance the declaration of `B.m`:
  ///
  ///     class A<X, Y> {}
  ///     class B<S, T> on A<S, T> {
  ///       void m<U>(U u) {}
  ///     }
  ///
  /// is converted into this top level method:
  ///
  ///     void B<S,T>|m<U>(A<S, T> #this, U u) {}
  ///
  /// and a tear off
  ///
  ///     A<X, Y> a = ...;
  ///     var f = a.m;
  ///
  /// is converted into:
  ///
  ///     A<int, String> a = ...;
  ///     var f = <#U>(#U u) => B<S,T>|m<int,String,#U>(a, u);
  ///
  Expression createExtensionTearOff(
      Procedure procedure,
      VariableDeclaration extensionThis,
      List<TypeParameter> extensionTypeParameters,
      Token token);
}
