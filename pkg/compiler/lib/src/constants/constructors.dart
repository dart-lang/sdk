// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.constructors;

import '../elements/entities.dart' show FieldEntity;
import '../elements/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../util/util.dart';
import 'evaluation.dart';
import 'expressions.dart';

enum ConstantConstructorKind {
  GENERATIVE,
  REDIRECTING_GENERATIVE,
  REDIRECTING_FACTORY,
}

/// Definition of a constant constructor.
abstract class ConstantConstructor {
  ConstantConstructorKind get kind;

  /// Computes the type of the instance created in a const constructor
  /// invocation with type [newType].
  InterfaceType computeInstanceType(
      EvaluationEnvironment environment, InterfaceType newType);

  /// Computes the constant expressions of the fields of the created instance
  /// in a const constructor invocation with [arguments].
  Map<FieldEntity, ConstantExpression> computeInstanceFields(
      EvaluationEnvironment environment,
      List<ConstantExpression> arguments,
      CallStructure callStructure);

  accept(ConstantConstructorVisitor visitor, arg);
}

abstract class ConstantConstructorVisitor<R, A> {
  const ConstantConstructorVisitor();

  R visit(ConstantConstructor constantConstructor, A context) {
    return constantConstructor.accept(this, context);
  }

  R visitGenerative(GenerativeConstantConstructor constructor, A arg);
  R visitRedirectingGenerative(
      RedirectingGenerativeConstantConstructor constructor, A arg);
  R visitRedirectingFactory(
      RedirectingFactoryConstantConstructor constructor, A arg);
}

/// A generative constant constructor.
class GenerativeConstantConstructor implements ConstantConstructor {
  final InterfaceType type;
  final Map<dynamic /*int|String*/, ConstantExpression> defaultValues;
  final Map<FieldEntity, ConstantExpression> fieldMap;
  final ConstructedConstantExpression superConstructorInvocation;

  GenerativeConstantConstructor(this.type, this.defaultValues, this.fieldMap,
      this.superConstructorInvocation);

  ConstantConstructorKind get kind => ConstantConstructorKind.GENERATIVE;

  InterfaceType computeInstanceType(
      EvaluationEnvironment environment, InterfaceType newType) {
    return environment.substByContext(type, newType);
  }

  Map<FieldEntity, ConstantExpression> computeInstanceFields(
      EvaluationEnvironment environment,
      List<ConstantExpression> arguments,
      CallStructure callStructure) {
    NormalizedArguments args =
        new NormalizedArguments(defaultValues, callStructure, arguments);
    Map<FieldEntity, ConstantExpression> appliedFieldMap =
        applyFields(environment, args, superConstructorInvocation);
    fieldMap.forEach((FieldEntity field, ConstantExpression constant) {
      appliedFieldMap[field] = constant.apply(args);
    });
    return appliedFieldMap;
  }

  accept(ConstantConstructorVisitor visitor, arg) {
    return visitor.visitGenerative(this, arg);
  }

