// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_buffer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

/// An enumeration of possible statement completion kinds.
class DartStatementCompletion {
  static const NO_COMPLETION =
      StatementCompletionKind('No_COMPLETION', 'No completion available');
  static const SIMPLE_ENTER = StatementCompletionKind(
      'SIMPLE_ENTER', 'Insert a newline at the end of the current line');
  static const SIMPLE_SEMICOLON = StatementCompletionKind(
      'SIMPLE_SEMICOLON', 'Add a semicolon and newline');
  static const COMPLETE_CLASS_DECLARATION = StatementCompletionKind(
      'COMPLETE_CLASS_DECLARATION', 'Complete class declaration');
  static const COMPLETE_CONTROL_FLOW_BLOCK = StatementCompletionKind(
      'COMPLETE_CONTROL_FLOW_BLOCK', 'Complete control flow block');
  static const COMPLETE_DO_STMT =
      StatementCompletionKind('COMPLETE_DO_STMT', 'Complete do-statement');
  static const COMPLETE_IF_STMT =
      StatementCompletionKind('COMPLETE_IF_STMT', 'Complete if-statement');
  static const COMPLETE_FOR_STMT =
      StatementCompletionKind('COMPLETE_FOR_STMT', 'Complete for-statement');
  static const COMPLETE_FOR_EACH_STMT = StatementCompletionKind(
      'COMPLETE_FOR_EACH_STMT', 'Complete for-each-statement');
  static const COMPLETE_FUNCTION_DECLARATION = StatementCompletionKind(
      'COMPLETE_FUNCTION_DECLARATION', 'Complete function declaration');
  static const COMPLETE_SWITCH_STMT = StatementCompletionKind(
      'COMPLETE_SWITCH_STMT', 'Complete switch-statement');
  static const COMPLETE_TRY_STMT =
      StatementCompletionKind('COMPLETE_TRY_STMT', 'Complete try-statement');
  static const COMPLETE_VARIABLE_DECLARATION = StatementCompletionKind(
      'COMPLETE_VARIABLE_DECLARATION', 'Complete variable declaration');
  static const COMPLETE_WHILE_STMT = StatementCompletionKind(
      'COMPLETE_WHILE_STMT', 'Complete while-statement');
}

/// A description of a statement completion.
///
/// Clients may not extend, implement or mix-in this class.
class StatementCompletion {
  /// A description of the assist being proposed.
  final StatementCompletionKind kind;

  /// The change to be made in order to apply the assist.
  final SourceChange change;

  /// Initialize a newly created completion to have the given [kind] and
  /// [change].
  StatementCompletion(this.kind, this.change);
}

/// The context for computing a statement completion.
class StatementCompletionContext {
  final ResolvedUnitResult resolveResult;
  final int selectionOffset;

  StatementCompletionContext(this.resolveResult, this.selectionOffset);
}

/// A description of a class of statement completions. Instances are intended to
/// hold the information that is common across a number of completions and to be
/// shared by those completions.
///
/// Clients may not extend, implement or mix-in this class.
class StatementCompletionKind {
  /// The name of this kind of statement completion, used for debugging.
  final String name;

  /// A human-readable description of the changes that will be applied by this
  /// kind of statement completion.
  final String message;

  /// Initialize a newly created kind of statement completion to have the given
  /// [name] and [message].
  const StatementCompletionKind(this.name, this.message);

  @override
  String toString() => name;
}

/// The computer for Dart statement completions.
class StatementCompletionProcessor {
  static final NO_COMPLETION = StatementCompletion(
      DartStatementCompletion.NO_COMPLETION, SourceChange('', edits: []));

  final StatementCompletionContext statementContext;
  final CorrectionUtils utils;

  /// TODO(brianwilkerson) Refactor the code so that the completion is returned
  ///  from the methods in which it's computed rather than being a field that we
  ///  have to test.
  StatementCompletion? completion;
  SourceChange change = SourceChange('statement-completion');
  List<engine.AnalysisError> errors = [];
  final Map<String, LinkedEditGroup> linkedPositionGroups =
      <String, LinkedEditGroup>{};
  Position? exitPosition;

  StatementCompletionProcessor(this.statementContext)
      : utils = CorrectionUtils(statementContext.resolveResult);

  String get eol => utils.endOfLine;

  String get file => statementContext.resolveResult.path;

  LineInfo get lineInfo => statementContext.resolveResult.lineInfo;

  int get selectionOffset => statementContext.selectionOffset;

  Source get source => unitElement.source;

  CompilationUnit get unit => statementContext.resolveResult.unit;

  CompilationUnitElement get unitElement => unit.declaredElement!;

