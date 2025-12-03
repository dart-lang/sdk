// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test generator for quadratic behavior in processing of
// safepoints in linear scan register allocator.
//
// See https://github.com/flutter/flutter/issues/176619

void main() {
  const n = 5000;

  print('''
@pragma('vm:never-inline')
String foo(String a, String b) {
  return '<\$a:\$b>';
}

@pragma('vm:never-inline')
String bar(String v) {
  switch(v) {
''');
  for (var i = 0; i < n; i++) {
    print('    case "v$i": return foo("a$i", v);');
  }
  print('''
    default: return '?';
  }
}
''');

  print('''

void main(List<String> args) {
  final a = args.length == 2 ? args[0] : 'a';
  final b = args.length == 2 ? args[1] : 'b';
  print(bar(foo(a, b)));
}
''');
}
