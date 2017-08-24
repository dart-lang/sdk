// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_buffer.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/**
 * An enumeration of possible statement completion kinds.
 */
class DartStatementCompletion {
  static const NO_COMPLETION =
      const StatementCompletionKind('No_COMPLETION', 'No completion available');
  static const SIMPLE_ENTER = const StatementCompletionKind(
      'SIMPLE_ENTER', "Insert a newline at the end of the current line");
  static const SIMPLE_SEMICOLON = const StatementCompletionKind(
      'SIMPLE_SEMICOLON', "Add a semicolon and newline");
  static const COMPLETE_CLASS_DECLARATION = const StatementCompletionKind(
      'COMPLETE_CLASS_DECLARATION', "Complete class declaration");
  static const COMPLETE_CONTROL_FLOW_BLOCK = const StatementCompletionKind(
      'COMPLETE_CONTROL_FLOW_BLOCK', "Complete control flow block");
  static const COMPLETE_DO_STMT = const StatementCompletionKind(
      'COMPLETE_DO_STMT', "Complete do-statement");
  static const COMPLETE_IF_STMT = const StatementCompletionKind(
      'COMPLETE_IF_STMT', "Complete if-statement");
  static const COMPLETE_FOR_STMT = const StatementCompletionKind(
      'COMPLETE_FOR_STMT', "Complete for-statement");
  static const COMPLETE_FOR_EACH_STMT = const StatementCompletionKind(
      'COMPLETE_FOR_EACH_STMT', "Complete for-each-statement");
  static const COMPLETE_FUNCTION_DECLARATION = const StatementCompletionKind(
      'COMPLETE_FUNCTION_DECLARATION', "Complete function declaration");
  static const COMPLETE_SWITCH_STMT = const StatementCompletionKind(
      'COMPLETE_SWITCH_STMT', "Complete switch-statement");
  static const COMPLETE_TRY_STMT = const StatementCompletionKind(
      'COMPLETE_TRY_STMT', "Complete try-statement");
  static const COMPLETE_VARIABLE_DECLARATION = const StatementCompletionKind(
      'COMPLETE_VARIABLE_DECLARATION', "Complete variable declaration");
  static const COMPLETE_WHILE_STMT = const StatementCompletionKind(
      'COMPLETE_WHILE_STMT', "Complete while-statement");
}

/**
 * A description of a statement completion.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class StatementCompletion {
  /**
   * A description of the assist being proposed.
   */
  final StatementCompletionKind kind;

  /**
   * The change to be made in order to apply the assist.
   */
  final SourceChange change;

  /**
   * Initialize a newly created completion to have the given [kind] and [change].
   */
  StatementCompletion(this.kind, this.change);
}

/**
 * The context for computing a statement completion.
 */
class StatementCompletionContext {
  final String file;
  final LineInfo lineInfo;
  final int selectionOffset;
  final CompilationUnit unit;
  final CompilationUnitElement unitElement;
  final List<engine.AnalysisError> errors;

  StatementCompletionContext(this.file, this.lineInfo, this.selectionOffset,
      this.unit, this.unitElement, this.errors) {
    if (unitElement.context == null) {
      throw new Error(); // not reached; see getStatementCompletion()
    }
  }
}

/**
 * A description of a class of statement completions. Instances are intended to
 * hold the information that is common across a number of completions and to be
 * shared by those completions.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class StatementCompletionKind {
  /**
   * The name of this kind of statement completion, used for debugging.
   */
  final String name;

  /**
   * A human-readable description of the changes that will be applied by this
   * kind of statement completion.
   */
  final String message;

  /**
   * Initialize a newly created kind of statement completion to have the given
   * [name] and [message].
   */
  const StatementCompletionKind(this.name, this.message);

  @override
  String toString() => name;
}

/**
 * The computer for Dart statement completions.
 */
class StatementCompletionProcessor {
  static final NO_COMPLETION = new StatementCompletion(
      DartStatementCompletion.NO_COMPLETION, new SourceChange("", edits: []));

  final StatementCompletionContext statementContext;
  final CorrectionUtils utils;
  AstNode node;
  StatementCompletion completion;
  SourceChange change = new SourceChange('statement-completion');
  List errors = <engine.AnalysisError>[];
  final Map<String, LinkedEditGroup> linkedPositionGroups =
      <String, LinkedEditGroup>{};
  Position exitPosition = null;

  StatementCompletionProcessor(this.statementContext)
      : utils = new CorrectionUtils(statementContext.unit);

  String get eol => utils.endOfLine;

  String get file => statementContext.file;

