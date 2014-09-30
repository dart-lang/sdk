// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_printer_test;

import "package:expect/expect.dart";
import 'package:compiler/implementation/constants/values.dart';
import 'package:compiler/implementation/dart_backend/backend_ast_nodes.dart';
import 'package:compiler/implementation/scanner/scannerlib.dart';
import 'package:compiler/implementation/source_file.dart';
import 'package:compiler/implementation/dart2jslib.dart';
import 'package:compiler/implementation/tree/tree.dart' show DartString;
import 'dart:mirrors';
import 'package:compiler/implementation/tree/tree.dart' as tree;
import 'package:compiler/implementation/string_validator.dart';
import 'package:compiler/implementation/dart_backend/backend_ast_to_frontend_ast.dart'
    show TreePrinter;

/// For debugging the [AstBuilder] stack. Prints information about [x].
void show(x) {
  StringBuffer buf = new StringBuffer();
  Unparser unparser = new Unparser(buf);
  void unparse(x) {
    if (x is Expression)
      unparser.writeExpression(x);
    else if (x is TypeAnnotation)
      unparser.writeType(x);
    else if (x is Statement)
      unparser.writeStatement(x);
    else if (x is List) {
      buf.write('[');
      bool first = true;
      for (var y in x) {
        if (first)
          first = false;
        else
          buf.write(', ');
        unparse(y);
      }
      buf.write(']');
    }
  }
  unparse(x);
  print("${x.runtimeType}: ${buf.toString()}");
}

class PrintDiagnosticListener implements DiagnosticListener {
  void log(message) {
    print(message);
  }

  void internalError(Spannable spannable, message) {
    print(message);
  }

  SourceSpan spanFromSpannable(Spannable node) {
    return new SourceSpan(null, 0, 0);
  }

  void reportFatalError(Spannable node, MessageKind errorCode,
                        [Map arguments = const {}]) {
    print(errorCode);
    throw new Error();
  }

  void reportError(Spannable node, MessageKind errorCode,
                   [Map arguments = const {}]) {
    print(errorCode);
  }

  void reportWarning(Spannable node, MessageKind errorCode,
                     [Map arguments = const {}]) {
    print(errorCode);
  }

  void reportHint(Spannable node, MessageKind errorCode,
                  [Map arguments = const {}]) {
    print(errorCode);
  }

  void reportInfo(Spannable node, MessageKind errorCode,
                  [Map arguments = const {}]) {
    print(errorCode);
  }

  withCurrentElement(element, f()) {
    f();
  }
}

class AstBuilder extends Listener {
  final List stack = [];
  final StringValidator stringValidator
         = new StringValidator(new PrintDiagnosticListener());

  String asName(e) {
    if (e is Identifier)
      return e.name;
    else if (e == null)
      return null;
    else
      throw 'Expression is not a name: ${e.runtimeType}';
  }

  TypeAnnotation asType(x) {
    if (x is TypeAnnotation)
      return x;
    if (x is Identifier)
      return new TypeAnnotation(x.name);
    if (x == null)
      return null;
    else
      throw "Not a type: ${x.runtimeType}";
  }

  Parameter asParameter(x) {
    if (x is Parameter)
      return x;
    if (x is Identifier)
      return new Parameter(x.name);
    else
      throw "Not a parameter: ${x.runtimeType}";
  }

  void push(node) {
    stack.add(node);
  }
  dynamic peek() {
    return stack.last;
  }
  dynamic pop([coerce(x) = null]) {
    var x = stack.removeLast();
    if (coerce != null)
      return coerce(x);
    else
      return x;
  }
  List popList(int count, [List result, coerce(x) = null]) {
    if (result == null)
      result = <Node>[];
    for (int i=0; i<count; i++) {
      var x = stack[stack.length-count+i];
      if (coerce != null) {
        x = coerce(x);
      }
      result.add(x);
    }
    stack.removeRange(stack.length-count, stack.length);
    return result;
  }
  popTypeAnnotation() {
    List<TypeAnnotation> args = pop();
    if (args == null)
      return null;
    String name = pop(asName);
    return new TypeAnnotation(name, args);
  }

