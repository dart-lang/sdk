// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/32597: incorrect type was assigned to phi
// in strong mode.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

class Token {
  Token? next;
}

class StringToken extends Token {}

class ErrorToken extends Token {}

void foo(Token tokens) {
  Token? current = tokens;
  for (int i = 0; i < 1; i++) {
    while (current is ErrorToken) {
      ErrorToken first = current;
      // Loading phi (created for local variable 'current') from another local
      // variable ('first') with more specific type should not change the type
      // assigned to phi.
      print(first);
    }
    current = current!.next;
  }
}

void main() {
  Token token = new StringToken();
  token.next = token;

  for (int i = 0; i < 100; i++) {
    foo(token);
  }
  print('ok');
}
