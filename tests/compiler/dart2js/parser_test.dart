// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'parser_helper.dart';
import 'package:compiler/src/tree/tree.dart';

void testStatement(String statement) {
  Node node = parseStatement(statement);
  Expect.isNotNull(node.toString());
}

void testGenericTypes() {
  testStatement('List<T> t;');
  testStatement('List<List<T>> t;');
  testStatement('List<List<List<T>>> t;');
  testStatement('List<List<List<List<T>>>> t;');
  testStatement('List<List<List<List<List<T>>>>> t;');

  testStatement('List<List<T> > t;');
  testStatement('List<List<List<T> >> t;');
  testStatement('List<List<List<List<T> >>> t;');
  testStatement('List<List<List<List<List<T> >>>> t;');

  testStatement('List<List<List<T> > > t;');
  testStatement('List<List<List<List<T> > >> t;');
  testStatement('List<List<List<List<List<T> > >>> t;');

  testStatement('List<List<List<List<T> > > > t;');
  testStatement('List<List<List<List<List<T> > > >> t;');

  testStatement('List<List<List<List<List<T> > > > > t;');

  testStatement('List<List<List<List<List<T> >> >> t;');

  testStatement('List<List<List<List<List<T> >>> > t;');

  testStatement('List<List<List<List<List<T >>> >> t;');

  testStatement('List<T> t;');
  testStatement('List<List<T>> t;');
  testStatement('List<List<List<T>>> t;');
  testStatement('List<List<List<List<T>>>> t;');
  testStatement('List<List<List<List<List<T>>>>> t;');
}

void testPrefixedGenericTypes() {
  testStatement('lib.List<List<T> > t;');
  testStatement('lib.List<List<List<T> >> t;');
  testStatement('lib.List<List<List<List<T> >>> t;');
  testStatement('lib.List<List<List<List<List<T> >>>> t;');

  testStatement('lib.List<List<List<T> > > t;');
  testStatement('lib.List<List<List<List<T> > >> t;');
  testStatement('lib.List<List<List<List<List<T> > >>> t;');

  testStatement('lib.List<List<List<List<T> > > > t;');
  testStatement('lib.List<List<List<List<List<T> > > >> t;');

  testStatement('lib.List<List<List<List<List<T> > > > > t;');

  testStatement('lib.List<List<List<List<List<T> >> >> t;');

  testStatement('lib.List<List<List<List<List<T> >>> > t;');

  testStatement('lib.List<List<List<List<List<T >>> >> t;');
}

void testUnaryExpression() {
  testStatement('x++;');
  // TODO(ahe): reenable following test.
  // testStatement('++x++;');
  testStatement('++x;');
  testStatement('print(x++);');
  // TODO(ahe): reenable following test.
  // testStatement('print(++x++);'); // Accepted by parser, rejected later.
  testStatement('print(++x);');
}

void testChainedMethodCalls() {
  testStatement('MyClass.foo().bar().baz();');
  // TODO(ahe): reenable following test.
  // testStatement('MyClass.foo().-x;'); // Accepted by parser, rejected later.
  testStatement('a.b.c.d();');
}

void testFunctionStatement() {
  testStatement('int f() {}');
  testStatement('void f() {}');
}

void testDoStatement() {
  testStatement('do fisk(); while (hest());');
  testStatement('do { fisk(); } while (hest());');
}

void testWhileStatement() {
  testStatement('while (fisk()) hest();');
  testStatement('while (fisk()) { hest(); }');
}