  // EXPRESSIONS
  endCascade() {
    throw "Cascade not supported yet";
  }
  endIdentifierList(int count) {
    push(popList(count, <Identifier>[]));
  }
  endTypeList(int count) {
    push(popList(count, <TypeAnnotation>[], asType));
  }
  beginLiteralString(Token token) {
    String source = token.value;
    tree.StringQuoting quoting = StringValidator.quotingFromString(source);
    push(quoting);
    push(token); // collect token at the end
  }
  handleStringPart(Token token) {
    push(token); // collect token at the end
  }
  endLiteralString(int interpCount) {
    List parts = popList(2 * interpCount + 1, []);
    tree.StringQuoting quoting = pop();
    List<Expression> members = <Expression>[];
    for (var i=0; i<parts.length; i++) {
      var part = parts[i];
      if (part is Expression) {
        members.add(part);
      } else {
        assert(part is Token);
        DartString str = stringValidator.validateInterpolationPart(
            part as Token,
            quoting,
            isFirst: i == 0,
            isLast: i == parts.length - 1);
        members.add(new Literal(new StringConstant(str)));
      }
    }
    push(new StringConcat(members));
  }
  handleStringJuxtaposition(int litCount) {
    push(new StringConcat(popList(litCount, <Expression>[])));
  }
  endArguments(int count, begin, end) {
    push(popList(count, <Argument>[]));
  }
  handleNoArguments(token) {
    push(null);
  }
  handleNoTypeArguments(token) {
    push(<TypeAnnotation>[]);
  }
  endTypeArguments(int count, t, y) {
    List<TypeAnnotation> args = <TypeAnnotation>[];
    for (var i=0; i<count; i++) {
      args.add(popTypeAnnotation());
    }
    push(args.reversed.toList(growable:false));
  }
  handleVoidKeyword(token) {
    push(new Identifier("void"));
    push(<TypeAnnotation>[]); // prepare for popTypeAnnotation
  }
  handleQualified(Token period) {
    String last = pop(asName);
    String first = pop(asName);
    push(new Identifier('$first.$last'));
  }
  endSend(t) {
    List<Argument> arguments = pop();
    if (arguments == null)
      return; // not a function call
    Expression selector = pop();
    push(new CallFunction(selector, arguments));
  }
  endThrowExpression(t, tt) {
    push(new Throw(pop()));
  }
  handleAssignmentExpression(Token token) {
    Expression right = pop();
    Expression left = pop();
    push(new Assignment(left, token.value, right));
  }
  handleBinaryExpression(Token token) {
    Expression right = pop();
    Receiver left = pop();
    String tokenString = token.stringValue;
    if (tokenString == '.') {
      if (right is CallFunction) {
        String name = (right.callee as Identifier).name;
        push(new CallMethod(left, name, right.arguments));
      } else {
        push(new FieldExpression(left, (right as Identifier).name));
      }
    } else {
      push(new BinaryOperator(left, tokenString, right));
    }
  }
  handleConditionalExpression(question, colon) {
    Expression elseExpression = pop();
    Expression thenExpression = pop();
    Expression condition = pop();
    push(new Conditional(condition, thenExpression, elseExpression));
  }
  handleIdentifier(Token t) {
    push(new Identifier(t.value));
  }
  handleOperator(t) {
    push(new Identifier(t.value));
  }
  handleIndexedExpression(open, close) {
    Expression index = pop();
    Receiver object = pop();
    push(new IndexExpression(object, index));
  }
  handleIsOperator(operathor, not, endToken) {
    TypeAnnotation type = popTypeAnnotation();
    Expression exp = pop();
    TypeOperator r = new TypeOperator(exp, 'is', type);
    if (not != null) {
      push(new UnaryOperator('!', r));
    } else {
      push(r);
    }
  }
  handleAsOperator(operathor, endToken) {
    TypeAnnotation type = popTypeAnnotation();
    Expression exp = pop();
    push(new TypeOperator(exp, 'as', type));
  }
  handleLiteralBool(Token t) {
    bool value = t.value == 'true';
    push(new Literal(value ? new TrueConstant() : new FalseConstant()));
  }
  handleLiteralDouble(t) {
    push(new Literal(new DoubleConstant(double.parse(t.value))));
  }
  handleLiteralInt(Token t) {
    push(new Literal(new IntConstant(int.parse(t.value))));
  }
  handleLiteralNull(t) {
    push(new Literal(new NullConstant()));
  }
  endLiteralSymbol(Token hash, int idCount) {
    List<Identifier> ids = popList(idCount, <Identifier>[]);
    push(new LiteralSymbol(ids.map((id) => id.name).join('.')));
  }
  handleLiteralList(int count, begin, constKeyword, end) {
    List<Expression> exps = popList(count, <Expression>[]);
    List<TypeAnnotation> types = pop();
    assert(types.length <= 1);
    push(new LiteralList(exps,
      isConst: constKeyword != null,
      typeArgument: types.length == 0 ? null : types[0]
    ));
  }
  handleLiteralMap(int count, begin, constKeyword, end) {
    List<LiteralMapEntry> entries = popList(count, <LiteralMapEntry>[]);
    List<TypeAnnotation> types = pop();
    assert(types.length == 0 || types.length == 2);
    push(new LiteralMap(entries,
        isConst: constKeyword != null,
        typeArguments: types
    ));
  }
  endLiteralMapEntry(colon, endToken) {
    Expression value = pop();
    Expression key = pop();
    push(new LiteralMapEntry(key,value));
  }
  handleNamedArgument(colon) {
    Expression exp = pop();
    Identifier name = pop();
    push(new NamedArgument(name.name, exp));
  }
  endConstructorReference(Token start, Token period, Token end) {
    if (period == null) {
      push(null); // indicate missing constructor name
    }
  }
  handleNewExpression(t) {
    List<Argument> args = pop();
    String constructorName = pop(asName);
    TypeAnnotation type = popTypeAnnotation();
    push(new CallNew(type, args, constructorName: constructorName));
  }
  handleConstExpression(t) {
    List<Argument> args = pop();
    String constructorName = pop(asName);
    TypeAnnotation type = popTypeAnnotation();
    push(new CallNew(type, args, constructorName: constructorName,
                     isConst:true));
  }
  handleParenthesizedExpression(t) {
    // do nothing, just leave expression on top of stack
  }
  handleSuperExpression(t) {
    push(new SuperReceiver());
  }
  handleThisExpression(t) {
    push(new This());
  }
  handleUnaryPostfixAssignmentExpression(Token t) {
    push(new Increment.postfix(pop(), t.value));
  }
  handleUnaryPrefixAssignmentExpression(Token t) {
    push(new Increment.prefix(pop(), t.value));
  }
  handleUnaryPrefixExpression(Token t) {
    push(new UnaryOperator(t.value, pop()));
  }

