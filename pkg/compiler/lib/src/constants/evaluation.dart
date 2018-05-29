// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.constants.evaluation;

import 'package:front_end/src/fasta/util/link.dart' show Link;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import 'constructors.dart';
import 'expressions.dart';
import 'values.dart';

/// Environment used for evaluating constant expressions.
abstract class EvaluationEnvironment {
  CommonElements get commonElements;

  DartTypes get types;

  /// Type in the enclosing constructed
  InterfaceType get enclosingConstructedType;

  /// Read environments string passed in using the '-Dname=value' option.
  String readFromEnvironment(String name);

  /// Returns the [ConstantExpression] for the value of the constant [local].
  ConstantExpression getLocalConstant(covariant Local local);

  /// Returns the [ConstantExpression] for the value of the constant [field].
  ConstantExpression getFieldConstant(covariant FieldEntity field);

  /// Returns the [ConstantConstructor] corresponding to the constant
  /// [constructor].
  ConstantConstructor getConstructorConstant(
      covariant ConstructorEntity constructor);

  /// Performs the substitution of the type arguments of [target] for their
  /// corresponding type variables in [type].
  DartType substByContext(
      covariant DartType base, covariant InterfaceType target);

  /// Returns [type] in the context of the [enclosingConstructedType].
  DartType getTypeInContext(DartType type);

  void reportWarning(
      ConstantExpression expression, MessageKind kind, Map arguments);

  void reportError(
      ConstantExpression expression, MessageKind kind, Map arguments);

  ConstantValue evaluateConstructor(ConstructorEntity constructor,
      InterfaceType type, ConstantValue evaluate());

  ConstantValue evaluateField(FieldEntity field, ConstantValue evaluate());

  /// `true` if assertions are enabled.
  bool get enableAssertions;
}

abstract class EvaluationEnvironmentBase implements EvaluationEnvironment {
  Link<Spannable> _spannableStack = const Link<Spannable>();
  InterfaceType enclosingConstructedType;
  final Set<FieldEntity> _currentlyEvaluatedFields = new Set<FieldEntity>();
  final bool constantRequired;

  EvaluationEnvironmentBase(Spannable spannable, {this.constantRequired}) {
    _spannableStack = _spannableStack.prepend(spannable);
  }

  DiagnosticReporter get reporter;

  /// Returns the [Spannable] used for reporting errors and warnings.
  ///
  /// Returns the second-to-last in the spannable stack, if available, to point
  /// to the use, rather than the declaration, of a constructor or field.
  ///
  /// For instance
  ///
  ///    const foo = const bool.fromEnvironment("foo", default: 0);
  ///
  /// will point to `foo` instead of the declaration of `bool.fromEnvironment`.
  Spannable get _spannable => _spannableStack.tail.isEmpty
      ? _spannableStack.head
      : _spannableStack.tail.head;

  @override
  ConstantValue evaluateField(FieldEntity field, ConstantValue evaluate()) {
    if (_currentlyEvaluatedFields.add(field)) {
      _spannableStack = _spannableStack.prepend(field);
      ConstantValue result = evaluate();
      _currentlyEvaluatedFields.remove(field);
      _spannableStack = _spannableStack.tail;
      return result;
    }
    if (constantRequired) {
      reporter.reportErrorMessage(
          field, MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS);
    }
    return new NonConstantValue();
  }

  @override
  ConstantValue evaluateConstructor(ConstructorEntity constructor,
      InterfaceType type, ConstantValue evaluate()) {
    _spannableStack = _spannableStack.prepend(constructor);
    var old = enclosingConstructedType;
    enclosingConstructedType = type;
    ConstantValue result = evaluate();
    enclosingConstructedType = old;
    _spannableStack = _spannableStack.tail;
    return result;
  }

  @override
  void reportError(
      ConstantExpression expression, MessageKind kind, Map arguments) {
    if (constantRequired) {
      // TODO(johnniwinther): Should [ConstantExpression] have a location?
      reporter.reportErrorMessage(_spannable, kind, arguments);
    }
  }

