// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/keyword_helper.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
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

  /// Return the node that should be used as the context in which completion is
  /// occurring.
  ///
  /// This is normally the covering node, but if the covering node begins with
  /// an identifier (or keyword) and the [offset] is covered by the identifier,
  /// then we look for the highest node that also begins with the same token and
  /// use the parent of that node.
  ///
  /// This allows us more context for completing what the user might be trying
  /// to write and also reduces the complexity of the visitor and reduces the
  /// amount of code duplication.
  AstNode get _completionNode {
    var selection = state.selection;
    var coveringNode = selection.coveringNode;
    var beginToken = coveringNode.beginToken;
    if (!beginToken.isKeywordOrIdentifier ||
        !selection.isCoveredByToken(beginToken)) {
      return coveringNode;
    }
    var child = coveringNode;
    var parent = child.parent;
    while (parent != null && parent.beginToken == beginToken) {
      child = parent;
      parent = child.parent;
    }
    // The [child] is now the highest node that starts with the [beginToken].
    if (parent != null) {
      return parent;
    }
    return child;
  }

  /// Compute the candidate suggestions associated with this pass.
  void computeSuggestions() {
    _completionNode.accept(this);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    collector.completionLocation = 'AssignmentExpression_rightHandSide';
    _forExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    collector.completionLocation = 'AwaitExpression_expression';
    _forExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var operator = node.operator.lexeme;
    collector.completionLocation = 'BinaryExpression_${operator}_rightOperand';
    _forExpression(node);
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _forExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (offset < node.classKeyword.offset) {
      keywordHelper.addClassModifiers(node);
      return;
    }
    if (offset <= node.classKeyword.end) {
      keywordHelper.addKeyword(Keyword.CLASS);
      return;
    }
    if (offset <= node.name.end) {
      // TODO(brianwilkerson) Suggest a name for the class.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      keywordHelper.addClassDeclarationKeywords(node);
      return;
    }
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'ClassDeclaration_member';
      _forClassMember();
      var element = node.members.elementBefore(offset);
      if (element is MethodDeclaration) {
        var body = element.body;
        if (body.isEmpty) {
          keywordHelper.addFunctionBodyModifiers(body);
        }
      }
    }
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    var expression = node.expression;
    if (expression is SimpleIdentifier) {
      node.parent?.accept(this);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var separator = node.separator;
    if (separator != null) {
      if (offset >= separator.end && offset <= node.body.offset) {
        collector.completionLocation = 'ConstructorDeclaration_initializer';
        keywordHelper.addConstructorInitializerKeywords(node);
      }
    }
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (!featureSet.isEnabled(Feature.enhanced_enums)) {
      return;
    }
    if (offset < node.enumKeyword.offset) {
      // There are no modifiers for enums.
      return;
    }
    if (offset <= node.enumKeyword.end) {
      keywordHelper.addKeyword(Keyword.ENUM);
      return;
    }
    if (offset <= node.name.end) {
      // TODO(brianwilkerson) Suggest a name for the mixin.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      keywordHelper.addEnumDeclarationKeywords(node);
      return;
    }
    var rightBracket = node.rightBracket;
    if (!rightBracket.isSynthetic && offset >= rightBracket.end) {
      return;
    }
    var semicolon = node.semicolon;
    if (semicolon != null && offset >= semicolon.end) {
      collector.completionLocation = 'EnumDeclaration_member';
      _forEnumMember();
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (offset < node.extensionKeyword.offset) {
      // There are no modifiers for extensions.
      return;
    }
    if (offset <= node.extensionKeyword.end) {
      keywordHelper.addKeyword(Keyword.EXTENSION);
      return;
    }
    var name = node.name;
    if (name != null && offset <= name.end) {
      // TODO(brianwilkerson) We probably need to suggest `on`.
      // TODO(brianwilkerson) We probably need to suggest `type` when extension
      //  types are supported.
      // Don't suggest a name for the extension.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      if (node.onKeyword.isSynthetic) {
        keywordHelper.addExtensionDeclarationKeywords(node);
      } else {
        collector.completionLocation = 'ExtensionDeclaration_extendedType';
      }
      return;
    }
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'ExtensionDeclaration_member';
      _forExtensionMember();
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // If the cursor is at the beginning of the declaration, include the
    // compilation unit keywords. See dartbug.com/41039.
    var returnType = node.returnType;
    if ((returnType == null || returnType.beginToken == returnType.endToken) &&
        offset <= node.name.offset) {
      collector.completionLocation = 'FunctionDeclaration_returnType';
      keywordHelper.addKeyword(Keyword.DYNAMIC);
      keywordHelper.addKeyword(Keyword.VOID);
    }
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
  void visitMixinDeclaration(MixinDeclaration node) {
    if (offset < node.mixinKeyword.offset) {
      keywordHelper.addMixinModifiers(node);
      return;
    }
    if (offset <= node.mixinKeyword.end) {
      keywordHelper.addKeyword(Keyword.MIXIN);
      return;
    }
    if (offset <= node.name.end) {
      // TODO(brianwilkerson) Suggest a name for the mixin.
      return;
    }
    if (offset <= node.leftBracket.offset) {
      keywordHelper.addMixinDeclarationKeywords(node);
      return;
    }
    if (offset >= node.leftBracket.end && offset <= node.rightBracket.offset) {
      collector.completionLocation = 'MixinDeclaration_member';
      _forMixinMember();
      var element = node.members.elementBefore(offset);
      if (element is MethodDeclaration) {
        var body = element.body;
        if (body.isEmpty) {
          keywordHelper.addFunctionBodyModifiers(body);
        }
      }
    }
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    _forExpression(node);
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
  void visitReturnStatement(ReturnStatement node) {
    collector.completionLocation = 'ReturnStatement_expression';
    _forExpression(node.expression ?? node);
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
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitSpreadElement(SpreadElement node) {
    collector.completionLocation = 'SpreadElement_expression';
    _forExpression(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _visitParentIfAtOrBeforeNode(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _forExpression(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _forExpression(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    collector.completionLocation = 'ThrowExpression_expression';
    _forExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    var variableDeclarationList = node.variables;
    var variables = variableDeclarationList.variables;
    if (variables.isEmpty || offset > variables.first.beginToken.end) {
      return;
    }
    if (node.externalKeyword == null) {
      keywordHelper.addKeyword(Keyword.EXTERNAL);
    }
    if (variableDeclarationList.lateKeyword == null &&
        featureSet.isEnabled(Feature.non_nullable)) {
      keywordHelper.addKeyword(Keyword.LATE);
    }
    if (!variables.first.isConst) {
      keywordHelper.addKeyword(Keyword.CONST);
    }
    if (!variables.first.isFinal) {
      keywordHelper.addKeyword(Keyword.FINAL);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var equals = node.equals;
    if (equals != null && offset >= equals.end) {
      collector.completionLocation = 'VariableDeclaration_initializer';
      _forExpression(node);
    }
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a class member.
  void _forClassMember() {
    keywordHelper.addClassMemberKeywords();
    // TODO(brianwilkerson) Suggest type names.
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
  /// beginning of an enum member.
  void _forEnumMember() {
    keywordHelper.addEnumMemberKeywords();
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
  /// beginning of an extension member.
  void _forExtensionMember() {
    keywordHelper.addExtensionMemberKeywords();
  }

  /// Add the suggestions that are appropriate when the selection is at the
  /// beginning of a mixin member.
  void _forMixinMember() {
    keywordHelper.addMixinMemberKeywords();
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