  handleFunctionTypedFormalParameter(tok) {
    // handled in endFormalParameter
  }
  endFormalParameter(thisKeyword) {
    Expression defaultValue = null;
    var x = pop();
    if (x is DefaultValue) {
      defaultValue = x.expression;
      x = pop();
    }
    if (x is Parameters) {
      String name = pop(asName);
      TypeAnnotation returnType = popTypeAnnotation();
      push(new Parameter.function(name, returnType, x, defaultValue));
    } else {
      String name = asName(x);
      TypeAnnotation type = popTypeAnnotation();
      push(new Parameter(name, type:type, defaultValue:defaultValue));
    }
  }
  handleValuedFormalParameter(eq, tok) {
    push(new DefaultValue(pop()));
  }
  endOptionalFormalParameters(int count, begin, end) {
    bool isNamed = end.value == '}';
    push(popList(count, <Parameter>[], asParameter));
    push(isNamed); // Indicate optional parameters to endFormalParameters.
  }
  endFormalParameters(count, begin, end) {
    if (count == 0) {
      push(new Parameters([]));
      return;
    }
    var last = pop();   // Detect if optional parameters are present.
    if (last is bool) { // See endOptionalFormalParameters.
      List<Parameter> optional = pop();
      List<Parameter> required = popList(count-1, <Parameter>[], asParameter);
      push(new Parameters(required, optional, last));
    } else {
      // No optional parameters.
      List<Parameter> required = popList(count-1, <Parameter>[], asParameter);
      required.add(last);
      push(new Parameters(required));
    }
  }
  handleNoFormalParameters(tok) {
    push(new Parameters([]));
  }
  endUnamedFunction(t) {
    Statement body = pop();
    Parameters parameters = pop();
    push(new FunctionExpression(parameters, body));
  }
  handleNoType(Token token) {
    push(null);
  }

