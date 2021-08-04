// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.redirecting_factory_body;

import 'package:kernel/ast.dart';

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

/// Name used for a synthesized let variable used to encode type arguments to
/// the redirection target in a factory method body.
const String varNamePrefix = "#typeArg";

class RedirectingFactoryBody extends ReturnStatement {
  RedirectingFactoryBody._internal(Expression value) : super(value);

  RedirectingFactoryBody(
      Member target, List<DartType> typeArguments, FunctionNode function)
      : this._internal(_makeForwardingCall(target, typeArguments, function));

  RedirectingFactoryBody.error(String errorMessage)
      : this._internal(new InvalidExpression(errorMessage));

  Member? get target {
    final Expression? value = this.expression;
    if (value is StaticInvocation) {
      return value.target;
    } else if (value is ConstructorInvocation) {
      return value.target;
    }
    return null;
  }

  String? get errorMessage {
    final Expression? value = this.expression;
    return value is InvalidExpression ? value.message : null;
  }

  bool get isError => errorMessage != null;

  List<DartType>? get typeArguments {
    final Expression? value = this.expression;
    if (value is InvocationExpression) {
      return value.arguments.types;
    }
    return null;
  }

  static Expression _makeForwardingCall(
      Member target, List<DartType> typeArguments, FunctionNode function) {
    final List<Expression> positional = function.positionalParameters
        .map((v) => new VariableGet(v)..fileOffset = v.fileOffset)
        .toList();
    final List<NamedExpression> named = function.namedParameters
        .map((v) => new NamedExpression(
            v.name!, new VariableGet(v)..fileOffset = v.fileOffset)
          ..fileOffset = v.fileOffset)
        .toList();
    final Arguments args =
        new Arguments(positional, named: named, types: typeArguments);
    if (target is Procedure) {
      return new StaticInvocation(target, args)
        ..fileOffset = function.fileOffset;
    } else if (target is Constructor) {
      return new ConstructorInvocation(target, args)
        ..fileOffset = function.fileOffset;
    } else {
      throw 'Unexpected target for redirecting factory:'
          ' ${target.runtimeType} $target';
    }
  }

  static void restoreFromDill(Procedure factory) {
    // This is a hack / work around for storing redirecting constructors in
    // dill files. See `ClassBuilder.addRedirectingConstructor` in
    // [kernel_class_builder.dart](kernel_class_builder.dart).
    FunctionNode function = factory.function;
    Expression value = (function.body as ReturnStatement).expression!;
    function.body = new RedirectingFactoryBody._internal(value)
      ..parent = function;
  }

  static bool hasRedirectingFactoryBodyShape(Procedure factory) {
    final FunctionNode function = factory.function;
    final Statement? body = function.body;
    if (body is! ReturnStatement) return false;
    final Expression? value = body.expression;
    if (body is InvalidExpression) {
      return true;
    } else if (value is StaticInvocation || value is ConstructorInvocation) {
      // Verify that invocation forwards all arguments.
      final Arguments args = (value as InvocationExpression).arguments;
      if (args.positional.length != function.positionalParameters.length) {
        return false;
      }
      int i = 0;
      for (Expression arg in args.positional) {
        if (arg is! VariableGet) {
          return false;
        }
        if (arg.variable != function.positionalParameters[i]) {
          return false;
        }
        ++i;
      }
      if (args.named.length != function.namedParameters.length) {
        return false;
      }
      i = 0;
      for (NamedExpression arg in args.named) {
        final Expression value = arg.value;
        if (value is! VariableGet) {
          return false;
        }
        final VariableDeclaration param = function.namedParameters[i];
        if (value.variable != param) {
          return false;
        }
        if (arg.name != param.name) {
          return false;
        }
        ++i;
      }
      return true;
    } else {
      return false;
    }
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

bool isRedirectingFactory(Member? member, {EnsureLoaded? helper}) {
  assert(helper == null || helper.isLoaded(member));
  return member is Procedure && member.function.body is RedirectingFactoryBody;
}

RedirectingFactoryBody? getRedirectingFactoryBody(Member? member) {
  return isRedirectingFactory(member)
      ? member!.function!.body as RedirectingFactoryBody
      : null;
}

class RedirectionTarget {
  final Member target;
  final List<DartType> typeArguments;

  RedirectionTarget(this.target, this.typeArguments);
}

RedirectionTarget? getRedirectionTarget(Procedure member, EnsureLoaded helper) {
  List<DartType> typeArguments = new List<DartType>.generate(
      member.function.typeParameters.length, (int i) {
    return new TypeParameterType.withDefaultNullabilityForLibrary(
        member.function.typeParameters[i], member.enclosingLibrary);
  }, growable: true);

  // We use the [tortoise and hare algorithm]
  // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
  // handle cycles.
  Member tortoise = member;
  RedirectingFactoryBody? tortoiseBody = getRedirectingFactoryBody(tortoise);
  Member? hare = tortoiseBody?.target;
  helper.ensureLoaded(hare);
  RedirectingFactoryBody? hareBody = getRedirectingFactoryBody(hare);
  while (tortoise != hare) {
    if (tortoiseBody == null || tortoiseBody.isError) {
      return new RedirectionTarget(tortoise, typeArguments);
    }
    Member nextTortoise = tortoiseBody.target!;
    helper.ensureLoaded(nextTortoise);
    List<DartType>? nextTypeArguments = tortoiseBody.typeArguments;
    if (nextTypeArguments != null) {
      Substitution sub = Substitution.fromPairs(
          tortoise.function!.typeParameters, typeArguments);
      typeArguments =
          new List<DartType>.generate(nextTypeArguments.length, (int i) {
        return sub.substituteType(nextTypeArguments[i]);
      }, growable: true);
    } else {
      typeArguments = <DartType>[];
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
