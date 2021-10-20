// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithNullAware extends CorrectionProducer {
  /// The kind of correction to be made.
  final _CorrectionKind correctionKind;

  ReplaceWithNullAware(this.correctionKind);

  @override
  // NNBD makes this obsolete in the "chain" application; for the "single"
  // application, there are other options and a null-aware replacement is not
  // predictably correct.
  bool get canBeAppliedInBulk => false;

  @override
  // NNBD makes this obsolete in the "chain" application; for the "single"
  // application, there are other options and a null-aware replacement is not
  // predictably correct.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_NULL_AWARE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (correctionKind == _CorrectionKind.inChain) {
      await _computeInChain(builder);
    } else if (correctionKind == _CorrectionKind.single) {
      await _computeSingle(builder);
    }
  }

  Future<void> _computeInChain(ChangeBuilder builder) async {
    var node = coveredNode;
    if (node is Expression) {
      final node_final = node;
      await builder.addDartFileEdit(file, (builder) {
        var parent = node_final.parent;
        while (parent != null) {
          if (parent is MethodInvocation && parent.target == node) {
            var operator = parent.operator;
            if (operator != null) {
              builder.addSimpleReplacement(range.token(operator), '?.');
            }
          } else if (parent is PropertyAccess && parent.target == node) {
            builder.addSimpleReplacement(range.token(parent.operator), '?.');
          } else {
            break;
          }
          node = parent;
          parent = node?.parent;
        }
      });
    }
  }

  Future<void> _computeSingle(ChangeBuilder builder) async {
    var node = coveredNode?.parent;
    if (node is MethodInvocation) {
      var operator = node.operator;
      if (operator != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(operator), '?.');
        });
      }
    } else if (node is PrefixedIdentifier) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(node.period), '?.');
      });
    } else if (node is PropertyAccess) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(node.operator), '?.');
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithNullAware inChain() =>
      ReplaceWithNullAware(_CorrectionKind.inChain);

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithNullAware single() =>
      ReplaceWithNullAware(_CorrectionKind.single);
}

/// The kinds of corrections supported by [ReplaceWithNullAware].
enum _CorrectionKind {
  inChain,
  single,
}
