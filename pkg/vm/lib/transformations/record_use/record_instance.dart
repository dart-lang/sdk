// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/kernel/record_use.dart' show isBeingRecorded;
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/constructor_tearoff_lowering.dart';
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
      final instance = ConstructorTearoffReference(
        loadingUnits: [_loadingUnitLookup(context)],
      );
      _addToUsage(constant.target.enclosingClass as ast.Class, instance);
    }
  }

  void _collectRedirectingFactoryTearOffConstant(
    ast.ConstantExpression context,
    ast.RedirectingFactoryTearOffConstant constant,
  ) {
    final instance = ConstructorTearoffReference(
      loadingUnits: [_loadingUnitLookup(context)],
    );
    _addToUsage(constant.target.enclosingClass!, instance);
  }

  void _collectConstructorTearOffConstant(
    ast.ConstantExpression context,
    ast.ConstructorTearOffConstant constant,
  ) {
    final instance = ConstructorTearoffReference(
      loadingUnits: [_loadingUnitLookup(context)],
    );
    _addToUsage(constant.target.enclosingClass as ast.Class, instance);
  }

  void recordConstructorInvocation(ast.ConstructorInvocation node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      _recordCreation(target.enclosingClass, node.arguments, node);
    }
  }

  void recordRedirectingFactoryInvocation(ast.StaticInvocation node) {
    final target = node.target;
    assert(target.isRedirectingFactory);
    if (isBeingRecorded(target)) {
      ast.Member ultimateTarget = target;
      while (ultimateTarget is ast.Procedure &&
          ultimateTarget.isRedirectingFactory) {
        ultimateTarget =
            ultimateTarget.function.redirectingFactoryTarget!.target!;
      }
      _recordCreation(ultimateTarget.enclosingClass!, node.arguments, node);
    }
  }

  void _recordCreation(
    ast.Class cls,
    ast.Arguments arguments,
    ast.TreeNode context,
  ) {
    final positionalArguments =
        arguments.positional
            .map((argument) => evaluateExpression(argument))
            .toList();
    final namedArguments = <String, MaybeConstant>{};
    for (final argument in arguments.named) {
      namedArguments[argument.name] = evaluateExpression(argument.value);
    }

    final instance = InstanceCreationReference(
      positionalArguments: positionalArguments,
      namedArguments: namedArguments,
      loadingUnits: [_loadingUnitLookup(context)],
    );
    _addToUsage(cls, instance);
  }

  void recordConstructorTearOff(ast.ConstructorTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      final instance = ConstructorTearoffReference(
        loadingUnits: [_loadingUnitLookup(node)],
      );
      _addToUsage(target.enclosingClass as ast.Class, instance);
    }
  }

  void recordLoweredConstructorTearOff(ast.StaticTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      final instance = ConstructorTearoffReference(
        loadingUnits: [_loadingUnitLookup(node)],
      );
      _addToUsage(target.enclosingClass as ast.Class, instance);
    }
  }

  void recordRedirectingFactoryTearOff(ast.RedirectingFactoryTearOff node) {
    final target = node.target;
    if (isBeingRecorded(target)) {
      ast.Member ultimateTarget = target;
      while (ultimateTarget is ast.Procedure &&
          ultimateTarget.isRedirectingFactory) {
        ultimateTarget =
            ultimateTarget.function.redirectingFactoryTarget!.target!;
      }
      final instance = ConstructorTearoffReference(
        loadingUnits: [_loadingUnitLookup(node)],
      );
      _addToUsage(ultimateTarget.enclosingClass!, instance);
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
    instanceConstant: evaluateInstanceConstant(constant),
    loadingUnits: [_loadingUnitLookup(expression)],
  );

  Definition _definitionFromClass(ast.Class cls) {
    final enclosingLibrary = cls.enclosingLibrary;
    final importUri = enclosingLibrary.importUri.toString();

    return Definition(importUri, [
      Name(cls.name, kind: DefinitionKind.classKind),
    ]);
  }
}