  endReturnStatement(bool hasExpression, begin, end) {
    // This is also called for functions whose body is "=> expression"
    if (hasExpression) {
      push(new Return(pop()));
    } else {
      push(new Return());
    }
  }

  endExpressionStatement(Token token) {
    push(new ExpressionStatement(pop()));
  }

  endDoWhileStatement(Token doKeyword, Token whileKeyword, Token end) {
    Expression condition = pop();
    Statement body = pop();
    push(new DoWhile(body, condition));
  }

  endWhileStatement(Token whileKeyword, Token end) {
    Statement body = pop();
    Expression condition = pop();
    push(new While(condition, body));
  }

  endBlock(int count, Token begin, Token end) {
    push(new Block(popList(count, <Statement>[])));
  }

  endRethrowStatement(Token throwToken, Token endToken) {
    push(new Rethrow());
  }

  endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Statement finallyBlock = null;
    if (finallyKeyword != null) {
      finallyBlock = pop();
    }
    List<CatchBlock> catchBlocks = popList(catchCount, <CatchBlock>[]);
    Statement tryBlock = pop();
    push(new Try(tryBlock, catchBlocks, finallyBlock));
  }

  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    Statement block = pop();
    String exceptionVar = null;
    String stackVar = null;
    if (catchKeyword != null) {
      Parameters params = pop();
      exceptionVar = params.requiredParameters[0].name;
      if (params.requiredParameters.length > 1) {
        stackVar = params.requiredParameters[1].name;
      }
    }
    TypeAnnotation type = onKeyword == null ? null : pop();
    push(new CatchBlock(block,
      onType: type,
      exceptionVar: exceptionVar,
      stackVar: stackVar
    ));
  }

  endSwitchStatement(Token switchKeyword, Token end) {
    List<SwitchCase> cases = pop();
    Expression expression = pop();
    push(new Switch(expression, cases));
  }

  endSwitchBlock(int caseCount, Token begin, Token end) {
    push(popList(caseCount, <SwitchCase>[]));
  }

  handleSwitchCase(int labelCount, int caseCount, Token defaultKeyword,
                   int statementCount, Token first, Token end) {
    List<Statement> statements = popList(statementCount, <Statement>[]);
    List<Expression> cases = popList(caseCount, <Expression>[]);
    if (defaultKeyword != null) {
      cases = null;
    }
    push(new SwitchCase(cases, statements));
  }

  handleCaseMatch(Token caseKeyword, Token colon) {
    // do nothing, leave case expression on stack
  }

  handleBreakStatement(bool hasTarget, Token breakKeyword, Token end) {
    String target = hasTarget ? pop(asName) : null;
    push(new Break(target));
  }

  handleContinueStatement(bool hasTarget, Token continueKeyword, Token end) {
    String target = hasTarget ? pop(asName) : null;
    push(new Continue(target));
  }

  handleEmptyStatement(Token token) {
    push(new EmptyStatement());
  }


  VariableDeclaration asVariableDeclaration(x) {
    if (x is VariableDeclaration)
      return x;
    if (x is Identifier)
      return new VariableDeclaration(x.name);
    throw "Not a variable definition: ${x.runtimeType}";
  }

  endVariablesDeclaration(int count, Token end) {
    List<VariableDeclaration> variables =
        popList(count, <VariableDeclaration>[], asVariableDeclaration);
    TypeAnnotation type = popTypeAnnotation();
    push(new VariableDeclarations(variables,
      type: type,
      isFinal: false, // TODO(asgerf): Parse modifiers.
      isConst: false
    ));
  }

  endInitializer(Token assign) {
    Expression init = pop();
    String name = pop(asName);
    push(new VariableDeclaration(name, init));
  }

  endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = (elseToken == null) ? null : pop();
    Statement thenPart = pop();
    Expression condition = pop();
    push(new If(condition, thenPart, elsePart));
  }

  endForStatement(int updateCount, Token begin, Token end) {
    Statement body = pop();
    List<Expression> updates = popList(updateCount, <Expression>[]);
    ExpressionStatement condition = pop(); // parsed as expression statement
    Expression exp = condition == null ? null : condition.expression;
    Node initializer = pop();
    push(new For(initializer, exp, updates, body));
  }

  handleNoExpression(Token token) {
    push(null);
  }

  endForIn(Token begin, Token inKeyword, Token end) {
    Statement body = pop();
    Expression exp = pop();
    Node declaredIdentifier = pop();
    push(new ForIn(declaredIdentifier, exp, body));
  }

  handleAssertStatement(Token assertKeyword, Token semicolonToken) {
    Expression exp = pop();
    Expression call = new CallFunction(new Identifier("assert"), [exp]);
    push(new ExpressionStatement(call));
  }

  endLabeledStatement(int labelCount) {
    Statement statement = pop();
    for (int i=0; i<labelCount; i++) {
      String label = pop(asName);
      statement = new LabeledStatement(label, statement);
    }
    push(statement);
  }

  endFunctionDeclaration(Token end) {
    Statement body = pop();
    Parameters parameters = pop();
    String name = pop(asName);
    TypeAnnotation returnType = popTypeAnnotation();
    push(new FunctionDeclaration(new FunctionExpression(parameters, body,
        name: name,
        returnType: returnType)));
  }

  endFunctionBody(int count, Token begin, Token end) {
    push(new Block(popList(count, <Statement>[])));
  }
}

