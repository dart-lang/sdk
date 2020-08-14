// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';

class DataDriven extends MultiCorrectionProducer {
  /// The transform sets used by the current test.
  @visibleForTesting
  static List<TransformSet> transformSetsForTests;

  @override
  Iterable<CorrectionProducer> get producers sync* {
    var name = _name;
    var importedUris = <String>[];
    var library = resolvedResult.libraryElement;
    for (var importElement in library.imports) {
      // TODO(brianwilkerson) Filter based on combinators to help avoid making
      //  invalid suggestions.
      importedUris.add(importElement.uri);
    }
    for (var set in _availableTransformSets) {
      for (var transform in set.transformsFor(name, importedUris)) {
        yield DataDrivenFix(transform);
      }
    }
  }

  List<TransformSet> get _availableTransformSets {
    if (transformSetsForTests != null) {
      return transformSetsForTests;
    }
    // TODO(brianwilkerson) This data needs to be cached somewhere and updated
    //  when the `package_config.json` file for an analysis context is modified.
    return <TransformSet>[];
  }

  /// Return the name that was changed.
  String get _name {
    var node = this.node;
    if (node is SimpleIdentifier) {
      return node.name;
    } else if (node is ConstructorName) {
      return node.name.name;
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static DataDriven newInstance() => DataDriven();
}

/// A correction processor that can make one of the possible change computed by
/// the [DataDriven] producer.
class DataDrivenFix extends CorrectionProducer {
  /// The transform being applied to implement this fix.
  final Transform _transform;

  DataDrivenFix(this._transform);

  @override
  List<Object> get fixArguments => [_transform.title];

  @override
  FixKind get fixKind => DartFixKind.DATA_DRIVEN;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var changes = _transform.changes;
    var data = <Object>[];
    for (var change in changes) {
      var result = change.validate(this);
      if (result == null) {
        return;
      }
      data.add(result);
    }
    await builder.addDartFileEdit(file, (builder) {
      for (var i = 0; i < changes.length; i++) {
        changes[i].apply(builder, this, data[i]);
      }
    });
  }
}
