// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/kernel/record_use.dart' as recordUse;
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/metadata/loading_units.dart';
import 'package:vm/transformations/record_use/record_use.dart';

class InstanceUseRecorder {
  final Map<ast.Class, Usage<InstanceReference>> instancesForClass = {};
  final List<LoadingUnit> _loadingUnits;
  final Uri source;

  InstanceUseRecorder(this.source, this._loadingUnits);

  void recordAnnotationUse(ast.ConstantExpression node) {
    final constant = node.constant;
    if (constant is ast.InstanceConstant) {
      if (recordUse.findRecordUseAnnotation(constant.classNode).isNotEmpty) {
        _collectUseInformation(node, constant);
      }
    }
  }

  void _collectUseInformation(
    ast.ConstantExpression node,
    ast.InstanceConstant constant,
  ) {
    // Collect the name and definition location of the invocation. This is
    // shared across multiple calls to the same method.
    final existingInstance = _getCall(constant.classNode);

    // Collect the (int, bool, double, or String) arguments passed in the call.
    existingInstance.references.add(_createInstanceReference(node, constant));
  }

  /// Collect the name and definition location of the invocation. This is
  /// shared across multiple calls to the same method.
  Usage<InstanceReference> _getCall(ast.Class cls) {
    final definition = _definitionFromClass(cls);
    return instancesForClass.putIfAbsent(
      cls,
      () => Usage(definition: definition, references: []),
    );
  }

  Definition _definitionFromClass(ast.Class cls) {
    final enclosingLibrary = cls.enclosingLibrary;
    String file = getImportUri(enclosingLibrary, source);

    return Definition(
      identifier: Identifier(importUri: file, name: cls.name),
      location: cls.location!.recordLocation(source),
      loadingUnit:
          loadingUnitForNode(cls.enclosingLibrary, _loadingUnits).toString(),
    );
  }

  InstanceReference _createInstanceReference(
    ast.ConstantExpression node,
    ast.InstanceConstant constant,
  ) =>
      InstanceReference(
        location: node.location!.recordLocation(source),
        instanceConstant: _fieldsFromConstant(constant),
        loadingUnit: loadingUnitForNode(node, _loadingUnits).toString(),
      );

  InstanceConstant _fieldsFromConstant(ast.InstanceConstant constant) =>
      InstanceConstant(
          fields: constant.fieldValues.map(
        (key, value) => MapEntry(
          key.asField.name.text,
          evaluateConstant(value),
        ),
      ));
}