  LineInfo get lineInfo => statementContext.lineInfo;

  int get requestLine => lineInfo.getLocation(selectionOffset).lineNumber;

  int get selectionOffset => statementContext.selectionOffset;

  Source get source => statementContext.unitElement.source;

  CompilationUnit get unit => statementContext.unit;

  CompilationUnitElement get unitElement => statementContext.unitElement;

  Future<StatementCompletion> compute() async {
    node = _selectedNode();
    if (node == null) {
      return NO_COMPLETION;
    }
    node = node
        .getAncestor((n) => n is Statement || _isNonStatementDeclaration(n));
    if (node == null) {
      return _complete_simpleEnter() ? completion : NO_COMPLETION;
    }
    if (node is Block) {
      Block blockNode = node;
      if (blockNode.statements.isNotEmpty) {
        node = blockNode.statements.last;
      }
    }
    if (_isEmptyStatement(node)) {
      node = node.parent;
    }
    for (engine.AnalysisError error in statementContext.errors) {
      if (error.offset >= node.offset &&
          error.offset <= node.offset + node.length) {
        if (error.errorCode is! HintCode) {
          errors.add(error);
        }
      }
    }

    _checkExpressions();
    if (node is Statement) {
      if (errors.isEmpty) {
        if (_complete_ifStatement() ||
            _complete_forStatement() ||
            _complete_forEachStatement() ||
            _complete_whileStatement() ||
            _complete_controlFlowBlock()) {
          return completion;
        }
      } else {
        if (_complete_ifStatement() ||
            _complete_doStatement() ||
            _complete_forStatement() ||
            _complete_forEachStatement() ||
            _complete_functionDeclarationStatement() ||
            _complete_switchStatement() ||
            _complete_tryStatement() ||
            _complete_whileStatement() ||
            _complete_controlFlowBlock() ||
            _complete_simpleSemicolon() ||
            _complete_methodCall()) {
          return completion;
        }
      }
    } else if (node is Declaration) {
      if (errors.isNotEmpty) {
        if (_complete_classDeclaration() ||
            _complete_functionDeclaration() ||
            _complete_variableDeclaration()) {
          return completion;
        }
      }
    }
    if (_complete_simpleEnter()) {
      return completion;
    }
    return NO_COMPLETION;
  }

  void _addInsertEdit(int offset, String text) {
    SourceEdit edit = new SourceEdit(offset, 0, text);
    doSourceChange_addElementEdit(change, unitElement, edit);
  }

  void _addReplaceEdit(SourceRange range, String text) {
    SourceEdit edit = new SourceEdit(range.offset, range.length, text);
    doSourceChange_addElementEdit(change, unitElement, edit);
  }

  void _appendEmptyBraces(SourceBuilder sb, [bool needsExitMark = false]) {
    sb.append('{');
    sb.append(eol);
    String indent = utils.getLinePrefix(selectionOffset);
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
    String indent = utils.getLinePrefix(offset);
    int loc = utils.getLineNext(offset);
    _addInsertEdit(loc, indent + eol);
    return loc + indent.length;
  }

  String _baseNodeText(AstNode astNode) {
    String text = utils.getNodeText(astNode);
    if (text.endsWith(eol)) {
      text = text.substring(0, text.length - eol.length);
    }
    return text;
  }

