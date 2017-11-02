// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

typedef String Renamer(Name name);

class JavaScriptPrintingOptions {
  final bool shouldCompressOutput;
  final bool minifyLocalVariables;
  final bool preferSemicolonToNewlineInMinifiedOutput;
  final Renamer renamerForNames;

  JavaScriptPrintingOptions(
      {this.shouldCompressOutput: false,
      this.minifyLocalVariables: false,
      this.preferSemicolonToNewlineInMinifiedOutput: false,
      this.renamerForNames: identityRenamer});

  static String identityRenamer(Name name) => name.name;
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
      Node node, int startPosition, int endPosition, int closingPosition) {}
}

/// A simple implementation of [JavaScriptPrintingContext] suitable for tests.
class SimpleJavaScriptPrintingContext extends JavaScriptPrintingContext {
  final StringBuffer buffer = new StringBuffer();

  void emit(String string) {
    buffer.write(string);
  }

  String getText() => buffer.toString();
}

String DebugPrint(Node node) {
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions();
  SimpleJavaScriptPrintingContext context =
      new SimpleJavaScriptPrintingContext();
  Printer printer = new Printer(options, context);
  printer.visit(node);
  return context.getText();
}

class Printer implements NodeVisitor {
  final JavaScriptPrintingOptions options;
  final JavaScriptPrintingContext context;
  final bool shouldCompressOutput;
  final DanglingElseVisitor danglingElseVisitor;
  final LocalNamer localNamer;

  int _charCount = 0;
  bool inForInit = false;
  bool atStatementBegin = false;
  bool pendingSemicolon = false;
  bool pendingSpace = false;

  // The current indentation level.
  int _indentLevel = 0;
  // A cache of all indentation strings used so far.
  List<String> _indentList = <String>[""];

  static final identifierCharacterRegExp = new RegExp(r'^[a-zA-Z_0-9$]');
  static final expressionContinuationRegExp = new RegExp(r'^[-+([]');

  Printer(JavaScriptPrintingOptions options, JavaScriptPrintingContext context)
      : options = options,
        context = context,
        shouldCompressOutput = options.shouldCompressOutput,
        danglingElseVisitor = new DanglingElseVisitor(context),
        localNamer = determineRenamer(
            options.shouldCompressOutput, options.minifyLocalVariables);

  static LocalNamer determineRenamer(
      bool shouldCompressOutput, bool allowVariableMinification) {
    return (shouldCompressOutput && allowVariableMinification)
        ? new MinifyRenamer()
        : new IdentityNamer();
  }