class DefaultValue {
  final Expression expression;
  DefaultValue(this.expression);
}

/// Compares ASTs for structural equality.
void checkDeepEqual(x, y) {
  if (x is List && y is List) {
    if (x.length != y.length)
      return;
    for (var i=0; i<x.length; i++) {
      checkDeepEqual(x[i], y[i]);
    }
  }
  else if (x is Node && y is Node) {
    if (x.runtimeType != y.runtimeType)
      throw new Error();
    InstanceMirror xm = reflect(x);
    InstanceMirror ym = reflect(y);
    for (Symbol name in xm.type.instanceMembers.keys) {
      if (reflectClass(Object).declarations.containsKey(name)) {
        continue; // do not check things from Object, such as hashCode
      }
      MethodMirror mm = xm.type.instanceMembers[name];
      if (mm.isGetter) {
        var xv = xm.getField(name).reflectee;
        var yv = ym.getField(name).reflectee;
        checkDeepEqual(xv,yv);
      }
    }
  }
  else if (x is PrimitiveConstant && y is PrimitiveConstant) {
    checkDeepEqual(x.value, y.value);
  }
  else if (x is DartString && y is DartString) {
    if (x.slowToString() != y.slowToString()) {
      throw new Error();
    }
  }
  else {
    if (x != y) {
      throw new Error();
    }
  }
}

