// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.completion.statement;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/source_buffer.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An enumeration of possible statement completion kinds.
 */
class DartStatementCompletion {
  static const NO_COMPLETION =
      const StatementCompletionKind('No_COMPLETION', 'No completion available');
  static const PLAIN_OLE_ENTER = const StatementCompletionKind(
      'PLAIN_OLE_ENTER', "Insert a newline at the end of the current line");
  static const SIMPLE_SEMICOLON = const StatementCompletionKind(
      'SIMPLE_SEMICOLON', "Add a semicolon and newline");
  static const COMPLETE_IF_STMT = const StatementCompletionKind(
      'COMPLETE_IF_STMT', "Complete if-statement");
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
  final AnalysisContext analysisContext;
  final CorrectionUtils utils;
  int fileStamp;
  AstNode node;
  StatementCompletion completion;
  SourceChange change = new SourceChange('statement-completion');
  List errors = <engine.AnalysisError>[];
  final Map<String, LinkedEditGroup> linkedPositionGroups =
      <String, LinkedEditGroup>{};
  Position exitPosition = null;

  StatementCompletionProcessor(this.statementContext)
      : analysisContext = statementContext.unitElement.context,
        utils = new CorrectionUtils(statementContext.unit) {
    fileStamp = analysisContext.getModificationStamp(source);
  }

  String get eol => utils.endOfLine;

  String get file => statementContext.file;

  LineInfo get lineInfo => statementContext.lineInfo;

  int get requestLine => lineInfo.getLocation(selectionOffset).lineNumber;

  int get selectionOffset => statementContext.selectionOffset;

  Source get source => statementContext.unitElement.source;

  CompilationUnit get unit => statementContext.unit;

  CompilationUnitElement get unitElement => statementContext.unitElement;

  Future<StatementCompletion> compute() async {
    // If the source was changed between the constructor and running
    // this asynchronous method, it is not safe to use the unit.
    if (analysisContext.getModificationStamp(source) != fileStamp) {
      return NO_COMPLETION;
    }
    node = new NodeLocator(selectionOffset).searchWithin(unit);
    if (node == null) {
      return NO_COMPLETION;
    }
    // TODO(messick): This needs to work for declarations.
    node = node.getAncestor((n) => n is Statement);
    for (engine.AnalysisError error in statementContext.errors) {
      if (error.offset >= node.offset &&
          error.offset <= node.offset + node.length) {
        if (error.errorCode is! HintCode) {
          errors.add(error);
        }
      }
    }

    if (_complete_ifStatement() ||
        _complete_whileStatement() ||
        _complete_simpleSemicolon() ||
        _complete_plainOleEnter()) {
      return completion;
    }
    return NO_COMPLETION;
  }

  void _addIndentEdit(SourceRange range, String oldIndent, String newIndent) {
    SourceEdit edit = utils.createIndentEdit(range, oldIndent, newIndent);
    doSourceChange_addElementEdit(change, unitElement, edit);
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
    sb.append(' {');
    sb.append(eol);
    String indent = utils.getLinePrefix(selectionOffset);
    sb.append(indent);
    sb.append(utils.getIndent(1));
    if (needsExitMark) {
      sb.setExitOffset();
    }
    sb.append(eol);
    sb.append(indent);
    sb.append('}');
  }

  int _appendNewlinePlusIndent() {
    // Append a newline plus proper indent and another newline.
    // Return the position before the second newline.
    String indent = utils.getLinePrefix(selectionOffset);
    int loc = utils.getLineNext(selectionOffset);
    _addInsertEdit(loc, indent + eol);
    return loc + indent.length;
  }

