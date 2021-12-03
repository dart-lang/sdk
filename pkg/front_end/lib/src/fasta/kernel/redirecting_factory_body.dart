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

/// Returns the redirecting factory constructors for the enclosing class from
/// [field].
///
/// `isRedirectingFactoryField(field)` is assumed to be true.
Iterable<Procedure> getRedirectingFactories(Field field) {
  assert(isRedirectingFactoryField(field));
  List<Procedure> redirectingFactories = [];
  ListLiteral initializer = field.initializer as ListLiteral;
  for (Expression expression in initializer.expressions) {
    Procedure target;
    if (expression is ConstantExpression) {
      ConstructorTearOffConstant constant =
          expression.constant as ConstructorTearOffConstant;
      target = constant.target as Procedure;
    } else {
      ConstructorTearOff get = expression as ConstructorTearOff;
      target = get.target as Procedure;
    }
    redirectingFactories.add(target);
  }
  return redirectingFactories;
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

RedirectionTarget getRedirectionTarget(Procedure factory, EnsureLoaded helper) {
  List<DartType> typeArguments = new List<DartType>.generate(
      factory.function.typeParameters.length, (int i) {
    return new TypeParameterType.withDefaultNullabilityForLibrary(
        factory.function.typeParameters[i], factory.enclosingLibrary);
  }, growable: true);

  // Cyclic factories are detected earlier, so we're guaranteed to
  // reach either a non-redirecting factory or an error eventually.
  Member target = factory;
  for (;;) {
    RedirectingFactoryBody? body = getRedirectingFactoryBody(target);
    if (body == null || body.isError) {
      return new RedirectionTarget(target, typeArguments);
    }
    Member nextMember = body.target!;
    helper.ensureLoaded(nextMember);
    List<DartType>? nextTypeArguments = body.typeArguments;
    if (nextTypeArguments != null) {
      Substitution sub = Substitution.fromPairs(
          target.function!.typeParameters, typeArguments);
      typeArguments =
          new List<DartType>.generate(nextTypeArguments.length, (int i) {
        return sub.substituteType(nextTypeArguments[i]);
      }, growable: true);
    } else {
      typeArguments = <DartType>[];
    }
    target = nextMember;
  }
}
