// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart'
    show ConstantsBackend, DartLibrarySupport, Target;
import 'package:kernel/type_environment.dart';

import 'package:front_end/src/api_prototype/constant_evaluator.dart'
    show ConstantEvaluator, ErrorReporter, EvaluationMode, SimpleErrorReporter;

import '../target_os.dart';
import 'pragma.dart';

/// Evaluates uses of static fields and getters using VM-specific and
/// platform-specific knowledge.
///
/// The provided [TargetOS], when non-null, is used when evaluating static
/// fields and getters annotated with "vm:platform-const".
///
/// To avoid restricting getters annotated with "vm:platform-const" to be just
/// a single return statement whose body is evaluated, as well as handling
/// immediately-invoked closures wrapping complex initializing code in field
/// initializers, we enable constant evaluation of functions.
class VMConstantEvaluator extends ConstantEvaluator {
  final TargetOS? _targetOS;
  final Map<String, Constant> _constantFields = {};

  final Class? _platformClass;
  final PragmaAnnotationParser _pragmaParser;

  VMConstantEvaluator(
      DartLibrarySupport dartLibrarySupport,
      ConstantsBackend backend,
      Component component,
      Map<String, String>? environmentDefines,
      TypeEnvironment typeEnvironment,
      ErrorReporter errorReporter,
      this._targetOS,
      this._pragmaParser,
      {bool enableTripleShift = false,
      bool enableAsserts = true,
      bool errorOnUnevaluatedConstant = false})
      : _platformClass = typeEnvironment.coreTypes.platformClass,
        super(dartLibrarySupport, backend, component, environmentDefines,
            typeEnvironment, errorReporter,
            enableTripleShift: enableTripleShift,
            // We use evaluation of const functions for getters and immediately
            // invoked closures in field initializers.
            enableConstFunctions: true,
            enableAsserts: enableAsserts,
            errorOnUnevaluatedConstant: errorOnUnevaluatedConstant,
            evaluationMode: EvaluationMode.strong) {
    // Only add Platform fields if the Platform class is part of the component
    // being evaluated.
    if (_targetOS != null && _platformClass != null) {
      _constantFields['operatingSystem'] = StringConstant(_targetOS.name);
      _constantFields['pathSeparator'] =
          StringConstant(_targetOS.pathSeparator);
    }
  }

  static VMConstantEvaluator create(
      Target target, Component component, TargetOS? targetOS,
      {bool evaluateAnnotations = true,
      bool enableTripleShift = false,
      bool enableConstructorTearOff = false,
      bool enableAsserts = true,
      bool errorOnUnevaluatedConstant = false,
      ErrorReporter? errorReporter,
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
        errorReporter ?? const SimpleErrorReporter(),
        targetOS,
        ConstantPragmaAnnotationParser(coreTypes, target),
        enableTripleShift: enableTripleShift,
        enableAsserts: enableAsserts,
        errorOnUnevaluatedConstant: errorOnUnevaluatedConstant);
  }

  bool get _hasTargetOS => _targetOS != null;

  bool _isPlatformConst(Member member) => _pragmaParser
      .parsedPragmas<ParsedPlatformConstPragma>(member.annotations)
      .isNotEmpty;

  bool shouldEvaluateMember(Member node) =>
      _hasTargetOS && _isPlatformConst(node);

  @override
  Constant visitStaticGet(StaticGet node) {
    assert(_hasTargetOS);
    final target = node.target;

    // This visitor can be called recursively while evaluating an abstraction
    // over the Platform getters and fields, so check that the visited node has
    // an appropriately annotated target.
    if (!_isPlatformConst(target)) return super.visitStaticGet(node);

    visitedLibraries.add(target.enclosingLibrary);

    if (target is Field) {
      // If this is a special Platform field that has a pre-calculated value
      // for the given operating system, just use the canonicalized value.
      if (target.enclosingClass == _platformClass) {
        final constant = _constantFields[target.name.text];
        if (constant != null) {
          return canonicalize(constant);
        }
      }

      // The base class only evaluates const fields, so the VM constant
      // evaluator must manually request the initializer be evaluated.
      // instead of just calling super.visitStaticGet(target).
      return withNewEnvironment(
          () => evaluateExpressionInContext(target, target.initializer!));
    }

    // The base class already handles constant evaluation of a getter.
    return super.visitStaticGet(node);
  }
}
