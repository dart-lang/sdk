// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/kernel/record_use.dart' show isBeingRecorded;
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use.dart';
import 'package:vm/transformations/record_use/record_call.dart';
import 'package:vm/transformations/record_use/record_use.dart';

import 'constant_collector.dart';

/// Record a const instance by calling [recordConstantExpression]. After all the
/// const instances have been recorded, retrieve them using [instancesForClass].
class InstanceRecorder {
  /// Keep track of the classes which are recorded, to easily add found
  /// instances.
  final Map<DefinitionWithInstances, List<InstanceReference>>
  instancesForClass = {};

  /// A function to look up the loading unit for a reference.
  final LoadingUnitLookup _loadingUnitLookup;

  /// A map to look up the collector for each loading unit.
  ///
  /// This is used to correctly record constants shared across multiple loading
  /// units. Each unit's collector maintains its own set of "seen" constants.
  // TODO: A more efficient approach would be to cache the results per constant
  // and "replay" them for new loading units instead of re-traversing. But this
  // would require a deep integration between the ConstantCollector and
  // InstanceRecorder.
  final Map<LoadingUnit, ConstantCollector> _collectorsByUnit = {};

  /// Whether to save line and column info as well as the URI.
  //TODO(mosum): add verbose mode to enable this
  bool exactLocation = false;

  InstanceRecorder(this._loadingUnitLookup);

  void recordConstantExpression(ast.ConstantExpression node) {
    final unit = _loadingUnitLookup(node);
    final collector = _collectorsByUnit.putIfAbsent(
      unit,
      () => ConstantCollector.collectWith(_handleConstant),
    );
    collector.collect(node);
  }

  void _handleConstant(ast.ConstantExpression context, ast.Constant constant) {
    if (constant is ast.InstanceConstant) {
      _collectInstance(context, constant);
    } else if (constant is ast.ConstructorTearOffConstant) {
      _collectConstructorTearOffConstant(context, constant);
    } else if (constant is ast.RedirectingFactoryTearOffConstant) {
      _collectRedirectingFactoryTearOffConstant(context, constant);
    } else if (constant is ast.StaticTearOffConstant) {
      _collectStaticTearOffConstant(context, constant);
    }
  }

  void _collectStaticTearOffConstant(
    ast.ConstantExpression context,
    ast.StaticTearOffConstant constant,
  ) {
    if (isTearOffLowering(constant.target)) {
      final effectiveTarget = getConstructorEffectiveTarget(constant.target);
      final cls = effectiveTarget.enclosingClass as ast.Class;
      final instance = ConstructorTearoffReference(
        definition: definitionFromMember(effectiveTarget),
        loadingUnit: _loadingUnitLookup(context),
      );
      _addToUsage(cls, instance);
    }
  }

  void _collectRedirectingFactoryTearOffConstant(
    ast.ConstantExpression context,
    ast.RedirectingFactoryTearOffConstant constant,
  ) {
    final effectiveTarget = getConstructorEffectiveTarget(constant.target);
    final cls = effectiveTarget.enclosingClass!;
    final instance = ConstructorTearoffReference(
      definition: definitionFromMember(effectiveTarget),
      loadingUnit: _loadingUnitLookup(context),
    );
    _addToUsage(cls, instance);
  }

  void _collectConstructorTearOffConstant(
    ast.ConstantExpression context,
    ast.ConstructorTearOffConstant constant,
  ) {
    final effectiveTarget = getConstructorEffectiveTarget(constant.target);
    final cls = effectiveTarget.enclosingClass as ast.Class;
    final instance = ConstructorTearoffReference(
      definition: definitionFromMember(effectiveTarget),
      loadingUnit: _loadingUnitLookup(context),
    );
    _addToUsage(cls, instance);
  }

