// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.constructors;

import '../dart_types.dart';
import '../elements/elements.dart' show FieldElement;
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
  InterfaceType computeInstanceType(InterfaceType newType);

  /// Computes the constant expressions of the fields of the created instance
  /// in a const constructor invocation with [arguments].
  Map<FieldElement, ConstantExpression> computeInstanceFields(
      List<ConstantExpression> arguments, CallStructure callStructure);

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
  final Map<FieldElement, ConstantExpression> fieldMap;
  final ConstructedConstantExpression superConstructorInvocation;

  GenerativeConstantConstructor(this.type, this.defaultValues, this.fieldMap,
      this.superConstructorInvocation);

  ConstantConstructorKind get kind => ConstantConstructorKind.GENERATIVE;

  InterfaceType computeInstanceType(InterfaceType newType) {
    return type.substByContext(newType);
  }

  Map<FieldElement, ConstantExpression> computeInstanceFields(
      List<ConstantExpression> arguments, CallStructure callStructure) {
    NormalizedArguments args =
        new NormalizedArguments(defaultValues, callStructure, arguments);
    Map<FieldElement, ConstantExpression> appliedFieldMap =
        applyFields(args, superConstructorInvocation);
    fieldMap.forEach((FieldElement field, ConstantExpression constant) {
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
    fieldMap.forEach((FieldElement field, ConstantExpression expression) {
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
  static Map<FieldElement, ConstantExpression> applyFields(
      NormalizedArguments args,
      ConstructedConstantExpression constructorInvocation) {
    Map<FieldElement, ConstantExpression> appliedFieldMap =
        <FieldElement, ConstantExpression>{};
    if (constructorInvocation != null) {
      Map<FieldElement, ConstantExpression> fieldMap =
          constructorInvocation.computeInstanceFields();
      fieldMap.forEach((FieldElement field, ConstantExpression constant) {
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

  InterfaceType computeInstanceType(InterfaceType newType) {
    return thisConstructorInvocation
        .computeInstanceType()
        .substByContext(newType);
  }

  Map<FieldElement, ConstantExpression> computeInstanceFields(
      List<ConstantExpression> arguments, CallStructure callStructure) {
    NormalizedArguments args =
        new NormalizedArguments(defaultValues, callStructure, arguments);
    Map<FieldElement, ConstantExpression> appliedFieldMap =
        GenerativeConstantConstructor.applyFields(
            args, thisConstructorInvocation);
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

  InterfaceType computeInstanceType(InterfaceType newType) {
    return targetConstructorInvocation
        .computeInstanceType()
        .substByContext(newType);
  }

  Map<FieldElement, ConstantExpression> computeInstanceFields(
      List<ConstantExpression> arguments, CallStructure callStructure) {
    ConstantConstructor constantConstructor =
        targetConstructorInvocation.target.constantConstructor;
    return constantConstructor.computeInstanceFields(arguments, callStructure);
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
