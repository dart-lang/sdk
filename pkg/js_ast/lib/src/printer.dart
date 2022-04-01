// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.15

library js_ast.printer;

import 'characters.dart' as char_codes;
import 'nodes.dart';
import 'precedence.dart';
import 'strings.dart';

class JavaScriptPrintingOptions {
  final bool utf8;
  final bool shouldCompressOutput;
  final bool minifyLocalVariables;
  final bool preferSemicolonToNewlineInMinifiedOutput;

  const JavaScriptPrintingOptions({
    this.utf8 = false,
    this.shouldCompressOutput = false,
    this.minifyLocalVariables = false,
    this.preferSemicolonToNewlineInMinifiedOutput = false,
  });
}

/// An environment in which JavaScript printing is done.  Provides emitting of
/// text and pre- and post-visit callbacks.
abstract class JavaScriptPrintingContext {
  /// Signals an error.  This should happen only for serious internal errors.
  void error(String message) {
    throw message;
  }

  /// Adds [string] to the output.
  void emit(String string);

  /// Callback for the start of printing of [node]. [startPosition] is the
  /// position of the first non-whitespace character of [node].
  ///
  /// [enterNode] is called in pre-traversal order.
  void enterNode(Node node, int startPosition) {}

  /// Callback for the end of printing of [node]. [startPosition] is the
  /// position of the first non-whitespace character of [node] (also provided
  /// in the [enterNode] callback), [endPosition] is the position immediately
  /// following the last character of [node]. [closingPosition] is the
  /// position of the ending delimiter of [node]. This is only provided for
  /// [Fun] nodes and is `null` otherwise.
  ///
  /// [enterNode] is called in post-traversal order.
  void exitNode(
      Node node, int startPosition, int endPosition, int? closingPosition) {}

  /// Should return `true` if the printing tolerates unfinalized deferred AST
  /// nodes.
  bool get isDebugContext => false;
}

/// A simple implementation of [JavaScriptPrintingContext] suitable for tests.
class SimpleJavaScriptPrintingContext extends JavaScriptPrintingContext {
  final StringBuffer buffer = StringBuffer();

  @override
  void emit(String string) {
    buffer.write(string);
  }

  String getText() => buffer.toString();
}

class _DebugJavaScriptPrintingContext extends SimpleJavaScriptPrintingContext {
  @override
  bool get isDebugContext => true;
}

String DebugPrint(Node node, {bool utf8 = false}) {
  JavaScriptPrintingOptions options = JavaScriptPrintingOptions(utf8: utf8);
  SimpleJavaScriptPrintingContext context = _DebugJavaScriptPrintingContext();
  Printer printer = Printer(options, context);
  printer.visit(node);
  return context.getText();
}

class Printer implements NodeVisitor<void> {
  final JavaScriptPrintingOptions options;
  final JavaScriptPrintingContext context;
  final bool shouldCompressOutput;
  final DanglingElseVisitor danglingElseVisitor;
  final LocalNamer localNamer;
  final bool isDebugContext;

  int _charCount = 0;
  bool inForInit = false;
  bool atStatementBegin = false;
  bool pendingSemicolon = false;
  bool pendingSpace = false;

  // The current indentation level.
  int _indentLevel = 0;
  // A cache of all indentation strings used so far.
  final List<String> _indentList = [''];

  static final identifierCharacterRegExp = RegExp(r'^[a-zA-Z_0-9$]');
  static final expressionContinuationRegExp = RegExp(r'^[-+([]');

  Printer(this.options, this.context)
      : isDebugContext = context.isDebugContext,
        shouldCompressOutput = options.shouldCompressOutput,
        danglingElseVisitor = DanglingElseVisitor(context),
        localNamer = determineRenamer(
            options.shouldCompressOutput, options.minifyLocalVariables);

  static LocalNamer determineRenamer(
      bool shouldCompressOutput, bool allowVariableMinification) {
    return (shouldCompressOutput && allowVariableMinification)
        ? MinifyRenamer()
        : IdentityNamer();
  }

  // The current indentation string.
  String get indentation {
    // Lazily add new indentation strings as required.
    while (_indentList.length <= _indentLevel) {
      _indentList.add('${_indentList.last}  ');
    }
    return _indentList[_indentLevel];
  }

  void indentMore() {
    _indentLevel++;
  }

  void indentLess() {
    _indentLevel--;
  }

  /// Always emit a newline, even under `enableMinification`.
  void forceLine() {
    out('\n', isWhitespace: true);
  }

  /// Emits a newline for readability.
  void lineOut() {
    if (!shouldCompressOutput) forceLine();
  }

  void spaceOut() {
    if (!shouldCompressOutput) out(' ', isWhitespace: true);
  }

  String lastAddedString = '\u0000';

  int get lastCharCode {
    assert(lastAddedString.isNotEmpty);
    return lastAddedString.codeUnitAt(lastAddedString.length - 1);
  }

  void out(String str, {bool isWhitespace = false}) {
    if (str != '') {
      if (pendingSemicolon) {
        if (!shouldCompressOutput) {
          _emit(';');
        } else if (str != '}') {
          // We want to output newline instead of semicolon because it makes
          // the raw stack traces much easier to read and it also makes line-
          // based tools like diff work much better.  JavaScript will
          // automatically insert the semicolon at the newline if it means a
          // parsing error is avoided, so we can only do this trick if the
          // next line is not something that can be glued onto a valid
          // expression to make a new valid expression.

          // If we're using the new emitter where most pretty printed code
          // is escaped in strings, it is a lot easier to deal with semicolons
          // than newlines because the former doesn't need escaping.
          if (options.preferSemicolonToNewlineInMinifiedOutput ||
              expressionContinuationRegExp.hasMatch(str)) {
            _emit(';');
          } else {
            _emit('\n');
          }
        }
      }
      if (pendingSpace &&
          (!shouldCompressOutput || identifierCharacterRegExp.hasMatch(str))) {
        _emit(' ');
      }
      pendingSpace = false;
      pendingSemicolon = false;
      if (!isWhitespace) {
        enterNode();
      }
      _emit(str);
      lastAddedString = str;
    }
  }

  void outLn(String str) {
    out(str);
    lineOut();
  }

  void outSemicolonLn() {
    if (shouldCompressOutput) {
      pendingSemicolon = true;
    } else {
      out(';');
      forceLine();
    }
  }

