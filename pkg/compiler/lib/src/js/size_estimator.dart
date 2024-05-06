// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js.size_estimator;

import 'package:js_ast/js_ast.dart';
import 'package:js_ast/src/characters.dart' as charCodes;
import 'package:js_ast/src/precedence.dart';

import '../js_backend/deferred_holder_expression.dart';
import '../js_backend/string_reference.dart';
import '../js_backend/type_reference.dart';
import '../js_emitter/metadata_collector.dart';

/// Estimates the size of the JavaScript AST represented by the provided [Node].
int estimateSize(Node node) {
  var estimator = SizeEstimator();
  estimator.visit(node);
  return estimator.charCount;
}

/// [SizeEstimator] is a [NodeVisitor] designed to produce a consistent size
/// estimate for a given JavaScript AST. [SizeEstimator] trades accuracy for
/// stability and performance. In addition, [SizeEstimator] assumes we will emit
/// production quality minified JavaScript.
class SizeEstimator implements NodeVisitor<void> {
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
      // occurrences we will have on average 13 bytes. For a more detailed
      // estimate, we'd have to partially finalize the results.
      return '###_###_###_#';
    } else if (node is StringReference) {
      // Worst case we have to inline the string so size of string + 2 bytes for
      // quotes.
      return "'${node.constant.toDartString()}'";
    } else if (node is DeferredHolderExpression) {
      // 1 byte holder + dot + nameSizeEstimate
      return '#.$nameSizeEstimate';
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

  void visitCommaSeparated(List<Expression> nodes, Precedence hasRequiredType,
      {required bool newInForInit, required bool newAtStatementBegin}) {
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

  bool blockBody(Statement body, {required bool needsSeparation}) {
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
    visitNestedExpression(node.expression, Precedence.expression,
        newInForInit: false, newAtStatementBegin: true);
    outSemicolonLn();
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    out(';'); // ';'
  }

  void ifOut(If node) {
    Statement then = node.then;
    Statement elsePart = node.otherwise;
    bool hasElse = node.hasElse;

    out('if('); // 'if('
    visitNestedExpression(node.condition, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(then, needsSeparation: false);
    if (hasElse) {
      out('else'); // 'else'
      if (elsePart is If) {
        pendingSpace = true;
        ifOut(elsePart);
      } else {
        blockBody(elsePart, needsSeparation: true);
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
      visitNestedExpression(loop.init!, Precedence.expression,
          newInForInit: true, newAtStatementBegin: false);
    }
    out(';'); // ';'
    if (loop.condition != null) {
      visitNestedExpression(loop.condition!, Precedence.expression,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(';'); // ';'
    if (loop.update != null) {
      visitNestedExpression(loop.update!, Precedence.expression,
          newInForInit: false, newAtStatementBegin: false);
    }
    out(')'); // ')'
    blockBody(loop.body, needsSeparation: false);
  }

  @override
  void visitForIn(ForIn loop) {
    out('for('); // 'for('
    visitNestedExpression(loop.leftHandSide, Precedence.expression,
        newInForInit: true, newAtStatementBegin: false);
    out(' in'); // ' in'
    pendingSpace = true;
    visitNestedExpression(loop.object, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(loop.body, needsSeparation: false);
  }

  @override
  void visitWhile(While loop) {
    out('while('); // 'while('
    visitNestedExpression(loop.condition, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(loop.body, needsSeparation: false);
  }

  @override
  void visitDo(Do loop) {
    out('do'); // 'do'
    if (blockBody(loop.body, needsSeparation: true)) {}
    out('while('); // 'while('
    visitNestedExpression(loop.condition, Precedence.expression,
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
      visitNestedExpression(node.value!, Precedence.expression,
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
    visitNestedExpression(node.expression, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitThrow(Throw node) {
    out('throw'); // 'throw'
    pendingSpace = true;
    visitNestedExpression(node.expression, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    outSemicolonLn();
  }

  @override
  void visitTry(Try node) {
    out('try'); // 'try'
    blockBody(node.body, needsSeparation: true);
    if (node.catchPart != null) {
      visit(node.catchPart!);
    }
    if (node.finallyPart != null) {
      out('finally'); // 'finally'
      blockBody(node.finallyPart!, needsSeparation: true);
    }
  }

  @override
  void visitCatch(Catch node) {
    out('catch('); // 'catch('
    visitNestedExpression(node.declaration, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
    blockBody(node.body, needsSeparation: false);
  }

  @override
  void visitSwitch(Switch node) {
    out('switch('); // 'switch('
    visitNestedExpression(node.key, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out('){'); // '){
    visitAll(node.cases);
    out('}'); // '}'
  }

  @override
  void visitCase(Case node) {
    out('case'); // 'case'
    pendingSpace = true;
    visitNestedExpression(node.expression, Precedence.expression,
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
    out('${node.label}:');
    blockBody(node.body, needsSeparation: false);
  }

  int functionOut(Fun fun, Expression? name, VarCollector vars) {
    out('function'); // 'function'
    if (name != null) {
      out(' '); // ' '
      // Name must be a [Decl]. Therefore only test for primary expressions.
      visitNestedExpression(name, Precedence.primary,
          newInForInit: false, newAtStatementBegin: false);
    }
    out('('); // '('
    visitCommaSeparated(fun.params, Precedence.primary,
        newInForInit: false, newAtStatementBegin: false);
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
  void visitFunctionDeclaration(FunctionDeclaration declaration) {
    VarCollector vars = VarCollector();
    vars.visitFunctionDeclaration(declaration);
    functionOut(declaration.function, declaration.name, vars);
  }

  void visitNestedExpression(Expression node, Precedence requiredPrecedence,
      {required bool newInForInit, required bool newAtStatementBegin}) {
    bool needsParentheses = !node.isFinalized ||
        // a - (b + c).
        (requiredPrecedence != Precedence.expression &&
            node.precedenceLevel.index < requiredPrecedence.index) ||
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
  void visitVariableDeclarationList(VariableDeclarationList list) {
    out('var '); // 'var '
    final nodes = list.declarations;
    if (inForInit) {
      visitCommaSeparated(nodes, Precedence.assignment,
          newInForInit: inForInit, newAtStatementBegin: false);
    } else {
      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        if (i > 0) {
          atStatementBegin = false;
          out(','); // ','
        }
        visitNestedExpression(node, Precedence.assignment,
            newInForInit: inForInit, newAtStatementBegin: false);
      }
    }
  }

  void _outputIncDec(String op, Expression variable) {
    // We can eliminate the space preceding the inc/dec in some cases,
    // but for estimation purposes we assume the worst case.
    if (op == '+') {
      out(' ++');
    } else {
      out(' --');
    }
    visitNestedExpression(variable, Precedence.unary,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitAssignment(Assignment assignment) {
    /// To print assignments like `a = a + 1` and `a = a + b` compactly as
    /// `++a` and `a += b` in the face of [DeferredExpression]s we detect the
    /// pattern of the undeferred assignment.
    final op = assignment.op;
    Node leftHandSide = assignment.leftHandSide;
    Node rightHandSide = assignment.value;
    if ((op == '+' || op == '-') &&
        leftHandSide is VariableUse &&
        rightHandSide is LiteralNumber &&
        rightHandSide.value == "1") {
      // Output 'a += 1' as '++a' and 'a -= 1' as '--a'.
      _outputIncDec(op!, assignment.leftHandSide);
      return;
    }
    if (!assignment.isCompound &&
        leftHandSide is VariableUse &&
        rightHandSide is Binary) {
      final rLeft = rightHandSide.left;
      final rRight = rightHandSide.right;
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
            _outputIncDec(op, assignment.leftHandSide);
            return;
          }
          // Output 'a = a + b' as 'a += b'.
          visitNestedExpression(assignment.leftHandSide, Precedence.call,
              newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
          assert(op.length == 1);
          out('$op='); // '$op='
          visitNestedExpression(rRight, Precedence.assignment,
              newInForInit: inForInit, newAtStatementBegin: false);
          return;
        }
      }
    }
    visitNestedExpression(assignment.leftHandSide, Precedence.call,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    if (op != null) out(op);
    out('='); // '='
    visitNestedExpression(assignment.value, Precedence.assignment,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitVariableInitialization(VariableInitialization initialization) {
    visitNestedExpression(initialization.declaration, Precedence.call,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    if (initialization.value != null) {
      out('=');
      visitNestedExpression(initialization.value!, Precedence.assignment,
          newInForInit: inForInit, newAtStatementBegin: false);
    }
  }

  @override
  void visitConditional(Conditional cond) {
    visitNestedExpression(cond.condition, Precedence.logicalOr,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out('?'); // '?'
    // The then part is allowed to have an 'in'.
    visitNestedExpression(cond.then, Precedence.assignment,
        newInForInit: false, newAtStatementBegin: false);
    out(':'); // ':'
    visitNestedExpression(cond.otherwise, Precedence.assignment,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitNew(New node) {
    out('new'); // 'new'
    visitNestedExpression(node.target, Precedence.leftHandSide,
        newInForInit: inForInit, newAtStatementBegin: false);
    out('('); // '('
    visitCommaSeparated(node.arguments, Precedence.assignment,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
  }

  @override
  void visitCall(Call call) {
    visitNestedExpression(call.target, Precedence.call,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    out('('); // '('
    visitCommaSeparated(call.arguments, Precedence.assignment,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
  }

  @override
  void visitBinary(Binary binary) {
    Expression left = binary.left;
    Expression right = binary.right;
    String op = binary.op;
    Precedence leftPrecedenceRequirement;
    Precedence rightPrecedenceRequirement;
    switch (op) {
      case ',':
        //  x, (y, z) <=> (x, y), z.
        leftPrecedenceRequirement = Precedence.expression;
        rightPrecedenceRequirement = Precedence.expression;
        break;
      case "||":
        leftPrecedenceRequirement = Precedence.logicalOr;
        // x || (y || z) <=> (x || y) || z.
        rightPrecedenceRequirement = Precedence.logicalOr;
        break;
      case "&&":
        leftPrecedenceRequirement = Precedence.logicalAnd;
        // x && (y && z) <=> (x && y) && z.
        rightPrecedenceRequirement = Precedence.logicalAnd;
        break;
      case "|":
        leftPrecedenceRequirement = Precedence.bitOr;
        // x | (y | z) <=> (x | y) | z.
        rightPrecedenceRequirement = Precedence.bitOr;
        break;
      case "^":
        leftPrecedenceRequirement = Precedence.bitXor;
        // x ^ (y ^ z) <=> (x ^ y) ^ z.
        rightPrecedenceRequirement = Precedence.bitXor;
        break;
      case "&":
        leftPrecedenceRequirement = Precedence.bitAnd;
        // x & (y & z) <=> (x & y) & z.
        rightPrecedenceRequirement = Precedence.bitAnd;
        break;
      case "==":
      case "!=":
      case "===":
      case "!==":
        leftPrecedenceRequirement = Precedence.equality;
        rightPrecedenceRequirement = Precedence.relational;
        break;
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "instanceof":
      case "in":
        leftPrecedenceRequirement = Precedence.relational;
        rightPrecedenceRequirement = Precedence.shift;
        break;
      case ">>":
      case "<<":
      case ">>>":
        leftPrecedenceRequirement = Precedence.shift;
        rightPrecedenceRequirement = Precedence.additive;
        break;
      case "+":
      case "-":
        leftPrecedenceRequirement = Precedence.additive;
        // We cannot remove parenthesis for "+" because
        //   x + (y + z) <!=> (x + y) + z:
        // Example:
        //   "a" + (1 + 2) => "a3";
        //   ("a" + 1) + 2 => "a12";
        rightPrecedenceRequirement = Precedence.multiplicative;
        break;
      case "*":
      case "/":
      case "%":
        leftPrecedenceRequirement = Precedence.multiplicative;
        // We cannot remove parenthesis for "*" because of precision issues.
        rightPrecedenceRequirement = Precedence.unary;
        break;
      case "**":
        leftPrecedenceRequirement = Precedence.exponentiation;
        // We cannot remove parenthesis for "**" because of precision issues.
        rightPrecedenceRequirement = Precedence.unary;
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
    visitNestedExpression(unary.argument, Precedence.unary,
        newInForInit: inForInit, newAtStatementBegin: false);
  }

  @override
  void visitPostfix(Postfix postfix) {
    visitNestedExpression(postfix.argument, Precedence.call,
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
    if (field.length == 0) return false;
    // Ignore the leading and trailing string-delimiter.
    for (int i = 0; i < field.length; i++) {
      // TODO(floitsch): allow more characters.
      int charCode = field.codeUnitAt(i);
      if (!(charCodes.$a <= charCode && charCode <= charCodes.$z ||
          charCodes.$A <= charCode && charCode <= charCodes.$Z ||
          charCode == charCodes.$$ ||
          charCode == charCodes.$_ ||
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
    visitNestedExpression(access.receiver, Precedence.call,
        newInForInit: inForInit, newAtStatementBegin: atStatementBegin);
    Node selector = access.selector;
    if (selector is LiteralString) {
      String field = literalStringToString(selector);
      if (isValidJavaScriptId(field)) {
        if (access.receiver is LiteralNumber) {
          // We can eliminate the space in some cases, but for simplicity we
          // always assume it is necessary.
          out(' '); // ' '
        }

        // '.${field}'
        out('.');
        out(field);
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
    visitNestedExpression(access.selector, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out(']'); // ']
  }

  @override
  void visitNamedFunction(NamedFunction namedFunction) {
    VarCollector vars = VarCollector();
    vars.visitNamedFunction(namedFunction);
    functionOut(namedFunction.function, namedFunction.name, vars);
  }

  @override
  void visitFun(Fun fun) {
    VarCollector vars = VarCollector();
    vars.visitFun(fun);
    functionOut(fun, null, vars);
  }

  @override
  void visitArrowFunction(ArrowFunction fun) {
    VarCollector vars = VarCollector();
    vars.visitArrowFunction(fun);
    arrowFunctionOut(fun, vars);
  }

  int arrowFunctionOut(ArrowFunction fun, VarCollector vars) {
    // TODO: support static, get/set, async, and generators.
    if (fun.params.length == 1) {
      visitNestedExpression(fun.params.single, Precedence.assignment,
          newInForInit: false, newAtStatementBegin: false);
    } else {
      out("(");
      visitCommaSeparated(fun.params, Precedence.primary,
          newInForInit: false, newAtStatementBegin: false);

      out(")");
    }
    out("=>");
    int closingPosition;
    Node body = fun.body;
    if (body is Block) {
      closingPosition = blockOut(body);
    } else {
      // Object initializers require parentheses to disambiguate
      // AssignmentExpression from FunctionBody. See:
      // https://tc39.github.io/ecma262/#sec-arrow-function-definitions
      bool needsParens = body is ObjectInitializer;
      if (needsParens) out("(");
      visitNestedExpression(body as Expression, Precedence.assignment,
          newInForInit: false, newAtStatementBegin: false);
      if (needsParens) out(")");
      closingPosition = charCount;
    }
    return closingPosition;
  }

  @override
  void visitDeferredExpression(DeferredExpression node) {
    if (node.isFinalized) {
      // Continue printing with the expression value.
      assert(node.precedenceLevel == node.value.precedenceLevel);
      node.value.accept(this);
    } else {
      out(sizeEstimate(node));
    }
  }

  @override
  void visitDeferredStatement(DeferredStatement node) {
    if (node.isFinalized) {
      // Continue printing with the statement value.
      node.statement.accept(this);
    } else {
      sizeEstimate(node);
    }
  }

  void outputNumberWithRequiredWhitespace(String number) {
    int charCode = number.codeUnitAt(0);
    if (charCode == charCodes.$MINUS) {
      // We can eliminate the space in some cases, but for simplicity we
      // always assume it is necessary.
      out(' ');
    }
    out(number); // '${number}'
  }

  @override
  void visitDeferredNumber(DeferredNumber node) {
    if (node.isFinalized) {
      outputNumberWithRequiredWhitespace("${node.value}");
    } else {
      out(sizeEstimate(node));
    }
  }

  @override
  void visitDeferredString(DeferredString node) {
    if (node.isFinalized) {
      out(node.value);
    } else {
      out(sizeEstimate(node));
    }
  }

  @override
  void visitLiteralBool(LiteralBool node) {
    out(node.value ? '!0' : '!1');
  }

  @override
  void visitLiteralString(LiteralString node) {
    out('"');
    out(literalStringToString(node));
    out('"');
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    node.visitChildren(this);
  }

  @override
  void visitName(Name node) {
    // For simplicity and stability we use a constant name size estimate.
    out(sizeEstimate(node));
  }

  @override
  void visitParentheses(Parentheses node) {
    out('('); // '('
    visitNestedExpression(node.enclosed, Precedence.expression,
        newInForInit: false, newAtStatementBegin: false);
    out(')'); // ')'
  }

  @override
  void visitLiteralNumber(LiteralNumber node) {
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
      visitNestedExpression(element, Precedence.assignment,
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
      final value = properties[i].value;
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
    propertyNameOut(node);
    out(':'); // ':'
    visitNestedExpression(node.value, Precedence.assignment,
        newInForInit: false, newAtStatementBegin: false);
  }

  @override
  void visitMethodDefinition(MethodDefinition node) {
    propertyNameOut(node);
    VarCollector vars = VarCollector();
    vars.visitMethodDefinition(node);
    methodOut(node, vars);
  }

  int methodOut(MethodDefinition node, VarCollector vars) {
    // TODO: support static, get/set, async, and generators.
    Fun fun = node.function;
    out("(");
    visitCommaSeparated(fun.params, Precedence.primary,
        newInForInit: false, newAtStatementBegin: false);
    out(")");
    int closingPosition = blockOut(fun.body);
    return closingPosition;
  }

  void propertyNameOut(Property node) {
    Node name = node.name;
    if (name is LiteralString) {
      String text = literalStringToString(name);
      if (isValidJavaScriptId(text)) {
        out(text);
      } else {
        // Approximation to `_handleString(text)`.
        out('"');
        out(text);
        out('"');
      }
    } else if (name is Name) {
      node.name.accept(this);
    } else if (name is DeferredExpression) {
      out(sizeEstimate(name));
    } else {
      assert(name is LiteralNumber);
      final nameNumber = node.name as LiteralNumber;
      out(nameNumber.value); // '${nameNumber.value}'
    }
  }

  @override
  void visitRegExpLiteral(RegExpLiteral node) {
    out(node.pattern); // '${node.pattern}'
  }

  @override
  void visitLiteralExpression(LiteralExpression node) {
    out(node.template); // '${node.template}'
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