Expression parseExpression(String code) {
  SourceFile file = new StringSourceFile('', code);
  Scanner scan = new Scanner(file);
  Token tok = scan.tokenize();
  AstBuilder builder = new AstBuilder();
  Parser parser = new Parser(builder);
  tok = parser.parseExpression(tok);
  if (builder.stack.length != 1 || tok.kind != EOF_TOKEN) {
    throw "Parse error in $code";
  }
  return builder.pop();
}
Statement parseStatement(String code) {
  SourceFile file = new StringSourceFile('', code);
  Scanner scan = new Scanner(file);
  Token tok = scan.tokenize();
  AstBuilder builder = new AstBuilder();
  Parser parser = new Parser(builder);
  tok = parser.parseStatement(tok);
  if (builder.stack.length != 1 || tok.kind != EOF_TOKEN) {
    throw "Parse error in $code";
  }
  return builder.pop();
}

String unparseExpression(Expression exp) {
  StringBuffer buf = new StringBuffer();
  new Unparser(buf).writeExpression(exp);
  return buf.toString();
}
String unparseStatement(Statement stmt) {
  StringBuffer buf = new StringBuffer();
  new Unparser(buf).writeStatement(stmt);
  return buf.toString();
}

/// Converts [exp] to an instance of the frontend AST and unparses that.
String frontUnparseExpression(Expression exp) {
  tree.Node node = new TreePrinter().makeExpression(exp);
  return tree.unparse(node);
}
/// Converts [stmt] to an instance of the frontend AST and unparses that.
String frontUnparseStatement(Statement stmt) {
  tree.Node node = new TreePrinter().makeStatement(stmt);
  return tree.unparse(node);
}

/// Parses [code], unparses the resulting AST, then parses the unparsed text.
/// The ASTs from the first and second parse are then compared for structural
/// equality. Alternatively, if [expected] is not an empty string, the second
/// parse must match the AST of parsing [expected].
void checkFn(String code, String expected, Function parse, Function unparse) {
  var firstParse = parse(code);
  String unparsed = unparse(firstParse);
  try {
    var secondParse = parse(unparsed);
    var baseline = expected == "" ? firstParse : parse(expected);
    checkDeepEqual(baseline, secondParse);
  } catch (e, stack) {
    Expect.fail('"$code" was unparsed as "$unparsed"');
  }
}

void checkExpression(String code, [String expected="", String expected2=""]) {
  checkFn(code, expected, parseExpression, unparseExpression);
  checkFn(code, expected2, parseExpression, frontUnparseExpression);
}
void checkStatement(String code, [String expected="", String expected2=""]) {
  checkFn(code, expected, parseStatement, unparseStatement);
  checkFn(code, expected2, parseStatement, frontUnparseStatement);
}

void debugTokens(String code) {
  SourceFile file = new StringSourceFile('', code);
  Scanner scan = new Scanner(file);
  Token tok = scan.tokenize();
  while (tok.next != tok) {
    print(tok.toString());
    tok = tok.next;
  }
}

