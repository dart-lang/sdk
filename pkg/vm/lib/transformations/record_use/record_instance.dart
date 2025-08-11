// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/metadata/loading_units.dart';
import 'package:vm/transformations/record_use/record_use.dart';

import 'constant_collector.dart';

/// Record a const instance by calling [recordConstantExpression]. After all the
/// const instances have been recorded, retrieve them using [instancesForClass].
class InstanceRecorder {
  /// Keep track of the classes which are recorded, to easily add found
  /// instances.
  final Map<Identifier, List<InstanceReference>> instancesForClass = {};

  /// Keep track of the calls which are recorded, to easily add newly found
  /// ones.
  final Map<Identifier, String> loadingUnitForDefinition = {};

  /// The ordered list of loading units to retrieve the loading unit index from.
  final List<LoadingUnit> _loadingUnits;

  /// The source uri to base relative URIs off of.
  final Uri _source;

  /// A visitor traversing and collecting constants.
  late final ConstantCollector collector;

  /// Whether to save line and column info as well as the URI.
  //TODO(mosum): add verbose mode to enable this
  bool exactLocation = false;

  InstanceRecorder(this._source, this._loadingUnits) {
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
    var (:identifier, :loadingUnit) = _definitionFromClass(cls);
    instancesForClass.update(
      identifier,
      (usage) => usage..add(instance),
      ifAbsent: () => [instance],
    );
    loadingUnitForDefinition.update(identifier, (value) {
      assert(value == loadingUnit);
      return value;
    }, ifAbsent: () => loadingUnit);
  }

  ({Identifier identifier, String loadingUnit}) _definitionFromClass(
    ast.Class cls,
  ) {
    final enclosingLibrary = cls.enclosingLibrary;
    final file = getImportUri(enclosingLibrary, _source);

    return (
      identifier: Identifier(importUri: file, name: cls.name),
      loadingUnit:
          loadingUnitForNode(cls.enclosingLibrary, _loadingUnits).toString(),
    );
  }

  InstanceReference _createInstanceReference(
    ast.ConstantExpression expression,
    ast.InstanceConstant constant,
  ) => InstanceReference(
    location: expression.location!.recordLocation(_source, exactLocation),
    instanceConstant: evaluateInstanceConstant(constant),
    loadingUnit: loadingUnitForNode(expression, _loadingUnits).toString(),
  );
}
