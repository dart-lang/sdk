// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'parser_helper.dart';
import 'package:compiler/implementation/tree/tree.dart';

void testNode(Node node, String expected, String text, [bool hard = true]) {
  var debug = 'text=$text,expected=$expected,node:${node}';
  Expect.isNotNull(node, debug);

  Token beginToken = node.getBeginToken();
  Expect.isNotNull(beginToken, debug);
  Token endToken = node.getEndToken();
  Expect.isNotNull(endToken, debug);

  int begin = beginToken.charOffset;
  int end = endToken.charOffset + endToken.charCount;
  Expect.isTrue(begin <= end, debug);

  if (hard) {
  	Expect.stringEquals(expected, text.substring(begin, end), debug);
  }
}

Node testExpression(String text, [String alternate]) {
  ExpressionStatement statement = parseStatement('$text;');
  Expression node = statement.expression;
  testNode(node, alternate == null ? text : alternate, text);
  return node;
}

void testUnaryExpression() {
  testExpression('x++');
  testExpression('++x');
}

void testAssignment() {
  Expression node;
  SendSet sendSet;
  String text;

  text = "a = b";
  node = testExpression(text);

  text = "a = b = c";
  node = testExpression(text);
  // Should parse as: a = (b = c).
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.arguments.head.asSendSet(), 'b = c', text);

  text = "a = b = c = d";
  node = testExpression(text);
  // Should parse as: a = (b = (c = d)).
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet = sendSet.arguments.head.asSendSet(), 'b = c = d', text);
  testNode(sendSet = sendSet.arguments.head.asSendSet(), 'c = d', text);

  text = "a.b = c";
  node = testExpression(text);
  // Should parse as: receiver = a, selector = b, arguments = c.
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.receiver, "a", "a.b = c");
  testNode(sendSet.selector, "b", "a.b = c");
  testNode(sendSet.arguments.head, "c", "a.b = c");

  text = "a.b = c.d";
  node = testExpression(text);
  // Should parse as: a.b = (c.d).
  Expect.isNotNull(sendSet = node.asSendSet());
  Expect.stringEquals("a", sendSet.receiver.toString());
  Expect.stringEquals("b", sendSet.selector.toString());
  Expect.stringEquals("c.d", sendSet.arguments.head.toString());

  text = "a.b = c.d = e.f";
  node = testExpression(text);
  // Should parse as: a.b = (c.d = (e.f)).
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.receiver, "a", text);
  testNode(sendSet.selector, "b", text);
  Expect.isNotNull(sendSet = sendSet.arguments.head.asSendSet());
  testNode(sendSet.receiver, "c", text);
  testNode(sendSet.selector, "d", text);
  testNode(sendSet.arguments.head, "e.f", text);
}

void testIndex() {
  Expression node;
  Send send;
  SendSet sendSet;
  String text;

  text = "a[b]";
  node = testExpression(text);
  // Should parse as: (a)[b].
  Expect.isNotNull(send = node.asSend());
  testNode(send.receiver, "a", text);
  // TODO(johnniwinther): [selector] is the synthetic [] Operator which doesn't
  // return the right begin/end tokens. In the next line we should have expected
  // "[b]" instead of "[b".
  testNode(send.selector, "[b", text);
  testNode(send.arguments.head, "b", text);

  text = "a[b] = c";
  node = testExpression(text);
  // Should parse as: (a)[b] = c.
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.receiver, "a", text);
  testNode(sendSet.selector, "[]", text, false); // Operator token is synthetic.
  testNode(sendSet.assignmentOperator, "=", text);
  testNode(sendSet.arguments.head, "b", text);
  testNode(sendSet.arguments.tail.head, "c", text);

  text = "a.b[c]";
  node = testExpression(text);
  // Should parse as: (a.b)[c].
  Expect.isNotNull(send = node.asSend());
  testNode(send.receiver, "a.b", text);
  testNode(send.selector, "[]", text, false); // Operator token is synthetic.
  testNode(send.arguments.head, "c", text);

  text = "a.b[c] = d";
  node = testExpression(text);
  // Should parse as: (a.b)[] = (c, d).
  Expect.isNotNull(sendSet = node.asSendSet());
  Expect.isNotNull(send = sendSet.receiver.asSend());
  testNode(send, "a.b", text);
  testNode(sendSet.selector, "[]", text, false); // Operator token is synthetic.
  testNode(sendSet.assignmentOperator, "=", text);
  testNode(sendSet.arguments.head, "c", text);
  testNode(sendSet.arguments.tail.head, "d", text);
}

void testPostfix() {
  Expression node;
  SendSet sendSet;
  String text;

  text = "a.b++";
  node = testExpression(text);
  // Should parse as: (a.b)++.
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.receiver, "a", text);
  testNode(sendSet.selector, "b", text);
  testNode(sendSet.assignmentOperator, "++", text);
  Expect.isTrue(sendSet.arguments.isEmpty);

  text = "++a[b]";
  // TODO(johnniwinther): SendSet generates the wrong end token in the following
  // line. We should have [:testExpression(text):] instead of
  // [:testExpression(text, "++a"):].
  node = testExpression(text, "++a");
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.receiver, "a", text);
  testNode(sendSet.selector, "[]", text, false); // Operator token is synthetic.
  testNode(sendSet.assignmentOperator, "++", text);
  testNode(sendSet.arguments.head, "b", text);

  text = "a[b]++";
  node = testExpression(text);
  Expect.isNotNull(sendSet = node.asSendSet());
  testNode(sendSet.receiver, "a", text);
  testNode(sendSet.selector, "[]", text, false); // Operator token is synthetic.
  testNode(sendSet.assignmentOperator, "++", text);
  testNode(sendSet.arguments.head, "b", text);
}

void main() {
  testUnaryExpression();
  testAssignment();
  testIndex();
  testPostfix();
}
