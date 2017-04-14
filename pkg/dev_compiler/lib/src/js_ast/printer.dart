// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

class JavaScriptPrintingOptions {
  final bool shouldCompressOutput;
  final bool minifyLocalVariables;
  final bool preferSemicolonToNewlineInMinifiedOutput;
  final bool emitTypes;
  final bool allowSingleLineIfStatements;

  /// True to allow keywords in properties, such as `obj.var` or `obj.function`
  /// Modern JS engines support this.
  final bool allowKeywordsInProperties;

  JavaScriptPrintingOptions(
      {this.shouldCompressOutput: false,
      this.minifyLocalVariables: false,
      this.preferSemicolonToNewlineInMinifiedOutput: false,
      this.emitTypes: false,
      this.allowKeywordsInProperties: false,
      this.allowSingleLineIfStatements: false});
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

  /// Callback immediately before printing [node].  Whitespace may be printed
  /// after this callback before the first non-whitespace character for [node].
  void enterNode(Node node) {}

  /// Callback after printing the last character representing [node].
  void exitNode(Node node) {}
}

/// A simple implementation of [JavaScriptPrintingContext] suitable for tests.
class SimpleJavaScriptPrintingContext extends JavaScriptPrintingContext {
  final StringBuffer buffer = new StringBuffer();

  void emit(String string) {
    buffer.write(string);
  }

  String getText() => buffer.toString();
}

// TODO(ochafik): Inline the body of [TypeScriptTypePrinter] here if/when it no
// longer needs to share utils with [ClosureTypePrinter].
class Printer extends TypeScriptTypePrinter implements NodeVisitor {
  final JavaScriptPrintingOptions options;
  final JavaScriptPrintingContext context;
  final bool shouldCompressOutput;
  final DanglingElseVisitor danglingElseVisitor;
  final LocalNamer localNamer;

  bool inForInit = false;
  bool atStatementBegin = false;
  bool inNewTarget = false;
  bool pendingSemicolon = false;
  bool pendingSpace = false;

  // The current indentation level.
  int _indentLevel = 0;
  // A cache of all indentation strings used so far.
  List<String> _indentList = <String>[""];

  /// Whether the next call to [indent] should just be a no-op.
  bool _skipNextIndent = false;

  static final identifierCharacterRegExp = new RegExp(r'^[a-zA-Z_0-9$]');
  static final expressionContinuationRegExp = new RegExp(r'^[-+([]');

  Printer(JavaScriptPrintingOptions options, JavaScriptPrintingContext context,
      {LocalNamer localNamer})
      : options = options,
        context = context,
        shouldCompressOutput = options.shouldCompressOutput,
        danglingElseVisitor = new DanglingElseVisitor(context),
        localNamer = determineRenamer(localNamer, options);

  static LocalNamer determineRenamer(
      LocalNamer localNamer, JavaScriptPrintingOptions options) {
    if (localNamer != null) return localNamer;
    return (options.shouldCompressOutput && options.minifyLocalVariables)
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
    out("\n");
  }

  /// Emits a newline for readability.
  void lineOut() {
    if (!shouldCompressOutput) forceLine();
  }

  void spaceOut() {
    if (!shouldCompressOutput) out(" ");
  }

  String lastAddedString = null;
  int get lastCharCode {
    if (lastAddedString == null) return 0;
    assert(lastAddedString.length != "");
    return lastAddedString.codeUnitAt(lastAddedString.length - 1);
  }

