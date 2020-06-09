// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/32597: incorrect type was assigned to phi
// in strong mode.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

import "package:expect/expect.dart";

class Token {
  Token next;
}

class StringToken extends Token {}

class ErrorToken extends Token {}

bool failed = false;

void foo(Token tokens, {bool x: false}) {
  dynamic v;
  {
    Token current = tokens;
    while (current is ErrorToken) {
      failed = true;
      current = null;
    }
    v = current;
  }
  if (x) {
    ErrorToken second = v;
    print(second);
  }
}

void main() {
  Token token = new StringToken();
  token.next = token;

  for (int i = 0; i < 100; i++) {
    foo(token);
  }
  print(failed ? 'failure' : 'success');
  Expect.isFalse(failed);
}
