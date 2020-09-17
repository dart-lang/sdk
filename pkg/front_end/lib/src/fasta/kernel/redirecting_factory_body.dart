// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.redirecting_factory_body;

import 'package:kernel/ast.dart'
    show
        DartType,
        Expression,
        ExpressionStatement,
        Field,
        FunctionNode,
        InvalidExpression,
        Let,
        Member,
        NullLiteral,
        Procedure,
        StaticGet,
        StringLiteral,
        TypeParameterType,
        VariableDeclaration;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'body_builder.dart' show EnsureLoaded;

/// Name used for a static field holding redirecting factory information.
const String redirectingName = "_redirecting#";

/// Returns `true` if [member] is synthesized field holding the names of
/// redirecting factories declared in the same class.
///
/// This field should be special-cased by backends.
bool isRedirectingFactoryField(Member member) {
  return member is Field &&
      member.isStatic &&
      member.name.text == redirectingName;
}

/// Name used for a synthesized let variable used to encode redirecting factory
/// information in a factory method body.
const String letName = "#redirecting_factory";

class RedirectingFactoryBody extends ExpressionStatement {
  RedirectingFactoryBody.internal(Expression value,
      [List<DartType> typeArguments])
      : super(new Let(new VariableDeclaration(letName, initializer: value),
            encodeTypeArguments(typeArguments)));

  RedirectingFactoryBody(Member target, [List<DartType> typeArguments])
      : this.internal(new StaticGet(target), typeArguments);

  RedirectingFactoryBody.unresolved(String name)
      : this.internal(new StringLiteral(name));

  Member get target {
    dynamic value = getValue(expression);
    return value is StaticGet ? value.target : null;
  }

  String get unresolvedName {
    dynamic value = getValue(expression);
    return value is StringLiteral ? value.value : null;
  }

  bool get isUnresolved => unresolvedName != null;

  List<DartType> get typeArguments {
    if (expression is Let) {
      Let bodyExpression = expression;
      if (bodyExpression.variable.name == letName) {
        return decodeTypeArguments(bodyExpression.body);
      }
    }
    return null;
  }

  static getValue(Expression expression) {
    if (expression is Let) {
      VariableDeclaration variable = expression.variable;
      if (variable.name == letName) {
        return variable.initializer;
      }
    }
    return null;
  }

  static void restoreFromDill(Procedure factory) {
    // This is a hack / work around for storing redirecting constructors in
    // dill files. See `ClassBuilder.addRedirectingConstructor` in
    // [kernel_class_builder.dart](kernel_class_builder.dart).
    FunctionNode function = factory.function;
    ExpressionStatement statement = function.body;
    List<DartType> typeArguments;
    if (statement.expression is Let) {
      Let expression = statement.expression;
      typeArguments = decodeTypeArguments(expression.body);
    }
    function.body = new RedirectingFactoryBody.internal(
        getValue(statement.expression), typeArguments)
      ..parent = function;
  }

  static Expression encodeTypeArguments(List<DartType> typeArguments) {
    String varNamePrefix = "#typeArg";
    Expression result = new InvalidExpression(null);
    if (typeArguments == null) {
      return result;
    }
    for (int i = typeArguments.length - 1; i >= 0; i--) {
      result = new Let(
          new VariableDeclaration("$varNamePrefix$i",
              type: typeArguments[i], initializer: new NullLiteral()),
          result);
    }
    return result;
  }

  static List<DartType> decodeTypeArguments(Expression encoded) {
    if (encoded is InvalidExpression) {
      return null;
    }
    List<DartType> result = <DartType>[];
    while (encoded is Let) {
      Let head = encoded;
      result.add(head.variable.type);
      encoded = head.body;
    }
    return result;
  }

  @override
  String toString() {
    return "RedirectingFactoryBody(${toStringInternal()})";
  }

  @override
  String toStringInternal() {
    return "";
  }
}

bool isRedirectingFactory(Member member, {EnsureLoaded helper}) {
  assert(helper == null || helper.isLoaded(member));
  return member is Procedure && member.function.body is RedirectingFactoryBody;
}

RedirectingFactoryBody getRedirectingFactoryBody(Member member) {
  return isRedirectingFactory(member) ? member.function.body : null;
}

class RedirectionTarget {
  final Member target;
  final List<DartType> typeArguments;

  RedirectionTarget(this.target, this.typeArguments);
}

RedirectionTarget getRedirectionTarget(Procedure member, EnsureLoaded helper) {
  List<DartType> typeArguments = <DartType>[]..length =
      member.function.typeParameters.length;
  for (int i = 0; i < typeArguments.length; i++) {
    typeArguments[i] = new TypeParameterType.withDefaultNullabilityForLibrary(
        member.function.typeParameters[i], member.enclosingLibrary);
  }

  // We use the [tortoise and hare algorithm]
  // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
  // handle cycles.
  Member tortoise = member;
  RedirectingFactoryBody tortoiseBody = getRedirectingFactoryBody(tortoise);
  Member hare = tortoiseBody?.target;
  helper.ensureLoaded(hare);
  RedirectingFactoryBody hareBody = getRedirectingFactoryBody(hare);
  while (tortoise != hare) {
    if (tortoiseBody?.isUnresolved ?? true) {
      return new RedirectionTarget(tortoise, typeArguments);
    }
    Member nextTortoise = tortoiseBody.target;
    helper.ensureLoaded(nextTortoise);
    List<DartType> nextTypeArguments = tortoiseBody.typeArguments;
    if (nextTypeArguments == null) {
      nextTypeArguments = <DartType>[];
    }

    Substitution sub =
        Substitution.fromPairs(tortoise.function.typeParameters, typeArguments);
    typeArguments = <DartType>[]..length = nextTypeArguments.length;
    for (int i = 0; i < typeArguments.length; i++) {
      typeArguments[i] = sub.substituteType(nextTypeArguments[i]);
    }

    tortoise = nextTortoise;
    tortoiseBody = getRedirectingFactoryBody(tortoise);
    helper.ensureLoaded(hareBody?.target);
    hare = getRedirectingFactoryBody(hareBody?.target)?.target;
    helper.ensureLoaded(hare);
    hareBody = getRedirectingFactoryBody(hare);
  }
  return null;
}