  void _checkExpressions() {
    // Note: This may queue edits that have to be accounted for later.
    // See _lengthOfInsertions().
    AstNode errorMatching(errorCode, {partialMatch = null}) {
      var error = _findError(errorCode, partialMatch: partialMatch);
      if (error == null) {
        return null;
      }
      AstNode expr = _selectedNode();
      return (expr.getAncestor((n) => n is StringInterpolation) == null)
          ? expr
          : null;
    }

    var expr = errorMatching(ScannerErrorCode.UNTERMINATED_STRING_LITERAL);
    if (expr != null) {
      String source = utils.getNodeText(expr);
      String content = source;
      int char = content.codeUnitAt(0);
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
        int newlineLoc = source.indexOf(eol, selectionOffset - expr.offset);
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
      expr = expr.getAncestor((n) => n is ListLiteral);
      if (expr != null) {
        ListLiteral lit = expr;
        if (lit.rightBracket.isSynthetic) {
          String src = utils.getNodeText(expr).trim();
          int loc = expr.offset + src.length;
          if (src.contains(eol)) {
            String indent = utils.getNodePrefix(node);
            _addInsertEdit(loc, ',' + eol + indent + ']');
          } else {
            _addInsertEdit(loc, ']');
          }
          _removeError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "']'");
          _removeError(ScannerErrorCode.EXPECTED_TOKEN, partialMatch: "']'");
          var ms =
              _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
          if (ms != null) {
            // Ensure the semicolon gets inserted in the correct location.
            ms.offset = loc - 1;
          }
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

  bool _complete_classDeclaration() {
    if (node is! ClassDeclaration) {
      return false;
    }
    ClassDeclaration decl = node;
    if (decl.leftBracket.isSynthetic && errors.length == 1) {
      // The space before the left brace is assumed to exist, even if it does not.
      SourceBuilder sb = new SourceBuilder(file, decl.end - 1);
      sb.append(' ');
      _appendEmptyBraces(sb, true);
      _insertBuilder(sb);
      _setCompletion(DartStatementCompletion.COMPLETE_CLASS_DECLARATION);
      return true;
    }
    return false;
  }

  bool _complete_controlFlowBlock() {
    Expression expr = (node is ExpressionStatement)
        ? (node as ExpressionStatement).expression
        : (node is ReturnStatement
            ? (node as ReturnStatement).expression
            : null);
    if (!(node is ReturnStatement || expr is ThrowExpression)) {
      return false;
    }
    if (node.parent is! Block) {
      return false;
    }
    AstNode outer = node.parent.parent;
    if (!(outer is DoStatement ||
        outer is ForStatement ||
        outer is ForEachStatement ||
        outer is IfStatement ||
        outer is WhileStatement)) {
      return false;
    }
    int previousInsertions = _lengthOfInsertions();
    int delta = 0;
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
            insertOffset = (node as ReturnStatement).returnKeyword.end;
          } else if (node is ExpressionStatement) {
            insertOffset =
                ((node as ExpressionStatement).expression as ThrowExpression)
                    .throwKeyword
                    .end;
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
    int offset = _appendNewlinePlusIndentAt(node.parent.end);
    exitPosition = new Position(file, offset + delta + previousInsertions);
    _setCompletion(DartStatementCompletion.COMPLETE_CONTROL_FLOW_BLOCK);
    return true;
  }

  bool _complete_doStatement() {
    if (node is! DoStatement) {
      return false;
    }
    DoStatement statement = node;
    SourceBuilder sb = _sourceBuilderAfterKeyword(statement.doKeyword);
    bool hasWhileKeyword = statement.whileKeyword.lexeme == "while";
    int exitDelta = 0;
    if (!_statementHasValidBody(statement.doKeyword, statement.body)) {
      String text = utils.getNodeText(statement.body);
      int delta = 0;
      if (text.startsWith(';')) {
        delta = 1;
        _addReplaceEdit(range.startLength(statement.body, delta), '');
        if (hasWhileKeyword) {
          text = utils.getNodeText(statement);
          if (text.indexOf(new RegExp(r'do\s*;\s*while')) == 0) {
            int end = text.indexOf('while');
            int start = text.indexOf(';') + 1;
            delta += end - start - 1;
            _addReplaceEdit(
                new SourceRange(start + statement.offset, end - start), ' ');
          }
        }
        sb = new SourceBuilder(file, sb.offset + delta);
        sb.append(' ');
      }
      _appendEmptyBraces(sb,
          !(hasWhileKeyword && _isSyntheticExpression(statement.condition)));
      if (delta != 0) {
        exitDelta = sb.length - delta;
      }
    } else if (_isEmptyBlock(statement.body)) {
      sb = new SourceBuilder(sb.file, statement.body.end);
    }
    SourceBuilder sb2;
    if (hasWhileKeyword) {
      var stmt = new _KeywordConditionBlockStructure(
          statement.whileKeyword,
          statement.leftParenthesis,
          statement.condition,
          statement.rightParenthesis,
          null);
      sb2 = _complete_keywordCondition(stmt);
      if (sb2 == null) {
        return false;
      }
      if (sb2.length == 0) {
        // true if condition is '()'
        if (exitPosition != null) {
          if (statement.semicolon.isSynthetic) {
            _insertBuilder(sb);
            sb = new SourceBuilder(file, exitPosition.offset + 1);
            sb.append(';');
          }
        }
      } else {
        if (sb.exitOffset == null && sb2?.exitOffset != null) {
          _insertBuilder(sb);
          sb = sb2;
          sb.append(';');
        } else {
          sb.append(sb2.toString());
        }
      }
    } else {
      sb.append(" while (");
      sb.setExitOffset();
      sb.append(");");
    }
    _insertBuilder(sb);
    if (exitDelta != 0) {
      exitPosition =
          new Position(exitPosition.file, exitPosition.offset + exitDelta);
    }
    _setCompletion(DartStatementCompletion.COMPLETE_DO_STMT);
    return true;
  }

  bool _complete_forEachStatement() {
    if (node is! ForEachStatement) {
      return false;
    }
    ForEachStatement forNode = node;
    if (forNode.inKeyword.isSynthetic) {
      return false; // Can't happen -- would be parsed as a for-statement.
    }
    SourceBuilder sb =
        new SourceBuilder(file, forNode.rightParenthesis.offset + 1);
    AstNode name = forNode.identifier;
    name ??= forNode.loopVariable;
    String src = utils.getNodeText(forNode);
    if (name == null) {
      exitPosition = new Position(file, forNode.leftParenthesis.offset + 1);
      src = src.substring(forNode.leftParenthesis.offset - forNode.offset);
      if (src.startsWith(new RegExp(r'\(\s*in\s*\)'))) {
        _addReplaceEdit(
            range.startOffsetEndOffset(forNode.leftParenthesis.offset + 1,
                forNode.rightParenthesis.offset),
            ' in ');
      } else if (src.startsWith(new RegExp(r'\(\s*in'))) {
        _addReplaceEdit(
            range.startOffsetEndOffset(
                forNode.leftParenthesis.offset + 1, forNode.inKeyword.offset),
            ' ');
      }
    } else if (_isSyntheticExpression(forNode.iterable)) {
      exitPosition = new Position(file, forNode.rightParenthesis.offset + 1);
      src = src.substring(forNode.inKeyword.offset - forNode.offset);
      if (src.startsWith(new RegExp(r'in\s*\)'))) {
        _addReplaceEdit(
            range.startOffsetEndOffset(
                forNode.inKeyword.offset + forNode.inKeyword.length,
                forNode.rightParenthesis.offset),
            ' ');
      }
    }
    if (!_statementHasValidBody(forNode.forKeyword, forNode.body)) {
      sb.append(' ');
      _appendEmptyBraces(sb, exitPosition == null);
    }
    _insertBuilder(sb);
    _setCompletion(DartStatementCompletion.COMPLETE_FOR_EACH_STMT);
    return true;
  }

  bool _complete_forStatement() {
    if (node is! ForStatement) {
      return false;
    }
    ForStatement forNode = node;
    SourceBuilder sb;
    int replacementLength = 0;
    if (forNode.leftParenthesis.isSynthetic) {
      if (!forNode.rightParenthesis.isSynthetic) {
        return false;
      }
      // keywordOnly (unit test name suffix that exercises this branch)
      sb = _sourceBuilderAfterKeyword(forNode.forKeyword);
      sb.append('(');
      sb.setExitOffset();
      sb.append(')');
    } else {
      if (!forNode.rightSeparator.isSynthetic) {
        // Fully-defined init, cond, updaters so nothing more needed here.
        // emptyParts, noError
        sb = new SourceBuilder(file, forNode.rightParenthesis.offset + 1);
      } else if (!forNode.leftSeparator.isSynthetic) {
        if (_isSyntheticExpression(forNode.condition)) {
          String text = utils
              .getNodeText(forNode)
              .substring(forNode.leftSeparator.offset - forNode.offset);
          Match match =
              new RegExp(r';\s*(/\*.*\*/\s*)?\)[ \t]*').matchAsPrefix(text);
          if (match != null) {
            // emptyCondition, emptyInitializersEmptyCondition
            replacementLength = match.end - match.start;
            sb = new SourceBuilder(file, forNode.leftSeparator.offset);
            sb.append('; ${match.group(1) == null ? '' : match.group(1)}; )');
            String suffix = text.substring(match.end);
            if (suffix.trim().isNotEmpty) {
              sb.append(' ');
              sb.append(suffix.trim());
              replacementLength += suffix.length;
              if (suffix.endsWith(eol)) {
                // emptyCondition
                replacementLength -= eol.length;
              }
            }
            exitPosition = _newPosition(forNode.leftSeparator.offset + 2);
          } else {
            return false; // Line comment in condition
          }
        } else {
          // emptyUpdaters
          sb = new SourceBuilder(file, forNode.rightParenthesis.offset);
          replacementLength = 1;
          sb.append('; )');
          exitPosition = _newPosition(forNode.rightSeparator.offset + 2);
        }
      } else if (_isSyntheticExpression(forNode.initialization)) {
        // emptyInitializers
        exitPosition = _newPosition(forNode.rightParenthesis.offset);
        sb = new SourceBuilder(file, forNode.rightParenthesis.offset);
      } else {
        int start = forNode.condition.offset + forNode.condition.length;
        String text =
            utils.getNodeText(forNode).substring(start - forNode.offset);
        if (text.startsWith(new RegExp(r'\s*\)'))) {
          // missingLeftSeparator
          int end = text.indexOf(')');
          sb = new SourceBuilder(file, start);
          _addReplaceEdit(new SourceRange(start, end), '; ; ');
          exitPosition = new Position(file, start - (end - '; '.length));
        } else {
          // Not possible; any comment following init is attached to init.
          exitPosition = _newPosition(forNode.rightParenthesis.offset);
          sb = new SourceBuilder(file, forNode.rightParenthesis.offset);
        }
      }
    }
    if (!_statementHasValidBody(forNode.forKeyword, forNode.body)) {
      // keywordOnly, noError
      sb.append(' ');
      _appendEmptyBraces(sb, true /*exitPosition == null*/);
    } else if (forNode.body is Block) {
      Block body = forNode.body;
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

  bool _complete_functionDeclaration() {
    if (node is! MethodDeclaration && node is! FunctionDeclaration) {
      return false;
    }
    bool needsParen = false;
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
      FunctionDeclaration func = node;
      paramListEnd = computeExitPos(func.functionExpression.parameters);
    } else {
      MethodDeclaration meth = node;
      paramListEnd = computeExitPos(meth.parameters);
    }
    SourceBuilder sb = new SourceBuilder(file, paramListEnd);
    if (needsParen) {
      sb.append(')');
    }
    sb.append(' ');
    _appendEmptyBraces(sb, true);
    _insertBuilder(sb);
    _setCompletion(DartStatementCompletion.COMPLETE_FUNCTION_DECLARATION);
    return true;
  }

  bool _complete_functionDeclarationStatement() {
    if (node is! FunctionDeclarationStatement) {
      return false;
    }
    var error = _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
    if (error != null) {
      FunctionDeclarationStatement stmt = node;
      String src = utils.getNodeText(stmt);
      int insertOffset = stmt.functionDeclaration.end - 1;
      if (stmt.functionDeclaration.functionExpression.body
          is ExpressionFunctionBody) {
        ExpressionFunctionBody fnb =
            stmt.functionDeclaration.functionExpression.body;
        int fnbOffset = fnb.functionDefinition.offset;
        String fnSrc = src.substring(fnbOffset - stmt.offset);
        if (!fnSrc.startsWith('=>')) {
          return false;
        }
        int delta = 0;
        if (fnb.expression.isSynthetic) {
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

  bool _complete_ifOrWhileStatement(
      _KeywordConditionBlockStructure statement, StatementCompletionKind kind) {
    if (_statementHasValidBody(statement.keyword, statement.block)) {
      return false;
    }
    SourceBuilder sb = _complete_keywordCondition(statement);
    if (sb == null) {
      return false;
    }
    int overshoot = _lengthOfDeletions();
    sb.append(' ');
    _appendEmptyBraces(sb, exitPosition == null);
    _insertBuilder(sb);
    if (overshoot != 0) {
      exitPosition = _newPosition(exitPosition.offset - overshoot);
    }
    _setCompletion(kind);
    return true;
  }

  bool _complete_ifStatement() {
    if (node is! IfStatement) {
      return false;
    }
    IfStatement ifNode = node;
    if (ifNode.elseKeyword != null) {
      if (selectionOffset >= ifNode.elseKeyword.end &&
          ifNode.elseStatement is EmptyStatement) {
        SourceBuilder sb = new SourceBuilder(file, selectionOffset);
        String src = utils.getNodeText(ifNode);
        if (!src
            .substring(ifNode.elseKeyword.end - node.offset)
            .startsWith(new RegExp(r'[ \t]'))) {
          sb.append(' ');
        }
        _appendEmptyBraces(sb, true);
        _insertBuilder(sb);
        _setCompletion(DartStatementCompletion.COMPLETE_IF_STMT);
        return true;
      }
      return false;
    }
    var stmt = new _KeywordConditionBlockStructure(
        ifNode.ifKeyword,
        ifNode.leftParenthesis,
        ifNode.condition,
        ifNode.rightParenthesis,
        ifNode.thenStatement);
    return _complete_ifOrWhileStatement(
        stmt, DartStatementCompletion.COMPLETE_IF_STMT);
  }

  SourceBuilder _complete_keywordCondition(
      _KeywordConditionBlockStructure statement) {
    SourceBuilder sb;
    if (statement.leftParenthesis.isSynthetic) {
      if (!statement.rightParenthesis.isSynthetic) {
        // Quite unlikely to see this so don't try to fix it.
        return null;
      }
      sb = _sourceBuilderAfterKeyword(statement.keyword);
      sb.append('(');
      sb.setExitOffset();
      sb.append(')');
    } else {
      if (_isSyntheticExpression(statement.condition)) {
        exitPosition = _newPosition(statement.leftParenthesis.offset + 1);
        sb = new SourceBuilder(file, statement.rightParenthesis.offset + 1);
      } else {
        int afterParen = statement.rightParenthesis.offset + 1;
        if (utils
            .getNodeText(node)
            .substring(afterParen - node.offset)
            .startsWith(new RegExp(r'[ \t]'))) {
          _addReplaceEdit(new SourceRange(afterParen, 1), '');
          sb = new SourceBuilder(file, afterParen + 1);
        } else {
          sb = new SourceBuilder(file, afterParen);
        }
      }
    }
    return sb;
  }

  bool _complete_methodCall() {
    var parenError =
        _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "')'") ??
            _findError(ScannerErrorCode.EXPECTED_TOKEN, partialMatch: "')'");
    if (parenError == null) {
      return false;
    }
    AstNode argList = _selectedNode(at: selectionOffset)
        .getAncestor((n) => n is ArgumentList);
    if (argList == null) {
      argList = _selectedNode(at: parenError.offset)
          .getAncestor((n) => n is ArgumentList);
    }
    if (argList?.getAncestor((n) => n == node) == null) {
      return false;
    }
    int previousInsertions = _lengthOfInsertions();
    int loc = min(selectionOffset, argList.end - 1);
    int delta = 1;
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
    String indent = utils.getLinePrefix(selectionOffset);
    int exit = utils.getLineNext(selectionOffset);
    _addInsertEdit(exit, indent + eol);
    exit += indent.length + eol.length + previousInsertions;

    _setCompletionAt(DartStatementCompletion.SIMPLE_ENTER, exit + delta);
    return true;
  }

  bool _complete_simpleEnter() {
    int offset;
    if (!errors.isEmpty) {
      offset = selectionOffset;
    } else {
      String indent = utils.getLinePrefix(selectionOffset);
      int loc = utils.getLineNext(selectionOffset);
      _addInsertEdit(loc, indent + eol);
      offset = loc + indent.length;
    }
    _setCompletionAt(DartStatementCompletion.SIMPLE_ENTER, offset);
    return true;
  }

  bool _complete_simpleSemicolon() {
    if (errors.length != 1) {
      return false;
    }
    var error = _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
    if (error != null) {
      int previousInsertions = _lengthOfInsertions();
      // TODO(messick) Fix this to find the correct place in all cases.
      int insertOffset = error.offset + error.length;
      _addInsertEdit(insertOffset, ';');
      int offset = _appendNewlinePlusIndent() + 1 /*';'*/ + previousInsertions;
      _setCompletionAt(DartStatementCompletion.SIMPLE_SEMICOLON, offset);
      return true;
    }
    return false;
  }

  bool _complete_switchStatement() {
    if (node is! SwitchStatement) {
      return false;
    }
    SourceBuilder sb;
    SwitchStatement switchNode = node;
    if (switchNode.leftParenthesis.isSynthetic &&
        switchNode.rightParenthesis.isSynthetic) {
      exitPosition = new Position(file, switchNode.switchKeyword.end + 2);
      String src = utils.getNodeText(switchNode);
      if (src
          .substring(switchNode.switchKeyword.end - switchNode.offset)
          .startsWith(new RegExp(r'[ \t]+'))) {
        sb = new SourceBuilder(file, switchNode.switchKeyword.end + 1);
      } else {
        sb = new SourceBuilder(file, switchNode.switchKeyword.end);
        sb.append(' ');
      }
      sb.append('()');
    } else if (switchNode.leftParenthesis.isSynthetic ||
        switchNode.rightParenthesis.isSynthetic) {
      return false;
    } else {
      sb = new SourceBuilder(file, switchNode.rightParenthesis.offset + 1);
      if (_isSyntheticExpression(switchNode.expression)) {
        exitPosition =
            new Position(file, switchNode.leftParenthesis.offset + 1);
      }
    }
    if (switchNode
        .leftBracket.isSynthetic /*&& switchNode.rightBracket.isSynthetic*/) {
      // See https://github.com/dart-lang/sdk/issues/29391
      sb.append(' ');
      _appendEmptyBraces(sb, exitPosition == null);
    } else {
      SwitchMember member = _findInvalidElement(switchNode.members);
      if (member != null) {
        if (member.colon.isSynthetic) {
          int loc =
              member is SwitchCase ? member.expression.end : member.keyword.end;
          sb = new SourceBuilder(file, loc);
          sb.append(': ');
          exitPosition = new Position(file, loc + 2);
        }
      }
    }
    _insertBuilder(sb);
    _setCompletion(DartStatementCompletion.COMPLETE_SWITCH_STMT);
    return true;
  }

  bool _complete_tryStatement() {
    if (node is! TryStatement) {
      return false;
    }
    TryStatement tryNode = node;
    SourceBuilder sb;
    CatchClause catchNode;
    bool addSpace = true;
    if (tryNode.body.leftBracket.isSynthetic) {
      String src = utils.getNodeText(tryNode);
      if (src
          .substring(tryNode.tryKeyword.end - tryNode.offset)
          .startsWith(new RegExp(r'[ \t]+'))) {
        // keywordSpace
        sb = new SourceBuilder(file, tryNode.tryKeyword.end + 1);
      } else {
        // keywordOnly
        sb = new SourceBuilder(file, tryNode.tryKeyword.end);
        sb.append(' ');
      }
      _appendEmptyBraces(sb, true);
      _insertBuilder(sb);
      sb = null;
    } else if ((catchNode = _findInvalidElement(tryNode.catchClauses)) !=
        null) {
      if (catchNode.onKeyword != null) {
        if (catchNode.exceptionType.length == 0 ||
            null !=
                _findError(StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE,
                    partialMatch: "name 'catch")) {
          String src = utils.getNodeText(catchNode);
          if (src.startsWith(new RegExp(r'on[ \t]+'))) {
            if (src.startsWith(new RegExp(r'on[ \t][ \t]+'))) {
              // onSpaces
              exitPosition = new Position(file, catchNode.onKeyword.end + 1);
              sb = new SourceBuilder(file, catchNode.onKeyword.end + 2);
              addSpace = false;
            } else {
              // onSpace
              sb = new SourceBuilder(file, catchNode.onKeyword.end + 1);
              sb.setExitOffset();
            }
          } else {
            // onOnly
            sb = new SourceBuilder(file, catchNode.onKeyword.end);
            sb.append(' ');
            sb.setExitOffset();
          }
        } else {
          // onType
          sb = new SourceBuilder(file, catchNode.exceptionType.end);
        }
      }
      if (catchNode.catchKeyword != null) {
        // catchOnly
        var struct = new _KeywordConditionBlockStructure(
            catchNode.catchKeyword,
            catchNode.leftParenthesis,
            catchNode.exceptionParameter,
            catchNode.rightParenthesis,
            catchNode.body);
        if (sb != null) {
          // onCatch
          _insertBuilder(sb);
        }
        sb = _complete_keywordCondition(struct);
        if (sb == null) {
          return false;
        }
      }
      if (catchNode.body.leftBracket.isSynthetic) {
        // onOnly and others
        if (addSpace) {
          sb.append(' ');
        }
        _appendEmptyBraces(sb, exitPosition == null);
      }
      _insertBuilder(sb);
    } else if (tryNode.finallyKeyword != null) {
      if (tryNode.finallyBlock.leftBracket.isSynthetic) {
        // finallyOnly
        sb = new SourceBuilder(file, tryNode.finallyKeyword.end);
        sb.append(' ');
        _appendEmptyBraces(sb, true);
        _insertBuilder(sb);
      }
    }
    _setCompletion(DartStatementCompletion.COMPLETE_TRY_STMT);
    return true;
  }

  bool _complete_variableDeclaration() {
    if (node is! VariableDeclaration) {
      return false;
    }
    _addInsertEdit(node.end, ';');
    exitPosition = new Position(file, _appendNewlinePlusIndentAt(node.end) + 1);
    _setCompletion(DartStatementCompletion.COMPLETE_VARIABLE_DECLARATION);
    return true;
  }

  bool _complete_whileStatement() {
    if (node is! WhileStatement) {
      return false;
    }
    WhileStatement whileNode = node;
    if (whileNode != null) {
      var stmt = new _KeywordConditionBlockStructure(
          whileNode.whileKeyword,
          whileNode.leftParenthesis,
          whileNode.condition,
          whileNode.rightParenthesis,
          whileNode.body);
      return _complete_ifOrWhileStatement(
          stmt, DartStatementCompletion.COMPLETE_WHILE_STMT);
    }
    return false;
  }

  engine.AnalysisError _findError(ErrorCode code, {partialMatch: null}) {
    return errors.firstWhere(
        (err) =>
            err.errorCode == code &&
            (partialMatch == null ? true : err.message.contains(partialMatch)),
        orElse: () => null);
  }

  T _findInvalidElement<T extends AstNode>(NodeList<T> list) {
    return list.firstWhere(
        (item) => selectionOffset >= item.offset && selectionOffset <= item.end,
        orElse: () => null);
  }

  LinkedEditGroup _getLinkedPosition(String groupId) {
    LinkedEditGroup group = linkedPositionGroups[groupId];
    if (group == null) {
      group = new LinkedEditGroup.empty();
      linkedPositionGroups[groupId] = group;
    }
    return group;
  }

  void _insertBuilder(SourceBuilder builder, [int length = 0]) {
    {
      SourceRange range = new SourceRange(builder.offset, length);
      String text = builder.toString();
      _addReplaceEdit(range, text);
    }
    // add linked positions
    builder.linkedPositionGroups.forEach((String id, LinkedEditGroup group) {
      LinkedEditGroup fixGroup = _getLinkedPosition(id);
      group.positions.forEach((Position position) {
        fixGroup.addPosition(position, group.length);
      });
      group.suggestions.forEach((LinkedEditSuggestion suggestion) {
        fixGroup.addSuggestion(suggestion);
      });
    });
    // add exit position
    {
      int exitOffset = builder.exitOffset;
      if (exitOffset != null) {
        exitPosition = _newPosition(exitOffset);
      }
    }
  }

  bool _isEmptyBlock(AstNode stmt) {
    return stmt is Block && stmt.statements.isEmpty;
  }

  bool _isEmptyStatement(AstNode stmt) {
    return stmt is EmptyStatement || _isEmptyBlock(stmt);
  }

  bool _isNonStatementDeclaration(AstNode n) {
    if (n is! Declaration) {
      return false;
    }
    if (n is! VariableDeclaration && n is! FunctionDeclaration) {
      return true;
    }
    AstNode p = n.parent;
    return p is! Statement && p?.parent is! Statement;
  }

  bool _isSyntheticExpression(Expression expr) {
    return expr is SimpleIdentifier && expr.isSynthetic;
  }

  int _lengthOfDeletions() {
    if (change.edits.isEmpty) {
      return 0;
    }
    int length = 0;
    for (SourceFileEdit edit in change.edits) {
      for (SourceEdit srcEdit in edit.edits) {
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
    int length = 0;
    for (SourceFileEdit edit in change.edits) {
      for (SourceEdit srcEdit in edit.edits) {
        if (srcEdit.length == 0) {
          length += srcEdit.replacement.length;
        }
      }
    }
    return length;
  }

  Position _newPosition(int offset) {
    return new Position(file, offset);
  }

  void _removeError(errorCode, {partialMatch = null}) {
    var error = _findError(errorCode, partialMatch: partialMatch);
    if (error != null) {
      errors.remove(error);
    }
  }

  AstNode _selectedNode({int at: null}) =>
      new NodeLocator(at == null ? selectionOffset : at).searchWithin(unit);

  void _setCompletion(StatementCompletionKind kind, [List args]) {
    assert(exitPosition != null);
    change.selection = exitPosition;
    change.message = formatList(kind.message, args);
    linkedPositionGroups.values
        .forEach((group) => change.addLinkedEditGroup(group));
    completion = new StatementCompletion(kind, change);
  }

  void _setCompletionAt(StatementCompletionKind kind, int offset, [List args]) {
    exitPosition = _newPosition(offset);
    _setCompletion(kind, args);
  }

  SourceBuilder _sourceBuilderAfterKeyword(Token keyword) {
    SourceBuilder sb;
    String text = _baseNodeText(node);
    text = text.substring(keyword.offset - node.offset);
    int len = keyword.length;
    if (text.length == len || // onCatchComment
        !text.substring(len, len + 1).contains(new RegExp(r'[ \t]'))) {
      sb = new SourceBuilder(file, keyword.offset + len);
      sb.append(' ');
    } else {
      sb = new SourceBuilder(file, keyword.offset + len + 1);
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
      Block block = body;
      return (!(block.leftBracket.isSynthetic));
    }
    return (lineInfo.getLocation(keyword.offset) ==
        lineInfo.getLocation(body.offset));
  }
}

// Encapsulate common structure of if-statement and while-statement.
class _KeywordConditionBlockStructure {
  final Token keyword;
  final Token leftParenthesis, rightParenthesis;
  final Expression condition;
  final Statement block;

  _KeywordConditionBlockStructure(this.keyword, this.leftParenthesis,
      this.condition, this.rightParenthesis, this.block);

  int get offset => keyword.offset;
}