  Future<StatementCompletion> compute() async {
    var node = _selectedNode();
    if (node == null) {
      return NO_COMPLETION;
    }
    node = node.thisOrAncestorMatching(
        (n) => n is Statement || _isNonStatementDeclaration(n));
    if (node == null) {
      return _complete_simpleEnter() ? completion! : NO_COMPLETION;
    }
    if (node is Block) {
      if (node.statements.isNotEmpty) {
        node = node.statements.last;
      }
    }
    if (_isEmptyStatementOrEmptyBlock(node)) {
      node = node.parent!;
    }
    for (var error in statementContext.resolveResult.errors) {
      if (error.offset >= node.offset && error.offset <= node.end) {
        if (error.errorCode is! HintCode && error.errorCode is! WarningCode) {
          errors.add(error);
        }
      }
    }

    _checkExpressions(node);
    if (node is Statement) {
      if (errors.isEmpty) {
        if (_complete_ifStatement(node) ||
            _complete_forStatement2(node) ||
            _complete_whileStatement(node) ||
            _complete_controlFlowBlock(node)) {
          return completion!;
        }
      } else {
        if (_complete_ifStatement(node) ||
            _complete_doStatement(node) ||
            _complete_forStatement2(node) ||
            _complete_functionDeclarationStatement(node) ||
            _complete_switchStatement(node) ||
            _complete_tryStatement(node) ||
            _complete_whileStatement(node) ||
            _complete_controlFlowBlock(node) ||
            _complete_simpleSemicolon(node) ||
            _complete_methodCall(node)) {
          return completion!;
        }
      }
    } else if (node is Declaration) {
      if (errors.isNotEmpty) {
        if (_complete_classDeclaration(node) ||
            _complete_variableDeclaration(node) ||
            _complete_simpleSemicolon(node) ||
            _complete_functionDeclaration(node)) {
          return completion!;
        }
      }
    }
    if (_complete_simpleEnter()) {
      return completion!;
    }
    return NO_COMPLETION;
  }

  void _addInsertEdit(int offset, String text) {
    var edit = SourceEdit(offset, 0, text);
    doSourceChange_addElementEdit(change, unitElement, edit);
  }

  void _addReplaceEdit(SourceRange range, String text) {
    var edit = SourceEdit(range.offset, range.length, text);
    // TODO(brianwilkerson) The commented out function call has been inlined in
    //  order to work around a situation in which _complete_doStatement creates
    //  a conflicting edit that happens to work because of the order in which
    //  the edits are applied. The implementation needs to be cleaned up in
    //  order to prevent the conflicting edit from being generated.
    // doSourceChange_addElementEdit(change, unitElement, edit);
    var fileEdit = change.getFileEdit(unitElement.source.fullName);
    if (fileEdit == null) {
      fileEdit = SourceFileEdit(file, 0);
      change.addFileEdit(fileEdit);
    }
    var edits = fileEdit.edits;
    var length = edits.length;
    var index = 0;
    while (index < length && edits[index].offset > edit.offset) {
      index++;
    }
    edits.insert(index, edit);
  }

  void _appendEmptyBraces(SourceBuilder sb, [bool needsExitMark = false]) {
    sb.append('{');
    sb.append(eol);
    var indent = utils.getLinePrefix(selectionOffset);
    sb.append(indent);
    sb.append(utils.getIndent(1));
    if (needsExitMark && sb.exitOffset == null) {
      sb.setExitOffset();
    }
    sb.append(eol);
    sb.append(indent);
    sb.append('}');
  }

  int _appendNewlinePlusIndent() {
    return _appendNewlinePlusIndentAt(selectionOffset);
  }

  int _appendNewlinePlusIndentAt(int offset) {
    // Append a newline plus proper indent and another newline.
    // Return the position before the second newline.
    var indent = utils.getLinePrefix(offset);
    var loc = utils.getLineNext(offset);
    _addInsertEdit(loc, indent + eol);
    return loc + indent.length;
  }

  String _baseNodeText(AstNode astNode) {
    var text = utils.getNodeText(astNode);
    if (text.endsWith(eol)) {
      text = text.substring(0, text.length - eol.length);
    }
    return text;
  }