  void outIndent(String str) {
    indent();
    out(str);
  }

  void outIndentLn(String str) {
    indent();
    outLn(str);
  }

  void indent() {
    if (!shouldCompressOutput) {
      out(indentation, isWhitespace: true);
    }
  }

  EnterExitNode? currentNode;

  void _emit(String text) {
    context.emit(text);
    _charCount += text.length;
  }

  void startNode(Node node) {
    currentNode = EnterExitNode(currentNode, node);
    if (node is DeferredExpression) {
      if (!isDebugContext || node.isFinalized) {
        startNode(node.value);
      }
    }
  }

  void enterNode() {
    currentNode!.addToNode(context, _charCount);
  }

  void endNode(Node node) {
    if (node is DeferredExpression) {
      if (!isDebugContext || node.isFinalized) {
        endNode(node.value);
      }
    }
    assert(currentNode!.node == node);
    currentNode = currentNode!.exitNode(context, _charCount);
  }

  void visit(Node node) {
    startNode(node);
    node.accept(this);
    endNode(node);
  }

  void visitCommaSeparated(List<Expression> nodes, int hasRequiredType,
      {required bool newInForInit, required bool newAtStatementBegin}) {
    for (int i = 0; i < nodes.length; i++) {
      if (i != 0) {
        atStatementBegin = false;
        out(',');
        spaceOut();
      }
      visitNestedExpression(nodes[i], hasRequiredType,
          newInForInit: newInForInit, newAtStatementBegin: newAtStatementBegin);
    }
  }

  void visitAll(List<Node> nodes) {
    nodes.forEach(visit);
  }

  Expression _undefer(Expression node) {
    if (isDebugContext && !node.isFinalized) return node;
    if (node is DeferredExpression) return _undefer(node.value);
    return node;
  }

  @override
  void visitProgram(Program program) {
    if (program.body.isNotEmpty) {
      visitAll(program.body);
    }
  }

  Statement unwrapBlockIfSingleStatement(Statement body) {
    Statement result = body;
    while (result is Block) {
      Block block = result;
      if (block.statements.length != 1) break;
      result = block.statements.single;
    }
    return result;
  }

  bool blockBody(Statement body,
      {required bool needsSeparation, required bool needsNewline}) {
    if (body is Block) {
      spaceOut();
      blockOut(body, shouldIndent: false, needsNewline: needsNewline);
      return true;
    }
    if (shouldCompressOutput && needsSeparation) {
      // If [shouldCompressOutput] is false, then the 'lineOut' will insert
      // the separation.
      out(' ', isWhitespace: true);
    } else {
      lineOut();
    }
    indentMore();
    visit(body);
    indentLess();
    return false;
  }

  /// Elide Blocks and DeferredStatements with Blocks as children.
  void blockOutWithoutBraces(Node node) {
    if (node is Block) {
      startNode(node);
      Block block = node;
      block.statements.forEach(blockOutWithoutBraces);
      endNode(node);
    } else if (node is DeferredStatement) {
      startNode(node);
      blockOutWithoutBraces(node.statement);
      endNode(node);
    } else {
      visit(node);
    }
  }

  int blockOut(Block node,
      {required bool shouldIndent, required bool needsNewline}) {
    if (shouldIndent) indent();
    startNode(node);
    out('{');
    lineOut();
    indentMore();
    node.statements.forEach(blockOutWithoutBraces);
    indentLess();
    indent();
    out('}');
    int closingPosition = _charCount - 1;
    endNode(node);
    if (needsNewline) lineOut();
    return closingPosition;
  }

