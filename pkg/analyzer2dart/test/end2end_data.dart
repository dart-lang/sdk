// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test data for the end2end test.
library test.end2end.data;

import 'test_helper.dart' show Group;
import 'test_helper.dart' as base show TestSpec;

class TestSpec extends base.TestSpec {
  const TestSpec(String input, [String output])
      : super(input, output != null ? output : input);
}

const List<Group> TEST_DATA = const <Group>[
  const Group('Empty main', const <TestSpec>[
    const TestSpec('''
main() {}
'''),

    const TestSpec('''
main() {}
foo() {}
''', '''
main() {}
'''),
  ]),
  const Group('Simple call-chains', const <TestSpec>[
    const TestSpec('''
foo() {}
main() {
  foo();
}
'''),

    const TestSpec('''
bar() {}
foo() {
  bar();
}
main() {
  foo();
}
'''),

    const TestSpec('''
bar() {
  main();
}
foo() {
  bar();
}
main() {
  foo();
}
'''),

  ]),
  const Group('Literals', const <TestSpec>[
    const TestSpec('''
main() {
  return 0;
}
'''),

    const TestSpec('''
main() {
  return 1.5;
}
'''),

    const TestSpec('''
main() {
  return true;
}
'''),

    const TestSpec('''
main() {
  return false;
}
'''),

    const TestSpec('''
main() {
  return "a";
}
'''),

    const TestSpec('''
main() {
  return "a" "b";
}
''', '''
main() {
  return "ab";
}
'''),
  ]),

  const Group('Parameters', const <TestSpec>[
    const TestSpec('''
main(args) {}
'''),

    const TestSpec('''
main(a, b) {}
'''),
  ]),

  const Group('Typed parameters', const <TestSpec>[
    const TestSpec('''
void main(args) {}
'''),

    const TestSpec('''
main(int a, String b) {}
'''),

    const TestSpec('''
main(Comparator a, List b) {}
'''),

    const TestSpec('''
main(Comparator<dynamic> a, List<dynamic> b) {}
''','''
main(Comparator a, List b) {}
'''),

    const TestSpec('''
main(Map a, Map<dynamic, List<int>> b) {}
'''),
  ]),

  const Group('Pass arguments', const <TestSpec>[
    const TestSpec('''
foo(a) {}
main() {
  foo(null);
}
'''),

    const TestSpec('''
bar(b, c) {}
foo(a) {}
main() {
  foo(null);
  bar(0, "");
}
'''),

    const TestSpec('''
bar(b) {}
foo(a) {
  bar(a);
}
main() {
  foo(null);
}
'''),
  ]),

  const Group('Top level field access', const <TestSpec>[
    const TestSpec('''
main(args) {
  return deprecated;
}
'''),
  ]),

  const Group('Local variables', const <TestSpec>[
    const TestSpec('''
main() {
  var a;
  return a;
}
''','''
main() {}
'''),

    const TestSpec('''
main() {
  var a = 0;
  return a;
}
''','''
main() {
  return 0;
}
'''),
  ]),

  const Group('Local variable writes', const <TestSpec>[
    const TestSpec('''
main() {
  var a;
  a = 10;
  return a;
}
''', '''
main() {
  return 10;
}
'''),

    const TestSpec('''
main() {
  var a = 0;
  a = 10;
  return a;
}
''', '''
main() {
  return 10;
}
'''),

    const TestSpec('''
main() {
  var a = 0;
  print(a);
  a = "";
  print(a);
  return a;
}
'''),

    const TestSpec('''
main(a) {
  print(a);
  a = "";
  print(a);
  return a;
}
'''),

    const TestSpec('''
main(a) {
  if (a) {
    a = "";
  }
  print(a);
  return a;
}
'''),
  ]),

  const Group('Dynamic access', const <TestSpec>[
    const TestSpec('''
main(a) {
  return a.foo;
}
'''),

    const TestSpec('''
main() {
  var a = "";
  return a.foo;
}
''','''
main() {
  return "".foo;
}
'''),
  ]),

  const Group('Dynamic invocation', const <TestSpec>[
    const TestSpec('''
main(a) {
  return a.foo(0);
}
'''),

    const TestSpec('''
main() {
  var a = "";
  return a.foo(0, 1);
}
''','''
main() {
  return "".foo(0, 1);
}
'''),
  ]),

  const Group('Binary expressions', const <TestSpec>[
    const TestSpec('''
main(a) {
  return a + deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a - deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a * deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a / deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a ~/ deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a % deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a < deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a <= deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a > deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a >= deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a << deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a >> deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a & deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a | deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a ^ deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a == deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a != deprecated;
}
''','''
main(a) {
  return !(a == deprecated);
}
'''),

    const TestSpec('''
main(a) {
  return a && deprecated;
}
'''),

    const TestSpec('''
main(a) {
  return a || deprecated;
}
'''),
  ]),

  const Group('If statement', const <TestSpec>[
    const TestSpec('''
main(a) {
  if (a) {
    print(0);
  }
}
'''),

    const TestSpec('''
main(a) {
  if (a) {
    print(0);
  } else {
    print(1);
  }
}
''','''
main(a) {
  a ? print(0) : print(1);
}
'''),

    const TestSpec('''
main(a) {
  if (a) {
    print(0);
  } else {
    print(1);
    print(2);
  }
}
'''),
  ]),

  const Group('Conditional expression', const <TestSpec>[
    const TestSpec('''
main(a) {
  return a ? print(0) : print(1);
}
'''),
  ]),

  // These test that unreachable statements are skipped within a block.
  const Group('Block statements', const <TestSpec>[
    const TestSpec('''
main(a) {
  return 0;
  return 1;
}
''', '''
main(a) {
  return 0;
}
'''),

    const TestSpec('''
main(a) {
  if (a) {
    return 0;
    return 1;
  } else {
    return 2;
    return 3;
  }
}
''', '''
main(a) {
  return a ? 0 : 2;
}
'''),

    const TestSpec('''
main(a) {
  if (a) {
    print(0);
    return 0;
    return 1;
  } else {
    print(2);
    return 2;
    return 3;
  }
}
''', '''
main(a) {
  if (a) {
    print(0);
    return 0;
  } else {
    print(2);
    return 2;
  }
}
'''),
  ]),

  const Group('List literal', const <TestSpec>[
    const TestSpec('''
main() {
  return [];
}
'''),

    const TestSpec('''
main() {
  return <int>[];
}
'''),

    const TestSpec('''
main() {
  return <int>[0];
}
'''),

    const TestSpec('''
main(a) {
  return <int>[0, 1, a];
}
'''),

    const TestSpec('''
main(a) {
  return [0, [1], [a, <int>[3]]];
}
'''),
  ]),

  const Group('Constructor invocation', const <TestSpec>[
    const TestSpec('''
main(a) {
  new Object();
}
'''),

const TestSpec('''
main(a) {
  new Deprecated("");
}
'''),
  ]),

  const Group('Map literal', const <TestSpec>[
    const TestSpec('''
main() {
  return {};
}
'''),

    const TestSpec('''
main() {
  return <int, String>{};
}
'''),

    const TestSpec('''
main() {
  return <String, int>{"a": 0};
}
'''),

    const TestSpec('''
main(a) {
  return <String, int>{"a": 0, "b": 1, "c": a};
}
'''),

    const TestSpec('''
main(a) {
  return {0: "a", 1: {2: "b"}, a: {3: "c"}};
}
'''),
  ]),
  const Group('For loop', const <TestSpec>[
    const TestSpec('''
main() {
  for (;;) {}
}
''', '''
main() {
  while (true) {}
}
'''),

const TestSpec('''
main() {
  for (var i = 0; i < 10; i = i + 1) {
    print(i);
  }
}
''', '''
main() {
  var i = 0;
  while (i < 10) {
    print(i);
    ++i;
  }
}
'''),

const TestSpec('''
main(i) {
  for (i = 0; i < 10; i = i + 1) {
    print(i);
  }
}
''', '''
main(i) {
  i = 0;
  while (i < 10) {
    print(i);
    ++i;
  }
}
'''),
  ]),

  const Group('While loop', const <TestSpec>[
    const TestSpec('''
main() {
  while (true) {}
}
'''),

const TestSpec('''
main() {
  var i = 0;
  while (i < 10) {
    print(i);
    i = i + 1;
  }
}''', '''
main() {
  var i = 0;
  while (i < 10) {
    print(i);
    ++i;
  }
}'''),
  ]),

  const Group('Type operators', const <TestSpec>[
    const TestSpec('''
main(a) {
  return a is String;
}
'''),

    const TestSpec('''
main(a) {
  return a is List<String>;
}
'''),

    const TestSpec('''
main(a) {
  return a is Comparator<String>;
}
'''),

  const TestSpec('''
main(a) {
  return a is! String;
}
''', '''
main(a) {
  return !(a is String);
}
'''),

const TestSpec('''
main(a) {
  return a as String;
}
'''),
  ]),

  const Group('For in loop', const <TestSpec>[
// TODO(johnniwinther): Add tests for `i` as top-level, static and instance
// fields.
    const TestSpec('''
main(a) {
  for (var i in a) {
    print(i);
  }
}
''', '''
main(a) {
  var v0 = a.iterator;
  while (v0.moveNext()) {
    print(v0.current);
  }
}'''),

    const TestSpec('''
main(a) {
  for (var i in a) {
    print(i);
    i = 0;
    print(i);
  }
}
''', '''
main(a) {
  var v0 = a.iterator, i;
  while (v0.moveNext()) {
    i = v0.current;
    print(i);
    i = 0;
    print(i);
  }
}
'''),

    const TestSpec('''
main(a) {
  var i;
  for (i in a) {
    print(i);
  }
}
''', '''
main(a) {
  var i, v0 = a.iterator;
  while (v0.moveNext()) {
    i = v0.current;
    print(i);
  }
}
'''),
  ]),
];