  void _checkExpressions(AstNode node) {
    // Note: This may queue edits that have to be accounted for later.
    // See _lengthOfInsertions().
    AstNode? errorMatching(ErrorCode errorCode, {Pattern? partialMatch}) {
      var error = _findError(errorCode, partialMatch: partialMatch);
      if (error == null) {
        return null;
      }
      var expr = _selectedNode();
      return (expr?.thisOrAncestorOfType<StringInterpolation>() == null)
          ? expr
          : null;
    }

    var expr = errorMatching(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
    if (expr != null) {
      var source = utils.getNodeText(expr);
      var content = source;
      var char = content.codeUnitAt(0);
      if (char == 'r'.codeUnitAt(0)) {
        content = source.substring(1);
        char = content.codeUnitAt(0);
      }
      String delimiter;
      int loc;
      if (content.length >= 3 &&
          char == content.codeUnitAt(1) &&
          char == content.codeUnitAt(2)) {
        // multi-line string
        delimiter = content.substring(0, 3);
        var newlineLoc = source.indexOf(eol, selectionOffset - expr.offset);
        if (newlineLoc < 0) {
          newlineLoc = source.length;
        }
        loc = newlineLoc + expr.offset;
      } else {
        // add first char of src
        delimiter = content.substring(0, 1);
        loc = expr.offset + source.length;
      }
      _removeError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
      _addInsertEdit(loc, delimiter);
    }
    expr = errorMatching(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "']'") ??
        errorMatching(ScannerErrorCode.EXPECTED_TOKEN, partialMatch: "']'");
    if (expr != null) {
      expr = expr.thisOrAncestorOfType<ListLiteral>();
      if (expr is ListLiteral) {
        if (expr.rightBracket.isSynthetic) {
          var src = utils.getNodeText(expr).trim();
          var loc = expr.offset + src.length;
          if (src.contains(eol)) {
            var indent = utils.getNodePrefix(node);
            _addInsertEdit(loc, ',$eol$indent]');
          } else {
            _addInsertEdit(loc, ']');
          }
          _removeError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "']'");
          _removeError(ScannerErrorCode.EXPECTED_TOKEN, partialMatch: "']'");
        }
      }
    }
    // The following code is similar to the code for ']' but does not work well.
    // A closing brace is recognized as belong to the map even if it is intended
    // to close a block of code.
    /*
    expr = errorMatching(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "'}'");
    if (expr != null) {
      expr = expr.getAncestor((n) => n is MapLiteral);
      if (expr != null) {
        MapLiteral lit = expr;
        String src = utils.getNodeText(expr).trim();
        int loc = expr.offset + src.length;
        if (lit.entries.last.separator.isSynthetic) {
          _addInsertEdit(loc, ': ');
        }
        if (!src.endsWith('}')/*lit.rightBracket.isSynthetic*/) {
          _addInsertEdit(loc, '}');
        }
        _removeError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "'}'");
        var ms =
          _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
        if (ms != null) {
          // Ensure the semicolon gets inserted in the correct location.
          ms.offset = loc - 1;
        }
      }
    }
    */
  }

  bool _complete_classDeclaration(AstNode node) {
    if (node is! ClassDeclaration) {
      return false;
    }
    if (node.leftBracket.isSynthetic && errors.length == 1) {
      // The space before the left brace is assumed to exist, even if it does not.
      var sb = SourceBuilder(file, node.end - 1);
      sb.append(' ');
      _appendEmptyBraces(sb, true);
      _insertBuilder(sb);
      _setCompletion(DartStatementCompletion.COMPLETE_CLASS_DECLARATION);
      return true;
    }
    return false;
  }

  bool _complete_controlFlowBlock(AstNode node) {
    var expr = (node is ExpressionStatement)
        ? node.expression
        : (node is ReturnStatement ? node.expression : null);
    if (!(node is ReturnStatement || expr is ThrowExpression)) {
      return false;
    }
    var parent = node.parent;
    if (parent is! Block) {
      return false;
    }
    var outer = parent.parent;
    if (!(outer is DoStatement ||
        outer is ForStatement ||
        outer is IfStatement ||
        outer is WhileStatement)) {
      return false;
    }
    var previousInsertions = _lengthOfInsertions();
    var delta = 0;
    if (errors.isNotEmpty) {
      var error =
          _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
      if (error != null) {
        int insertOffset;
        // Fasta scanner reports unterminated string literal errors
        // and generates a synthetic string token with non-zero length.
        // Because of this, check for length == 0 rather than isSynthetic.
        if (expr == null || expr.length == 0) {
          if (node is ReturnStatement) {
            insertOffset = node.returnKeyword.end;
          } else if (node is ExpressionStatement) {
            insertOffset =
                (node.expression as ThrowExpression).throwKeyword.end;
          } else {
            insertOffset = node.end; // Not reached.
          }
        } else {
          insertOffset = expr.end;
        }
        //TODO(messick) Uncomment the following line when error location is fixed.
        //insertOffset = error.offset + error.length;
        _addInsertEdit(insertOffset, ';');
        delta = 1;
      }
    }
    var offset = _appendNewlinePlusIndentAt(parent.end);
    exitPosition = Position(file, offset + delta + previousInsertions);
    _setCompletion(DartStatementCompletion.COMPLETE_CONTROL_FLOW_BLOCK);
    return true;
  }

  bool _complete_doStatement(AstNode node) {
    if (node is! DoStatement) {
      return false;
    }
    var sb = _sourceBuilderAfterKeyword(node, node.doKeyword);
    var hasWhileKeyword = !node.whileKeyword.isSynthetic;
    var exitDelta = 0;
    if (!_statementHasValidBody(node.doKeyword, node.body)) {
      var text = utils.getNodeText(node.body);
      var delta = 0;
      if (text.startsWith(';')) {
        delta = 1;
        _addReplaceEdit(range.startLength(node.body, delta), '');
        if (hasWhileKeyword) {
          text = utils.getNodeText(node);
          if (text.indexOf(RegExp(r'do\s*;\s*while')) == 0) {
            var end = text.indexOf('while');
            var start = text.indexOf(';') + 1;
            delta += end - start - 1;
            _addReplaceEdit(SourceRange(start + node.offset, end - start), ' ');
          }
        }
        sb = SourceBuilder(file, sb.offset + delta);
        sb.append(' ');
      }
      _appendEmptyBraces(
          sb, !(hasWhileKeyword && _isSyntheticExpression(node.condition)));
      if (delta != 0) {
        exitDelta = sb.length - delta;
      }
    } else if (_isEmptyBlock(node.body)) {
      sb = SourceBuilder(sb.file, node.body.end);
    }
    SourceBuilder? sb2;
    if (hasWhileKeyword) {
      var stmt = _KeywordConditionBlockStructure(node.whileKeyword,
          node.leftParenthesis, node.condition, node.rightParenthesis, null);
      sb2 = _complete_keywordCondition(node, stmt);
      if (sb2 == null) {
        return false;
      }
      if (sb2.length == 0) {
        // true if condition is '()'
        final exitPosition = this.exitPosition;
        if (exitPosition != null) {
          if (node.semicolon.isSynthetic) {
            _insertBuilder(sb);
            sb = SourceBuilder(file, exitPosition.offset + 1);
            sb.append(';');
          }
        }
      } else {
        if (sb.exitOffset == null && sb2.exitOffset != null) {
          _insertBuilder(sb);
          sb = sb2;
          sb.append(';');
        } else {
          sb.append(sb2.toString());
        }
      }
    } else {
      sb.append(' while (');
      sb.setExitOffset();
      sb.append(');');
    }
    _insertBuilder(sb);
    if (exitDelta != 0) {
      exitPosition =
          Position(exitPosition!.file, exitPosition!.offset + exitDelta);
    }
    _setCompletion(DartStatementCompletion.COMPLETE_DO_STMT);
    return true;
  }

  bool _complete_forEachStatement(
      ForStatement forNode, ForEachParts forEachParts) {
    AstNode name;
    if (forEachParts is ForEachPartsWithIdentifier) {
      name = forEachParts.identifier;
    } else if (forEachParts is ForEachPartsWithDeclaration) {
      name = forEachParts.loopVariable;
    } else {
      throw StateError('Unrecognized for loop parts');
    }
    return _complete_forEachStatementRest(
        forNode,
        forNode.forKeyword,
        forNode.leftParenthesis,
        name,
        forEachParts.inKeyword,
        forEachParts.iterable,
        forNode.rightParenthesis,
        forNode.body);
  }

  bool _complete_forEachStatementRest(
      AstNode node,
      Token forKeyword,
      Token leftParenthesis,
      AstNode? name,
      Token inKeyword,
      Expression? iterable,
      Token rightParenthesis,
      Statement body) {
    if (inKeyword.isSynthetic) {
      return false; // Can't happen -- would be parsed as a for-statement.
    }
    var sb = SourceBuilder(file, rightParenthesis.offset + 1);
    var src = utils.getNodeText(node);
    if (name == null) {
      exitPosition = Position(file, leftParenthesis.offset + 1);
      src = src.substring(leftParenthesis.offset - node.offset);
      if (src.startsWith(RegExp(r'\(\s*in\s*\)'))) {
        _addReplaceEdit(
            range.startOffsetEndOffset(
                leftParenthesis.offset + 1, rightParenthesis.offset),
            ' in ');
      } else if (src.startsWith(RegExp(r'\(\s*in'))) {
        _addReplaceEdit(
            range.startOffsetEndOffset(
                leftParenthesis.offset + 1, inKeyword.offset),
            ' ');
      }
    } else if (iterable != null && _isSyntheticExpression(iterable)) {
      exitPosition = Position(file, rightParenthesis.offset + 1);
      src = src.substring(inKeyword.offset - node.offset);
      if (src.startsWith(RegExp(r'in\s*\)'))) {
        _addReplaceEdit(
            range.startOffsetEndOffset(
                inKeyword.offset + inKeyword.length, rightParenthesis.offset),
            ' ');
      }
    }
    if (!_statementHasValidBody(forKeyword, body)) {
      sb.append(' ');
      _appendEmptyBraces(sb, exitPosition == null);
    }
    _insertBuilder(sb);
    _setCompletion(DartStatementCompletion.COMPLETE_FOR_EACH_STMT);
    return true;
  }

  bool _complete_forStatement(ForStatement forNode, ForParts forParts) {
    SourceBuilder sb;
    var replacementLength = 0;
    if (forNode.leftParenthesis.isSynthetic) {
      if (!forNode.rightParenthesis.isSynthetic) {
        return false;
      }
      // keywordOnly (unit test name suffix that exercises this branch)
      sb = _sourceBuilderAfterKeyword(forNode, forNode.forKeyword);
      sb.append('(');
      sb.setExitOffset();
      sb.append(')');
    } else {
      if (!forParts.rightSeparator.isSynthetic) {
        // Fully-defined init, cond, updaters so nothing more needed here.
        // emptyParts, noError
        sb = SourceBuilder(file, forNode.rightParenthesis.offset + 1);
      } else if (!forParts.leftSeparator.isSynthetic) {
        if (_isSyntheticExpression(forParts.condition)) {
          var text = utils
              .getNodeText(forNode)
              .substring(forParts.leftSeparator.offset - forNode.offset);
          var match = RegExp(r';\s*(/\*.*\*/\s*)?\)[ \t]*').matchAsPrefix(text);
          if (match != null) {
            // emptyCondition, emptyInitializersEmptyCondition
            replacementLength = match.end - match.start;
            sb = SourceBuilder(file, forParts.leftSeparator.offset);
            sb.append('; ${match.group(1) ?? ''}; )');
            var suffix = text.substring(match.end);
            if (suffix.trim().isNotEmpty) {
              sb.append(' ');
              sb.append(suffix.trim());
              replacementLength += suffix.length;
              if (suffix.endsWith(eol)) {
                // emptyCondition
                replacementLength -= eol.length;
              }
            }
            exitPosition = _newPosition(forParts.leftSeparator.offset + 2);
          } else {
            return false; // Line comment in condition
          }
        } else {
          // emptyUpdaters
          sb = SourceBuilder(file, forNode.rightParenthesis.offset);
          replacementLength = 1;
          sb.append('; )');
          exitPosition = _newPosition(forParts.rightSeparator.offset + 2);
        }
      } else if (forParts is ForPartsWithExpression &&
          _isSyntheticExpression(forParts.initialization)) {
        // emptyInitializers
        exitPosition = _newPosition(forNode.rightParenthesis.offset);
        sb = SourceBuilder(file, forNode.rightParenthesis.offset);
      } else if (forParts is ForPartsWithExpression &&
          forParts.initialization is SimpleIdentifier &&
          forParts.initialization!.beginToken.lexeme == 'in') {
        // looks like a for/each statement missing the loop variable
        return _complete_forEachStatementRest(
            forNode,
            forNode.forKeyword,
            forNode.leftParenthesis,
            null,
            forParts.initialization!.beginToken,
            null,
            forNode.rightParenthesis,
            forNode.body);
      } else {
        var start = forParts.condition!.offset + forParts.condition!.length;
        var text = utils.getNodeText(forNode).substring(start - forNode.offset);
        if (text.startsWith(RegExp(r'\s*\)'))) {
          // missingLeftSeparator
          var end = text.indexOf(')');
          sb = SourceBuilder(file, start);
          _addReplaceEdit(SourceRange(start, end), '; ; ');
          exitPosition = Position(file, start - (end - '; '.length));
        } else {
          // Not possible; any comment following init is attached to init.
          exitPosition = _newPosition(forNode.rightParenthesis.offset);
          sb = SourceBuilder(file, forNode.rightParenthesis.offset);
        }
      }
    }
    var body = forNode.body;
    if (!_statementHasValidBody(forNode.forKeyword, body)) {
      // keywordOnly, noError
      sb.append(' ');
      _appendEmptyBraces(sb, true /*exitPosition == null*/);
    } else if (body is Block) {
      if (body.rightBracket.end <= selectionOffset) {
        // emptyInitializersAfterBody
        errors = []; // Ignore errors; they are for previous statement.
        return false; // If cursor is after closing brace just add newline.
      }
    }
    _insertBuilder(sb, replacementLength);
    _setCompletion(DartStatementCompletion.COMPLETE_FOR_STMT);
    return true;
  }

  bool _complete_forStatement2(AstNode node) {
    if (node is ForStatement) {
      var forLoopParts = node.forLoopParts;
      if (forLoopParts is ForParts) {
        return _complete_forStatement(node, forLoopParts);
      } else if (forLoopParts is ForEachParts) {
        return _complete_forEachStatement(node, forLoopParts);
      }
    }
    return false;
  }

  bool _complete_functionDeclaration(AstNode node) {
    if (node is! MethodDeclaration && node is! FunctionDeclaration) {
      return false;
    }
    var needsParen = false;
    int computeExitPos(FormalParameterList parameters) {
      if (needsParen = parameters.rightParenthesis.isSynthetic) {
        var error = _findError(ParserErrorCode.MISSING_CLOSING_PARENTHESIS);
        if (error != null) {
          return error.offset - 1;
        }
      }
      return node.end - 1;
    }

    int paramListEnd;
    if (node is FunctionDeclaration) {
      var parameters = node.functionExpression.parameters;
      if (parameters == null) {
        return false;
      }
      paramListEnd = computeExitPos(parameters);
    } else if (node is MethodDeclaration) {
      var parameters = node.parameters;
      if (parameters == null) {
        return false;
      }
      paramListEnd = computeExitPos(parameters);
    } else {
      return false;
    }
    var sb = SourceBuilder(file, paramListEnd);
    if (needsParen) {
      sb.append(')');
    }
    sb.append(' ');
    _appendEmptyBraces(sb, true);
    _insertBuilder(sb);
    _setCompletion(DartStatementCompletion.COMPLETE_FUNCTION_DECLARATION);
    return true;
  }

  bool _complete_functionDeclarationStatement(AstNode node) {
    if (node is! FunctionDeclarationStatement) {
      return false;
    }
    var error = _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
    if (error != null) {
      var src = utils.getNodeText(node);
      var insertOffset = node.functionDeclaration.end - 1;
      var body = node.functionDeclaration.functionExpression.body;
      if (body is ExpressionFunctionBody) {
        var fnbOffset = body.functionDefinition.offset;
        var fnSrc = src.substring(fnbOffset - node.offset);
        if (!fnSrc.startsWith('=>')) {
          return false;
        }
        var delta = 0;
        if (body.expression.isSynthetic) {
          if (!fnSrc.startsWith('=> ')) {
            _addInsertEdit(insertOffset, ' ');
            delta = 1;
          }
          _addInsertEdit(insertOffset, ';');
          _appendNewlinePlusIndentAt(insertOffset);
        } else {
          delta = 1;
          _addInsertEdit(insertOffset, ';');
          insertOffset = _appendNewlinePlusIndent();
        }
        _setCompletionAt(
            DartStatementCompletion.SIMPLE_SEMICOLON, insertOffset + delta);
        return true;
      }
    }
    return false;
  }

  bool _complete_ifOrWhileStatement(AstNode node,
      _KeywordConditionBlockStructure statement, StatementCompletionKind kind) {
    if (_statementHasValidBody(statement.keyword, statement.block!)) {
      return false;
    }
    var sb = _complete_keywordCondition(node, statement);
    if (sb == null) {
      return false;
    }
    var overshoot = _lengthOfDeletions();
    sb.append(' ');
    _appendEmptyBraces(sb, exitPosition == null);
    _insertBuilder(sb);
    if (overshoot != 0) {
      exitPosition = _newPosition(exitPosition!.offset - overshoot);
    }
    _setCompletion(kind);
    return true;
  }

  bool _complete_ifStatement(AstNode node) {
    if (node is! IfStatement) {
      return false;
    }
    var elseKeyword = node.elseKeyword;
    if (elseKeyword != null) {
      if (selectionOffset >= elseKeyword.end &&
          _isEmptyStatement(node.elseStatement)) {
        var sb = SourceBuilder(file, selectionOffset);
        var src = utils.getNodeText(node);
        if (!src
            .substring(elseKeyword.end - node.offset)
            .startsWith(RegExp(r'[ \t]'))) {
          sb.append(' ');
        }
        _appendEmptyBraces(sb, true);
        _insertBuilder(sb);
        _setCompletion(DartStatementCompletion.COMPLETE_IF_STMT);
        return true;
      }
      return false;
    }
    var stmt = _KeywordConditionBlockStructure(
        node.ifKeyword,
        node.leftParenthesis,
        node.expression,
        node.rightParenthesis,
        node.thenStatement);
    return _complete_ifOrWhileStatement(
        node, stmt, DartStatementCompletion.COMPLETE_IF_STMT);
  }

  SourceBuilder? _complete_keywordCondition(
      AstNode node, _KeywordConditionBlockStructure statement) {
    SourceBuilder sb;
    if (statement.leftParenthesis.isSynthetic) {
      if (!statement.rightParenthesis.isSynthetic) {
        // Quite unlikely to see this so don't try to fix it.
        return null;
      }
      sb = _sourceBuilderAfterKeyword(node, statement.keyword);
      sb.append('(');
      sb.setExitOffset();
      sb.append(')');
    } else {
      if (_isSyntheticExpression(statement.condition)) {
        exitPosition = _newPosition(statement.leftParenthesis.offset + 1);
        sb = SourceBuilder(file, statement.rightParenthesis.offset + 1);
      } else if (statement.rightParenthesis.isSynthetic) {
        sb = SourceBuilder(file, statement.condition.end);
        sb.append(')');
      } else {
        var afterParen = statement.rightParenthesis.offset + 1;
        if (utils
            .getNodeText(node)
            .substring(afterParen - node.offset)
            .startsWith(RegExp(r'[ \t]'))) {
          _addReplaceEdit(SourceRange(afterParen, 1), '');
          sb = SourceBuilder(file, afterParen + 1);
        } else {
          sb = SourceBuilder(file, afterParen);
        }
      }
    }
    return sb;
  }

  bool _complete_methodCall(AstNode node) {
    var parenError =
        _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "')'") ??
            _findError(ScannerErrorCode.EXPECTED_TOKEN, partialMatch: "')'");
    if (parenError == null) {
      return false;
    }
    var argList = _selectedNode(at: selectionOffset)
        ?.thisOrAncestorOfType<ArgumentList>();
    argList ??= _selectedNode(at: parenError.offset)
        ?.thisOrAncestorOfType<ArgumentList>();
    if (argList == null ||
        argList.thisOrAncestorMatching((n) => n == node) == null) {
      return false;
    }
    var previousInsertions = _lengthOfInsertions();
    var loc = min(selectionOffset, argList.end - 1);
    var delta = 1;
    var semicolonError =
        _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
    if (semicolonError == null) {
      loc += 1;
      delta = 0;
    }
    _addInsertEdit(loc, ')');
    if (semicolonError != null) {
      _addInsertEdit(loc, ';');
    }
    var indent = utils.getLinePrefix(selectionOffset);
    var exit = utils.getLineNext(selectionOffset);
    _addInsertEdit(exit, indent + eol);
    exit += indent.length + eol.length + previousInsertions;

    _setCompletionAt(DartStatementCompletion.SIMPLE_ENTER, exit + delta);
    return true;
  }

  bool _complete_simpleEnter() {
    int offset;
    if (errors.isNotEmpty) {
      offset = selectionOffset;
    } else {
      var indent = utils.getLinePrefix(selectionOffset);
      var loc = utils.getLineNext(selectionOffset);
      _addInsertEdit(loc, indent + eol);
      offset = loc + indent.length;
    }
    _setCompletionAt(DartStatementCompletion.SIMPLE_ENTER, offset);
    return true;
  }

  bool _complete_simpleSemicolon(AstNode node) {
    if (errors.length != 1) {
      return false;
    }
    var error = _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
    if (error != null) {
      var previousInsertions = _lengthOfInsertions();
      // TODO(messick) Fix this to find the correct place in all cases.
      var insertOffset = error.offset + error.length;
      _addInsertEdit(insertOffset, ';');
      var offset = _appendNewlinePlusIndent() + 1 /*';'*/ + previousInsertions;
      _setCompletionAt(DartStatementCompletion.SIMPLE_SEMICOLON, offset);
      return true;
    }
    return false;
  }

  bool _complete_switchStatement(AstNode node) {
    if (node is! SwitchStatement) {
      return false;
    }
    SourceBuilder sb;
    if (node.leftParenthesis.isSynthetic && node.rightParenthesis.isSynthetic) {
      exitPosition = Position(file, node.switchKeyword.end + 2);
      var src = utils.getNodeText(node);
      if (src
          .substring(node.switchKeyword.end - node.offset)
          .startsWith(RegExp(r'[ \t]+'))) {
        sb = SourceBuilder(file, node.switchKeyword.end + 1);
      } else {
        sb = SourceBuilder(file, node.switchKeyword.end);
        sb.append(' ');
      }
      sb.append('()');
    } else if (node.leftParenthesis.isSynthetic ||
        node.rightParenthesis.isSynthetic) {
      return false;
    } else {
      sb = SourceBuilder(file, node.rightParenthesis.offset + 1);
      if (_isSyntheticExpression(node.expression)) {
        exitPosition = Position(file, node.leftParenthesis.offset + 1);
      }
    }
    if (node
        .leftBracket.isSynthetic /*&& switchNode.rightBracket.isSynthetic*/) {
      // See https://github.com/dart-lang/sdk/issues/29391
      sb.append(' ');
      _appendEmptyBraces(sb, exitPosition == null);
    } else {
      var member = _findInvalidElement(node.members);
      if (member != null) {
        if (member.colon.isSynthetic) {
          var loc =
              member is SwitchCase ? member.expression.end : member.keyword.end;
          sb = SourceBuilder(file, loc);
          sb.append(': ');
          exitPosition = Position(file, loc + 2);
        }
      }
    }
    _insertBuilder(sb);
    _setCompletion(DartStatementCompletion.COMPLETE_SWITCH_STMT);
    return true;
  }

  bool _complete_tryStatement(AstNode node) {
    if (node is! TryStatement) {
      return false;
    }
    var addSpace = true;
    if (node.body.leftBracket.isSynthetic) {
      var src = utils.getNodeText(node);
      SourceBuilder sb;
      if (src
          .substring(node.tryKeyword.end - node.offset)
          .startsWith(RegExp(r'[ \t]+'))) {
        // keywordSpace
        sb = SourceBuilder(file, node.tryKeyword.end + 1);
      } else {
        // keywordOnly
        sb = SourceBuilder(file, node.tryKeyword.end);
        sb.append(' ');
      }
      _appendEmptyBraces(sb, true);
      _insertBuilder(sb);
    } else {
      SourceBuilder? sb;
      var catchNode = _findInvalidElement(node.catchClauses);
      if (catchNode != null) {
        var onKeyword = catchNode.onKeyword;
        var exceptionType = catchNode.exceptionType;
        if (onKeyword != null && exceptionType != null) {
          if (exceptionType.length == 0 ||
              _findError(CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE,
                      partialMatch: "name 'catch") !=
                  null) {
            var src = utils.getNodeText(catchNode);
            if (src.startsWith(RegExp(r'on[ \t]+'))) {
              if (src.startsWith(RegExp(r'on[ \t][ \t]+'))) {
                // onSpaces
                exitPosition = Position(file, onKeyword.end + 1);
                sb = SourceBuilder(file, onKeyword.end + 2);
                addSpace = false;
              } else {
                // onSpace
                sb = SourceBuilder(file, onKeyword.end + 1);
                sb.setExitOffset();
              }
            } else {
              // onOnly
              sb = SourceBuilder(file, onKeyword.end);
              sb.append(' ');
              sb.setExitOffset();
            }
          } else {
            // onType
            sb = SourceBuilder(file, exceptionType.end);
          }
        }
        var catchKeyword = catchNode.catchKeyword;
        if (catchKeyword != null) {
          // catchOnly
          var struct = _KeywordConditionBlockStructure(
              catchKeyword,
              catchNode.leftParenthesis!,
              catchNode.exceptionParameter!,
              catchNode.rightParenthesis!,
              catchNode.body);
          if (sb != null) {
            // onCatch
            _insertBuilder(sb);
          }
          sb = _complete_keywordCondition(node, struct);
          if (sb == null) {
            return false;
          }
        }
        if (sb != null) {
          if (catchNode.body.leftBracket.isSynthetic) {
            // onOnly and others
            if (addSpace) {
              sb.append(' ');
            }
            _appendEmptyBraces(sb, exitPosition == null);
          }
          _insertBuilder(sb);
        }
      } else if (node.finallyKeyword != null) {
        if (node.finallyBlock!.leftBracket.isSynthetic) {
          // finallyOnly
          sb = SourceBuilder(file, node.finallyKeyword!.end);
          sb.append(' ');
          _appendEmptyBraces(sb, true);
          _insertBuilder(sb);
        }
      }
    }
    _setCompletion(DartStatementCompletion.COMPLETE_TRY_STMT);
    return true;
  }

  bool _complete_variableDeclaration(AstNode node) {
    if (node is! VariableDeclaration) {
      return false;
    }
    _addInsertEdit(node.end, ';');
    exitPosition = Position(file, _appendNewlinePlusIndentAt(node.end) + 1);
    _setCompletion(DartStatementCompletion.COMPLETE_VARIABLE_DECLARATION);
    return true;
  }

  bool _complete_whileStatement(AstNode node) {
    if (node is! WhileStatement) {
      return false;
    }
    var stmt = _KeywordConditionBlockStructure(node.whileKeyword,
        node.leftParenthesis, node.condition, node.rightParenthesis, node.body);
    return _complete_ifOrWhileStatement(
        node, stmt, DartStatementCompletion.COMPLETE_WHILE_STMT);
  }

  engine.AnalysisError? _findError(ErrorCode code, {Pattern? partialMatch}) {
    return errors.firstWhereOrNull((err) =>
        err.errorCode == code &&
        (partialMatch == null ? true : err.message.contains(partialMatch)));
  }

  T? _findInvalidElement<T extends AstNode>(NodeList<T> list) {
    return list.firstWhereOrNull((item) =>
        selectionOffset >= item.offset && selectionOffset <= item.end);
  }

  void _insertBuilder(SourceBuilder builder, [int length = 0]) {
    {
      var range = SourceRange(builder.offset, length);
      var text = builder.toString();
      _addReplaceEdit(range, text);
    }
    // add exit position
    {
      var exitOffset = builder.exitOffset;
      if (exitOffset != null) {
        exitPosition = _newPosition(exitOffset);
      }
    }
  }

  bool _isEmptyBlock(AstNode stmt) {
    return stmt is Block && stmt.statements.isEmpty;
  }

  bool _isEmptyStatement(AstNode? stmt) {
    if (stmt is ExpressionStatement) {
      var expression = stmt.expression;
      if (expression is SimpleIdentifier) {
        return expression.token.isSynthetic;
      }
    }
    return stmt is EmptyStatement;
  }

  bool _isEmptyStatementOrEmptyBlock(AstNode stmt) {
    return _isEmptyStatement(stmt) || _isEmptyBlock(stmt);
  }

  bool _isNonStatementDeclaration(AstNode n) {
    if (n is! Declaration) {
      return false;
    }
    if (n is! VariableDeclaration && n is! FunctionDeclaration) {
      return true;
    }
    var p = n.parent;
    return p is! Statement &&
        p?.parent is! Statement &&
        p?.parent?.parent is! Statement;
  }

  bool _isSyntheticExpression(AstNode? expr) {
    return expr is SimpleIdentifier && expr.isSynthetic;
  }

  int _lengthOfDeletions() {
    if (change.edits.isEmpty) {
      return 0;
    }
    var length = 0;
    for (var edit in change.edits) {
      for (var srcEdit in edit.edits) {
        if (srcEdit.length > 0) {
          length += srcEdit.length - srcEdit.replacement.length;
        }
      }
    }
    return length;
  }

  int _lengthOfInsertions() {
    // Any _complete_*() that may follow changes made by _checkExpressions()
    // must cache the result of this method and add that value to its
    // exit position. That's assuming all edits are done in increasing position.
    // There are currently no editing sequences that produce both insertions and
    // deletions, but if there were this approach would have to be generalized.
    if (change.edits.isEmpty) {
      return 0;
    }
    var length = 0;
    for (var edit in change.edits) {
      for (var srcEdit in edit.edits) {
        if (srcEdit.length == 0) {
          length += srcEdit.replacement.length;
        }
      }
    }
    return length;
  }

  Position _newPosition(int offset) {
    return Position(file, offset);
  }

  void _removeError(ErrorCode errorCode, {Pattern? partialMatch}) {
    var error = _findError(errorCode, partialMatch: partialMatch);
    if (error != null) {
      errors.remove(error);
    }
  }

  AstNode? _selectedNode({int? at}) =>
      NodeLocator(at ?? selectionOffset).searchWithin(unit);

  void _setCompletion(StatementCompletionKind kind) {
    assert(exitPosition != null);
    change.selection = exitPosition;
    change.message = formatList(kind.message, null);
    for (var group in linkedPositionGroups.values) {
      change.addLinkedEditGroup(group);
    }
    completion = StatementCompletion(kind, change);
  }

  void _setCompletionAt(StatementCompletionKind kind, int offset) {
    exitPosition = _newPosition(offset);
    _setCompletion(kind);
  }

  SourceBuilder _sourceBuilderAfterKeyword(AstNode node, Token keyword) {
    SourceBuilder sb;
    var text = _baseNodeText(node);
    text = text.substring(keyword.offset - node.offset);
    var len = keyword.length;
    if (text.length == len || // onCatchComment
        !text.substring(len, len + 1).contains(RegExp(r'[ \t]'))) {
      sb = SourceBuilder(file, keyword.offset + len);
      sb.append(' ');
    } else {
      sb = SourceBuilder(file, keyword.offset + len + 1);
    }
    return sb;
  }

  bool _statementHasValidBody(Token keyword, Statement body) {
    // A "valid" body is either a non-synthetic block or a single statement
    // on the same line as the parent statement, similar to dart_style.
    if (body.isSynthetic) {
      return false;
    }
    if (body is Block) {
      var block = body;
      return !block.leftBracket.isSynthetic;
    }
    return lineInfo.getLocation(keyword.offset) ==
        lineInfo.getLocation(body.offset);
  }
}

// Encapsulate common structure of if-statement and while-statement.
class _KeywordConditionBlockStructure {
  final Token keyword;
  final Token leftParenthesis, rightParenthesis;
  final AstNode condition;
  final Statement? block;

  _KeywordConditionBlockStructure(this.keyword, this.leftParenthesis,
      this.condition, this.rightParenthesis, this.block);

  int get offset => keyword.offset;
}
