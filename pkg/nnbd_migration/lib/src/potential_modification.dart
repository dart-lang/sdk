// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// Records information about how a conditional expression or statement might
/// need to be modified.
class ConditionalModification extends PotentialModification {
  final int offset;

  final int end;

  final bool isStatement;

  final ConditionalDiscard discard;

  final _KeepNode condition;

  final _KeepNode thenStatement;

  final _KeepNode elseStatement;

  factory ConditionalModification(AstNode node, ConditionalDiscard discard) {
    if (node is IfStatement) {
      return ConditionalModification._(
          node.offset,
          node.end,
          node is Statement,
          discard,
          _KeepNode(node.condition),
          _KeepNode(node.thenStatement),
          node.elseStatement == null ? null : _KeepNode(node.elseStatement));
    } else if (node is IfElement) {
      return ConditionalModification._(
          node.offset,
          node.end,
          node is Statement,
          discard,
          _KeepNode(node.condition),
          _KeepNode(node.thenElement),
          node.elseElement == null ? null : _KeepNode(node.elseElement));
    } else {
      throw new UnimplementedError('TODO(paulberry)');
    }
  }

  ConditionalModification._(this.offset, this.end, this.isStatement,
      this.discard, this.condition, this.thenStatement, this.elseStatement);

  @override
  NullabilityFixDescription get description => discard.keepFalse
      ? NullabilityFixDescription.discardThen
      : (elseStatement == null
          ? NullabilityFixDescription.discardCondition
          : NullabilityFixDescription.discardElse);

  @override
  bool get isEmpty => discard.keepTrue && discard.keepFalse;

  @override
  Iterable<SourceEdit> get modifications {
    if (isEmpty) return const [];
    // TODO(paulberry): move the following logic into DartEditBuilder (see
    // dartbug.com/35872).
    var result = <SourceEdit>[];
    var keepNodes = <_KeepNode>[];
    if (!discard.pureCondition) {
      keepNodes.add(condition); // TODO(paulberry): test
    }
    if (discard.keepTrue) {
      keepNodes.add(thenStatement); // TODO(paulberry): test
    }
    if (discard.keepFalse && elseStatement != null) {
      keepNodes.add(elseStatement); // TODO(paulberry): test
    }
    // TODO(paulberry): test thoroughly
    for (int i = 0; i < keepNodes.length; i++) {
      var keepNode = keepNodes[i];
      if (i == 0 && keepNode.offset != offset) {
        result.add(SourceEdit(offset, 0, '/* '));
      }
      if (i != 0 || keepNode.offset != offset) {
        result.add(SourceEdit(keepNode.offset, 0, '*/ '));
      }
      if (i != keepNodes.length - 1 || keepNode.end != end) {
        result.add(SourceEdit(keepNode.end, 0,
            keepNode.isExpression && isStatement ? '; /*' : ' /*'));
      }
      if (i == keepNodes.length - 1 && keepNode.end != end) {
        result.add(SourceEdit(end, 0, ' */'));
      }
    }
    return result;
  }

  @override
  Iterable<FixReasonInfo> get reasons => discard.reasons;
}

/// Records information about the possible addition of a `?` suffix to a type in
/// the source code.
class PotentiallyAddQuestionSuffix extends PotentialModification {
  final NullabilityNode node;
  final DartType type;
  final int _offset;

  PotentiallyAddQuestionSuffix(this.node, this.type, this._offset);

  @override
  NullabilityFixDescription get description =>
      NullabilityFixDescription.makeTypeNullable(
          type.getDisplayString(withNullability: false));

  @override
  bool get isEmpty => !node.isNullable;

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? [] : [SourceEdit(_offset, 0, '?')];

  @override
  Iterable<FixReasonInfo> get reasons => [node];
}

/// Records information about the possible addition of a `required` keyword
/// to the source code.
class PotentiallyAddRequired extends PotentialModification {
  final NullabilityNode _node;

  final int _offset;
  final String className;
  final String methodName;
  final String parameterName;

  factory PotentiallyAddRequired(
      DefaultFormalParameter parameter, NullabilityNode node) {
    final element = parameter.declaredElement;
    final method = element.enclosingElement;
    final cls = method.enclosingElement;
    return PotentiallyAddRequired._(
        node, parameter.offset, cls.name, method.name, element.name);
  }

  PotentiallyAddRequired._(this._node, this._offset, this.className,
      this.methodName, this.parameterName);

  @override
  NullabilityFixDescription get description =>
      NullabilityFixDescription.addRequired(
          className, methodName, parameterName);

  @override
  bool get isEmpty => _node.isNullable;

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? const [] : [SourceEdit(_offset, 0, 'required ')];

  @override
  Iterable<FixReasonInfo> get reasons => [_node];
}

/// Interface used by data structures representing potential modifications to
/// the code being migrated.
abstract class PotentialModification {
  /// Gets a [NullabilityFixDescription] describing this modification.
  NullabilityFixDescription get description;

  bool get isEmpty;

  /// Gets the individual migrations that need to be done, considering the
  /// solution to the constraint equations.
  Iterable<SourceEdit> get modifications;

  /// Gets the reasons for this potential modification.
  Iterable<FixReasonInfo> get reasons;
}

/// Helper object used by [ConditionalModification] to keep track of AST nodes
/// within the conditional expression.
class _KeepNode {
  final int offset;

  final int end;

  final bool isExpression;

  factory _KeepNode(AstNode node) {
    int offset = node.offset;
    int end = node.end;
    if (node is Block && node.statements.isNotEmpty) {
      offset = node.statements.beginToken.offset;
      end = node.statements.endToken.end;
    }
    return _KeepNode._(offset, end, node is Expression);
  }

  _KeepNode._(this.offset, this.end, this.isExpression);
}
