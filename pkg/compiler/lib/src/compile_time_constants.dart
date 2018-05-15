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
import 'elements/elements.dart';
import 'elements/resolution_types.dart';
import 'resolution/tree_elements.dart' show TreeElements;
import 'tree/tree.dart';

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

  /// Returns the constant value for the initializer of [element].
  @deprecated
  ConstantValue getConstantValueForVariable(VariableElement element);
}

/// A class that can compile and provide constants for variables, nodes and
/// metadata.
abstract class ConstantCompiler extends ConstantEnvironment {
  /// Compiles the compile-time constant for the initializer of [element], or
  /// reports an error if the initializer is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstantExpression compileConstant(VariableElement element);

  /// Computes the compile-time constant for the variable initializer,
  /// if possible.
  ConstantExpression compileVariable(VariableElement element);

  /// Compiles the constant for [node].
  ///
  /// Reports an error if [node] is not a compile-time constant and
  /// [enforceConst].
  ///
  /// If `!enforceConst`, then if [node] is a "runtime constant" (for example
  /// a reference to a deferred constant) it will be returned - otherwise null
  /// is returned.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true});

  /// Compiles the compile-time constant for the value [metadata], or reports an
  /// error if the value is not a compile-time constant.
  ///
  /// Depending on implementation, the constant compiler might also compute
  /// the compile-time constant for the backend interpretation of constants.
  ///
  /// The returned constant is always of the frontend interpretation.
  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements);

  /// Evaluates [constant] and caches the result.
  // TODO(johnniwinther): Remove when all constants are evaluated.
  void evaluate(ConstantExpression constant);
}

/// A [BackendConstantEnvironment] provides access to constants needed for
/// backend implementation.
abstract class BackendConstantEnvironment extends ConstantEnvironment {
  /// Returns the compile-time constant value associated with [node].
  ///
  /// Depending on implementation, the constant might be stored in [elements].
  ConstantValue getConstantValueForNode(Node node, TreeElements elements);

  /// Returns the compile-time constant associated with [node].
  ///
  /// Depending on implementation, the constant might be stored in [elements].
  ConstantExpression getConstantForNode(Node node, TreeElements elements);

  /// Returns the compile-time constant value of [metadata].
  ConstantValue getConstantValueForMetadata(MetadataAnnotation metadata);

  /// Register that [element] needs lazy initialization.
  void registerLazyStatic(FieldElement element);
}

