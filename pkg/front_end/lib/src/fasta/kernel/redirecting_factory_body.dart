// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.redirecting_factory_body;

import 'package:kernel/ast.dart'
    show
        Expression,
        ExpressionStatement,
        FunctionNode,
        InvalidExpression,
        Let,
        Member,
        Procedure,
        StaticGet,
        StringLiteral,
        VariableDeclaration;

const String letName = "#redirecting_factory";

class RedirectingFactoryBody extends ExpressionStatement {
  RedirectingFactoryBody.internal(Expression value)
      : super(new Let(new VariableDeclaration(letName, initializer: value),
            new InvalidExpression()));

  RedirectingFactoryBody(Member target) : this.internal(new StaticGet(target));

  RedirectingFactoryBody.unresolved(String name)
      : this.internal(new StringLiteral(name));

  Member get target {
    var value = getValue(expression);
    return value is StaticGet ? value.target : null;
  }

  String get unresolvedName {
    var value = getValue(expression);
    return value is StringLiteral ? value.value : null;
  }

  bool get isUnresolved => unresolvedName != null;

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
    // dill files. See `KernelClassBuilder.addRedirectingConstructor` in
    // [kernel_class_builder.dart](kernel_class_builder.dart).
    FunctionNode function = factory.function;
    ExpressionStatement statement = function.body;
    function.body =
        new RedirectingFactoryBody.internal(getValue(statement.expression))
          ..parent = function;
  }
}

RedirectingFactoryBody getRedirectingFactoryBody(Member member) {
  return member is Procedure && member.function.body is RedirectingFactoryBody
      ? member.function.body
      : null;
}

Member getRedirectionTarget(Procedure member) {
  // We use the [tortoise and hare algorithm]
  // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
  // handle cycles.
  Member tortoise = member;
  RedirectingFactoryBody tortoiseBody = getRedirectingFactoryBody(tortoise);
  Member hare = tortoiseBody?.target;
  RedirectingFactoryBody hareBody = getRedirectingFactoryBody(hare);
  while (tortoise != hare) {
    if (tortoiseBody?.isUnresolved ?? true) return tortoise;
    tortoise = tortoiseBody.target;
    tortoiseBody = getRedirectingFactoryBody(tortoise);
    hare = getRedirectingFactoryBody(hareBody?.target)?.target;
    hareBody = getRedirectingFactoryBody(hare);
  }
  return null;
}
