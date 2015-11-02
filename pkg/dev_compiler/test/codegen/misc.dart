// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Codegen dependency order test
const UNINITIALIZED = const _Uninitialized();
class _Uninitialized { const _Uninitialized(); }

class Generic<T> {
  Type get type => Generic;
}

// super ==
// https://github.com/dart-lang/dev_compiler/issues/226
class Base {
  int x = 1, y = 2;
  operator==(obj) {
    return obj is Base && obj.x == x && obj.y == y;
  }
}
class Derived {
  int z = 3;
  operator==(obj) {
    return obj is Derived && obj.z == z && super == obj;
  }
}

// string escape tests
// https://github.com/dart-lang/dev_compiler/issues/227
bool _isWhitespace(String ch) =>
    ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';

const expr = 'foo';
const _escapeMap = const {
  '\n': r'\n',
  '\r': r'\r',
  '\f': r'\f',
  '\b': r'\b',
  '\t': r'\t',
  '\v': r'\v',
  '\x7F': r'\x7F', // delete
  '\${${expr}}': ''
};


main() {
  // Number literals in call expressions.
  print(1.toString());
  print(1.0.toString());
  print(1.1.toString());

  // Type literals, #184
  dynamic x = 42;
  print(x == dynamic);
  print(x == Generic);

  // Should be Generic<dynamic>
  print(new Generic<int>().type);

  print(new Derived() == new Derived()); // true
}
