// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/convert_argument_to_type_argument_change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/rename_change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
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
        yield _DataDrivenFix(transform);
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
class _DataDrivenFix extends CorrectionProducer {
  final Transform _transform;

  _DataDrivenFix(this._transform);

  @override
  List<Object> get fixArguments => [_transform.title];

  @override
  FixKind get fixKind => DartFixKind.DATA_DRIVEN;

  /// Return the node representing the name that was changed.
  SimpleIdentifier get _nameNode {
    var node = this.node;
    if (node is SimpleIdentifier) {
      return node;
    } else if (node is ConstructorName) {
      return node.name;
    }
    throw StateError('Unexpected class of node: ${node.runtimeType}');
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // TODO(brianwilkerson) Consider a validation loop in which we validate that
    //  all of the changes can be applied before we start applying any of them.
    await builder.addDartFileEdit(file, (builder) {
      for (var change in _transform.changes) {
        // TODO(brianwilkerson) Consider moving the logic for each change into
        //  the change to avoid having too much logic here.
        //    change.apply(builder, this);
        if (change is ConvertArgumentToTypeArgumentChange) {
          var parent = node.parent;
          if (parent is MethodInvocation) {
            var arguments = parent.argumentList.arguments;
            var argumentIndex = change.argumentIndex;
            if (argumentIndex >= arguments.length) {
              return;
            }
            var argument = arguments[argumentIndex];
            if (argument is! SimpleIdentifier) {
              return;
            }
            // TODO(brianwilkerson) Generalize this into a utility to add an
            //  element to a list.
            var typeArguments = parent.typeArguments;
            var typeArgumentIndex = change.typeArgumentIndex;
            if (typeArguments == null) {
              // Adding the first type argument.
              if (typeArgumentIndex != 0) {
                return;
              }
              builder.addSimpleInsertion(parent.argumentList.offset,
                  '<${(argument as SimpleIdentifier).name}>');
            } else {
              if (typeArgumentIndex > typeArguments.arguments.length) {
                return;
              } else if (typeArgumentIndex == 0) {
                builder.addSimpleInsertion(typeArguments.leftBracket.end,
                    '${(argument as SimpleIdentifier).name}, ');
              } else {
                var previous = typeArguments.arguments[typeArgumentIndex - 1];
                builder.addSimpleInsertion(
                    previous.end, ', ${(argument as SimpleIdentifier).name}');
              }
            }
            builder.addDeletion(range.nodeInList(arguments, argument));
          }
        } else if (change is RenameChange) {
          builder.addSimpleReplacement(range.node(_nameNode), change.newName);
        }
      }
    });
  }
}