  @override
  void reportWarning(
      ConstantExpression expression, MessageKind kind, Map arguments) {
    if (constantRequired) {
      reporter.reportWarningMessage(_spannable, kind, arguments);
    }
  }

  @override
  DartType getTypeInContext(DartType type) {
    // Running example for comments:
    //
    //     class A<T> {
    //       final T t;
    //       const A(dynamic t) : this.t = t; // implicitly `t as A.T`
    //     }
    //     class B<S> extends A<S> {
    //       const B(dynamic s) : super(s);
    //     }
    //     main() => const B<num>(0);
    //
    // We visit `t as A.T` while evaluating `const B<num>(0)`.

    // The `as` type is `A.T`.
    DartType typeInContext = type;

    // The enclosing type is `B<num>`.
    DartType enclosingType = enclosingConstructedType;
    if (enclosingType != null) {
      ClassEntity contextClass;
      type.forEachTypeVariable((TypeVariableType type) {
        if (type.element.typeDeclaration is ClassEntity) {
          // We find `A` from `A.T`. Since we don't have nested classes, class
          // based type variables can only come from the same class.
          contextClass = type.element.typeDeclaration;
        }
      });
      if (contextClass != null) {
        // The enclosing type `B<num>` as an instance of `A` is `A<num>`.
        enclosingType = types.asInstanceOf(enclosingType, contextClass);
      }
      // `A.T` in the context of the enclosing type `A<num>` is `num`.
      typeInContext = enclosingType != null
          ? substByContext(typeInContext, enclosingType)
          : typeInContext;
    }
    return typeInContext;
  }
}

/// The normalized arguments passed to a const constructor computed from the
/// actual [arguments] and the [defaultValues] of the called construrctor.
class NormalizedArguments {
  final Map<dynamic /*int|String*/, ConstantExpression> defaultValues;
  final CallStructure callStructure;
  final List<ConstantExpression> arguments;

  NormalizedArguments(this.defaultValues, this.callStructure, this.arguments);

  /// Returns the normalized named argument [name].
  ConstantExpression getNamedArgument(String name) {
    int index = callStructure.namedArguments.indexOf(name);
    if (index == -1) {
      // The named argument is not provided.
      assert(
          defaultValues[name] != null,
          failedAt(CURRENT_ELEMENT_SPANNABLE,
              "No default value for named argument '$name' in $this."));
      return defaultValues[name];
    }
    ConstantExpression value =
        arguments[index + callStructure.positionalArgumentCount];
    assert(
        value != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "No value for named argument '$name' in $this."));
    return value;
  }

  /// Returns the normalized [index]th positional argument.
  ConstantExpression getPositionalArgument(int index) {
    if (index >= callStructure.positionalArgumentCount) {
      // The positional argument is not provided.
      assert(
          defaultValues[index] != null,
          failedAt(CURRENT_ELEMENT_SPANNABLE,
              "No default value for positional argument $index in $this."));
      return defaultValues[index];
    }
    ConstantExpression value = arguments[index];
    assert(
        value != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "No value for positional argument $index in $this."));
    return value;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('NormalizedArguments[');
    sb.write('defaultValues={');
    bool needsComma = false;
    defaultValues.forEach((var key, ConstantExpression value) {
      if (needsComma) {
        sb.write(',');
      }
      if (key is String) {
        sb.write('"');
        sb.write(key);
        sb.write('"');
      } else {
        sb.write(key);
      }
      sb.write(':');
      sb.write(value.toStructuredText());
      needsComma = true;
    });
    sb.write('},callStructure=');
    sb.write(callStructure);
    sb.write(',arguments=[');
    arguments.forEach((ConstantExpression value) {
      if (needsComma) {
        sb.write(',');
      }
      sb.write(value.toStructuredText());
      needsComma = true;
    });
    sb.write(']]');
    return sb.toString();
  }
}