  void recordConstructorInvocation(ast.ConstructorInvocation node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      _recordCreation(
        getConstructorEffectiveTarget(target),
        node.arguments,
        node,
      );
    }
  }

  void recordRedirectingFactoryInvocation(ast.StaticInvocation node) {
    final target = node.target;
    assert(target.isRedirectingFactory);
    if (isBeingRecorded(target)) {
      _recordCreation(
        getConstructorEffectiveTarget(target),
        node.arguments,
        node,
      );
    }
  }

  void _recordCreation(
    ast.Member target,
    ast.Arguments arguments,
    ast.TreeNode context,
  ) {
    final cls = target.enclosingClass!;
    final positionalArguments = arguments.positional
        .map((argument) => evaluateExpression(argument))
        .toList();
    final namedArguments = <String, MaybeConstant>{};
    for (final argument in arguments.named) {
      namedArguments[argument.name] = evaluateExpression(argument.value);
    }

    // Fill up with the default values
    final function = target is ast.Procedure
        ? target.function
        : (target as ast.Constructor).function;
    for (final parameter in function.namedParameters) {
      final initializer = parameter.initializer;
      final name = parameter.name;
      if (initializer != null &&
          name != null &&
          !namedArguments.containsKey(name)) {
        namedArguments[name] = evaluateExpression(initializer);
      }
    }
    for (
      var i = positionalArguments.length;
      i < function.positionalParameters.length;
      i++
    ) {
      final parameter = function.positionalParameters[i];
      final initializer = parameter.initializer;
      if (initializer != null) {
        positionalArguments.add(evaluateExpression(initializer));
      }
    }

    final instance = InstanceCreationReference(
      definition: definitionFromMember(target),
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
      loadingUnit: _loadingUnitLookup(context),
    );
    _addToUsage(cls, instance);
  }

  void recordConstructorTearOff(ast.ConstructorTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      final effectiveTarget = getConstructorEffectiveTarget(target);
      final cls = effectiveTarget.enclosingClass as ast.Class;
      final instance = ConstructorTearoffReference(
        definition: definitionFromMember(effectiveTarget),
        loadingUnit: _loadingUnitLookup(node),
      );
      _addToUsage(cls, instance);
    }
  }

  void recordLoweredConstructorTearOff(ast.StaticTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      final effectiveTarget = getConstructorEffectiveTarget(target);
      final cls = effectiveTarget.enclosingClass as ast.Class;
      final instance = ConstructorTearoffReference(
        definition: definitionFromMember(effectiveTarget),
        loadingUnit: _loadingUnitLookup(node),
      );
      _addToUsage(cls, instance);
    }
  }

  void recordRedirectingFactoryTearOff(ast.RedirectingFactoryTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      final effectiveTarget = getConstructorEffectiveTarget(target);
      final cls = effectiveTarget.enclosingClass!;
      final instance = ConstructorTearoffReference(
        definition: definitionFromMember(effectiveTarget),
        loadingUnit: _loadingUnitLookup(node),
      );
      _addToUsage(cls, instance);
    }
  }

  void recordStaticGet(ast.StaticGet node) {
    final target = node.target;
    // Record enum const instance field accesses.
    if (target is ast.Field && isBeingRecorded(target)) {
      final initializer = target.initializer;
      if (initializer is ast.ConstantExpression) {
        final constant = initializer.constant;
        if (constant is ast.InstanceConstant) {
          final instance = InstanceConstantReference(
            instanceConstant: evaluateConstant(constant),
            loadingUnit: _loadingUnitLookup(node),
          );
          _addToUsage(constant.classNode, instance);
        }
      }
    }
  }

  void _collectInstance(
    ast.ConstantExpression expression,
    ast.InstanceConstant constant,
  ) {
    final instance = _createInstanceReference(expression, constant);
    _addToUsage(constant.classNode, instance);
  }

  /// Collect the name and definition location of the invocation. This is
  /// shared across multiple calls to the same method.
  void _addToUsage(ast.Class cls, InstanceReference instance) {
    final identifier = definitionFromClass(cls) as DefinitionWithInstances;
    // TODO: Merge loading units if an identical InstanceReference already
    // exists.
    instancesForClass.update(
      identifier,
      (usage) => usage..add(instance),
      ifAbsent: () => [instance],
    );
  }

  InstanceReference _createInstanceReference(
    ast.ConstantExpression expression,
    ast.InstanceConstant constant,
  ) => InstanceConstantReference(
    instanceConstant: evaluateConstant(constant),
    loadingUnit: _loadingUnitLookup(expression),
  );
}