  // The current indentation string.
  String get indentation {
    // Lazily add new indentation strings as required.
    while (_indentList.length <= _indentLevel) {
      _indentList.add(_indentList.last + "  ");
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
    out("\n", isWhitespace: true);
  }

  /// Emits a newline for readability.
  void lineOut() {
    if (!shouldCompressOutput) forceLine();
  }

  void spaceOut() {
    if (!shouldCompressOutput) out(" ", isWhitespace: true);
  }

  String lastAddedString = null;

  int get lastCharCode {
    if (lastAddedString == null) return 0;
    assert(lastAddedString.length != 0);
    return lastAddedString.codeUnitAt(lastAddedString.length - 1);
  }

  void out(String str, {bool isWhitespace: false}) {
    if (str != "") {
      if (pendingSemicolon) {
        if (!shouldCompressOutput) {
          _emit(";");
        } else if (str != "}") {
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
            _emit(";");
          } else {
            _emit("\n");
          }
        }
      }
      if (pendingSpace &&
          (!shouldCompressOutput || identifierCharacterRegExp.hasMatch(str))) {
        _emit(" ");
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
      out(";");
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

  EnterExitNode currentNode;

  void _emit(String text) {
    context.emit(text);
    _charCount += text.length;
  }

  void startNode(Node node) {
    currentNode = new EnterExitNode(currentNode, node);
  }

  void enterNode() {
    currentNode.addToNode(context, _charCount);
  }

  void endNode(Node node) {
    assert(currentNode.node == node);
    currentNode = currentNode.exitNode(context, _charCount);
  }

  void visit(Node node) {
    startNode(node);
    node.accept(this);
    endNode(node);
  }

  void visitCommaSeparated(List<Node> nodes, int hasRequiredType,
      {bool newInForInit, bool newAtStatementBegin}) {
    for (int i = 0; i < nodes.length; i++) {
      if (i != 0) {
        atStatementBegin = false;
        out(",");
        spaceOut();
      }
      visitNestedExpression(nodes[i], hasRequiredType,
          newInForInit: newInForInit, newAtStatementBegin: newAtStatementBegin);
    }
  }

  void visitAll(List<Node> nodes) {
    nodes.forEach(visit);
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

  bool blockBody(Statement body, {bool needsSeparation, bool needsNewline}) {
    if (body is Block) {
      spaceOut();
      blockOut(body, shouldIndent: false, needsNewline: needsNewline);
      return true;
    }
    if (shouldCompressOutput && needsSeparation) {
      // If [shouldCompressOutput] is false, then the 'lineOut' will insert
      // the separation.
      out(" ", isWhitespace: true);
    } else {
      lineOut();
    }
    indentMore();
    visit(body);
    indentLess();
    return false;
  }

  void blockOutWithoutBraces(Node node) {
    if (node is Block) {
      startNode(node);
      Block block = node;
      block.statements.forEach(blockOutWithoutBraces);
      endNode(node);
    } else {
      visit(node);
    }
  }

  int blockOut(Block node, {bool shouldIndent, bool needsNewline}) {
    if (shouldIndent) indent();
    startNode(node);
    out("{");
    lineOut();
    indentMore();
    node.statements.forEach(blockOutWithoutBraces);
    indentLess();
    indent();
    out("}");
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
    outIndentLn(";");
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
        then = new Block(<Statement>[then]);
      }
    }
    if (shouldIndent) indent();
    out("if");
    spaceOut();
    out("(");
    visitNestedExpression(node.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    bool thenWasBlock =
        blockBody(then, needsSeparation: false, needsNewline: !hasElse);
    if (hasElse) {
      if (thenWasBlock) {
        spaceOut();
      } else {
        indent();
      }
      out("else");
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
    outIndent("for");
    spaceOut();
    out("(");
    if (loop.init != null) {
      visitNestedExpression(loop.init, EXPRESSION,
          newInForInit: true, newAtStatementBegin: false);
    }
    out(";");
    if (loop.condition != null) {
      spaceOut();
      visitNestedExpression(loop.condition, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(";");
    if (loop.update != null) {
      spaceOut();
      visitNestedExpression(loop.update, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(")");
    blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: false, needsNewline: true);
  }

  @override
  void visitForIn(ForIn loop) {
    outIndent("for");
    spaceOut();
    out("(");
    visitNestedExpression(loop.leftHandSide, EXPRESSION,
        newInForInit: true, newAtStatementBegin: false);
    out(" in");
    pendingSpace = true;
    visitNestedExpression(loop.object, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: false, needsNewline: true);
  }

  @override
  void visitWhile(While loop) {
    outIndent("while");
    spaceOut();
    out("(");
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: false, needsNewline: true);
  }

  @override
  void visitDo(Do loop) {
    outIndent("do");
    if (blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: true, needsNewline: false)) {
      spaceOut();
    } else {
      indent();
    }
    out("while");
    spaceOut();
    out("(");
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    outSemicolonLn();
  }

  @override
  void visitContinue(Continue node) {
    if (node.targetLabel == null) {
      outIndent("continue");
    } else {
      outIndent("continue ${node.targetLabel}");
    }
    outSemicolonLn();
  }

  @override
  void visitBreak(Break node) {
    if (node.targetLabel == null) {
      outIndent("break");
    } else {
      outIndent("break ${node.targetLabel}");
    }
    outSemicolonLn();
  }

  @override
  void visitReturn(Return node) {
    if (node.value == null) {
      outIndent("return");
    } else {
      outIndent("return");
      pendingSpace = true;
      visitNestedExpression(node.value, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    outSemicolonLn();
  }

  @override
  void visitDartYield(DartYield node) {
    if (node.hasStar) {
      outIndent("yield*");
    } else {
      outIndent("yield");
    }
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitThrow(Throw node) {
    outIndent("throw");
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitTry(Try node) {
    outIndent("try");
    blockBody(node.body, needsSeparation: true, needsNewline: false);
    if (node.catchPart != null) {
      visit(node.catchPart);
    }
    if (node.finallyPart != null) {
      spaceOut();
      out("finally");
      blockBody(node.finallyPart, needsSeparation: true, needsNewline: true);
    } else {
      lineOut();
    }
  }

  @override
  void visitCatch(Catch node) {
    spaceOut();
    out("catch");
    spaceOut();
    out("(");
    visitNestedExpression(node.declaration, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    blockBody(node.body, needsSeparation: false, needsNewline: false);
  }

  @override
  void visitSwitch(Switch node) {
    outIndent("switch");
    spaceOut();
    out("(");
    visitNestedExpression(node.key, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    spaceOut();
    outLn("{");
    indentMore();
    visitAll(node.cases);
    indentLess();
    outIndentLn("}");
  }

  @override
  void visitCase(Case node) {
    outIndent("case");
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outLn(":");
    if (!node.body.statements.isEmpty) {
      indentMore();
      blockOutWithoutBraces(node.body);
      indentLess();
    }
  }

  @override
  void visitDefault(Default node) {
    outIndentLn("default:");
    if (!node.body.statements.isEmpty) {
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
      visit(new EmptyStatement());
      return;
    }
    outIndent("${node.label}:");
    blockBody(body, needsSeparation: false, needsNewline: true);
  }

  int functionOut(Fun fun, Node name, VarCollector vars) {
    out("function");
    if (name != null) {
      out(" ");
      // Name must be a [Decl]. Therefore only test for primary expressions.
      visitNestedExpression(name, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    localNamer.enterScope(vars);
    out("(");
    if (fun.params != null) {
      visitCommaSeparated(fun.params, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(")");
    switch (fun.asyncModifier) {
      case const AsyncModifier.sync():
        break;
      case const AsyncModifier.async():
        out(' ', isWhitespace: true);
        out('async');
        break;
      case const AsyncModifier.syncStar():
        out(' ', isWhitespace: true);
        out('sync*');
        break;
      case const AsyncModifier.asyncStar():
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
  visitFunctionDeclaration(FunctionDeclaration declaration) {
    VarCollector vars = new VarCollector();
    vars.visitFunctionDeclaration(declaration);
    indent();
    startNode(declaration.function);
    currentNode.closingPosition =
        functionOut(declaration.function, declaration.name, vars);
    endNode(declaration.function);
    lineOut();
  }

  visitNestedExpression(Expression node, int requiredPrecedence,
      {bool newInForInit, bool newAtStatementBegin}) {
    bool needsParentheses =
        // a - (b + c).
        (requiredPrecedence != EXPRESSION &&
                node.precedenceLevel < requiredPrecedence) ||
            // for (a = (x in o); ... ; ... ) { ... }
            (newInForInit && node is Binary && node.op == "in") ||
            // (function() { ... })().
            // ({a: 2, b: 3}.toString()).
            (newAtStatementBegin &&
                (node is NamedFunction ||
                    node is Fun ||
                    node is ObjectInitializer));
    if (needsParentheses) {
      inForInit = false;
      atStatementBegin = false;
      out("(");
      visit(node);
      out(")");
    } else {
      inForInit = newInForInit;
      atStatementBegin = newAtStatementBegin;
      visit(node);
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList list) {
    out("var ");
    visitCommaSeparated(list.declarations, ASSIGNMENT,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  visitAssignment(Assignment assignment) {
    visitNestedExpression(assignment.leftHandSide, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    if (assignment.value != null) {
      spaceOut();
      String op = assignment.op;
      if (op != null) out(op);
      out("=");
      spaceOut();
      visitNestedExpression(assignment.value, ASSIGNMENT,
          newInForInit: inForInit, newAtStatementBegin: false);
    }
  }

  @override
  visitVariableInitialization(VariableInitialization initialization) {
    visitAssignment(initialization);
  }

  @override
  visitConditional(Conditional cond) {
    visitNestedExpression(cond.condition, LOGICAL_OR,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    spaceOut();
    out("?");
    spaceOut();
    // The then part is allowed to have an 'in'.
    visitNestedExpression(cond.then, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    spaceOut();
    out(":");
    spaceOut();
    visitNestedExpression(cond.otherwise, ASSIGNMENT,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  visitNew(New node) {
    out("new ");
    visitNestedExpression(node.target, LEFT_HAND_SIDE,
        newInForInit: inForInit, newAtStatementBegin: false);
    out("(");
    visitCommaSeparated(node.arguments, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
  }

  @override
  visitCall(Call call) {
    visitNestedExpression(call.target, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out("(");
    visitCommaSeparated(call.arguments, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
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
      case "||":
        leftPrecedenceRequirement = LOGICAL_OR;
        // x || (y || z) <=> (x || y) || z.
        rightPrecedenceRequirement = LOGICAL_OR;
        break;
      case "&&":
        leftPrecedenceRequirement = LOGICAL_AND;
        // x && (y && z) <=> (x && y) && z.
        rightPrecedenceRequirement = LOGICAL_AND;
        break;
      case "|":
        leftPrecedenceRequirement = BIT_OR;
        // x | (y | z) <=> (x | y) | z.
        rightPrecedenceRequirement = BIT_OR;
        break;
      case "^":
        leftPrecedenceRequirement = BIT_XOR;
        // x ^ (y ^ z) <=> (x ^ y) ^ z.
        rightPrecedenceRequirement = BIT_XOR;
        break;
      case "&":
        leftPrecedenceRequirement = BIT_AND;
        // x & (y & z) <=> (x & y) & z.
        rightPrecedenceRequirement = BIT_AND;
        break;
      case "==":
      case "!=":
      case "===":
      case "!==":
        leftPrecedenceRequirement = EQUALITY;
        rightPrecedenceRequirement = RELATIONAL;
        break;
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "instanceof":
      case "in":
        leftPrecedenceRequirement = RELATIONAL;
        rightPrecedenceRequirement = SHIFT;
        break;
      case ">>":
      case "<<":
      case ">>>":
        leftPrecedenceRequirement = SHIFT;
        rightPrecedenceRequirement = ADDITIVE;
        break;
      case "+":
      case "-":
        leftPrecedenceRequirement = ADDITIVE;
        // We cannot remove parenthesis for "+" because
        //   x + (y + z) <!=> (x + y) + z:
        // Example:
        //   "a" + (1 + 2) => "a3";
        //   ("a" + 1) + 2 => "a12";
        rightPrecedenceRequirement = MULTIPLICATIVE;
        break;
      case "*":
      case "/":
      case "%":
        leftPrecedenceRequirement = MULTIPLICATIVE;
        // We cannot remove parenthesis for "*" because of precision issues.
        rightPrecedenceRequirement = UNARY;
        break;
      default:
        context.error("Forgot operator: $op");
    }

    visitNestedExpression(left, leftPrecedenceRequirement,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);

    if (op == "in" || op == "instanceof") {
      // There are cases where the space is not required but without further
      // analysis we cannot know.
      out(" ", isWhitespace: true);
      out(op);
      out(" ", isWhitespace: true);
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
      case "delete":
      case "void":
      case "typeof":
        // There are cases where the space is not required but without further
        // analysis we cannot know.
        out(op);
        out(" ", isWhitespace: true);
        break;
      case "+":
      case "++":
        if (lastCharCode == charCodes.$PLUS) out(" ", isWhitespace: true);
        out(op);
        break;
      case "-":
      case "--":
        if (lastCharCode == charCodes.$MINUS) out(" ", isWhitespace: true);
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
    out("this");
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
    return charCodes.$0 <= charCode && charCode <= charCodes.$9;
  }

  bool isValidJavaScriptId(String field) {
    if (field.length < 3) return false;
    // Ignore the leading and trailing string-delimiter.
    for (int i = 1; i < field.length - 1; i++) {
      // TODO(floitsch): allow more characters.
      int charCode = field.codeUnitAt(i);
      if (!(charCodes.$a <= charCode && charCode <= charCodes.$z ||
          charCodes.$A <= charCode && charCode <= charCodes.$Z ||
          charCode == charCodes.$$ ||
          charCode == charCodes.$_ ||
          i != 1 && isDigit(charCode))) {
        return false;
      }
    }
    // TODO(floitsch): normally we should also check that the field is not a
    // reserved word.  We don't generate fields with reserved word names except
    // for 'super'.
    if (field == '"super"') return false;
    if (field == '"catch"') return false;
    return true;
  }

  @override
  void visitAccess(PropertyAccess access) {
    visitNestedExpression(access.receiver, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    Node selector = access.selector;
    if (selector is LiteralString) {
      LiteralString selectorString = selector;
      String fieldWithQuotes = selectorString.value;
      if (isValidJavaScriptId(fieldWithQuotes)) {
        if (access.receiver is LiteralNumber &&
            lastCharCode != charCodes.$CLOSE_PAREN) {
          out(" ", isWhitespace: true);
        }
        out(".");
        startNode(selector);
        out(fieldWithQuotes.substring(1, fieldWithQuotes.length - 1));
        endNode(selector);
        return;
      }
    } else if (selector is Name) {
      if (access.receiver is LiteralNumber &&
          lastCharCode != charCodes.$CLOSE_PAREN) {
        out(" ", isWhitespace: true);
      }
      out(".");
      startNode(selector);
      selector.accept(this);
      endNode(selector);
      return;
    }
    out("[");
    visitNestedExpression(selector, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out("]");
  }

  @override
  void visitNamedFunction(NamedFunction namedFunction) {
    VarCollector vars = new VarCollector();
    vars.visitNamedFunction(namedFunction);
    startNode(namedFunction.function);
    currentNode.closingPosition =
        functionOut(namedFunction.function, namedFunction.name, vars);
    endNode(namedFunction.function);
  }

  @override
  void visitFun(Fun fun) {
    VarCollector vars = new VarCollector();
    vars.visitFun(fun);
    currentNode.closingPosition = functionOut(fun, null, vars);
  }

  @override
  visitDeferredExpression(DeferredExpression node) {
    // Continue printing with the expression value.
    assert(node.precedenceLevel == node.value.precedenceLevel);
    node.value.accept(this);
  }

  outputNumberWithRequiredWhitespace(String number) {
    int charCode = number.codeUnitAt(0);
    if (charCode == charCodes.$MINUS && lastCharCode == charCodes.$MINUS) {
      out(" ", isWhitespace: true);
    }
    out(number);
  }

  @override
  visitDeferredNumber(DeferredNumber node) {
    outputNumberWithRequiredWhitespace("${node.value}");
  }

  @override
  visitDeferredString(DeferredString node) {
    out(node.value);
  }

  @override
  visitLiteralBool(LiteralBool node) {
    out(node.value ? "true" : "false");
  }

  @override
  void visitLiteralString(LiteralString node) {
    out(node.value);
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    node.visitChildren(this);
  }

  @override
  visitName(Name node) {
    out(options.renamerForNames(node));
  }

  @override
  visitLiteralNumber(LiteralNumber node) {
    outputNumberWithRequiredWhitespace(node.value);
  }

  @override
  void visitLiteralNull(LiteralNull node) {
    out("null");
  }

  @override
  void visitArrayInitializer(ArrayInitializer node) {
    out("[");
    List<Expression> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      Expression element = elements[i];
      if (element is ArrayHole) {
        // Note that array holes must have a trailing "," even if they are
        // in last position. Otherwise `[,]` (having length 1) would become
        // equal to `[]` (the empty array)
        // and [1,,] (array with 1 and a hole) would become [1,] = [1].
        startNode(element);
        out(",");
        endNode(element);
        continue;
      }
      if (i != 0) spaceOut();
      visitNestedExpression(element, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
      // We can skip the trailing "," for the last element (since it's not
      // an array hole).
      if (i != elements.length - 1) out(",");
    }
    out("]");
  }

  @override
  void visitArrayHole(ArrayHole node) {
    context.error("Unreachable");
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
    out("{");
    indentMore();
    for (int i = 0; i < properties.length; i++) {
      Node value = properties[i].value;
      if (isOneLiner && exitOneLinerMode(value)) isOneLiner = false;
      if (i != 0) {
        out(",");
        if (isOneLiner) spaceOut();
      }
      if (!isOneLiner) {
        forceLine();
        indent();
      }
      visit(properties[i]);
    }
    indentLess();
    if (!isOneLiner && !properties.isEmpty) {
      lineOut();
      indent();
    }
    out("}");
  }

  @override
  void visitProperty(Property node) {
    startNode(node.name);
    if (node.name is LiteralString) {
      LiteralString nameString = node.name;
      String name = nameString.value;
      if (isValidJavaScriptId(name)) {
        out(name.substring(1, name.length - 1));
      } else {
        out(name);
      }
    } else if (node.name is Name) {
      node.name.accept(this);
    } else {
      assert(node.name is LiteralNumber);
      LiteralNumber nameNumber = node.name;
      out(nameNumber.value);
    }
    endNode(node.name);
    out(":");
    spaceOut();
    visitNestedExpression(node.value, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
  }

  @override
  void visitRegExpLiteral(RegExpLiteral node) {
    out(node.pattern);
  }

  @override
  void visitLiteralExpression(LiteralExpression node) {
    String template = node.template;
    List<Expression> inputs = node.inputs;

    List<String> parts = template.split('#');
    int inputsLength = inputs == null ? 0 : inputs.length;
    if (parts.length != inputsLength + 1) {
      context.error('Wrong number of arguments for JS: $template');
    }
    // Code that uses JS must take care of operator precedences, and
    // put parenthesis if needed.
    out(parts[0]);
    for (int i = 0; i < inputsLength; i++) {
      visit(inputs[i]);
      out(parts[i + 1]);
    }
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
    out("await ");
    visit(node.expression);
  }
}

class OrderedSet<T> {
  final Set<T> set;
  final List<T> list;

  OrderedSet()
      : set = new Set<T>(),
        list = <T>[];

  void add(T x) {
    if (set.add(x)) {
      // [Set.add] returns `true` if 'x' was added.
      list.add(x);
    }
  }

  void forEach(void fun(T x)) {
    list.forEach(fun);
  }
}

// Collects all the var declarations in the function.  We need to do this in a
// separate pass because JS vars are lifted to the top of the function.
class VarCollector extends BaseVisitor {
  bool nested;
  bool enableRenaming = true;
  final OrderedSet<String> vars;
  final OrderedSet<String> params;

  static final String disableVariableMinificationPattern = "::norenaming::";
  static final String enableVariableMinificationPattern = "::dorenaming::";

  VarCollector()
      : nested = false,
        vars = new OrderedSet<String>(),
        params = new OrderedSet<String>();

  void forEachVar(void fn(String v)) => vars.forEach(fn);
  void forEachParam(void fn(String p)) => params.forEach(fn);

  void collectVarsInFunction(Fun fun) {
    if (!nested) {
      nested = true;
      if (fun.params != null) {
        for (int i = 0; i < fun.params.length; i++) {
          params.add(fun.params[i].name);
        }
      }
      visitBlock(fun.body);
      nested = false;
    }
  }

  void visitFunctionDeclaration(FunctionDeclaration declaration) {
    // Note that we don't bother collecting the name of the function.
    collectVarsInFunction(declaration.function);
  }

  void visitNamedFunction(NamedFunction namedFunction) {
    // Note that we don't bother collecting the name of the function.
    collectVarsInFunction(namedFunction.function);
  }

  void visitFun(Fun fun) {
    collectVarsInFunction(fun);
  }

  void visitThis(This node) {}

  void visitComment(Comment node) {
    if (node.comment.contains(disableVariableMinificationPattern)) {
      enableRenaming = false;
    } else if (node.comment.contains(enableVariableMinificationPattern)) {
      enableRenaming = true;
    }
  }

  void visitVariableDeclaration(VariableDeclaration decl) {
    if (enableRenaming && decl.allowRename) vars.add(decl.name);
  }
}

/**
 * Returns true, if the given node must be wrapped into braces when used
 * as then-statement in an [If] that has an else branch.
 */
class DanglingElseVisitor extends BaseVisitor<bool> {
  JavaScriptPrintingContext context;

  DanglingElseVisitor(this.context);

  bool visitProgram(Program node) => false;

  bool visitNode(Statement node) {
    context.error("Forgot node: $node");
    return null;
  }

  bool visitBlock(Block node) => false;
  bool visitExpressionStatement(ExpressionStatement node) => false;
  bool visitEmptyStatement(EmptyStatement node) => false;
  bool visitIf(If node) {
    if (!node.hasElse) return true;
    return node.otherwise.accept(this);
  }

  bool visitFor(For node) => node.body.accept(this);
  bool visitForIn(ForIn node) => node.body.accept(this);
  bool visitWhile(While node) => node.body.accept(this);
  bool visitDo(Do node) => false;
  bool visitContinue(Continue node) => false;
  bool visitBreak(Break node) => false;
  bool visitReturn(Return node) => false;
  bool visitThrow(Throw node) => false;
  bool visitTry(Try node) {
    if (node.finallyPart != null) {
      return node.finallyPart.accept(this);
    } else {
      return node.catchPart.accept(this);
    }
  }

  bool visitCatch(Catch node) => node.body.accept(this);
  bool visitSwitch(Switch node) => false;
  bool visitCase(Case node) => false;
  bool visitDefault(Default node) => false;
  bool visitFunctionDeclaration(FunctionDeclaration node) => false;
  bool visitLabeledStatement(LabeledStatement node) => node.body.accept(this);
  bool visitLiteralStatement(LiteralStatement node) => true;

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
  String getName(String oldName) => oldName;
  String declareVariable(String oldName) => oldName;
  String declareParameter(String oldName) => oldName;
  void enterScope(VarCollector vars) {}
  void leaveScope() {}
}

class MinifyRenamer implements LocalNamer {
  final List<Map<String, String>> maps = [];
  final List<int> parameterNumberStack = [];
  final List<int> variableNumberStack = [];
  int parameterNumber = 0;
  int variableNumber = 0;

  MinifyRenamer();

  void enterScope(VarCollector vars) {
    maps.add(new Map<String, String>());
    variableNumberStack.add(variableNumber);
    parameterNumberStack.add(parameterNumber);
    vars.forEachVar(declareVariable);
    vars.forEachParam(declareParameter);
  }

  void leaveScope() {
    maps.removeLast();
    variableNumber = variableNumberStack.removeLast();
    parameterNumber = parameterNumberStack.removeLast();
  }

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
        ? charCodes.$a + n
        : charCodes.$A + n - LOWER_CASE_LETTERS;
  }

  // Parameters go from a to z and variables go from z to a.  This makes each
  // argument list and each top-of-function var declaration look similar and
  // helps gzip compress the file.  If we have more than 26 arguments and
  // variables then we meet somewhere in the middle of the alphabet.  After
  // that we give up trying to be nice to the compression algorithm and just
  // use the same namespace for arguments and variables, starting with A, and
  // moving on to a0, a1, etc.
  String declareVariable(String oldName) {
    if (avoidRenaming(oldName)) return oldName;
    var newName;
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

  String declareParameter(String oldName) {
    if (avoidRenaming(oldName)) return oldName;
    var newName;
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
      newName = new String.fromCharCodes([nthLetter(n)]);
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
      codes.add(charCodes.$0 + digit);
      newName = new String.fromCharCodes(codes);
    }
    assert(new RegExp(r'[a-zA-Z][a-zA-Z0-9]*').hasMatch(newName));
    maps.last[oldName] = newName;
    return newName;
  }
}

/// Information pertaining the enter and exit callbacks for [node].
class EnterExitNode {
  final EnterExitNode parent;
  final Node node;

  int startPosition;
  int closingPosition;

  EnterExitNode(this.parent, this.node);

  void addToNode(JavaScriptPrintingContext context, int position) {
    if (startPosition == null) {
      // [position] is the start position of [node].
      if (parent != null) {
        // This might be the start position of the parent as well.
        parent.addToNode(context, position);
      }
      startPosition = position;
      context.enterNode(node, position);
    }
  }

  EnterExitNode exitNode(JavaScriptPrintingContext context, int position) {
    // Enter must happen before exit.
    addToNode(context, position);
    context.exitNode(node, startPosition, position, closingPosition);
    return parent;
  }
}
