// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/metadata/loading_units.dart';
import 'package:vm/transformations/record_use/record_use.dart';

import 'constant_collector.dart';

/// Record a const instance by calling [recordConstantExpression]. After all the
/// const instances have been recorded, retrieve them using [foundInstances].
class InstanceRecorder {
  /// The collection of recorded instances found so far.
  Iterable<Usage<InstanceReference>> get foundInstances =>
      _instancesForClass.values;

  /// Keep track of the classes which are recorded, to easily add found
  /// instances.
  final Map<ast.Class, Usage<InstanceReference>> _instancesForClass = {};

  /// The ordered list of loading units to retrieve the loading unit index from.
  final List<LoadingUnit> _loadingUnits;

  /// The source uri to base relative URIs off of.
  final Uri _source;

  /// A visitor traversing and collecting constants.
  late final ConstantCollector collector;

  InstanceRecorder(this._source, this._loadingUnits) {
    collector = ConstantCollector.collectWith(_collectInstance);
  }

  void recordConstantExpression(ast.ConstantExpression node) =>
      collector.collect(node);

  void _collectInstance(
    ast.ConstantExpression expression,
    ast.InstanceConstant constant,
  ) {
    // Collect the name and definition location of the invocation. This is
    // shared across multiple calls to the same method.
    final existingInstance = _getCall(constant.classNode);

    // Collect the (int, bool, double, or String) arguments passed in the call.
    existingInstance.references
        .add(_createInstanceReference(expression, constant));
  }

  /// Collect the name and definition location of the invocation. This is
  /// shared across multiple calls to the same method.
  Usage<InstanceReference> _getCall(ast.Class cls) {
    final definition = _definitionFromClass(cls);
    return _instancesForClass[cls] ??=
        Usage(definition: definition, references: []);
  }

  Definition _definitionFromClass(ast.Class cls) {
    final enclosingLibrary = cls.enclosingLibrary;
    final file = getImportUri(enclosingLibrary, _source);

    return Definition(
      identifier: Identifier(importUri: file, name: cls.name),
      location: cls.location!.recordLocation(_source),
      loadingUnit:
          loadingUnitForNode(cls.enclosingLibrary, _loadingUnits).toString(),
    );
  }

  InstanceReference _createInstanceReference(
    ast.ConstantExpression expression,
    ast.InstanceConstant constant,
  ) =>
      InstanceReference(
        location: expression.location!.recordLocation(_source),
        instanceConstant: _fieldsFromConstant(constant),
        loadingUnit: loadingUnitForNode(expression, _loadingUnits).toString(),
      );

  InstanceConstant _fieldsFromConstant(ast.InstanceConstant constant) =>
      InstanceConstant(
        fields: constant.fieldValues.map(
          (key, value) => MapEntry(
            key.asField.name.text,
            evaluateConstant(value),
          ),
        ),
      );
}
