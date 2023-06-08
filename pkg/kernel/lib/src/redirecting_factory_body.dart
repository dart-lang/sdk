// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.redirecting_factory_body;

import 'package:kernel/ast.dart';

import 'package:kernel/type_algebra.dart' show Substitution;

abstract class EnsureLoaded {
  void ensureLoaded(Member? member);

  bool isLoaded(Member? member);
}

/// Name of variable used to wrap expression by the VMs FFI Finalizable
/// transformation.
///
/// Used to recognize the original expression for recovering the redirecting
/// factory body.
const String expressionValueWrappedFinalizableName =
    ":expressionValueWrappedFinalizable";

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

// TODO(johnniwinther): Clean up this library and remove [RedirectingFactory].
class RedirectingFactoryBody {
  static ReturnStatement createRedirectingFactoryBody(
      Member target, List<DartType> typeArguments, FunctionNode function) {
    return new ReturnStatement(
        _makeForwardingCall(target, typeArguments, function));
  }

  static ReturnStatement createRedirectingFactoryErrorBody(
      String errorMessage) {
    return ReturnStatement(new InvalidExpression(errorMessage));
  }

  static Expression _makeForwardingCall(
      Member target, List<DartType> typeArguments, FunctionNode function) {
    final List<Expression> positional = function.positionalParameters
        .map<Expression>((v) => new VariableGet(v)..fileOffset = v.fileOffset)
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
}

RedirectingFactoryTarget? getRedirectingFactoryTarget(Member? member) {
  return member?.function?.redirectingFactoryTarget;
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
    RedirectingFactoryTarget? redirectingFactoryTarget =
        getRedirectingFactoryTarget(target);
    if (redirectingFactoryTarget == null || redirectingFactoryTarget.isError) {
      return new RedirectionTarget(target, typeArguments);
    }
    Member nextMember = redirectingFactoryTarget.target!;
    helper.ensureLoaded(nextMember);
    List<DartType>? nextTypeArguments = redirectingFactoryTarget.typeArguments;
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
