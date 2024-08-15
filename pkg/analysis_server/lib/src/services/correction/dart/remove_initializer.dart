// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveInitializer extends ResolvedCorrectionProducer {
  @override
  final CorrectionApplicability applicability;

  /// If true, remove the `late` keyword.
  final bool _removeLate;

  /// Initialize a newly created instance that can't apply bulk and in-file
  /// fixes.
  RemoveInitializer({required super.context})
      : applicability = CorrectionApplicability.singleLocation,
        _removeLate = true;

  /// Initialize a newly created instance that can apply bulk and in-file fixes.
  RemoveInitializer.bulkFixable({required super.context})
      : applicability = CorrectionApplicability.automatically,
        _removeLate = true;

  /// Initialize a newly created instance that can't apply bulk and in-file
  /// fixes and will not remove the `late` keyword if present.
  RemoveInitializer.notLate({required super.context})
      : applicability = CorrectionApplicability.singleLocation,
        _removeLate = false;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_INITIALIZER;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_INITIALIZER_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node.thisOrAncestorOfType<DefaultFormalParameter>();
    if (parameter != null) {
      // Handle formal parameters with default values.
      var identifier = parameter.name;
      var defaultValue = parameter.defaultValue;
      if (identifier != null && defaultValue != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            range.endEnd(identifier, defaultValue),
          );
        });
      }
    } else {
      // Handle variable declarations with default values.
      var variable = node.thisOrAncestorOfType<VariableDeclaration>();
      var initializer = variable?.initializer;
      if (variable != null && initializer != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            range.endEnd(variable.name, initializer),
          );
        });
        // Delete the `late` keyword if present.
        if (_removeLate && variable.isLate) {
          var parent = node.parent;
          if (parent != null) {
            await builder.addDartFileEdit(file, (builder) {
              builder.addDeletion(
                range.startLength(
                    parent.beginToken, parent.beginToken.length + 1),
              );
            });
          }
        }
      } else {
        var initializer =
            node.thisOrAncestorOfType<ConstructorFieldInitializer>();
        var parent = initializer?.parent;
        if (parent is ConstructorDeclaration) {
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(
                range.nodeInList(parent.initializers, initializer!));
          });
        }
      }
    }
  }
}