  int get hashCode {
    int hash = Hashing.objectHash(type);
    hash = Hashing.mapHash(defaultValues, hash);
    hash = Hashing.mapHash(fieldMap, hash);
    return Hashing.objectHash(superConstructorInvocation, hash);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! GenerativeConstantConstructor) return false;
    return type == other.type &&
        superConstructorInvocation == other.superConstructorInvocation &&
        mapEquals(defaultValues, other.defaultValues) &&
        mapEquals(fieldMap, other.fieldMap);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("{'type': $type");
    defaultValues.forEach((key, ConstantExpression expression) {
      sb.write(",\n 'default:${key}': ${expression.toDartText()}");
    });
    fieldMap.forEach((FieldEntity field, ConstantExpression expression) {
      sb.write(",\n 'field:${field}': ${expression.toDartText()}");
    });
    if (superConstructorInvocation != null) {
      sb.write(",\n 'constructor: ${superConstructorInvocation.toDartText()}");
    }
    sb.write("}");
    return sb.toString();
  }

  static bool mapEquals(Map map1, Map map2) {
    if (map1.length != map1.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  /// Creates the field-to-constant map from applying [args] to
  /// [constructorInvocation]. If [constructorInvocation] is `null`, an empty
  /// map is created.
  static Map<FieldEntity, ConstantExpression> applyFields(
      EvaluationEnvironment environment,
      NormalizedArguments args,
      ConstructedConstantExpression constructorInvocation) {
    Map<FieldEntity, ConstantExpression> appliedFieldMap =
        <FieldEntity, ConstantExpression>{};
    if (constructorInvocation != null) {
      Map<FieldEntity, ConstantExpression> fieldMap =
          constructorInvocation.computeInstanceFields(environment);
      fieldMap.forEach((FieldEntity field, ConstantExpression constant) {
        appliedFieldMap[field] = constant.apply(args);
      });
    }
    return appliedFieldMap;
  }
}

/// A redirecting generative constant constructor.
class RedirectingGenerativeConstantConstructor implements ConstantConstructor {
  final Map<dynamic /*int|String*/, ConstantExpression> defaultValues;
  final ConstructedConstantExpression thisConstructorInvocation;

  RedirectingGenerativeConstantConstructor(
      this.defaultValues, this.thisConstructorInvocation);

  ConstantConstructorKind get kind {
    return ConstantConstructorKind.REDIRECTING_GENERATIVE;
  }

  InterfaceType computeInstanceType(
      EvaluationEnvironment environment, InterfaceType newType) {
    return environment.substByContext(
        thisConstructorInvocation.computeInstanceType(environment), newType);
  }

  Map<FieldEntity, ConstantExpression> computeInstanceFields(
      EvaluationEnvironment environment,
      List<ConstantExpression> arguments,
      CallStructure callStructure) {
    NormalizedArguments args =
        new NormalizedArguments(defaultValues, callStructure, arguments);
    Map<FieldEntity, ConstantExpression> appliedFieldMap =
        GenerativeConstantConstructor.applyFields(
            environment, args, thisConstructorInvocation);
    return appliedFieldMap;
  }

  accept(ConstantConstructorVisitor visitor, arg) {
    return visitor.visitRedirectingGenerative(this, arg);
  }

  int get hashCode {
    int hash = Hashing.objectHash(thisConstructorInvocation);
    return Hashing.mapHash(defaultValues, hash);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! RedirectingGenerativeConstantConstructor) return false;
    return thisConstructorInvocation == other.thisConstructorInvocation &&
        GenerativeConstantConstructor.mapEquals(
            defaultValues, other.defaultValues);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("{'type': ${thisConstructorInvocation.type}");
    defaultValues.forEach((key, ConstantExpression expression) {
      sb.write(",\n 'default:${key}': ${expression.toDartText()}");
    });
    sb.write(",\n 'constructor': ${thisConstructorInvocation.toDartText()}");
    sb.write("}");
    return sb.toString();
  }
}

/// A redirecting factory constant constructor.
class RedirectingFactoryConstantConstructor implements ConstantConstructor {
  final ConstructedConstantExpression targetConstructorInvocation;

  RedirectingFactoryConstantConstructor(this.targetConstructorInvocation);

  ConstantConstructorKind get kind {
    return ConstantConstructorKind.REDIRECTING_FACTORY;
  }

  InterfaceType computeInstanceType(
      EvaluationEnvironment environment, InterfaceType newType) {
    return environment.substByContext(
        targetConstructorInvocation.computeInstanceType(environment), newType);
  }

  Map<FieldEntity, ConstantExpression> computeInstanceFields(
      EvaluationEnvironment environment,
      List<ConstantExpression> arguments,
      CallStructure callStructure) {
    ConstantConstructor constantConstructor =
        environment.getConstructorConstant(targetConstructorInvocation.target);
    return constantConstructor.computeInstanceFields(
        environment, arguments, callStructure);
  }

  accept(ConstantConstructorVisitor visitor, arg) {
    return visitor.visitRedirectingFactory(this, arg);
  }

  int get hashCode {
    return Hashing.objectHash(targetConstructorInvocation);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! RedirectingFactoryConstantConstructor) return false;
    return targetConstructorInvocation == other.targetConstructorInvocation;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("{");
    sb.write("'constructor': ${targetConstructorInvocation.toDartText()}");
    sb.write("}");
    return sb.toString();
  }
}