/// Interface for the task that compiles the constant environments for the
/// frontend and backend interpretation of compile-time constants.
abstract class ConstantCompilerTask extends CompilerTask
    implements ConstantCompiler {
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
abstract class ConstantCompilerBase implements ConstantCompiler {
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

  @override
  @deprecated
  ConstantValue getConstantValueForVariable(VariableElement element) {
    ConstantExpression constant = initialVariableValues[element.declaration];
    // TODO(johnniwinther): Support eager evaluation of the constant.
    return constant != null ? getConstantValue(constant) : null;
  }

  ConstantExpression compileConstant(VariableElement element) {
    return internalCompileVariable(element, true, true);
  }

  @override
  void evaluate(ConstantExpression constant) {}

  ConstantExpression compileVariable(VariableElement element) {
    return internalCompileVariable(element, false, true);
  }

  /// Compile [element] into a constant expression. If [isConst] is true,
  /// then [element] is a constant variable. If [checkType] is true, then
  /// report an error if [element] does not typecheck.
  ConstantExpression internalCompileVariable(
      VariableElement element, bool isConst, bool checkType) {
    if (initialVariableValues.containsKey(element.declaration)) {
      ConstantExpression result = initialVariableValues[element.declaration];
      return result;
    }
    if (element.hasConstant) {
      if (element.constant != null) {
        assert(
            hasConstantValue(element.constant),
            failedAt(
                element,
                "Constant expression has not been evaluated: "
                "${element.constant.toStructuredText()}."));
      }
      return element.constant;
    }
    AstElement currentElement = element.analyzableElement;
    return reporter.withCurrentElement(element, () {
      // TODO(johnniwinther): Avoid this eager analysis.
      compiler.resolution.ensureResolved(currentElement.declaration);

      ConstantExpression constant = compileVariableWithDefinitions(
          element, currentElement.resolvedAst.elements,
          isConst: isConst, checkType: checkType);
      return constant;
    });
  }

  /**
   * Returns the a compile-time constant if the variable could be compiled
   * eagerly. If the variable needs to be initialized lazily returns `null`.
   * If the variable is `const` but cannot be compiled eagerly reports an
   * error.
   */
  ConstantExpression compileVariableWithDefinitions(
      VariableElement element, TreeElements definitions,
      {bool isConst: false, bool checkType: true}) {
    Node node = element.node;
    if (pendingVariables.contains(element)) {
      if (isConst) {
        reporter.reportErrorMessage(
            node, MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS);
        ConstantExpression expression = new ErroneousConstantExpression();
        constantValueMap[expression] = constantSystem.createNull();
        return expression;
      }
      return null;
    }
    pendingVariables.add(element);

    Expression initializer = element.initializer;
    ConstantExpression expression;
    if (initializer == null) {
      // No initial value.
      expression = new NullConstantExpression();
      constantValueMap[expression] = constantSystem.createNull();
    } else {
      expression = compileNodeWithDefinitions(initializer, definitions,
          isConst: isConst);
      if (compiler.options.enableTypeAssertions &&
          checkType &&
          expression != null &&
          element.isField) {
        ResolutionDartType elementType = element.type;
        ConstantValue value = getConstantValue(expression);
        if (elementType.isMalformed && !value.isNull) {
          if (isConst) {
            // TODO(johnniwinther): Check that it is possible to reach this
            // point in a situation where `elementType is! MalformedType`.
            if (elementType is MalformedType) {
              ErroneousElement element = elementType.element;
              reporter.reportErrorMessage(
                  node, element.messageKind, element.messageArguments);
            }
          } else {
            // We need to throw an exception at runtime.
            expression = null;
          }
        } else {
          ResolutionDartType constantType = value.getType(commonElements);
          if (!constantSystem.isSubtype(
              compiler.resolution.types, constantType, elementType)) {
            if (isConst) {
              reporter.reportErrorMessage(node, MessageKind.NOT_ASSIGNABLE,
                  {'fromType': constantType, 'toType': elementType});
            } else {
              // If the field cannot be lazily initialized, we will throw
              // the exception at runtime.
              expression = null;
            }
          }
        }
      }
    }
    if (expression != null) {
      initialVariableValues[element.declaration] = expression;
    } else {
      assert(
          !isConst,
          failedAt(
              element, "Variable $element does not compile to a constant."));
    }
    pendingVariables.remove(element);
    return expression;
  }

  void cacheConstantValue(ConstantExpression expression, ConstantValue value) {
    constantValueMap[expression] = value;
  }

  ConstantExpression compileNodeWithDefinitions(
      Node node, TreeElements definitions,
      {bool isConst: true}) {
    assert(node != null);
    return null;
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

  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true}) {
    return compileNodeWithDefinitions(node, elements, isConst: enforceConst);
  }

  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }
}

/// [ConstantCompiler] that uses the Dart semantics for the compile-time
/// constant evaluation.
class DartConstantCompiler extends ConstantCompilerBase {
  DartConstantCompiler(Compiler compiler)
      : super(compiler, const DartConstantSystem());

  ConstantExpression getConstantForNode(Node node, TreeElements definitions) {
    return definitions.getConstant(node);
  }

  ConstantExpression compileNodeWithDefinitions(
      Node node, TreeElements definitions,
      {bool isConst: true}) {
    ConstantExpression constant = definitions.getConstant(node);
    if (constant != null && hasConstantValue(constant)) {
      return constant;
    }
    constant =
        super.compileNodeWithDefinitions(node, definitions, isConst: isConst);
    if (constant != null) {
      definitions.setConstant(node, constant);
    }
    return constant;
  }
}