  bool _complete_ifOrWhileStatement(
      _IfWhileStructure statement, StatementCompletionKind kind) {
    String text = utils.getNodeText(node);
    if (text.endsWith(eol)) {
      text = text.substring(0, text.length - eol.length);
    }
    SourceBuilder sb;
    bool needsExit = false;
    if (statement.leftParenthesis.lexeme.isEmpty) {
      if (!statement.rightParenthesis.lexeme.isEmpty) {
        // Quite unlikely to see this so don't try to fix it.
        return false;
      }
      int len = statement.keyword.length;
      if (text.length == len ||
          !text.substring(len, len + 1).contains(new RegExp(r'\s'))) {
        sb = new SourceBuilder(file, statement.offset + len);
        sb.append(' ');
      } else {
        sb = new SourceBuilder(file, statement.offset + len + 1);
      }
      sb.append('(');
      sb.setExitOffset();
      sb.append(')');
    } else {
      if (_isEmptyExpression(statement.condition)) {
        exitPosition = _newPosition(statement.leftParenthesis.offset + 1);
        sb = new SourceBuilder(file, statement.rightParenthesis.offset + 1);
      } else {
        sb = new SourceBuilder(file, statement.rightParenthesis.offset + 1);
        needsExit = true;
      }
    }
    if (statement.block is EmptyStatement) {
      _appendEmptyBraces(sb, needsExit);
    }
    _insertBuilder(sb);
    _setCompletion(kind);
    return true;
  }

  bool _complete_ifStatement() {
    if (errors.isEmpty || node is! IfStatement) {
      return false;
    }
    IfStatement ifNode = node;
    if (ifNode != null) {
      if (ifNode.elseKeyword != null) {
        return false;
      }
      var stmt = new _IfWhileStructure(ifNode.ifKeyword, ifNode.leftParenthesis,
          ifNode.condition, ifNode.rightParenthesis, ifNode.thenStatement);
      return _complete_ifOrWhileStatement(
          stmt, DartStatementCompletion.COMPLETE_IF_STMT);
    }
    return false;
  }

  bool _complete_plainOleEnter() {
    int offset;
    if (!errors.isEmpty) {
      offset = selectionOffset;
    } else {
      String indent = utils.getLinePrefix(selectionOffset);
      int loc = utils.getLineNext(selectionOffset);
      _addInsertEdit(loc, indent + eol);
      offset = loc + indent.length + eol.length;
    }
    _setCompletionAt(DartStatementCompletion.PLAIN_OLE_ENTER, offset);
    return true;
  }

  bool _complete_simpleSemicolon() {
    if (errors.length != 1) {
      return false;
    }
    var error = _findError(ParserErrorCode.EXPECTED_TOKEN, partialMatch: "';'");
    if (error != null) {
      int insertOffset = error.offset + error.length;
      _addInsertEdit(insertOffset, ';');
      int offset = _appendNewlinePlusIndent() + 1 /* ';' */;
      _setCompletionAt(DartStatementCompletion.SIMPLE_SEMICOLON, offset);
      return true;
    }
    return false;
  }

  bool _complete_whileStatement() {
    if (errors.isEmpty || node is! WhileStatement) {
      return false;
    }
    WhileStatement whileNode = node;
    if (whileNode != null) {
      var stmt = new _IfWhileStructure(
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
    var error =
        errors.firstWhere((err) => err.errorCode == code, orElse: () => null);
    if (error != null) {
      if (partialMatch != null) {
        return error.message.contains(partialMatch) ? error : null;
      }
      return error;
    }
    return null;
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
      SourceRange range = rangeStartLength(builder.offset, length);
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

  bool _isEmptyExpression(Expression expr) {
    if (expr is! SimpleIdentifier) {
      return false;
    }
    SimpleIdentifier id = expr as SimpleIdentifier;
    return id.length == 0;
  }

  Position _newPosition(int offset) {
    return new Position(file, offset);
  }

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
}

// Encapsulate common structure of if-statement and while-statement.
class _IfWhileStructure {
  final Token keyword;
  final Token leftParenthesis, rightParenthesis;
  final Expression condition;
  final Statement block;

  _IfWhileStructure(this.keyword, this.leftParenthesis, this.condition,
      this.rightParenthesis, this.block);

  int get offset => keyword.offset;
}
