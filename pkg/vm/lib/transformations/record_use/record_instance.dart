// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/kernel/record_use.dart' show isBeingRecorded;
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/transformations/record_use/record_use.dart';

import 'constant_collector.dart';

/// Record a const instance by calling [recordConstantExpression]. After all the
/// const instances have been recorded, retrieve them using [instancesForClass].
class InstanceRecorder {
  /// Keep track of the classes which are recorded, to easily add found
  /// instances.
  final Map<Definition, List<InstanceReference>> instancesForClass = {};

  /// A function to look up the loading unit for a reference.
  final LoadingUnitLookup _loadingUnitLookup;

  /// A visitor traversing and collecting constants.
  late final ConstantCollector collector;

  /// Whether to save line and column info as well as the URI.
  //TODO(mosum): add verbose mode to enable this
  bool exactLocation = false;

  InstanceRecorder(this._loadingUnitLookup) {
    collector = ConstantCollector.collectWith(_handleConstant);
  }

  void recordConstantExpression(ast.ConstantExpression node) =>
      collector.collect(node);

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
    if (isConstructorTearOffLowering(constant.target)) {
      final effectiveTarget = getConstructorEffectiveTarget(constant.target);
      final cls = effectiveTarget.enclosingClass as ast.Class;
      final instance = ConstructorTearoffReference(
        definition: _definitionFromMember(effectiveTarget),
        loadingUnits: [_loadingUnitLookup(context)],
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
      definition: _definitionFromMember(effectiveTarget),
      loadingUnits: [_loadingUnitLookup(context)],
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
      definition: _definitionFromMember(effectiveTarget),
      loadingUnits: [_loadingUnitLookup(context)],
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
    final positionalArguments =
        arguments.positional
            .map((argument) => evaluateExpression(argument))
            .toList();
    final namedArguments = <String, MaybeConstant>{};
    for (final argument in arguments.named) {
      namedArguments[argument.name] = evaluateExpression(argument.value);
    }

    final instance = InstanceCreationReference(
      definition: _definitionFromMember(target),
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
      loadingUnits: [_loadingUnitLookup(context)],
    );
    _addToUsage(cls, instance);
  }

  void recordConstructorTearOff(ast.ConstructorTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      final effectiveTarget = getConstructorEffectiveTarget(target);
      final cls = effectiveTarget.enclosingClass as ast.Class;
      final instance = ConstructorTearoffReference(
        definition: _definitionFromMember(effectiveTarget),
        loadingUnits: [_loadingUnitLookup(node)],
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
        definition: _definitionFromMember(effectiveTarget),
        loadingUnits: [_loadingUnitLookup(node)],
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
        definition: _definitionFromMember(effectiveTarget),
        loadingUnits: [_loadingUnitLookup(node)],
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
            loadingUnits: [_loadingUnitLookup(node)],
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
    final identifier = _definitionFromClass(cls);
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
    loadingUnits: [_loadingUnitLookup(expression)],
  );

  /// Returns a [Definition] for [cls].
  ///
  /// Currently only works for top-level classes and enums. If support for more
  /// complex definition paths is needed (e.g. nested classes), it should be
  /// added here.
  Definition _definitionFromClass(ast.Class cls) {
    final enclosingLibrary = cls.enclosingLibrary;
    final importUri = enclosingLibrary.importUri.toString();

    return Definition(importUri, [className(cls)]);
  }

  /// Returns a [Definition] for [target].
  ///
  /// Currently only works for constructors and factories in top-level classes
  /// and enums. If support for more complex definition paths is needed, it
  /// should be added here.
  Definition _definitionFromMember(ast.Member target) {
    final cls = target.enclosingClass!;
    final importUri = cls.enclosingLibrary.importUri.toString();

    return Definition(importUri, [
      className(cls),
      Name(target.name.text, kind: DefinitionKind.constructorKind),
    ]);
  }
}
