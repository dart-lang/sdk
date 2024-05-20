// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ReplaceWithNullAware extends ResolvedCorrectionProducer {
  /// The kind of correction to be made.
  final _CorrectionKind _correctionKind;

  /// The operator to replace.
  String _operator = '.';

  ReplaceWithNullAware.inChain() : _correctionKind = _CorrectionKind.inChain;

  ReplaceWithNullAware.single() : _correctionKind = _CorrectionKind.single;

  @override
  CorrectionApplicability get applicability =>
      // NNBD makes this obsolete in the "chain" application; for the "single"
      // application, there are other options and a null-aware replacement is
      // not predictably correct.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_operator, '?$_operator'];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_NULL_AWARE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_correctionKind == _CorrectionKind.inChain) {
      await _computeInChain(builder);
    } else if (_correctionKind == _CorrectionKind.single) {
      await _computeSingle(builder);
    }
  }

  Future<void> _computeInChain(ChangeBuilder builder) async {
    var node = coveredNode;
    if (node is Expression) {
      var node_final = node;
      await builder.addDartFileEdit(file, (builder) {
        var parent = node_final.parent;
        while (parent != null) {
          if (parent is MethodInvocation && parent.target == node) {
            var operator = parent.operator;
            if (operator != null) {
              builder.addSimpleInsertion(operator.offset, '?');
            }
          } else if (parent is PropertyAccess && parent.target == node) {
            builder.addSimpleInsertion(parent.operator.offset, '?');
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
    if (node is CascadeExpression) {
      node = node.cascadeSections.first;
    } else {
      var coveredNode = this.coveredNode;
      if (coveredNode is IndexExpression) {
        await _insert(builder, coveredNode.leftBracket);
        return;
      }
      var parent = node?.parent;
      if (parent is CascadeExpression) {
        node = parent.cascadeSections.first;
      }
    }
    if (node is MethodInvocation) {
      await _insert(builder, node.operator);
    } else if (node is PrefixedIdentifier) {
      await _insert(builder, node.period);
    } else if (node is PropertyAccess) {
      await _insert(builder, node.operator);
    } else if (node is IndexExpression) {
      await _insert(builder, node.period);
    }
  }

  Future<void> _insert(ChangeBuilder builder, Token? token) async {
    if (token != null) {
      _operator = token.lexeme;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(token.offset, '?');
      });
    }
  }
}

/// The kinds of corrections supported by [ReplaceWithNullAware].
enum _CorrectionKind {
  inChain,
  single,
}