void main() {
  // To check if these tests are effective, one should manually alter
  // something in [Unparser] and see if a test fails.

  checkExpression(" a +  b  + c");
  checkExpression("(a +  b) + c");
  checkExpression(" a + (b  + c)");

  checkExpression(" a +  b  - c");
  checkExpression("(a +  b) - c");
  checkExpression(" a + (b  - c)");

  checkExpression(" a -  b  + c");
  checkExpression("(a -  b) + c");
  checkExpression(" a - (b  + c)");

  checkExpression(" a *  b  + c");
  checkExpression("(a *  b) + c");
  checkExpression(" a * (b  + c)");

  checkExpression(" a +  b  * c");
  checkExpression("(a +  b) * c");
  checkExpression(" a + (b  * c)");

  checkExpression(" a *  b  * c");
  checkExpression("(a *  b) * c");
  checkExpression(" a * (b  * c)");

  checkExpression("a is T");
  checkExpression("a is! T");
  checkExpression("!(a is T)");

  checkExpression("a is T.x");
  checkExpression("a is! T.x");
  checkExpression("!(a is T.x)");
  checkExpression("!(a is T).x");

  checkExpression("a as T.x");
  checkExpression("(a as T).x");

  checkExpression("a == b");
  checkExpression("a != b");
  checkExpression("!(a == b)", "a != b");

  checkExpression("a && b ? c : d");
  checkExpression("(a && b) ? c : d");
  checkExpression("a && (b ? c : d)");

  checkExpression("a || b ? c : d");
  checkExpression("(a || b) ? c : d");
  checkExpression("a || (b ? c : d)");

  checkExpression(" a ? b :  c && d");
  checkExpression(" a ? b : (c && d)");
  checkExpression("(a ? b :  c) && d");

  checkExpression(" a ? b : c = d");
  checkExpression(" a ? b : (c = d)");

  checkExpression("(a == b) == c");
  checkExpression("a == (b == c)");

  checkExpression(" a <  b  == c");
  checkExpression("(a <  b) == c");
  checkExpression(" a < (b  == c)");

  checkExpression(" a ==  b  < c");
  checkExpression("(a ==  b) < c");
  checkExpression(" a == (b  < c)");

  checkExpression("x.f()");
  checkExpression("(x.f)()");

  checkExpression("x.f()()");
  checkExpression("(x.f)()()");

  checkExpression("x.f().g()");
  checkExpression("(x.f)().g()");

  checkExpression("x.f()");
  checkExpression("x.f(1 + 2)");
  checkExpression("x.f(1 + 2, 3 + 4)");
  checkExpression("x.f(1 + 2, foo:3 + 4)");
  checkExpression("x.f(1 + 2, foo:3 + 4, bar: 5)");
  checkExpression("x.f(foo:3 + 4)");
  checkExpression("x.f(foo:3 + 4, bar: 5)");

  checkExpression("x.f.g.h");
  checkExpression("(x.f).g.h");
  checkExpression("(x.f.g).h");

  checkExpression(" a =  b  + c");
  checkExpression(" a = (b  + c)");
  checkExpression("(a =  b) + c");

  checkExpression("a + (b = c)");

  checkExpression("dx * dx + dy * dy < r * r",
                  "((dx * dx) + (dy * dy)) < (r * r)");
  checkExpression("mid = left + right << 1",
                  "mid = ((left + right) << 1)");
  checkExpression("a + b % c * -d ^  e - f  ~/ x & ++y / z++ | w > a ? b : c");
  checkExpression("a + b % c * -d ^ (e - f) ~/ x & ++y / z++ | w > a ? b : c");

  checkExpression("'foo'");
  checkExpression("'foo' 'bar'", "'foobar'");

  checkExpression("{}.length");
  checkExpression("{x: 1+2}.length");
  checkExpression("<String,int>{}.length");
  checkExpression("<String,int>{x: 1+2}.length");

  checkExpression("[].length");
  checkExpression("[1+2].length");
  checkExpression("<num>[].length");
  checkExpression("<num>[1+2].length");

  checkExpression("x + -y");
  checkExpression("x + --y");
  checkExpression("x++ + y");
  checkExpression("x + ++y");
  checkExpression("x-- - y");
  checkExpression("x-- - -y");
  checkExpression("x - --y");

  checkExpression("x && !y");
  checkExpression("!x && y");
  checkExpression("!(x && y)");

  checkExpression(" super +  1  * 2");
  checkExpression("(super +  1) * 2");
  checkExpression(" super + (1  * 2)");
  checkExpression("x + -super");
  checkExpression("x-- - -super");
  checkExpression("x - -super");
  checkExpression("x && !super");

  checkExpression("super.f(1, 2) + 3");
  checkExpression("super.f + 3");

  checkExpression(r"'foo\nbar'");
  checkExpression(r"'foo\r\nbar'");
  checkExpression(r"'foo\rbar'");
  checkExpression(r"'foo\'bar'");
  checkExpression(r"""'foo"bar'""");
  checkExpression(r"r'foo\nbar'");
  checkExpression("''");
  checkExpression("r''");

  var sq = "'";
  var dq = '"';
  checkExpression("'$dq$dq' \"$sq$sq\"");
  checkExpression("'$dq$dq$dq$dq' \"$sq$sq$sq$sq\"");
  checkExpression(r"'\$\$\$\$\$\$\$\$\$'");
  checkExpression("'$dq$dq$dq' '\\n\\n\\n\\n\\n\\n\\n\\n\\n\\n' \"$sq$sq$sq\"");
  checkExpression("'$dq$dq$dq' '\\r\\r\\r\\r\\r\\r\\r\\r\\r\\r' \"$sq$sq$sq\"");
  checkExpression("'$dq$dq$dq' '\\r\\n\\r\\n\\r\\n\\r\\n\\r\\n' \"$sq$sq$sq\"");

  checkExpression(r"'$foo'");
  checkExpression(r"'${foo}x'");
  checkExpression(r"'${foo}x\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\'");
  checkExpression(r"'abc' '${foo}' r'\\\\\\\'");

  checkExpression(r"'${$x}'");
  checkExpression(r"'${$x}y'");
  checkExpression("null + null");

  checkExpression("(x) => x",
                  '',
                  '(x){return x;}');
  checkStatement("fn(x) => x;",
                  '',
                  'fn(x){return x;}');

  checkExpression("throw x");
  checkStatement("throw x;");

  checkStatement("var x, y, z;");
  checkStatement("final x, y, z;");
  checkStatement("dynamic x, y, z;");
  checkStatement("String x, y, z;");
  checkStatement("List<int> x, y, z;");
  checkStatement("final dynamic x, y, z;");
  checkStatement("final String x, y, z;");
  checkStatement("final List<int> x, y, z;");

  checkStatement("var x = y, z;");
  checkStatement("var x, y = z;");
  checkStatement("var x = y = z;");

  // Note: We sometimes have to pass an expected string to account for
  //       block flattening which does not preserve structural AST equality
  checkStatement("if (x)   if (y) foo();   else bar();  ");
  checkStatement("if (x) { if (y) foo(); } else bar();  ");
  checkStatement("if (x) { if (y) foo();   else bar(); }",
                 "if (x)   if (y) foo();   else bar();  ");

  checkStatement("if (x) while (y)   if (z) foo();   else bar();  ");
  checkStatement("if (x) while (y) { if (z) foo(); } else bar();  ");
  checkStatement("if (x) while (y) { if (z) foo();   else bar(); }",
                 "if (x) while (y)   if (z) foo();   else bar();  ");

  checkStatement("{var x = 1; {var x = 2;} return x;}");
  checkStatement("{var x = 1; {x = 2;} return x;}",
                 "{var x = 1;  x = 2;  return x;}",
                 "{var x = 1;  x = 2;  return x;}");

  checkStatement("if (x) {var x = 1;}");

  checkStatement("({'foo': 1}).bar();");
  checkStatement("({'foo': 1}).length;");
  checkStatement("({'foo': 1}).length + 1;");
  checkStatement("({'foo': 1})['foo'].toString();");
  checkStatement("({'foo': 1})['foo'] = 3;");
  checkStatement("({'foo': 1}['foo']());");
  checkStatement("({'foo': 1}['foo'])();");
  checkStatement("({'foo': 1})['foo'].x++;");
  checkStatement("({'foo': 1}) is Map;");
  checkStatement("({'foo': 1}) as Map;");
  checkStatement("({'foo': 1}) is util.Map;");
  checkStatement("({'foo': 1}) + 1;");

  checkStatement("[1].bar();");
  checkStatement("1.bar();");
  checkStatement("'foo'.bar();");

  checkStatement("do while(x); while (y);");
  checkStatement("{do; while(x); while (y);}");

  checkStatement('switch(x) { case 1: case 2: return y; }');
  checkStatement('switch(x) { default: return y; }');
  checkStatement('switch(x) { case 1: x=y; default: return y; }');
  checkStatement('switch(x) { case 1: x=y; y=z; break; default: return y; }');

}

