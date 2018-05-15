// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compile_time_constant_evaluator;

import 'common/tasks.dart' show CompilerTask, Measurer;
import 'common.dart';
import 'compiler.dart' show Compiler;
import 'constant_system_dart.dart';
import 'constants/constant_system.dart';
import 'constants/expressions.dart';
import 'constants/values.dart';
import 'common_elements.dart' show CommonElements;
import 'elements/entities.dart';
import 'elements/elements.dart';

/// A [ConstantEnvironment] provides access for constants compiled for variable
/// initializers.
abstract class ConstantEnvironment {
  /// The [ConstantSystem] used by this environment.
  ConstantSystem get constantSystem;

  /// Returns `true` if a value has been computed for [expression].
  bool hasConstantValue(ConstantExpression expression);

  /// Returns the constant value computed for [expression].
  // TODO(johnniwinther): Support directly evaluation of [expression].
  ConstantValue getConstantValue(ConstantExpression expression);
}

/// A [BackendConstantEnvironment] provides access to constants needed for
/// backend implementation.
abstract class BackendConstantEnvironment extends ConstantEnvironment {
  /// Register that [element] needs lazy initialization.
  void registerLazyStatic(FieldEntity element);
}

/// Interface for the task that compiles the constant environments for the
/// frontend and backend interpretation of compile-time constants.
abstract class ConstantCompilerTask extends CompilerTask
    implements ConstantEnvironment {
  ConstantCompilerTask(Measurer measurer) : super(measurer);

  /// Copy all cached constant values from [task].
  ///
  /// This is a hack to support reuse cached compilers in memory_compiler.
  // TODO(johnniwinther): Remove this when values are computed from the
  // expressions.
  void copyConstantValues(ConstantCompilerTask task);
}

/**
 * The [ConstantCompilerBase] is provides base implementation for compilation of
 * compile-time constants for both the Dart and JavaScript interpretation of
 * constants. It keeps track of compile-time constants for initializations of
 * global and static fields, and default values of optional parameters.
 */
abstract class ConstantCompilerBase implements ConstantEnvironment {
  final Compiler compiler;
  final ConstantSystem constantSystem;

  /**
   * Contains the initial values of fields and default values of parameters.
   *
   * Must contain all static and global initializations of const fields.
   *
   * May contain eagerly compiled initial values for statics and instance
   * fields (if those are compile-time constants).
   *
   * May contain default parameter values of optional arguments.
   *
   * Invariant: The keys in this map are declarations.
   */
  // TODO(johnniwinther): Make this purely internal when no longer used by
  // poi/forget_element_test.
  final Map<VariableElement, ConstantExpression> initialVariableValues =
      new Map<VariableElement, ConstantExpression>();

  /** The set of variable elements that are in the process of being computed. */
  final Set<VariableElement> pendingVariables = new Set<VariableElement>();

  final Map<ConstantExpression, ConstantValue> constantValueMap =
      <ConstantExpression, ConstantValue>{};

  ConstantCompilerBase(this.compiler, this.constantSystem);

  DiagnosticReporter get reporter => compiler.reporter;

  CommonElements get commonElements => compiler.resolution.commonElements;

  void cacheConstantValue(ConstantExpression expression, ConstantValue value) {
    constantValueMap[expression] = value;
  }

  bool hasConstantValue(ConstantExpression expression) {
    return constantValueMap.containsKey(expression);
  }

  @override
  ConstantValue getConstantValue(ConstantExpression expression) {
    assert(
        expression != null,
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "ConstantExpression is null in getConstantValue."));
    ConstantValue value = constantValueMap[expression];
    if (value == null &&
        expression != null &&
        expression.kind == ConstantExpressionKind.ERRONEOUS) {
      // TODO(johnniwinther): When the Dart constant system sees a constant
      // expression as erroneous but the JavaScript constant system finds it ok
      // we have store a constant value for the erroneous constant expression.
      // Ensure the computed constant expressions are always the same; that only
      // the constant values may be different.
      value = new NullConstantValue();
    }
    return value;
  }
}

/// [ConstantCompiler] that uses the Dart semantics for the compile-time
/// constant evaluation.
class DartConstantCompiler extends ConstantCompilerBase {
  DartConstantCompiler(Compiler compiler)
      : super(compiler, const DartConstantSystem());
}
