// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js.size_estimator;

import 'package:js_ast/js_ast.dart';
import 'package:js_ast/src/characters.dart' as charCodes;
import 'package:js_ast/src/precedence.dart';

import '../js_backend/string_reference.dart';
import '../js_backend/type_reference.dart';
import '../js_emitter/metadata_collector.dart';

/// Estimates the size of the Javascript AST represented by the provided [Node].
int estimateSize(Node node) {
  var estimator = SizeEstimator();
  estimator.visit(node);
  return estimator.charCount;
}

/// [SizeEstimator] is a [NodeVisitor] designed to produce a consistent size
/// estimate for a given JavaScript AST. [SizeEstimator] trades accuracy for
/// stability and performance. In addition, [SizeEstimator] assumes we will emit
/// production quality minified JavaScript.
class SizeEstimator implements NodeVisitor {
  int charCount = 0;
  bool inForInit = false;
  bool atStatementBegin = false;
  bool pendingSemicolon = false;
  bool pendingSpace = false;

  static final String variableSizeEstimate = '#';
  static final String nameSizeEstimate = '###';

  String sizeEstimate(Node node) {
    if (node is VariableDeclaration || node is VariableUse) {
      // We assume all [VariableDeclaration] and [VariableUse] nodes are
      // locals.
      return variableSizeEstimate;
    } else if (node is Name ||
        node is Parameter ||
        node is VariableDeclaration ||
        node is VariableUse) {
      return nameSizeEstimate;
    } else if (node is LiteralString) {
      assert(!node.isFinalized);
      // We assume all non-final literal strings are minified names, and thus
      // use the nameSizeEstimate.
      return nameSizeEstimate;
    } else if (node is BoundMetadataEntry) {
      // Value is an int.
      return '####';
    } else if (node is TypeReference) {
      // Type references vary in size. Some references look like:
      // '<typeHolder>$.<type>' where <typeHolder> is a one byte local and
      // <type> is roughly 3 bytes. However, we also have to initialize the type
      // in the holder, some like ab:f("QQ<b7c>"), ie 16 bytes. For two
      // occurences we will have on average 13 bytes. For a more detailed
      // estimate, we'd have to partially finalize the results.
      return '###_###_###_#';
    } else if (node is StringReference) {
      // Worst case we have to inline the string so size of string + 2 bytes for
      // quotes.
      return "'${node.constant.toDartString()}'";
    } else {
      throw UnsupportedError('$node type is not supported');
    }
  }

  String literalStringToString(LiteralString node) {
    if (node.isFinalized) {
      return node.value;
    } else {
      return sizeEstimate(node);
    }
  }

  /// Always emit a newline, even under `enableMinification`.
  void forceLine() {
    out('\n'); // '\n'
  }

  void out(String s) {
    if (s.length > 0) {
      // We can elide a semicolon in some cases, but for simplicity we
      // assume a semicolon is needed here.
      if (pendingSemicolon) {
        emit(';'); // ';'
      }

      // We can elide a pending space in some cases, but for simplicity we
      // assume a space is needed here.
      if (pendingSpace) {
        emit(' '); // ' '
      }
      pendingSpace = false;
      pendingSemicolon = false;
      emit(s); // str
    }
  }

  void outSemicolonLn() {
    pendingSemicolon = true;
  }

  void emit(String s) {
    charCount += s.length;
  }

  void visit(Node node) {
    node.accept(this);
  }

