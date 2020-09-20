// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_manager.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
    for (var set in _availableTransformSetsForLibrary(library)) {
      for (var transform in set.transformsFor(name, importedUris)) {
        yield DataDrivenFix(transform);
      }
    }
  }

  /// Return the name of the element that was changed.
  String get _name {
    var node = this.node;
    if (node is SimpleIdentifier) {
      return node.name;
    } else if (node is ConstructorName) {
      return node.name.name;
    } else if (node is NamedType) {
      return node.name.name;
    } else if (node is TypeArgumentList) {
      var parent = node.parent;
      if (parent is MethodInvocation) {
        return parent.methodName.name;
      } else if (parent is ExtensionOverride) {
        return parent.extensionName.name;
      }
    } else if (node is ArgumentList) {
      var parent = node.parent;
      if (parent is MethodInvocation) {
        return parent.methodName.name;
      } else if (parent is ExtensionOverride) {
        return parent.extensionName.name;
      }
    }
    return null;
  }

  /// Return the transform sets that are available for fixing issues in the
  /// given [library].
  List<TransformSet> _availableTransformSetsForLibrary(LibraryElement library) {
    if (transformSetsForTests != null) {
      return transformSetsForTests;
    }
    return TransformSetManager.instance.forLibrary(library);
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

  /// Return a description of the element that was changed.
  ElementDescriptor get element => _transform.element;

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
