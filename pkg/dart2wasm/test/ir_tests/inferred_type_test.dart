// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=foo|bar
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=-O0

void main() {
  final base = int.parse('1') == 1 ? Base() : Sub();
  final sub = Sub();

  // Can go to Base or Sub
  base.foo();
  base.foo(x: true);
  base.foo(x: false);

  // Devirtualized to Sub
  sub.bar();
  sub.bar(x: true);
  sub.bar(x: false);
}

class Base {
  void foo({dynamic x = true}) {
    print('Base.foo(x = $x)');
  }
}

class Sub extends Base {
  void foo({dynamic x = true}) {
    print('Sub.foo(x: $x)');
  }

  void bar({dynamic x = true}) {
    print('Sub.bar(x: $x)');
  }
}