  void visitCommaSeparated(List<Node> nodes, int hasRequiredType,
      {bool newInForInit, bool newAtStatementBegin}) {
    for (int i = 0; i < nodes.length; i++) {
      if (i != 0) {
        atStatementBegin = false;
        out(','); // ','
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

  bool blockBody(Statement body, {bool needsSeparation}) {
    if (body is Block) {
      blockOut(body);
      return true;
    }
    if (needsSeparation) {
      out(' '); // ' '
    }
    visit(body);
    return false;
  }

  void blockOutWithoutBraces(Node node) {
    if (node is Block) {
      Block block = node;
      block.statements.forEach(blockOutWithoutBraces);
    } else {
      visit(node);
    }
  }

  int blockOut(Block node) {
    out('{'); // '{'
    node.statements.forEach(blockOutWithoutBraces);
    out('}'); // '}'
    int closingPosition = charCount - 1;
    return closingPosition;
  }

  @override
  void visitBlock(Block block) {
    blockOut(block);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: true);
    outSemicolonLn();
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    out(';'); // ';'
  }

  void ifOut(If node) {
    Statement then = unwrapBlockIfSingleStatement(node.then);
    Statement elsePart = node.otherwise;
    bool hasElse = node.hasElse;

    out('if('); // 'if('
    visitNestedExpression(node.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(then, needsSeparation: false);
    if (hasElse) {
      out('else'); // 'else'
      if (elsePart is If) {
        pendingSpace = true;
        ifOut(elsePart);
      } else {
        blockBody(unwrapBlockIfSingleStatement(elsePart),
            needsSeparation: true);
      }
    }
  }

  @override
  void visitIf(If node) {
    ifOut(node);
  }

  @override
  void visitFor(For loop) {
    out('for('); // 'for('
    if (loop.init != null) {
      visitNestedExpression(loop.init, EXPRESSION,
          newInForInit: true, newAtStatementBegin: false);
    }
    out(';'); // ';'
    if (loop.condition != null) {
      visitNestedExpression(loop.condition, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(';'); // ';'
    if (loop.update != null) {
      visitNestedExpression(loop.update, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(')'); // ')'
    blockBody(unwrapBlockIfSingleStatement(loop.body), needsSeparation: false);
  }

  @override
  void visitForIn(ForIn loop) {
    out('for('); // 'for('
    visitNestedExpression(loop.leftHandSide, EXPRESSION,
        newInForInit: true, newAtStatementBegin: false);
    out(' in'); // ' in'
    pendingSpace = true;
    visitNestedExpression(loop.object, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(unwrapBlockIfSingleStatement(loop.body), needsSeparation: false);
  }

  @override
  void visitWhile(While loop) {
    out('while('); // 'while('
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(unwrapBlockIfSingleStatement(loop.body), needsSeparation: false);
  }

  @override
  void visitDo(Do loop) {
    out('do'); // 'do'
    if (blockBody(unwrapBlockIfSingleStatement(loop.body),
        needsSeparation: true)) {}
    out('while('); // 'while('
    visitNestedExpression(loop.condition, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    outSemicolonLn();
  }

  @override
  void visitContinue(Continue node) {
    if (node.targetLabel == null) {
      out('continue'); // 'continue'
    } else {
      out('continue ${node.targetLabel}'); // 'continue ${node.targetLabel}'
    }
    outSemicolonLn();
  }

  @override
  void visitBreak(Break node) {
    if (node.targetLabel == null) {
      out('break');
    } else {
      out('break ${node.targetLabel}');
    }
    outSemicolonLn();
  }

  @override
  void visitReturn(Return node) {
    out('return'); // 'return'
    if (node.value != null) {
      pendingSpace = true;
      visitNestedExpression(node.value, EXPRESSION,
          newInForInit: false, newAtStatementBegin: false);
    }
    outSemicolonLn();
  }

  @override
  void visitDartYield(DartYield node) {
    if (node.hasStar) {
      out('yield*'); // 'yield*'
    } else {
      out('yield'); // 'yield'
    }
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitThrow(Throw node) {
    out('throw'); // 'throw'
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitTry(Try node) {
    out('try'); // 'try'
    blockBody(node.body, needsSeparation: true);
    if (node.catchPart != null) {
      visit(node.catchPart);
    }
    if (node.finallyPart != null) {
      out('finally'); // 'finally'
      blockBody(node.finallyPart, needsSeparation: true);
    }
  }

  @override
  void visitCatch(Catch node) {
    out('catch('); // 'catch('
    visitNestedExpression(node.declaration, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(node.body, needsSeparation: false);
  }

  @override
  void visitSwitch(Switch node) {
    out('switch('); // 'switch('
    visitNestedExpression(node.key, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out('){'); // '){
    visitAll(node.cases);
    out('}'); // '}'
  }

  @override
  void visitCase(Case node) {
    out('case'); // 'case'
    pendingSpace = true;
    visitNestedExpression(node.expression, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(':'); // ':'
    if (!node.body.statements.isEmpty) {
      blockOutWithoutBraces(node.body);
    }
  }

  @override
  void visitDefault(Default node) {
    out('default:'); // 'default:'
    if (!node.body.statements.isEmpty) {
      blockOutWithoutBraces(node.body);
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
    out('${node.label}:');
    blockBody(body, needsSeparation: false);
  }

  int functionOut(Fun fun, Node name, VarCollector vars) {
    out('function'); // 'function'
    if (name != null) {
      out(' '); // ' '
      // Name must be a [Decl]. Therefore only test for primary expressions.
      visitNestedExpression(name, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    out('('); // '('
    if (fun.params != null) {
      visitCommaSeparated(fun.params, PRIMARY,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(')'); // ')'
    switch (fun.asyncModifier) {
      case AsyncModifier.sync:
        break;
      case AsyncModifier.async:
        out(' async'); // ' async'
        break;
      case AsyncModifier.syncStar:
        out(' sync*'); // ' sync*'
        break;
      case AsyncModifier.asyncStar:
        out(' async*'); // ' async*'
        break;
    }
    int closingPosition = blockOut(fun.body);
    return closingPosition;
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration declaration) {
    VarCollector vars = new VarCollector();
    vars.visitFunctionDeclaration(declaration);
    functionOut(declaration.function, declaration.name, vars);
  }

  visitNestedExpression(Expression node, int requiredPrecedence,
      {bool newInForInit, bool newAtStatementBegin}) {
    bool needsParentheses = !node.isFinalized ||
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
      out('('); // '('
      visit(node);
      out(')'); // ')'
    } else {
      inForInit = newInForInit;
      atStatementBegin = newAtStatementBegin;
      visit(node);
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList list) {
    out('var '); // 'var '
    List<Node> nodes = list.declarations;
    if (inForInit) {
      visitCommaSeparated(nodes, ASSIGNMENT,
          newInForInit: inForInit, newAtStatementBegin: false);
    } else {
      for (int i = 0; i < nodes.length; i++) {
        Node node = nodes[i];
        if (i > 0) {
          atStatementBegin = false;
          out(','); // ','
        }
        visitNestedExpression(node, ASSIGNMENT,
            newInForInit: inForInit, newAtStatementBegin: false);
      }
    }
  }

  void _outputIncDec(String op, Expression variable, [Expression alias]) {
    // We can eliminate the space preceding the inc/dec in some cases,
    // but for estimation purposes we assume the worst case.
    if (op == '+') {
      out(' ++');
    } else {
      out(' --');
    }
    visitNestedExpression(variable, UNARY,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  visitAssignment(Assignment assignment) {
    /// To print assignments like `a = a + 1` and `a = a + b` compactly as
    /// `++a` and `a += b` in the face of [DeferredExpression]s we detect the
    /// pattern of the undeferred assignment.
    String op = assignment.op;
    Node leftHandSide = assignment.leftHandSide;
    Node rightHandSide = assignment.value;
    if ((op == '+' || op == '-') &&
        leftHandSide is VariableUse &&
        rightHandSide is LiteralNumber &&
        rightHandSide.value == "1") {
      // Output 'a += 1' as '++a' and 'a -= 1' as '--a'.
      _outputIncDec(op, assignment.leftHandSide);
      return;
    }
    if (!assignment.isCompound &&
        leftHandSide is VariableUse &&
        rightHandSide is Binary) {
      Node rLeft = rightHandSide.left;
      Node rRight = rightHandSide.right;
      String op = rightHandSide.op;
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
              rRight.value == "1") {
            _outputIncDec(op, assignment.leftHandSide, rightHandSide.left);
            return;
          }
          // Output 'a = a + b' as 'a += b'.
          visitNestedExpression(assignment.leftHandSide, CALL,
              newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
          assert(op.length == 1);
          out('$op='); // '$op='
          visitNestedExpression(rRight, ASSIGNMENT,
              newInForInit: inForInit, newAtStatementBegin: false);
          return;
        }
      }
    }
    visitNestedExpression(assignment.leftHandSide, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    if (assignment.value != null) {
      if (op != null) out(op);
      out('='); // '='
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
    out('?'); // '?'
    // The then part is allowed to have an 'in'.
    visitNestedExpression(cond.then, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(':'); // ':'
    visitNestedExpression(cond.otherwise, ASSIGNMENT,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  visitNew(New node) {
    out('new'); // 'new'
    visitNestedExpression(node.target, LEFT_HAND_SIDE,
        newInForInit: inForInit, newAtStatementBegin: false);
    out('('); // '('
    visitCommaSeparated(node.arguments, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
  }

  @override
  visitCall(Call call) {
    visitNestedExpression(call.target, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out('('); // '('
    visitCommaSeparated(call.arguments, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
  }

  @override
  void visitBinary(Binary binary) {
    Expression left = binary.left;
    Expression right = binary.right;
    String op = binary.op;
    int leftPrecedenceRequirement;
    int rightPrecedenceRequirement;
    switch (op) {
      case ',':
        //  x, (y, z) <=> (x, y), z.
        leftPrecedenceRequirement = EXPRESSION;
        rightPrecedenceRequirement = EXPRESSION;
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
        throw UnsupportedError("Forgot operator: $op");
    }

    visitNestedExpression(left, leftPrecedenceRequirement,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);

    if (op == "in" || op == "instanceof") {
      // There are cases where the space is not required but without further
      // analysis we cannot know.
      out(' $op '); // ' $op '
    } else {
      out(op); // '$op'
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
      case "+":
      case "++":
      case "-":
      case "--":
        // We may be able to eliminate the space in some cases, but for
        // estimation we assume the worst case.
        out('$op '); // '$op '
        break;
      default:
        out('$op'); // '$op'
    }
    visitNestedExpression(unary.argument, UNARY,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitPostfix(Postfix postfix) {
    visitNestedExpression(postfix.argument, CALL,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out(postfix.op); // '${postfix.op}'
  }

  @override
  void visitVariableUse(VariableUse ref) {
    // For simplicity and stability we use a constant name size estimate.
    // In production this is:
    // '${localNamer.getName(ref.name)'
    out(sizeEstimate(ref));
  }

  @override
  void visitThis(This node) {
    out('this'); // 'this'
  }

  @override
  void visitVariableDeclaration(VariableDeclaration decl) {
    // '${localNamer.getName(decl.name)'
    out(sizeEstimate(decl));
  }

  @override
  void visitParameter(Parameter param) {
    // For simplicity and stability we use a constant name size estimate.
    // In production this is:
    // '${localNamer.getName(param.name)'
    out(sizeEstimate(param));
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
      String fieldWithQuotes = literalStringToString(selector);
      if (isValidJavaScriptId(fieldWithQuotes)) {
        if (access.receiver is LiteralNumber) {
          // We can eliminate the space in some cases, but for simplicity we
          // always assume it is necessary.
          out(' '); // ' '
        }

        // '.${fieldWithQuotes.substring(1, fieldWithQuotes.length - 1)}'
        out('.${fieldWithQuotes.substring(1, fieldWithQuotes.length - 1)}');
        return;
      }
    } else if (selector is Name) {
      Node receiver = access.receiver;
      if (receiver is LiteralNumber) {
        // We can eliminate the space in some cases, but for simplicity we
        // always assume it is necessary.
        out(' '); // ' '
      }
      out('.'); // '.'
      selector.accept(this);
      return;
    }
    out('['); // '['
    visitNestedExpression(access.selector, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(']'); // ']
  }

  @override
  void visitNamedFunction(NamedFunction namedFunction) {
    VarCollector vars = new VarCollector();
    vars.visitNamedFunction(namedFunction);
    functionOut(namedFunction.function, namedFunction.name, vars);
  }

  @override
  void visitFun(Fun fun) {
    VarCollector vars = new VarCollector();
    vars.visitFun(fun);
    functionOut(fun, null, vars);
  }

  @override
  visitDeferredExpression(DeferredExpression node) {
    if (node.isFinalized) {
      // Continue printing with the expression value.
      assert(node.precedenceLevel == node.value.precedenceLevel);
      node.value.accept(this);
    } else {
      out(sizeEstimate(node));
    }
  }

  outputNumberWithRequiredWhitespace(String number) {
    int charCode = number.codeUnitAt(0);
    if (charCode == charCodes.$MINUS) {
      // We can eliminate the space in some cases, but for simplicity we
      // always assume it is necessary.
      out(' ');
    }
    out(number); // '${number}'
  }

  @override
  visitDeferredNumber(DeferredNumber node) {
    if (node.isFinalized) {
      outputNumberWithRequiredWhitespace("${node.value}");
    } else {
      out(sizeEstimate(node));
    }
  }

  @override
  visitDeferredString(DeferredString node) {
    if (node.isFinalized) {
      out(node.value);
    } else {
      out(sizeEstimate(node));
    }
  }

  @override
  visitLiteralBool(LiteralBool node) {
    out(node.value ? '!0' : '!1');
  }

  @override
  void visitLiteralString(LiteralString node) {
    out(literalStringToString(node));
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    node.visitChildren(this);
  }

  @override
  visitName(Name node) {
    // For simplicity and stability we use a constant name size estimate.
    // In production this is:
    // '${options.renamerForNames(node)}'
    out(sizeEstimate(node));
  }

  @override
  visitParentheses(Parentheses node) {
    out('('); // '('
    visitNestedExpression(node.enclosed, EXPRESSION,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
  }

  @override
  visitLiteralNumber(LiteralNumber node) {
    outputNumberWithRequiredWhitespace(node.value);
  }

  @override
  void visitLiteralNull(LiteralNull node) {
    out('null'); // 'null'
  }

  @override
  void visitArrayInitializer(ArrayInitializer node) {
    out('['); // '['
    List<Expression> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      Expression element = elements[i];
      if (element is ArrayHole) {
        // Note that array holes must have a trailing "," even if they are
        // in last position. Otherwise `[,]` (having length 1) would become
        // equal to `[]` (the empty array)
        // and [1,,] (array with 1 and a hole) would become [1,] = [1].
        out(','); // ','
        continue;
      }
      visitNestedExpression(element, ASSIGNMENT,
          newInForInit: false, newAtStatementBegin: false);
      // We can skip the trailing "," for the last element (since it's not
      // an array hole).
      if (i != elements.length - 1) out(','); // ','
    }
    out(']'); // ']'
  }

  @override
  void visitArrayHole(ArrayHole node) {
    throw UnsupportedError("Unreachable");
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

    bool isOneLiner = true;
    List<Property> properties = node.properties;
    out('{'); // '{'
    for (int i = 0; i < properties.length; i++) {
      Node value = properties[i].value;
      if (isOneLiner && exitOneLinerMode(value)) isOneLiner = false;
      if (i != 0) {
        out(','); // ','
      }
      if (!isOneLiner) {
        forceLine();
      }
      visit(properties[i]);
    }
    out('}'); // '}'
  }

  @override
  void visitProperty(Property node) {
    Node name = node.name;
    if (name is LiteralString) {
      String text = literalStringToString(name);
      if (isValidJavaScriptId(text)) {
        // '${text.substring(1, text.length - 1)}
        out('${text.substring(1, text.length - 1)}');
      } else {
        out(text); // '$text'
      }
    } else if (name is Name) {
      node.name.accept(this);
    } else if (name is DeferredExpression) {
      out(sizeEstimate(name));
    } else {
      assert(name is LiteralNumber);
      LiteralNumber nameNumber = node.name;
      out(nameNumber.value); // '${nameNumber.value}'
    }
    out(':'); // ':'
    visitNestedExpression(node.value, ASSIGNMENT,
        newInForInit: false, newAtStatementBegin: false);
  }

  @override
  void visitRegExpLiteral(RegExpLiteral node) {
    out(node.pattern); // '${node.pattern}'
  }

  @override
  void visitLiteralExpression(LiteralExpression node) {
    String template = node.template;
    List<Expression> inputs = node.inputs;

    List<String> parts = template.split('#');
    int inputsLength = inputs == null ? 0 : inputs.length;
    if (parts.length != inputsLength + 1) {
      throw UnsupportedError('Wrong number of arguments for JS: $template');
    }
    // Code that uses JS must take care of operator precedences, and
    // put parenthesis if needed.
    out(parts[0]); // '${parts[0]}'
    for (int i = 0; i < inputsLength; i++) {
      visit(inputs[i]);
      out(parts[i + 1]); // '${parts[i + 1]}'
    }
  }

  @override
  void visitLiteralStatement(LiteralStatement node) {
    out(node.code); // '${node.code}'
  }

  void visitInterpolatedNode(InterpolatedNode node) {
    throw UnsupportedError('InterpolatedStatements are not supported');
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
    throw UnsupportedError('InterpolatedStatements are not supported');
  }

  @override
  void visitInterpolatedDeclaration(InterpolatedDeclaration node) {
    visitInterpolatedNode(node);
  }

  @override
  void visitComment(Comment node) {
    // We assume output is compressed and thus do not output comments.
  }

  @override
  void visitAwait(Await node) {
    out('await '); // 'await '
    visit(node.expression);
  }
}
