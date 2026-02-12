// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    collector = ConstantCollector.collectWith(_collectInstance);
  }

  void recordConstantExpression(ast.ConstantExpression node) =>
      collector.collect(node);

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

  Definition _definitionFromClass(ast.Class cls) {
    final enclosingLibrary = cls.enclosingLibrary;
    final importUri = enclosingLibrary.importUri.toString();

    return Definition(importUri: importUri, name: cls.name);
  }

  InstanceReference _createInstanceReference(
    ast.ConstantExpression expression,
    ast.InstanceConstant constant,
  ) => InstanceConstantReference(
    instanceConstant: evaluateInstanceConstant(constant),
    loadingUnit: _loadingUnitLookup(expression),
  );
}