void testConditionalExpression() {
  ExpressionStatement node = parseStatement("a ? b : c;");
  Conditional conditional = node.expression;

  node = parseStatement("a ? b ? c : d : e;");
  // Should parse as: a ? ( b ? c : d ) : e.
  conditional = node.expression;
  Expect.isNotNull(conditional.thenExpression.asConditional());
  Expect.isNotNull(conditional.elseExpression.asSend());

  node = parseStatement("a ? b : c ? d : e;");
  // Should parse as: a ? b : (c ? d : e).
  conditional = node.expression;
  Expect.isNotNull(conditional.thenExpression.asSend());
  Expect.isNotNull(conditional.elseExpression.asConditional());

  node = parseStatement("a ? b ? c : d : e ? f : g;");
  // Should parse as: a ? (b ? c : d) : (e ? f : g).
  conditional = node.expression;
  Expect.isNotNull(conditional.thenExpression.asConditional());
  Expect.isNotNull(conditional.elseExpression.asConditional());

  node = parseStatement("a = b ? c : d;");
  // Should parse as: a = (b ? c : d).
  SendSet sendSet = node.expression;
  Expect.isNotNull(sendSet.arguments.head.asConditional());

  node = parseStatement("a ? b : c = d;");
  // Should parse as: a ? b : (c = d).
  conditional = node.expression;
  Expect.isNull(conditional.thenExpression.asSendSet());
  Expect.isNotNull(conditional.elseExpression.asSendSet());

  node = parseStatement("a ? b = c : d;");
  // Should parse as: a ? (b = c) : d.
  conditional = node.expression;
  Expect.isNotNull(conditional.thenExpression.asSendSet());
  Expect.isNull(conditional.elseExpression.asSendSet());

  node = parseStatement("a ? b = c : d = e;");
  // Should parse as: a ? (b = c) : (d = e).
  conditional = node.expression;
  Expect.isNotNull(conditional.thenExpression.asSendSet());
  Expect.isNotNull(conditional.elseExpression.asSendSet());

  node = parseStatement("a ?? b ? c : d;");
  // Should parse as: (a ?? b) ? c : d;
  conditional = node.expression;
  Expect.isNotNull(conditional.condition.asSend());
  Expect.isTrue(conditional.condition.asSend().isIfNull);
  Expect.isNotNull(conditional.thenExpression.asSend());
  Expect.isNotNull(conditional.elseExpression.asSend());
}

void testNullOperators() {
  ExpressionStatement statement = parseStatement("a ?? b;");
  Expression node = statement.expression;
  Expect.isNotNull(node.asSend());
  Expect.isTrue(node.asSend().isIfNull);

  statement = parseStatement("a ??= b;");
  node = statement.expression;
  Expect.isNotNull(node.asSendSet());
  Expect.isTrue(node.asSendSet().isIfNullAssignment);

  statement = parseStatement("a?.b;");
  node = statement.expression;
  Expect.isNotNull(node.asSend());
  Expect.isTrue(node.asSend().isConditional);

  statement = parseStatement("a?.m();");
  node = statement.expression;
  Expect.isNotNull(node.asSend());
  Expect.isTrue(node.asSend().isConditional);
}

void testAssignment() {
  ExpressionStatement node;
  Expression expression;
  SendSet sendSet;

  node = parseStatement("a = b;");
  expression = node.expression;
  Expect.isNotNull(expression.asSendSet());

  node = parseStatement("a = b = c;");
  // Should parse as: a = (b = c).
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.isNotNull(sendSet.arguments.head.asSendSet());

  node = parseStatement("a = b = c = d;");
  // Should parse as: a = (b = (c = d)).
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.isNotNull(sendSet = sendSet.arguments.head.asSendSet());
  Expect.isNotNull(sendSet = sendSet.arguments.head.asSendSet());

  node = parseStatement("a.b = c;");
  // Should parse as: receiver = a, selector = b, arguments = c.
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.stringEquals("a", sendSet.receiver.toString());
  Expect.stringEquals("b", sendSet.selector.toString());
  Expect.stringEquals("c", sendSet.arguments.head.toString());

  node = parseStatement("a.b = c.d;");
  // Should parse as: a.b = (c.d).
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.stringEquals("a", sendSet.receiver.toString());
  Expect.stringEquals("b", sendSet.selector.toString());
  Expect.stringEquals("c.d", sendSet.arguments.head.toString());

  node = parseStatement("a.b = c.d = e.f;");
  // Should parse as: a.b = (c.d = (e.f)).
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.stringEquals("a", sendSet.receiver.toString());
  Expect.stringEquals("b", sendSet.selector.toString());
  Expect.isNotNull(sendSet = sendSet.arguments.head.asSendSet());
  Expect.stringEquals("c", sendSet.receiver.toString());
  Expect.stringEquals("d", sendSet.selector.toString());
  Expect.stringEquals("e.f", sendSet.arguments.head.toString());
}

