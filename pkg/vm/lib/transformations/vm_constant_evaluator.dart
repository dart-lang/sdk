// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart'
    show ConstantsBackend, DartLibrarySupport, Target;
import 'package:kernel/type_environment.dart';

import 'package:front_end/src/base/nnbd_mode.dart';
import 'package:front_end/src/fasta/kernel/constant_evaluator.dart'
    show
        AbortConstant,
        AbortStatus,
        ConstantEvaluator,
        ErrorReporter,
        EvaluationMode,
        ProceedStatus,
        ReturnStatus,
        SimpleErrorReporter,
        StatementConstantEvaluator;

import '../target_os.dart';

/// Evaluates uses of static fields and getters using VM-specific and
/// platform-specific knowledge.
///
/// [targetOS] represents the target operating system and is used when
/// evaluating static fields and getters annotated with "vm:platform-const".
///
/// To avoid restricting getters annotated with "vm:platform-const" to be just
/// a single return statement whose body is evaluated, we treat annotated
/// getters as const functions. If [enableConstFunctions] is false, then
/// only annotated getters are treated this way.
class VMConstantEvaluator extends ConstantEvaluator {
  final TargetOS? _targetOS;
  final Map<String, Constant> _constantFields = {};

  final Class? _platformClass;
  final Class _pragmaClass;
  final Field _pragmaName;

  VMConstantEvaluator(
      DartLibrarySupport dartLibrarySupport,
      ConstantsBackend backend,
      Component component,
      Map<String, String>? environmentDefines,
      TypeEnvironment typeEnvironment,
      ErrorReporter errorReporter,
      this._targetOS,
      {bool enableTripleShift = false,
      bool enableConstFunctions = false,
      bool errorOnUnevaluatedConstant = false,
      EvaluationMode evaluationMode = EvaluationMode.weak})
      : _platformClass = typeEnvironment.coreTypes.platformClass,
        _pragmaClass = typeEnvironment.coreTypes.pragmaClass,
        _pragmaName = typeEnvironment.coreTypes.pragmaName,
        super(dartLibrarySupport, backend, component, environmentDefines,
            typeEnvironment, errorReporter,
            enableTripleShift: enableTripleShift,
            enableConstFunctions: enableConstFunctions,
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
            evaluationMode: evaluationMode) {
    // Only add Platform fields if the Platform class is part of the component
    // being evaluated.
    final os = _targetOS;
    if (os != null && _platformClass != null) {
      _constantFields['operatingSystem'] = StringConstant(os.name);
      _constantFields['pathSeparator'] = StringConstant(os.pathSeparator);
    }
  }

  static VMConstantEvaluator create(
      Target target, Component component, TargetOS? targetOS, NnbdMode nnbdMode,
      {bool evaluateAnnotations = true,
      bool enableTripleShift = false,
      bool enableConstFunctions = false,
      bool enableConstructorTearOff = false,
      bool errorOnUnevaluatedConstant = false,
      Map<String, String>? environmentDefines,
      CoreTypes? coreTypes,
      ClassHierarchy? hierarchy}) {
    coreTypes ??= CoreTypes(component);
    hierarchy ??= ClassHierarchy(component, coreTypes);

    final typeEnvironment = TypeEnvironment(coreTypes, hierarchy);

    // Use the empty environment if unevaluated constants are not supported,
    // as passing null for environmentDefines in this case is an error.
    environmentDefines ??=
        target.constantsBackend.supportsUnevaluatedConstants ? null : {};
    return VMConstantEvaluator(
        target.dartLibrarySupport,
        target.constantsBackend,
        component,
        environmentDefines,
        typeEnvironment,
        SimpleErrorReporter(),
        targetOS,
        enableTripleShift: enableTripleShift,
        enableConstFunctions: enableConstFunctions,
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
        evaluationMode: EvaluationMode.fromNnbdMode(nnbdMode));
  }

  /// Used for methods and fields with initializers where the method body or
  /// field initializer must evaluate to a constant value when a target
  /// operating system is provided.
  static const _constPragmaName = "vm:platform-const";

  bool _hasAnnotation(Annotatable node, String name) {
    for (final annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        final constant = annotation.constant;
        if (constant is InstanceConstant &&
            constant.classNode == _pragmaClass &&
            constant.fieldValues[_pragmaName.fieldReference] ==
                StringConstant(name)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isPlatformConst(Member node) => _hasAnnotation(node, _constPragmaName);

  bool transformerShouldEvaluateExpression(Expression node) =>
      _targetOS != null && node is StaticGet && _isPlatformConst(node.target);

  Constant _executePlatformConstBody(Statement statement) {
    final status = statement.accept(StatementConstantEvaluator(this));
    if (status is AbortStatus) return status.error;
    // Happens if there is no return statement in a void Function(...) body.
    if (status is ProceedStatus) return canonicalize(NullConstant());
    if (status is ReturnStatus) {
      final value = status.value;
      return value != null ? value : canonicalize(NullConstant());
    }
    // Other statuses denote intermediate states and not final ones.
    throw 'No valid constant returned after executing $statement';
  }

  @override
  Constant visitStaticGet(StaticGet node) {
    assert(_targetOS != null);
    final target = node.target;

    // This visitor can be called recursively while evaluating an abstraction
    // over the Platform getters and fields, so check that the visited node has
    // an appropriately annotated target.
    if (!_isPlatformConst(target)) return super.visitStaticGet(node);

    return withNewEnvironment(() {
      final nameText = target.name.text;
      visitedLibraries.add(target.enclosingLibrary);

      // First, check for the fields in Platform whose initializers should not
      // be evaluated, but instead uses of the field should just be replaced
      // directly with an already calculated constant.
      if (target is Field && target.enclosingClass == _platformClass) {
        final constant = _constantFields[nameText];
        if (constant != null) {
          return canonicalize(constant);
        }
      }

      late Constant result;
      if (target is Field && target.initializer != null) {
        result = evaluateExpressionInContext(target, target.initializer!);
      } else if (target is Procedure && target.isGetter) {
        final body = target.function.body!;
        result = _executePlatformConstBody(body);
      }
      if (result is AbortConstant) {
        throw "The body or initialization of member '$nameText' does not "
            "evaluate to a constant value for the specified target operating "
            "system '$_targetOS'.";
      }
      return result;
    });
  }
}
