// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_helper.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// A completion pass that will create candidate suggestions based on the
/// elements in scope in the library containing the selection, as well as
/// suggestions that are not related to elements, such as keywords.
//
// The visit methods in this class are allowed to visit the parent of the
// visited node (the covering node), but are not allowed to visit children. This
// rule will prevent the introduction of an infinite loop between the visit
// methods of the parent and child.
class InScopeCompletionPass extends SimpleAstVisitor<void> {
  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// A helper that can be used to suggest keywords.
  late final KeywordHelper keywordHelper = KeywordHelper(
      collector: collector, featureSet: featureSet, offset: offset);

  /// Initialize a newly created completion visitor that can use the [state] to
  /// add candidate suggestions to the [collector].
  InScopeCompletionPass({required this.state, required this.collector});

  /// Return the feature set that applies to the library for which completions
  /// are being computed.
  FeatureSet get featureSet => state.libraryElement.featureSet;

  /// Return the offset at which completion was requested.
  int get offset => state.selection.offset;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    var expression = node.expression;
    if (expression is SimpleIdentifier) {
      node.parent?.accept(this);
    }
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    final offset = this.offset;
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'ListLiteral_element';
      _forCollectionElement(node, node.elements);
    }
  }

  @override
  void visitListPattern(ListPattern node) {
    collector.completionLocation = 'ListPattern_element';
    _forPattern();
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    collector.completionLocation = 'LogicalAndPattern_rightOperand';
    _forPattern();
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    collector.completionLocation = 'LogicalOrPattern_rightOperand';
    _forPattern();
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    if (offset == node.offset) {
      node.parent?.accept(this);
    } else if (offset >= node.separator.end) {
      collector.completionLocation = 'MapLiteralEntry_value';
    }
  }

  @override
  void visitMapPattern(MapPattern node) {
    collector.completionLocation = 'MapPatternEntry_key';
    _forConstantExpression(node);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    var separator = node.separator;
    if (separator.isSynthetic || offset <= separator.offset) {
      node.parent?.accept(this);
      return;
    }
    collector.completionLocation = 'MapPatternEntry_value';
    _forPattern();
  }

  @override
  void visitParenthesizedPattern(ParenthesizedPattern node) {
    collector.completionLocation = 'ParenthesizedPattern_expression';
    _forPattern();
  }

  @override
  void visitPatternField(PatternField node) {
    collector.completionLocation = 'PatternField_pattern';
    var name = node.name;
    if (name == null) {
      var parent = node.parent;
      if (parent is ObjectPattern) {
        // TODO(brianwilkerson) Suggest the properties of the object.
        // _addPropertiesOfType(parent.type.type);
      } else if (parent is RecordPattern) {
        _forPattern();
        // TODO(brianwilkerson) If we know the expected record type, add the
        //  names of any named fields.
      }
    } else if (name.name == null) {
      _forVariablePattern();
    } else {
      _forPattern();
    }
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    collector.completionLocation = 'RecordLiteral_fields';
    _forExpression(node);
  }

  @override
  void visitRestPatternElement(RestPatternElement node) {
    collector.completionLocation = 'RestPatternElement_pattern';
    _forPattern();
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    _forExpression(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var offset = this.offset;
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'SetOrMapLiteral_element';
      _forCollectionElement(node, node.elements);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    node.parent?.accept(this);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of an element in a collection [literal], with the given
  /// [elements].
  void _forCollectionElement(
      TypedLiteral literal, NodeList<CollectionElement> elements) {
    keywordHelper.addCollectionElementKeywords(literal, elements);
    // TODO(brianwilkerson) Suggest the variables available in the current
    //  scope.
    // _addVariablesInScope(literal);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a constant expression. The [node] provides context to
  /// determine which keywords to include.
  void _forConstantExpression(AstNode node) {
    var inConstantContext = node is Expression && node.inConstantContext;
    keywordHelper.addConstantExpressionKeywords(
        inConstantContext: inConstantContext);
    // TODO(brianwilkerson) Suggest the variables available in the current
    //  scope.
    // _addVariablesInScope(node, mustBeConstant: true);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of an expression. The [node] provides context to determine which
  /// keywords to include.
  void _forExpression(AstNode? node) {
    keywordHelper.addExpressionKeywords(node);
    // TODO(brianwilkerson) Suggest the variables available in the current
    //  scope.
    // _addVariablesInScope(node);
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a pattern.
  void _forPattern() {
    keywordHelper.addPatternKeywords();
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a variable pattern.
  void _forVariablePattern() {
    keywordHelper.addVariablePatternKeywords();
    // TODO(brianwilkerson) Suggest the types available in the currentscope.
    // _addTypesInScope();
  }

  /// If the completion offset is at or before the offset of the [node], then
  /// visit the parent of the node.
  void _visitParentIfAtOrBeforeNode(AstNode node) {
    if (offset <= node.offset) {
      node.parent?.accept(this);
    }
  }
}