void testIndex() {
  ExpressionStatement node;
  Expression expression;
  Send send;
  SendSet sendSet;

  node = parseStatement("a[b];");
  // Should parse as: (a)[b].
  expression = node.expression;
  Expect.isNotNull(send = expression.asSend());
  Expect.stringEquals("a", send.receiver.toString());
  Expect.stringEquals("[]", send.selector.toString());
  Expect.stringEquals("b", send.arguments.head.toString());

  node = parseStatement("a[b] = c;");
  // Should parse as: (a)[b] = c.
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.stringEquals("a", sendSet.receiver.toString());
  Expect.stringEquals("[]", sendSet.selector.toString());
  Expect.stringEquals("=", sendSet.assignmentOperator.toString());
  Expect.stringEquals("b", sendSet.arguments.head.toString());
  Expect.stringEquals("c", sendSet.arguments.tail.head.toString());

  node = parseStatement("a.b[c];");
  // Should parse as: (a.b)[c].
  expression = node.expression;
  Expect.isNotNull(send = expression.asSend());
  Expect.stringEquals("a.b", send.receiver.toString());
  Expect.stringEquals("[]", send.selector.toString());
  Expect.stringEquals("c", send.arguments.head.toString());

  node = parseStatement("a.b[c] = d;");
  // Should parse as: (a.b)[] = (c, d).
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.isNotNull(send = sendSet.receiver.asSend());
  Expect.stringEquals("a.b", send.toString());
  Expect.stringEquals("[]", sendSet.selector.toString());
  Expect.stringEquals("=", sendSet.assignmentOperator.toString());
  Expect.stringEquals("c", sendSet.arguments.head.toString());
  Expect.stringEquals("d", sendSet.arguments.tail.head.toString());
}

void testPostfix() {
  ExpressionStatement node;
  Expression expression;
  SendSet sendSet;

  node = parseStatement("a.b++;");
  // Should parse as: (a.b)++.
  expression = node.expression;
  Expect.isNotNull(sendSet = expression.asSendSet());
  Expect.stringEquals("a", sendSet.receiver.toString());
  Expect.stringEquals("b", sendSet.selector.toString());
  Expect.stringEquals("++", sendSet.assignmentOperator.toString());
  Expect.isTrue(sendSet.arguments.isEmpty);
}

void testOperatorParse() {
  FunctionExpression function = parseMember('operator -() => null;');
  Send name = function.name.asSend();
  Expect.isNotNull(name);
  Expect.stringEquals('operator', name.receiver.toString());
  Expect.stringEquals('-', name.selector.toString());
  Expect.isTrue(function.parameters.isEmpty);
  Expect.isNull(function.returnType);
  Expect.isNull(function.getOrSet);
}

class Collector extends DiagnosticReporter {
  int token = -1;

  void reportFatalError(Token token) {
    this.token = token.kind;
    throw this;
  }

  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    assert(token != -1);
    throw this;
  }

  spanFromToken(Token token) {
    this.token = token.kind;
  }

  void log(message) {
    print(message);
  }

  noSuchMethod(Invocation invocation) {
    throw 'unsupported operation';
  }

  @override
  DiagnosticMessage createMessage(spannable, messageKind,
      [arguments = const {}]) {
    return new DiagnosticMessage(null, spannable, null);
  }
}

void testMissingCloseParen() {
  final String source = '''foo(x {  // <= missing closing ")"
  return x;
}''';
  parse() {
    parseMember(source, reporter: new Collector());
  }

  check(exn) {
    Collector c = exn;
    Expect.equals(OPEN_CURLY_BRACKET_TOKEN, c.token);
    return true;
  }

  Expect.throws(parse, check);
}

void testMissingCloseBraceInClass() {
  final String source = 'class Foo {'; // Missing close '}'.
  parse() {
    fullParseUnit(source, reporter: new Collector());
  }

  check(exn) {
    Collector c = exn;
    Expect.equals(BAD_INPUT_TOKEN, c.token);
    return true;
  }

  Expect.throws(parse, check);
}

void testUnmatchedAngleBracket() {
  final String source = 'A<'; // unmatched '<'
  parse() {
    fullParseUnit(source, reporter: new Collector());
  }

  check(exn) {
    Collector c = exn;
    Expect.equals(LT_TOKEN, c.token);
    return true;
  }

  Expect.throws(parse, check);
}

void main() {
  testGenericTypes();
  // TODO(ahe): Enable this test when we handle library prefixes.
  // testPrefixedGenericTypes();
  testUnaryExpression();
  testChainedMethodCalls();
  testFunctionStatement();
  testDoStatement();
  testWhileStatement();
  testConditionalExpression();
  testNullOperators();
  testAssignment();
  testIndex();
  testPostfix();
  testOperatorParse();
  testMissingCloseParen();
  testMissingCloseBraceInClass();
  testUnmatchedAngleBracket();
}