  void out(String str) {
    if (str != "") {
      if (pendingSemicolon) {
        if (!shouldCompressOutput) {
          context.emit(";");
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
            context.emit(";");
          } else {
            context.emit("\n");
          }
        }
      }
      if (pendingSpace &&
          (!shouldCompressOutput || identifierCharacterRegExp.hasMatch(str))) {
        context.emit(" ");
      }
      pendingSpace = false;
      pendingSemicolon = false;
      context.emit(str);
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

  void skipNextIndent() {
    _skipNextIndent = true;
  }

  void indent() {
    if (_skipNextIndent) {
      _skipNextIndent = false;
      return;
    }
    if (!shouldCompressOutput) {
      out(indentation);
    }
  }

  visit(Node node) {
    context.enterNode(node);
    node.accept(this);
    context.exitNode(node);
  }

  visitCommaSeparated(List<Node> nodes, int hasRequiredType,
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

  visitAll(List<Node> nodes) {
    nodes.forEach(visit);
  }

  visitProgram(Program program) {
    if (program.scriptTag != null) {
      out('#!${program.scriptTag}\n');
    }
    visitAll(program.body);
  }

  bool blockBody(Node body, {bool needsSeparation, bool needsNewline}) {
    if (body is Block) {
      spaceOut();
      blockOut(body, false, needsNewline);
      return true;
    }
    if (shouldCompressOutput && needsSeparation) {
      // If [shouldCompressOutput] is false, then the 'lineOut' will insert
      // the separation.
      out(" ");
    } else {
      lineOut();
    }
    indentMore();
    visit(body);
    indentLess();
    return false;
  }

  void blockOutWithoutBraces(Node node) {
    if (node is Block && !node.isScope) {
      context.enterNode(node);
      Block block = node;
      block.statements.forEach(blockOutWithoutBraces);
      context.exitNode(node);
    } else {
      visit(node);
    }
  }

  void blockOut(Block node, bool shouldIndent, bool needsNewline) {
    if (shouldIndent) indent();
    context.enterNode(node);
    out("{");
    lineOut();
    indentMore();
    node.statements.forEach(blockOutWithoutBraces);
    indentLess();
    indent();
    out("}");
    context.exitNode(node);
    if (needsNewline) lineOut();
  }

  visitBlock(Block block) {
    blockOut(block, true, true);
  }

  visitExpressionStatement(ExpressionStatement expressionStatement) {
    indent();
    outClosureAnnotation(expressionStatement);
    visitNestedExpression(expressionStatement.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: true);
    outSemicolonLn();
  }

  visitEmptyStatement(EmptyStatement nop) {
    outIndentLn(";");
  }

  void ifOut(If node, bool shouldIndent) {
    Node then = node.then;
    Node elsePart = node.otherwise;
    bool hasElse = node.hasElse;

    // Handle dangling elses and a work-around for Android 4.0 stock browser.
    // Android 4.0 requires braces for a single do-while in the `then` branch.
    // See issue 10923.
    if (hasElse) {
      bool needsBraces = node.then.accept(danglingElseVisitor) || then is Do;
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
    bool thenWasBlock;
    if (options.allowSingleLineIfStatements && !hasElse && then is! Block) {
      thenWasBlock = false;
      spaceOut();
      skipNextIndent();
      visit(then);
    } else {
      thenWasBlock =
          blockBody(then, needsSeparation: false, needsNewline: !hasElse);
    }
    if (hasElse) {
      if (thenWasBlock) {
        spaceOut();
      } else {
        indent();
      }
      out("else");
      if (elsePart is If) {
        pendingSpace = true;
        ifOut(elsePart, false);
      } else {
        blockBody(elsePart, needsSeparation: true, needsNewline: true);
      }
    }
  }

  visitIf(If node) {
    ifOut(node, true);
  }

  visitFor(For loop) {
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
    blockBody(loop.body, needsSeparation: false, needsNewline: true);
  }

  visitForIn(ForIn loop) {
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
    blockBody(loop.body, needsSeparation: false, needsNewline: true);
  }

  visitForOf(ForOf loop) {
    outIndent("for");
    spaceOut();
    out("(");
    visitNestedExpression(loop.leftHandSide, EXPRESSION,
        newInForInit: true, newAtStatementBegin: false);
    out(" of");
    pendingSpace = true;
    visitNestedExpression(loop.iterable, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    blockBody(loop.body, needsSeparation: false, needsNewline: true);
  }

  visitWhile(While loop) {
    outIndent("while");
    spaceOut();
    out("(");
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    blockBody(loop.body, needsSeparation: false, needsNewline: true);
  }

  visitDo(Do loop) {
    outIndent("do");
    if (blockBody(loop.body, needsSeparation: true, needsNewline: false)) {
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

  visitContinue(Continue node) {
    if (node.targetLabel == null) {
      outIndent("continue");
    } else {
      outIndent("continue ${node.targetLabel}");
    }
    outSemicolonLn();
  }

  visitBreak(Break node) {
    if (node.targetLabel == null) {
      outIndent("break");
    } else {
      outIndent("break ${node.targetLabel}");
    }
    outSemicolonLn();
  }

  visitReturn(Return node) {
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

  visitDartYield(DartYield node) {
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

  visitThrow(Throw node) {
    outIndent("throw");
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  visitTry(Try node) {
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

  visitCatch(Catch node) {
    spaceOut();
    out("catch");
    spaceOut();
    out("(");
    visitNestedExpression(node.declaration, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    blockBody(node.body, needsSeparation: false, needsNewline: true);
  }

  visitSwitch(Switch node) {
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

  visitCase(Case node) {
    outIndent("case");
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outLn(":");
    if (!node.body.statements.isEmpty) {
      blockOut(node.body, true, true);
    }
  }

  visitDefault(Default node) {
    outIndentLn("default:");
    if (!node.body.statements.isEmpty) {
      blockOut(node.body, true, true);
    }
  }

  visitLabeledStatement(LabeledStatement node) {
    outIndent("${node.label}:");
    blockBody(node.body, needsSeparation: false, needsNewline: true);
  }

  void functionOut(Fun fun, Node name) {
    out("function");
    if (fun.isGenerator) out("*");
    if (name != null) {
      out(" ");
      // Name must be a [Decl]. Therefore only test for primary expressions.
      visitNestedExpression(name, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    localNamer.enterScope(fun);
    outTypeParams(fun.typeParams);
    out("(");
    if (fun.params != null) {
      visitCommaSeparated(fun.params, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(")");
    outTypeAnnotation(fun.returnType);
    switch (fun.asyncModifier) {
      case const AsyncModifier.sync():
        break;
      case const AsyncModifier.async():
        out(' async');
        break;
      case const AsyncModifier.syncStar():
        out(' sync*');
        break;
      case const AsyncModifier.asyncStar():
        out(' async*');
        break;
    }
    blockBody(fun.body, needsSeparation: false, needsNewline: false);
    localNamer.leaveScope();
  }

  visitFunctionDeclaration(FunctionDeclaration declaration) {
    indent();
    outClosureAnnotation(declaration);
    functionOut(declaration.function, declaration.name);
    lineOut();
  }

  visitNestedExpression(Expression node, int requiredPrecedence,
      {bool newInForInit, bool newAtStatementBegin}) {
    int nodePrecedence = node.precedenceLevel;
    bool needsParentheses =
        // a - (b + c).
        (requiredPrecedence != EXPRESSION &&
                nodePrecedence < requiredPrecedence) ||
            // for (a = (x in o); ... ; ... ) { ... }
            (newInForInit && node is Binary && node.op == "in") ||
            // (function() { ... })().
            // ({a: 2, b: 3}.toString()).
            (newAtStatementBegin &&
                (node is NamedFunction ||
                    node is FunctionExpression ||
                    node is ObjectInitializer));
    if (needsParentheses) {
      inForInit = false;
      atStatementBegin = false;
      inNewTarget = false;
      out("(");
      visit(node);
      out(")");
    } else {
      inForInit = newInForInit;
      atStatementBegin = newAtStatementBegin;
      visit(node);
    }
  }

  visitVariableDeclarationList(VariableDeclarationList list) {
    outClosureAnnotation(list);
    // Note: keyword can be null for non-static field declarations.
    if (list.keyword != null) {
      out(list.keyword);
      out(" ");
    }
    visitCommaSeparated(list.declarations, ASSIGNMENT,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  visitArrayBindingPattern(ArrayBindingPattern node) {
    out("[");
    visitCommaSeparated(node.variables, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out("]");
  }

  visitObjectBindingPattern(ObjectBindingPattern node) {
    out("{");
    visitCommaSeparated(node.variables, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out("}");
  }

  visitDestructuredVariable(DestructuredVariable node) {
    var name = node.name;
    var hasName = name != null;
    if (hasName) {
      if (name is LiteralString) {
        out("[");
        out(name.value);
        out("]");
      } else {
        visit(name);
      }
    }
    if (node.structure != null) {
      if (hasName) {
        out(":");
        spaceOut();
      }
      visit(node.structure);
    }
    outTypeAnnotation(node.type);
    if (node.defaultValue != null) {
      spaceOut();
      out("=");
      spaceOut();
      visitNestedExpression(node.defaultValue, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
  }

  visitSimpleBindingPattern(SimpleBindingPattern node) {
    visit(node.name);
  }

  visitAssignment(Assignment assignment) {
    visitNestedExpression(assignment.leftHandSide, LEFT_HAND_SIDE,
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

  visitVariableInitialization(VariableInitialization initialization) {
    outClosureAnnotation(initialization);
    visitAssignment(initialization);
  }

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

  visitNew(New node) {
    out("new ");
    inNewTarget = true;
    visitNestedExpression(node.target, ACCESS,
        newInForInit: inForInit, newAtStatementBegin: false);
    inNewTarget = false;
    out("(");
    visitCommaSeparated(node.arguments, SPREAD,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
  }

  visitCall(Call call) {
    visitNestedExpression(call.target, LEFT_HAND_SIDE,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out("(");
    visitCommaSeparated(call.arguments, SPREAD,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
  }

  visitBinary(Binary binary) {
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
      out(" ");
      out(op);
      out(" ");
    } else {
      if (leftSpace) spaceOut();
      out(op);
      spaceOut();
    }
    visitNestedExpression(right, rightPrecedenceRequirement,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  visitPrefix(Prefix unary) {
    String op = unary.op;
    switch (op) {
      case "delete":
      case "void":
      case "typeof":
        // There are cases where the space is not required but without further
        // analysis we cannot know.
        out(op);
        out(" ");
        break;
      case "+":
      case "++":
        if (lastCharCode == charCodes.$PLUS) out(" ");
        out(op);
        break;
      case "-":
      case "--":
        if (lastCharCode == charCodes.$MINUS) out(" ");
        out(op);
        break;
      default:
        out(op);
    }
    visitNestedExpression(unary.argument, unary.precedenceLevel,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  visitSpread(Spread unary) => visitPrefix(unary);

  visitYield(Yield yield) {
    out(yield.star ? "yield*" : "yield");
    if (yield.value == null) return;
    out(" ");
    visitNestedExpression(yield.value, yield.precedenceLevel,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  visitPostfix(Postfix postfix) {
    visitNestedExpression(postfix.argument, LEFT_HAND_SIDE,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out(postfix.op);
  }

  visitThis(This node) {
    out("this");
  }

  visitSuper(Super node) {
    out("super");
  }

  visitIdentifier(Identifier node) {
    out(localNamer.getName(node));
    outTypeAnnotation(node.type);
  }

  visitRestParameter(RestParameter node) {
    out('...');
    visitIdentifier(node.parameter);
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
    return options.allowKeywordsInProperties || field != '"super"';
  }

  visitAccess(PropertyAccess access) {
    // Normally we can omit parens on the receiver if it is a Call, even though
    // Call expressions have lower precedence. However this optimization doesn't
    // work inside New expressions:
    //
    //     new obj.foo().bar()
    //
    // This will be parsed as:
    //
    //     (new obj.foo()).bar()
    //
    // Which is incorrect. So we must have parenthesis in this case:
    //
    //     new (obj.foo()).bar()
    //
    int precedence = inNewTarget ? ACCESS : CALL;

    visitNestedExpression(access.receiver, precedence,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    propertyNameOut(access.selector, inAccess: true);
  }

  visitNamedFunction(NamedFunction namedFunction) {
    functionOut(namedFunction.function, namedFunction.name);
  }

  visitFun(Fun fun) {
    functionOut(fun, null);
  }

  visitArrowFun(ArrowFun fun) {
    localNamer.enterScope(fun);
    if (fun.params.length == 1 &&
        fun.params[0] is Identifier &&
        (!options.emitTypes || fun.params[0].type == null)) {
      visitNestedExpression(fun.params.single, SPREAD,
          newInForInit: false, newAtStatementBegin: false);
    } else {
      out("(");
      visitCommaSeparated(fun.params, SPREAD,
          newInForInit: false, newAtStatementBegin: false);
      out(")");
    }
    outTypeAnnotation(fun.returnType);
    spaceOut();
    out("=>");
    if (fun.body is Expression) {
      spaceOut();
      // Object initializers require parenthesis to disambiguate
      // AssignmentExpression from FunctionBody. See:
      // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-arrow-function-definitions
      var needsParen = fun.body is ObjectInitializer;
      if (needsParen) out("(");
      visitNestedExpression(fun.body, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
      if (needsParen) out(")");
    } else {
      blockBody(fun.body, needsSeparation: false, needsNewline: false);
    }
    localNamer.leaveScope();
  }

  visitLiteralBool(LiteralBool node) {
    out(node.value ? "true" : "false");
  }

  visitLiteralString(LiteralString node) {
    out(node.value);
  }

  visitLiteralNumber(LiteralNumber node) {
    int charCode = node.value.codeUnitAt(0);
    if (charCode == charCodes.$MINUS && lastCharCode == charCodes.$MINUS) {
      out(" ");
    }
    out(node.value);
  }

  visitLiteralNull(LiteralNull node) {
    out("null");
  }

  visitArrayInitializer(ArrayInitializer node) {
    out("[");
    indentMore();
    var multiline = node.multiline;
    List<Expression> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      Expression element = elements[i];
      if (element is ArrayHole) {
        // Note that array holes must have a trailing "," even if they are
        // in last position. Otherwise `[,]` (having length 1) would become
        // equal to `[]` (the empty array)
        // and [1,,] (array with 1 and a hole) would become [1,] = [1].
        out(",");
        continue;
      }
      if (i != 0 && !multiline) spaceOut();
      if (multiline) {
        forceLine();
        indent();
      }
      visitNestedExpression(element, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
      // We can skip the trailing "," for the last element (since it's not
      // an array hole).
      if (i != elements.length - 1) out(",");
    }
    indentLess();
    if (multiline) {
      lineOut();
      indent();
    }
    out("]");
  }

  visitArrayHole(ArrayHole node) {
    throw "Unreachable";
  }

  visitObjectInitializer(ObjectInitializer node) {
    List<Property> properties = node.properties;
    out("{");
    indentMore();

    var multiline = node.multiline;
    for (int i = 0; i < properties.length; i++) {
      if (i != 0) {
        out(",");
        if (!multiline) spaceOut();
      }
      if (multiline) {
        forceLine();
        indent();
      }
      visit(properties[i]);
    }
    indentLess();
    if (multiline) {
      lineOut();
      indent();
    }
    out("}");
  }

  visitProperty(Property node) {
    propertyNameOut(node.name);
    out(":");
    spaceOut();
    visitNestedExpression(node.value, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
  }

  visitRegExpLiteral(RegExpLiteral node) {
    out(node.pattern);
  }

  visitTemplateString(TemplateString node) {
    out('`');
    int len = node.interpolations.length;
    for (var i = 0; i < len; i++) {
      out(node.strings[i]);
      out(r'${');
      visit(node.interpolations[i]);
      out('}');
    }
    out(node.strings[len]);
    out('`');
  }

  visitTaggedTemplate(TaggedTemplate node) {
    visit(node.tag);
    visit(node.template);
  }

  visitClassDeclaration(ClassDeclaration node) {
    indent();
    visit(node.classExpr);
    lineOut();
  }

  void outTypeParams(Iterable<Identifier> typeParams) {
    if (typeParams != null && options.emitTypes && typeParams.isNotEmpty) {
      out("<");
      var first = true;
      for (var typeParam in typeParams) {
        if (!first) out(", ");
        first = false;
        visit(typeParam);
      }
      out(">");
    }
  }

  visitClassExpression(ClassExpression node) {
    out('class ');
    visit(node.name);
    outTypeParams(node.typeParams);
    if (node.heritage != null) {
      out(' extends ');
      visit(node.heritage);
    }
    spaceOut();
    if (node.methods.isNotEmpty) {
      out('{');
      lineOut();
      indentMore();
      if (options.emitTypes && node.fields != null) {
        for (var field in node.fields) {
          indent();
          visit(field);
          out(";");
          lineOut();
        }
      }
      for (var method in node.methods) {
        indent();
        visit(method);
        lineOut();
      }
      indentLess();
      indent();
      out('}');
    } else {
      out('{}');
    }
  }

  visitMethod(Method node) {
    outClosureAnnotation(node);
    if (node.isStatic) {
      out('static ');
    }
    if (node.isGetter) {
      out('get ');
    } else if (node.isSetter) {
      out('set ');
    } else if (node.function.isGenerator) {
      out('*');
    }
    propertyNameOut(node.name, inMethod: true);

    var fun = node.function;
    localNamer.enterScope(fun);
    out("(");
    if (fun.params != null) {
      visitCommaSeparated(fun.params, SPREAD,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(")");
    // TODO(jmesserly): async modifiers
    if (fun.body.statements.isEmpty) {
      spaceOut();
      out("{}");
    } else {
      blockBody(fun.body, needsSeparation: false, needsNewline: false);
    }
    localNamer.leaveScope();
  }

  void outClosureAnnotation(Node node) {
    if (node != null && node.closureAnnotation != null) {
      String comment = node.closureAnnotation.toString(indentation);
      if (comment.isNotEmpty) {
        out(comment);
        lineOut();
        indent();
      }
    }
  }

  void propertyNameOut(Expression node,
      {bool inMethod: false, bool inAccess: false}) {
    if (node is LiteralNumber) {
      LiteralNumber nameNumber = node;
      if (inAccess) out('[');
      out(nameNumber.value);
      if (inAccess) out(']');
    } else {
      if (node is LiteralString) {
        if (isValidJavaScriptId(node.value)) {
          if (inAccess) out('.');
          out(node.valueWithoutQuotes);
        } else {
          if (inMethod || inAccess) out("[");
          out(node.value);
          if (inMethod || inAccess) out("]");
        }
      } else {
        // ComputedPropertyName
        out("[");
        visitNestedExpression(node, EXPRESSION,
            newInForInit: false, newAtStatementBegin: false);
        out("]");
      }
    }
  }

  visitImportDeclaration(ImportDeclaration node) {
    indent();
    out('import ');
    if (node.defaultBinding != null) {
      visit(node.defaultBinding);
      if (node.namedImports != null) {
        out(',');
        spaceOut();
      }
    }
    nameSpecifierListOut(node.namedImports);
    fromClauseOut(node.from);
    outSemicolonLn();
  }

  visitExportDeclaration(ExportDeclaration node) {
    indent();
    out('export ');
    if (node.isDefault) out('default ');
    // TODO(jmesserly): we need to avoid indent/newline if this is a statement.
    visit(node.exported);
    outSemicolonLn();
  }

  visitExportClause(ExportClause node) {
    nameSpecifierListOut(node.exports);
    fromClauseOut(node.from);
  }

  nameSpecifierListOut(List<NameSpecifier> names) {
    if (names == null) return;

    if (names.length == 1 && names[0].name == '*') {
      visit(names[0]);
      return;
    }

    out('{');
    spaceOut();
    for (int i = 0; i < names.length; i++) {
      if (i != 0) {
        out(',');
        spaceOut();
      }
      visit(names[i]);
    }
    spaceOut();
    out('}');
  }

  fromClauseOut(LiteralString from) {
    if (from != null) {
      out(' from');
      spaceOut();
      visit(from);
    }
  }

  visitNameSpecifier(NameSpecifier node) {
    if (node.isStar) {
      out('*');
    } else {
      var importName = node.name.name;
      out(importName);

      if (node.asName == null) {
        // If our local was renamed, generate an implicit "as".
        // This is a convenience feature so imports can be renamed.
        var localName = localNamer.getName(node.name);
        if (localName != importName) {
          out(' as ');
          out(localName);
        }
      }
    }
    if (node.asName != null) {
      out(' as ');
      visitIdentifier(node.asName);
    }
  }

  visitModule(Module node) {
    visitAll(node.body);
  }

  visitLiteralExpression(LiteralExpression node) {
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

  visitLiteralStatement(LiteralStatement node) {
    outLn(node.code);
  }

  visitInterpolatedNode(InterpolatedNode node) {
    out('#${node.nameOrPosition}');
  }

  visitInterpolatedExpression(InterpolatedExpression node) =>
      visitInterpolatedNode(node);

  visitInterpolatedLiteral(InterpolatedLiteral node) =>
      visitInterpolatedNode(node);

  visitInterpolatedParameter(InterpolatedParameter node) =>
      visitInterpolatedNode(node);

  visitInterpolatedSelector(InterpolatedSelector node) =>
      visitInterpolatedNode(node);

  visitInterpolatedMethod(InterpolatedMethod node) =>
      visitInterpolatedNode(node);

  visitInterpolatedIdentifier(InterpolatedIdentifier node) =>
      visitInterpolatedNode(node);

  visitInterpolatedStatement(InterpolatedStatement node) {
    outLn('#${node.nameOrPosition}');
  }

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

  void visitCommentExpression(CommentExpression node) {
    if (shouldCompressOutput) return;
    String comment = node.comment.trim();
    if (comment.isEmpty) return;
    if (comment.startsWith('/*')) {
      out(comment);
    } else {
      out('/* $comment */');
    }
    visit(node.expression);
  }

  void visitAwait(Await node) {
    out("await ");
    visit(node.expression);
  }

  void outTypeAnnotation(TypeRef node) {
    if (node == null || !options.emitTypes || node.isUnknown) return;

    if (node is OptionalTypeRef) {
      out("?: ");
      visit(node.type);
    } else {
      out(": ");
      visit(node);
    }
  }
}

// Collects all the var declarations in the function.  We need to do this in a
// separate pass because JS vars are lifted to the top of the function.
class VarCollector extends BaseVisitor {
  bool nested;
  final Set<String> vars;
  final Set<String> params;

  VarCollector()
      : nested = false,
        vars = new Set<String>(),
        params = new Set<String>();

  void forEachVar(void fn(String v)) => vars.forEach(fn);
  void forEachParam(void fn(String p)) => params.forEach(fn);

  void collectVarsInFunction(FunctionExpression fun) {
    if (!nested) {
      nested = true;
      if (fun.params != null) {
        for (var param in fun.params) {
          // TODO(jmesserly): add ES6 support. Currently not needed because
          // dart2js does not emit ES6 rest param or destructuring.
          params.add((param as Identifier).name);
        }
      }
      fun.body.accept(this);
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

  void visitMethod(Method declaration) {
    collectVarsInFunction(declaration.function);
  }

  void visitFun(Fun fun) {
    collectVarsInFunction(fun);
  }

  void visitArrowFun(ArrowFun fun) {
    collectVarsInFunction(fun);
  }

  void visitClassExpression(ClassExpression node) {
    // Note that we don't bother collecting the name of the class.
    if (node.heritage != null) node.heritage.accept(this);
    for (Method method in node.methods) method.accept(this);
  }

  void visitCatch(Catch node) {
    declareVariable(node.declaration);
    node.body.accept(this);
  }

  void visitVariableInitialization(VariableInitialization node) {
    declareVariable(node.declaration);
    if (node.value != null) node.value.accept(this);
  }

  void declareVariable(Identifier decl) {
    if (decl.allowRename) vars.add(decl.name);
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

  bool visitNode(Node node) {
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
  bool visitForOf(ForOf node) => node.body.accept(this);
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
  bool visitClassDeclaration(ClassDeclaration node) => false;

  bool visitExpression(Expression node) => false;
}

abstract class LocalNamer {
  String getName(Identifier node);
  void enterScope(FunctionExpression node);
  void leaveScope();
}

class IdentityNamer implements LocalNamer {
  String getName(Identifier node) => node.name;
  void enterScope(FunctionExpression node) {}
  void leaveScope() {}
}

class MinifyRenamer implements LocalNamer {
  final List<Map<String, String>> maps = [];
  final List<int> parameterNumberStack = [];
  final List<int> variableNumberStack = [];
  int parameterNumber = 0;
  int variableNumber = 0;

  void enterScope(FunctionExpression node) {
    var vars = new VarCollector();
    node.accept(vars);
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

  String getName(Identifier node) {
    String oldName = node.name;
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

/// Like [BaseVisitor], but calls [declare] for [Identifier] declarations, and
/// [visitIdentifier] otherwise.
abstract class VariableDeclarationVisitor<T> extends BaseVisitor<T> {
  declare(Identifier node);

  visitFunctionExpression(FunctionExpression node) {
    node.params.forEach(_scanVariableBinding);
    node.body.accept(this);
  }

  _scanVariableBinding(VariableBinding d) {
    if (d is Identifier)
      declare(d);
    else
      d.accept(this);
  }

  visitRestParameter(RestParameter node) {
    _scanVariableBinding(node.parameter);
    super.visitRestParameter(node);
  }

  visitDestructuredVariable(DestructuredVariable node) {
    var name = node.name;
    if (name is Identifier) _scanVariableBinding(name);
    super.visitDestructuredVariable(node);
  }

  visitSimpleBindingPattern(SimpleBindingPattern node) {
    _scanVariableBinding(node.name);
    super.visitSimpleBindingPattern(node);
  }

  visitVariableInitialization(VariableInitialization node) {
    _scanVariableBinding(node.declaration);
    if (node.value != null) node.value.accept(this);
  }

  visitCatch(Catch node) {
    declare(node.declaration);
    node.body.accept(this);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    declare(node.name);
    node.function.accept(this);
  }

  visitNamedFunction(NamedFunction node) {
    declare(node.name);
    node.function.accept(this);
  }

  visitClassExpression(ClassExpression node) {
    declare(node.name);
    if (node.heritage != null) node.heritage.accept(this);
    for (Method element in node.methods) element.accept(this);
  }
}