  @override
  void visitBlock(Block block) {
    blockOut(block, shouldIndent: true, needsNewline: true);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    indent();
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: true);
    outSemicolonLn();
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    outIndentLn(';');
  }

  void ifOut(If node, bool shouldIndent) {
    Statement then = unwrapBlockIfSingleStatement(node.then);
    Statement elsePart = node.otherwise;
    bool hasElse = node.hasElse;

    // Handle dangling elses and a work-around for Android 4.0 stock browser.
    // Android 4.0 requires braces for a single do-while in the `then` branch.
    // See issue 10923.
    if (hasElse) {
      bool needsBraces = then.accept(danglingElseVisitor) || then is Do;
      if (needsBraces) {
        then = Block(<Statement>[then]);
      }
    }
    if (shouldIndent) indent();
    out('if');
    spaceOut();
    out('(');
    visitNestedExpression(node.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    bool thenWasBlock =
        blockBody(then, needsSeparation: false, needsNewline: !hasElse);
    if (hasElse) {
      if (thenWasBlock) {
        spaceOut();
      } else {
        indent();
      }
      out('else');
      if (elsePart is If) {
        pendingSpace = true;
        startNode(elsePart);
        ifOut(elsePart, false);
        endNode(elsePart);
      } else {
        blockBody(unwrapBlockIfSingleStatement(elsePart),
            needsSeparation: true, needsNewline: true);
      }
    }
  }

  @override
  void visitIf(If node) {
    ifOut(node, true);
  }

  @override
  void visitFor(For loop) {
    outIndent('for');
    spaceOut();
    out('(');
    if (loop.init != null) {
      visitNestedExpression(loop.init!, EXPRESSION,
          newInForInit: true, newAtStatementBegin: false);
    }
    out(';');
    if (loop.condition != null) {
      spaceOut();
      visitNestedExpression(loop.condition!, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(';');
    if (loop.update != null) {
      spaceOut();
      visitNestedExpression(loop.update!, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(')');
    blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: false, needsNewline: true);
  }

  @override
  void visitForIn(ForIn loop) {
    outIndent('for');
    spaceOut();
    out('(');
    visitNestedExpression(loop.leftHandSide, EXPRESSION,
        newInForInit: true, newAtStatementBegin: false);
    out(' in');
    pendingSpace = true;
    visitNestedExpression(loop.object, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: false, needsNewline: true);
  }

  @override
  void visitWhile(While loop) {
    outIndent('while');
    spaceOut();
    out('(');
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: false, needsNewline: true);
  }

  @override
  void visitDo(Do loop) {
    outIndent('do');
    if (blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: true, needsNewline: false)) {
      spaceOut();
    } else {
      indent();
    }
    out('while');
    spaceOut();
    out('(');
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    outSemicolonLn();
  }

  @override
  void visitContinue(Continue node) {
    if (node.targetLabel == null) {
      outIndent('continue');
    } else {
      outIndent('continue ${node.targetLabel}');
    }
    outSemicolonLn();
  }

  @override
  void visitBreak(Break node) {
    if (node.targetLabel == null) {
      outIndent('break');
    } else {
      outIndent('break ${node.targetLabel}');
    }
    outSemicolonLn();
  }

  @override
  void visitReturn(Return node) {
    final value = node.value;
    if (value == null) {
      outIndent('return');
    } else {
      outIndent('return');
      pendingSpace = true;
      visitNestedExpression(value, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    // Set the closing position to be before the optional semicolon.
    currentNode!.closingPosition = _charCount;
    outSemicolonLn();
  }

  @override
  void visitDartYield(DartYield node) {
    if (node.hasStar) {
      outIndent('yield*');
    } else {
      outIndent('yield');
    }
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitThrow(Throw node) {
    outIndent('throw');
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitTry(Try node) {
    outIndent('try');
    blockBody(node.body, needsSeparation: true, needsNewline: false);
    if (node.catchPart != null) {
      visit(node.catchPart!);
    }
    if (node.finallyPart != null) {
      spaceOut();
      out('finally');
      blockBody(node.finallyPart!, needsSeparation: true, needsNewline: true);
    } else {
      lineOut();
    }
  }

  @override
  void visitCatch(Catch node) {
    spaceOut();
    out('catch');
    spaceOut();
    out('(');
    visitNestedExpression(node.declaration, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    blockBody(node.body, needsSeparation: false, needsNewline: false);
  }

  @override
  void visitSwitch(Switch node) {
    outIndent('switch');
    spaceOut();
    out('(');
    visitNestedExpression(node.key, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    spaceOut();
    outLn('{');
    indentMore();
    visitAll(node.cases);
    indentLess();
    outIndentLn('}');
  }

  @override
  void visitCase(Case node) {
    outIndent('case');
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outLn(':');
    if (node.body.statements.isNotEmpty) {
      indentMore();
      blockOutWithoutBraces(node.body);
      indentLess();
    }
  }

  @override
  void visitDefault(Default node) {
    outIndentLn('default:');
    if (node.body.statements.isNotEmpty) {
      indentMore();
      blockOutWithoutBraces(node.body);
      indentLess();
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    Statement body = unwrapBlockIfSingleStatement(node.body);
    // `label: break label;`
    // Does not work on IE. The statement is a nop, so replace it by an empty
    // statement.
    // See:
    // https://connect.microsoft.com/IE/feedback/details/891889/parser-bugs
    if (body is Break && body.targetLabel == node.label) {
      visit(EmptyStatement());
      return;
    }
    outIndent('${node.label}:');
    blockBody(body, needsSeparation: false, needsNewline: true);
  }

  int functionOut(Fun fun, Expression? name, VarCollector vars) {
    out('function');
    if (name != null) {
      out(' ');
      // Name must be a [Decl]. Therefore only test for primary expressions.
      visitNestedExpression(name, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    localNamer.enterScope(vars);
    out('(');
    visitCommaSeparated(fun.params, PRIMARY,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    switch (fun.asyncModifier) {
      case AsyncModifier.sync:
        break;
      case AsyncModifier.async:
        out(' ', isWhitespace: true);
        out('async');
        break;
      case AsyncModifier.syncStar:
        out(' ', isWhitespace: true);
        out('sync*');
        break;
      case AsyncModifier.asyncStar:
        out(' ', isWhitespace: true);
        out('async*');
        break;
    }
    spaceOut();
    int closingPosition =
        blockOut(fun.body, shouldIndent: false, needsNewline: false);
    localNamer.leaveScope();
    return closingPosition;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration declaration) {
    VarCollector vars = VarCollector();
    vars.visitFunctionDeclaration(declaration);
    indent();
    startNode(declaration.function);
    currentNode!.closingPosition =
        functionOut(declaration.function, declaration.name, vars);
    endNode(declaration.function);
    lineOut();
  }

  void visitNestedExpression(Expression node, int requiredPrecedence,
      {required bool newInForInit, required bool newAtStatementBegin}) {
    int precedenceLevel =
        (isDebugContext && !node.isFinalized) ? CALL : node.precedenceLevel;
    bool needsParentheses =
        // a - (b + c).
        (requiredPrecedence != EXPRESSION &&
                precedenceLevel < requiredPrecedence) ||
            // for (a = (x in o); ... ; ... ) { ... }
            (newInForInit && node is Binary && node.op == 'in') ||
            // (function() { ... })().
            // ({a: 2, b: 3}.toString()).
            (newAtStatementBegin &&
                (node is NamedFunction ||
                    node is FunctionExpression ||
                    node is ObjectInitializer));
    if (needsParentheses) {
      inForInit = false;
      atStatementBegin = false;
      out('(');
      visit(node);
      out(')');
    } else {
      inForInit = newInForInit;
      atStatementBegin = newAtStatementBegin;
      visit(node);
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList list) {
    out('var ');
    final nodes = list.declarations;
    if (inForInit) {
      visitCommaSeparated(nodes, ASSIGNMENT,
          newInForInit: inForInit, newAtStatementBegin: false);
    } else {
      // Print 'big' declarations on their own line, while keeping adjacent
      // small and uninitialized declarations on the same line.
      bool useIndent = nodes.length > 1 && list.indentSplits;
      if (useIndent) {
        indentMore();
      }
      bool lastWasBig = false;
      for (int i = 0; i < nodes.length; i++) {
        Expression node = nodes[i];
        bool thisIsBig = !_isSmallInitialization(node);
        if (i > 0) {
          atStatementBegin = false;
          out(',');
          if (lastWasBig || thisIsBig) {
            lineOut();
            indent();
          } else {
            spaceOut();
          }
        }
        visitNestedExpression(node, ASSIGNMENT,
            newInForInit: inForInit, newAtStatementBegin: false);
        lastWasBig = thisIsBig;
      }
      if (useIndent) {
        indentLess();
      }
    }
  }

  bool _isSmallInitialization(Node node) {
    if (node is VariableInitialization) {
      if (node.value == null) return true;
      Node value = _undefer(node.value!);
      if (value is This) return true;
      if (value is LiteralNull) return true;
      if (value is LiteralNumber) return true;
      if (value is LiteralString && value.value.length <= 6) return true;
      if (value is ObjectInitializer && value.properties.isEmpty) return true;
      if (value is ArrayInitializer && value.elements.isEmpty) return true;
      if (value is Name && value.name.length <= 6) return true;
    }
    return false;
  }

  void _outputIncDec(String op, Expression variable, [Expression? alias]) {
    if (op == '+') {
      if (lastCharCode == char_codes.$PLUS) out(' ', isWhitespace: true);
      out('++');
    } else {
      if (lastCharCode == char_codes.$MINUS) out(' ', isWhitespace: true);
      out('--');
    }
    if (alias != null) startNode(alias);
    visitNestedExpression(variable, UNARY,
        newInForInit: inForInit, newAtStatementBegin: false);
    if (alias != null) endNode(alias);
  }

  @override
  void visitAssignment(Assignment assignment) {
    /// To print assignments like `a = a + 1` and `a = a + b` compactly as
    /// `++a` and `a += b` in the face of [DeferredExpression]s we detect the
    /// pattern of the undeferred assignment.
    String? op = assignment.op;
    Node leftHandSide = _undefer(assignment.leftHandSide);
    Node rightHandSide = _undefer(assignment.value);
    if ((op == '+' || op == '-') &&
        leftHandSide is VariableUse &&
        rightHandSide is LiteralNumber &&
        rightHandSide.value == '1') {
      // Output 'a += 1' as '++a' and 'a -= 1' as '--a'.
      _outputIncDec(op!, assignment.leftHandSide);
      return;
    }
    if (!assignment.isCompound &&
        leftHandSide is VariableUse &&
        rightHandSide is Binary) {
      Expression rLeft = _undefer(rightHandSide.left);
      Expression rRight = _undefer(rightHandSide.right);
      String? op = rightHandSide.op;
      if (op == '+' ||
          op == '-' ||
          op == '/' ||
          op == '*' ||
          op == '%' ||
          op == '^' ||
          op == '&' ||
          op == '|') {
        if (rLeft is VariableUse && rLeft.name == leftHandSide.name) {
          // Output 'a = a + 1' as '++a' and 'a = a - 1' as '--a'.
          if ((op == '+' || op == '-') &&
              rRight is LiteralNumber &&
              rRight.value == '1') {
            _outputIncDec(op, assignment.leftHandSide, rightHandSide.left);
            return;
          }
          // Output 'a = a + b' as 'a += b'.
          startNode(rightHandSide.left);
          visitNestedExpression(assignment.leftHandSide, CALL,
              newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
          endNode(rightHandSide.left);
          spaceOut();
          out(op);
          out('=');
          spaceOut();
          visitNestedExpression(rRight, ASSIGNMENT,
              newInForInit: inForInit, newAtStatementBegin: false);
          return;
        }
      }
    }
    visitNestedExpression(assignment.leftHandSide, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);

    spaceOut();
    if (op != null) out(op);
    out('=');
    spaceOut();
    visitNestedExpression(assignment.value, ASSIGNMENT,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitVariableInitialization(VariableInitialization initialization) {
    visitNestedExpression(initialization.declaration, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    if (initialization.value != null) {
      spaceOut();
      out('=');
      spaceOut();
      visitNestedExpression(initialization.value!, ASSIGNMENT,
          newInForInit: inForInit, newAtStatementBegin: false);
    }
  }

  @override
  void visitConditional(Conditional cond) {
    visitNestedExpression(cond.condition, LOGICAL_OR,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    spaceOut();
    out('?');
    spaceOut();
    // The then part is allowed to have an 'in'.
    visitNestedExpression(cond.then, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    spaceOut();
    out(':');
    spaceOut();
    visitNestedExpression(cond.otherwise, ASSIGNMENT,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitNew(New node) {
    out('new ');
    visitNestedExpression(node.target, LEFT_HAND_SIDE,
        newInForInit: inForInit, newAtStatementBegin: false);
    out('(');
    visitCommaSeparated(node.arguments, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
  }

  @override
  void visitCall(Call call) {
    visitNestedExpression(call.target, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out('(');
    visitCommaSeparated(call.arguments, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
  }

  @override
  void visitBinary(Binary binary) {
    Expression left = binary.left;
    Expression right = binary.right;
    String op = binary.op;
    int leftPrecedenceRequirement;
    int rightPrecedenceRequirement;
    bool leftSpace = true; // left<HERE>op right
    switch (op) {
      case ',':
        //  x, (y, z) <=> (x, y), z.
        leftPrecedenceRequirement = EXPRESSION;
        rightPrecedenceRequirement = EXPRESSION;
        leftSpace = false;
        break;
      case '||':
        leftPrecedenceRequirement = LOGICAL_OR;
        // x || (y || z) <=> (x || y) || z.
        rightPrecedenceRequirement = LOGICAL_OR;
        break;
      case '&&':
        leftPrecedenceRequirement = LOGICAL_AND;
        // x && (y && z) <=> (x && y) && z.
        rightPrecedenceRequirement = LOGICAL_AND;
        break;
      case '|':
        leftPrecedenceRequirement = BIT_OR;
        // x | (y | z) <=> (x | y) | z.
        rightPrecedenceRequirement = BIT_OR;
        break;
      case '^':
        leftPrecedenceRequirement = BIT_XOR;
        // x ^ (y ^ z) <=> (x ^ y) ^ z.
        rightPrecedenceRequirement = BIT_XOR;
        break;
      case '&':
        leftPrecedenceRequirement = BIT_AND;
        // x & (y & z) <=> (x & y) & z.
        rightPrecedenceRequirement = BIT_AND;
        break;
      case '==':
      case '!=':
      case '===':
      case '!==':
        leftPrecedenceRequirement = EQUALITY;
        rightPrecedenceRequirement = RELATIONAL;
        break;
      case '<':
      case '>':
      case '<=':
      case '>=':
      case 'instanceof':
      case 'in':
        leftPrecedenceRequirement = RELATIONAL;
        rightPrecedenceRequirement = SHIFT;
        break;
      case '>>':
      case '<<':
      case '>>>':
        leftPrecedenceRequirement = SHIFT;
        rightPrecedenceRequirement = ADDITIVE;
        break;
      case '+':
      case '-':
        leftPrecedenceRequirement = ADDITIVE;
        // We cannot remove parenthesis for "+" because
        //   x + (y + z) <!=> (x + y) + z:
        // Example:
        //   "a" + (1 + 2) => "a3";
        //   ("a" + 1) + 2 => "a12";
        rightPrecedenceRequirement = MULTIPLICATIVE;
        break;
      case '*':
      case '/':
      case '%':
        leftPrecedenceRequirement = MULTIPLICATIVE;
        // We cannot remove parenthesis for "*" because of precision issues.
        rightPrecedenceRequirement = UNARY;
        break;
      default:
        leftPrecedenceRequirement = EXPRESSION;
        rightPrecedenceRequirement = EXPRESSION;
        context.error('Forgot operator: $op');
    }

    visitNestedExpression(left, leftPrecedenceRequirement,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);

    if (op == 'in' || op == 'instanceof') {
      // There are cases where the space is not required but without further
      // analysis we cannot know.
      out(' ', isWhitespace: true);
      out(op);
      out(' ', isWhitespace: true);
    } else {
      if (leftSpace) spaceOut();
      out(op);
      spaceOut();
    }
    visitNestedExpression(right, rightPrecedenceRequirement,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitPrefix(Prefix unary) {
    String op = unary.op;
    switch (op) {
      case 'delete':
      case 'void':
      case 'typeof':
        // There are cases where the space is not required but without further
        // analysis we cannot know.
        out(op);
        out(' ', isWhitespace: true);
        break;
      case '+':
      case '++':
        if (lastCharCode == char_codes.$PLUS) out(' ', isWhitespace: true);
        out(op);
        break;
      case '-':
      case '--':
        if (lastCharCode == char_codes.$MINUS) out(' ', isWhitespace: true);
        out(op);
        break;
      default:
        out(op);
    }
    visitNestedExpression(unary.argument, UNARY,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitPostfix(Postfix postfix) {
    visitNestedExpression(postfix.argument, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out(postfix.op);
  }

  @override
  void visitVariableUse(VariableUse ref) {
    out(localNamer.getName(ref.name));
  }

  @override
  void visitThis(This node) {
    out('this');
  }

  @override
  void visitVariableDeclaration(VariableDeclaration decl) {
    out(localNamer.getName(decl.name));
  }

  @override
  void visitParameter(Parameter param) {
    out(localNamer.getName(param.name));
  }

  bool isDigit(int charCode) {
    return char_codes.$0 <= charCode && charCode <= char_codes.$9;
  }

  bool isValidJavaScriptId(String field) {
    if (field.isEmpty) return false;
    // Ignore the leading and trailing string-delimiter.
    for (int i = 0; i < field.length; i++) {
      // TODO(floitsch): allow more characters.
      int charCode = field.codeUnitAt(i);
      if (!(char_codes.$a <= charCode && charCode <= char_codes.$z ||
          char_codes.$A <= charCode && charCode <= char_codes.$Z ||
          charCode == char_codes.$$ ||
          charCode == char_codes.$_ ||
          i > 0 && isDigit(charCode))) {
        return false;
      }
    }
    // TODO(floitsch): normally we should also check that the field is not a
    // reserved word.  We don't generate fields with reserved word names except
    // for 'super'.
    if (field == 'super') return false;
    if (field == 'catch') return false;
    return true;
  }

  @override
  void visitAccess(PropertyAccess access) {
    visitNestedExpression(access.receiver, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);

    Node selector = _undefer(access.selector);
    if (isDebugContext && !selector.isFinalized) {
      _dotString(
          access.selector, access.receiver, selector.nonfinalizedDebugText(),
          assumeValid: true);
      return;
    }
    if (selector is LiteralString) {
      _dotString(access.selector, access.receiver, selector.value);
      return;
    }
    if (selector is StringConcatenation) {
      _dotString(access.selector, access.receiver,
          _StringContentsCollector(isDebugContext).collect(selector));
      return;
    }
    if (selector is Name) {
      _dotString(access.selector, access.receiver, selector.name);
      return;
    }

    out('[');
    visitNestedExpression(access.selector, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(']');
  }

  void _dotString(Node selector, Expression receiver, String selectorValue,
      {bool assumeValid = false}) {
    if (assumeValid || isValidJavaScriptId(selectorValue)) {
      if (_undefer(receiver) is LiteralNumber &&
          lastCharCode != char_codes.$CLOSE_PAREN) {
        out(' ', isWhitespace: true);
      }
      out('.');
      startNode(selector);
      out(selectorValue);
      endNode(selector);
    } else {
      out('[');
      _handleString(selectorValue);
      out(']');
    }
  }

  @override
  void visitNamedFunction(NamedFunction namedFunction) {
    VarCollector vars = VarCollector();
    vars.visitNamedFunction(namedFunction);
    startNode(namedFunction.function);
    int closingPosition = currentNode!.closingPosition =
        functionOut(namedFunction.function, namedFunction.name, vars);
    endNode(namedFunction.function);
    // Use closing position of `namedFunction.function` as the closing position
    // of the named function itself.
    currentNode!.closingPosition = closingPosition;
  }

  @override
  void visitFun(Fun fun) {
    VarCollector vars = VarCollector();
    vars.visitFun(fun);
    currentNode!.closingPosition = functionOut(fun, null, vars);
  }

  @override
  void visitArrowFunction(ArrowFunction fun) {
    VarCollector vars = VarCollector();
    vars.visitArrowFunction(fun);
    currentNode!.closingPosition = arrowFunctionOut(fun, vars);
  }

  static bool _isIdentifierParameter(Node node) => node is VariableReference;

  int arrowFunctionOut(ArrowFunction fun, VarCollector vars) {
    // TODO: support static, get/set, async, and generators.
    localNamer.enterScope(vars);
    final List<Parameter> params = fun.params;
    if (params.length == 1 && _isIdentifierParameter(params.first)) {
      visitNestedExpression(params.single, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
    } else {
      out('(');
      visitCommaSeparated(fun.params, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
      out(')');
    }
    spaceOut();
    out('=>');
    spaceOut();
    int closingPosition;
    Node body = fun.body;
    // Simplify arrow functions that return a single expression.
    // Note that this can result in some sourcemapped positions disappearing
    // around the elided Return. See http://dartbug.com/47354
    if (fun.implicitReturnAllowed && body is Block) {
      final statement = unwrapBlockIfSingleStatement(body);
      if (statement is Return) {
        body = statement.value!;
      }
    }
    if (body is Block) {
      closingPosition =
          blockOut(body, shouldIndent: false, needsNewline: false);
    } else {
      // Object initializers require parentheses to disambiguate
      // AssignmentExpression from FunctionBody. See:
      // https://tc39.github.io/ecma262/#sec-arrow-function-definitions
      bool needsParens = body is ObjectInitializer;
      if (needsParens) out('(');
      visitNestedExpression(body as Expression, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
      if (needsParens) out(')');
      closingPosition = _charCount;
    }
    localNamer.leaveScope();
    return closingPosition;
  }

  @override
  void visitDeferredExpression(DeferredExpression node) {
    if (isDebugContext && !node.isFinalized) {
      out(node.nonfinalizedDebugText());
      return;
    }
    // Continue printing with the expression value.
    assert(node.precedenceLevel == node.value.precedenceLevel);
    node.value.accept(this);
  }

  @override
  void visitDeferredStatement(DeferredStatement node) {
    startNode(node);
    visit(node.statement);
    endNode(node);
  }

  void outputNumberWithRequiredWhitespace(String number) {
    int charCode = number.codeUnitAt(0);
    if (charCode == char_codes.$MINUS && lastCharCode == char_codes.$MINUS) {
      out(' ', isWhitespace: true);
    }
    out(number);
  }

  @override
  void visitDeferredNumber(DeferredNumber node) {
    outputNumberWithRequiredWhitespace('${node.value}');
  }

  @override
  void visitDeferredString(DeferredString node) {
    out(node.value);
  }

  @override
  void visitLiteralBool(LiteralBool node) {
    out(node.value ? 'true' : 'false');
  }

  @override
  void visitLiteralString(LiteralString node) {
    if (isDebugContext && !node.isFinalized) {
      _handleString(node.nonfinalizedDebugText());
      return;
    }
    _handleString(node.value);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    _handleString(_StringContentsCollector(isDebugContext).collect(node));
  }

  void _handleString(String value) {
    final kind = StringToSource.analyze(value, utf8: options.utf8);
    out(kind.quote);
    if (kind.simple) {
      out(value);
    } else {
      final sb = StringBuffer();
      StringToSource.writeString(sb, value, kind, utf8: options.utf8);
      out(sb.toString());
    }
    out(kind.quote);
  }

  @override
  void visitName(Name node) {
    if (isDebugContext && !node.isFinalized) {
      out(node.nonfinalizedDebugText());
      return;
    }
    out(node.name);
  }

  @override
  void visitParentheses(Parentheses node) {
    out('(');
    visitNestedExpression(node.enclosed, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
  }

  @override
  void visitLiteralNumber(LiteralNumber node) {
    outputNumberWithRequiredWhitespace(node.value);
  }

  @override
  void visitLiteralNull(LiteralNull node) {
    out('null');
  }

  @override
  void visitArrayInitializer(ArrayInitializer node) {
    out('[');
    List<Expression> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      Expression element = elements[i];
      if (element is ArrayHole) {
        // Note that array holes must have a trailing "," even if they are
        // in last position. Otherwise `[,]` (having length 1) would become
        // equal to `[]` (the empty array)
        // and [1,,] (array with 1 and a hole) would become [1,] = [1].
        startNode(element);
        out(',');
        endNode(element);
        continue;
      }
      if (i != 0) spaceOut();
      visitNestedExpression(element, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
      // We can skip the trailing "," for the last element (since it's not
      // an array hole).
      if (i != elements.length - 1) out(',');
    }
    out(']');
  }

  @override
  void visitArrayHole(ArrayHole node) {
    context.error('Unreachable');
  }

  @override
  void visitObjectInitializer(ObjectInitializer node) {
    // Print all the properties on one line until we see a function-valued
    // property.  Ideally, we would use a proper pretty-printer to make the
    // decision based on layout.
    bool exitOneLinerMode(Expression value) {
      return value is Fun ||
          value is ArrayInitializer && value.elements.any((e) => e is Fun);
    }

    bool isOneLiner = node.isOneLiner || shouldCompressOutput;
    List<Property> properties = node.properties;
    out('{');
    indentMore();
    for (int i = 0; i < properties.length; i++) {
      Expression value = properties[i].value;
      if (isOneLiner && exitOneLinerMode(value)) isOneLiner = false;
      if (i != 0) {
        out(',');
        if (isOneLiner) spaceOut();
      }
      if (!isOneLiner) {
        forceLine();
        indent();
      }
      visit(properties[i]);
    }
    indentLess();
    if (!isOneLiner && properties.isNotEmpty) {
      lineOut();
      indent();
    }
    out('}');
  }

  @override
  void visitProperty(Property node) {
    propertyNameOut(node);
    out(':');
    spaceOut();
    visitNestedExpression(node.value, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
  }

  @override
  void visitMethodDefinition(MethodDefinition node) {
    propertyNameOut(node);
    VarCollector vars = VarCollector();
    vars.visitMethodDefinition(node);
    startNode(node.function);
    currentNode!.closingPosition = methodOut(node, vars);
    endNode(node.function);
  }

  int methodOut(MethodDefinition node, VarCollector vars) {
    // TODO: support static, get/set, async, and generators.
    Fun fun = node.function;
    localNamer.enterScope(vars);
    out('(');
    visitCommaSeparated(fun.params, PRIMARY,
        newInForInit: false, newAtStatementBegin: false);
    out(')');
    spaceOut();
    int closingPosition =
        blockOut(fun.body, shouldIndent: false, needsNewline: false);
    localNamer.leaveScope();
    return closingPosition;
  }

  void propertyNameOut(Property node) {
    startNode(node.name);
    Node name = _undefer(node.name);
    if (name is LiteralString) {
      _outPropertyName(name.value);
    } else if (name is Name) {
      _outPropertyName(name.name);
    } else if (name is LiteralNumber) {
      out(name.value);
    } else {
      // TODO(sra): Handle StringConcatenation.
      // TODO(sra): Handle general expressions, .e.g. `{[x]: 1}`.
      throw StateError('Unexpected Property name: $name');
    }
    endNode(node.name);
  }

  void _outPropertyName(String name) {
    if (isValidJavaScriptId(name)) {
      out(name);
    } else {
      _handleString(name);
    }
  }

  @override
  void visitRegExpLiteral(RegExpLiteral node) {
    out(node.pattern);
  }

  @override
  void visitLiteralExpression(LiteralExpression node) {
    out(node.template);
  }

  @override
  void visitLiteralStatement(LiteralStatement node) {
    outLn(node.code);
  }

  void visitInterpolatedNode(InterpolatedNode node) {
    out('#${node.nameOrPosition}');
  }

  @override
  void visitInterpolatedExpression(InterpolatedExpression node) =>
      visitInterpolatedNode(node);

  @override
  void visitInterpolatedLiteral(InterpolatedLiteral node) =>
      visitInterpolatedNode(node);

  @override
  void visitInterpolatedParameter(InterpolatedParameter node) =>
      visitInterpolatedNode(node);

  @override
  void visitInterpolatedSelector(InterpolatedSelector node) =>
      visitInterpolatedNode(node);

  @override
  void visitInterpolatedStatement(InterpolatedStatement node) {
    outLn('#${node.nameOrPosition}');
  }

  @override
  void visitInterpolatedDeclaration(InterpolatedDeclaration node) {
    visitInterpolatedNode(node);
  }

  @override
  void visitComment(Comment node) {
    if (shouldCompressOutput) return;
    String comment = node.comment.trim();
    if (comment.isEmpty) return;
    for (var line in comment.split('\n')) {
      if (comment.startsWith('//')) {
        outIndentLn(line.trim());
      } else {
        outIndentLn('// ${line.trim()}');
      }
    }
  }

  @override
  void visitAwait(Await node) {
    out('await ');
    visit(node.expression);
  }
}

class _StringContentsCollector extends BaseVisitorVoid {
  final StringBuffer _buffer = StringBuffer();
  final bool isDebugContext;

  _StringContentsCollector(this.isDebugContext);

  String collect(Node node) {
    node.accept(this);
    return _buffer.toString();
  }

  void _add(String value) {
    _buffer.write(value);
  }

  @override
  void visitNode(Node node) {
    throw StateError('Node should not be part of StringConcatenation: $node');
  }

  @override
  void visitLiteralString(LiteralString node) {
    if (isDebugContext && !node.isFinalized) {
      _add(node.nonfinalizedDebugText());
    } else {
      _add(node.value);
    }
  }

  @override
  void visitLiteralNumber(LiteralNumber node) {
    if (isDebugContext && !node.isFinalized) {
      _add(node.nonfinalizedDebugText());
    } else {
      _add(node.value);
    }
  }

  @override
  void visitName(Name node) {
    if (isDebugContext && !node.isFinalized) {
      _add(node.nonfinalizedDebugText());
    } else {
      _add(node.name);
    }
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    node.visitChildren(this);
  }
}

class OrderedSet<T> {
  final Set<T> set;
  final List<T> list;

  OrderedSet()
      : set = <T>{},
        list = <T>[];

  void add(T x) {
    if (set.add(x)) {
      // [Set.add] returns `true` if 'x' was added.
      list.add(x);
    }
  }

  void forEach(void Function(T x) fun) {
    list.forEach(fun);
  }
}

// Collects all the var declarations in the function.  We need to do this in a
// separate pass because JS vars are lifted to the top of the function.
class VarCollector extends BaseVisitorVoid {
  bool nested;
  bool enableRenaming = true;
  final OrderedSet<String> vars;
  final OrderedSet<String> params;

  static final String disableVariableMinificationPattern = '::norenaming::';
  static final String enableVariableMinificationPattern = '::dorenaming::';

  VarCollector()
      : nested = false,
        vars = OrderedSet<String>(),
        params = OrderedSet<String>();

  void forEachVar(void Function(String) fn) => vars.forEach(fn);
  void forEachParam(void Function(String) fn) => params.forEach(fn);

  void collectVarsInFunction(FunctionExpression fun) {
    if (!nested) {
      nested = true;
      for (int i = 0; i < fun.params.length; i++) {
        params.add(fun.params[i].name);
      }
      fun.body.accept(this);
      nested = false;
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration declaration) {
    // Note that we don't bother collecting the name of the function.
    collectVarsInFunction(declaration.function);
  }

  @override
  void visitNamedFunction(NamedFunction namedFunction) {
    // Note that we don't bother collecting the name of the function.
    collectVarsInFunction(namedFunction.function);
  }

  @override
  void visitMethodDefinition(MethodDefinition method) {
    // Note that we don't bother collecting the name of the function.
    collectVarsInFunction(method.function);
  }

  @override
  void visitFun(Fun fun) {
    collectVarsInFunction(fun);
  }

  @override
  void visitArrowFunction(ArrowFunction fun) {
    collectVarsInFunction(fun);
  }

  @override
  void visitThis(This node) {}

  @override
  void visitComment(Comment node) {
    if (node.comment.contains(disableVariableMinificationPattern)) {
      enableRenaming = false;
    } else if (node.comment.contains(enableVariableMinificationPattern)) {
      enableRenaming = true;
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration decl) {
    if (enableRenaming && decl.allowRename) vars.add(decl.name);
  }
}

/// Returns true, if the given node must be wrapped into braces when used
/// as then-statement in an [If] that has an else branch.
class DanglingElseVisitor extends BaseVisitor<bool> {
  JavaScriptPrintingContext context;

  DanglingElseVisitor(this.context);

  @override
  bool visitProgram(Program node) => false;

  @override
  bool visitNode(Node node) {
    context.error('Forgot node: $node');
    return true;
  }

  @override
  bool visitComment(Comment node) => true;

  @override
  bool visitBlock(Block node) => false;
  @override
  bool visitExpressionStatement(ExpressionStatement node) => false;
  @override
  bool visitEmptyStatement(EmptyStatement node) => false;
  @override
  bool visitDeferredStatement(DeferredStatement node) {
    return node.statement.accept(this);
  }

  @override
  bool visitIf(If node) {
    if (!node.hasElse) return true;
    return node.otherwise.accept(this);
  }

  @override
  bool visitFor(For node) => node.body.accept(this);
  @override
  bool visitForIn(ForIn node) => node.body.accept(this);
  @override
  bool visitWhile(While node) => node.body.accept(this);
  @override
  bool visitDo(Do node) => false;
  @override
  bool visitContinue(Continue node) => false;
  @override
  bool visitBreak(Break node) => false;
  @override
  bool visitReturn(Return node) => false;
  @override
  bool visitThrow(Throw node) => false;
  @override
  bool visitTry(Try node) {
    if (node.finallyPart != null) {
      return node.finallyPart!.accept(this);
    } else {
      return node.catchPart!.accept(this);
    }
  }

  @override
  bool visitCatch(Catch node) => node.body.accept(this);
  @override
  bool visitSwitch(Switch node) => false;
  @override
  bool visitCase(Case node) => false;
  @override
  bool visitDefault(Default node) => false;
  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) => false;
  @override
  bool visitLabeledStatement(LabeledStatement node) => node.body.accept(this);
  @override
  bool visitLiteralStatement(LiteralStatement node) => true;

  @override
  bool visitDartYield(DartYield node) => false;

  @override
  bool visitExpression(Expression node) => false;
}

abstract class LocalNamer {
  String getName(String oldName);
  String declareVariable(String oldName);
  String declareParameter(String oldName);
  void enterScope(VarCollector vars);
  void leaveScope();
}

class IdentityNamer implements LocalNamer {
  @override
  String getName(String oldName) => oldName;
  @override
  String declareVariable(String oldName) => oldName;
  @override
  String declareParameter(String oldName) => oldName;
  @override
  void enterScope(VarCollector vars) {}
  @override
  void leaveScope() {}
}

class MinifyRenamer implements LocalNamer {
  final List<Map<String, String>> maps = [];
  final List<int> parameterNumberStack = [];
  final List<int> variableNumberStack = [];
  int parameterNumber = 0;
  int variableNumber = 0;

  MinifyRenamer();

  @override
  void enterScope(VarCollector vars) {
    maps.add({});
    variableNumberStack.add(variableNumber);
    parameterNumberStack.add(parameterNumber);
    vars.forEachVar(declareVariable);
    vars.forEachParam(declareParameter);
  }

  @override
  void leaveScope() {
    maps.removeLast();
    variableNumber = variableNumberStack.removeLast();
    parameterNumber = parameterNumberStack.removeLast();
  }

  @override
  String getName(String oldName) {
    // Go from inner scope to outer looking for mapping of name.
    for (int i = maps.length - 1; i >= 0; i--) {
      var map = maps[i];
      var replacement = map[oldName];
      if (replacement != null) return replacement;
    }
    return oldName;
  }

  static const LOWER_CASE_LETTERS = 26;
  static const LETTERS = LOWER_CASE_LETTERS;
  static const DIGITS = 10;

  static int nthLetter(int n) {
    return (n < LOWER_CASE_LETTERS)
        ? char_codes.$a + n
        : char_codes.$A + n - LOWER_CASE_LETTERS;
  }

  // Parameters go from a to z and variables go from z to a.  This makes each
  // argument list and each top-of-function var declaration look similar and
  // helps gzip compress the file.  If we have more than 26 arguments and
  // variables then we meet somewhere in the middle of the alphabet.  After
  // that we give up trying to be nice to the compression algorithm and just
  // use the same namespace for arguments and variables, starting with A, and
  // moving on to a0, a1, etc.
  @override
  String declareVariable(String oldName) {
    if (avoidRenaming(oldName)) return oldName;
    String newName;
    if (variableNumber + parameterNumber < LOWER_CASE_LETTERS) {
      // Variables start from z and go backwards, for better gzipability.
      newName = getNameNumber(oldName, LOWER_CASE_LETTERS - 1 - variableNumber);
    } else {
      // After 26 variables and parameters we allocate them in the same order.
      newName = getNameNumber(oldName, variableNumber + parameterNumber);
    }
    variableNumber++;
    return newName;
  }

  @override
  String declareParameter(String oldName) {
    if (avoidRenaming(oldName)) return oldName;
    String newName;
    if (variableNumber + parameterNumber < LOWER_CASE_LETTERS) {
      newName = getNameNumber(oldName, parameterNumber);
    } else {
      newName = getNameNumber(oldName, variableNumber + parameterNumber);
    }
    parameterNumber++;
    return newName;
  }

  bool avoidRenaming(String oldName) {
    // Variables of this $form$ are used in pattern matching the message of JS
    // exceptions, so should not be renamed.
    // TODO(sra): Introduce a way for indicating in the JS text which variables
    // should not be renamed.
    return oldName.startsWith(r'$') && oldName.endsWith(r'$');
  }

  String getNameNumber(String oldName, int n) {
    if (maps.isEmpty) return oldName;

    String newName;
    if (n < LETTERS) {
      // Start naming variables a, b, c, ..., z, A, B, C, ..., Z.
      newName = String.fromCharCodes([nthLetter(n)]);
    } else {
      // Then name variables a0, a1, a2, ..., a9, b0, b1, ..., Z9, aa0, aa1, ...
      // For all functions with fewer than 500 locals this is just as compact
      // as using aa, ab, etc. but avoids clashes with keywords.
      n -= LETTERS;
      int digit = n % DIGITS;
      n ~/= DIGITS;
      int alphaChars = 1;
      int nameSpaceSize = LETTERS;
      // Find out whether we should use the 1-character namespace (size 52), the
      // 2-character namespace (size 52*52), etc.
      while (n >= nameSpaceSize) {
        n -= nameSpaceSize;
        alphaChars++;
        nameSpaceSize *= LETTERS;
      }
      var codes = <int>[];
      for (var i = 0; i < alphaChars; i++) {
        nameSpaceSize ~/= LETTERS;
        codes.add(nthLetter((n ~/ nameSpaceSize) % LETTERS));
      }
      codes.add(char_codes.$0 + digit);
      newName = String.fromCharCodes(codes);
    }
    assert(RegExp(r'[a-zA-Z][a-zA-Z0-9]*').hasMatch(newName));
    maps.last[oldName] = newName;
    return newName;
  }
}

/// Information pertaining the enter and exit callbacks for [node].
class EnterExitNode {
  final EnterExitNode? parent;
  final Node node;

  int? startPosition;
  int? closingPosition;

  EnterExitNode(this.parent, this.node);

  void addToNode(JavaScriptPrintingContext context, int position) {
    if (startPosition == null) {
      // [position] is the start position of [node].
      // This might be the start position of the parent as well.
      parent?.addToNode(context, position);
      startPosition = position;
      context.enterNode(node, position);
    }
  }

  EnterExitNode? exitNode(JavaScriptPrintingContext context, int position) {
    // Enter must happen before exit.
    addToNode(context, position);
    context.exitNode(node, startPosition!, position, closingPosition);
    return parent;
  }
}
