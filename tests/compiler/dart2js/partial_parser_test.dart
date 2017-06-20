// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'parser_helper.dart';

void main() {
  testSkipExpression();
}

void testSkipExpression() {
  PartialParser parser = new PartialParser(new Listener());
  Token token = scan('a < b;');
  token = parser.skipExpression(token);
  Expect.equals(';', token.lexeme);

  token = scan('[a < b]').next;
  token = parser.skipExpression(token);
  Expect.equals(']', token.lexeme);

  token = scan('a < b,');
  token = parser.skipExpression(token);
  Expect.equals(',', token.lexeme);
}
