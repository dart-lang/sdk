// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// typeFilter=Closure-0-2|Vtable-0-2
// functionFilter=XXX
// globalFilter=foo|bar

void main() {
  final objects = <dynamic>[
    () {},
    foo,
    bar,
    'a',
    1,
  ];
  final emptyClosure = objects[0];
  final fooClosure = objects[1];
  final barClosure = objects[2];
  emptyClosure();
  fooClosure(1);
  fooClosure(1, 'b');
  barClosure(1, 2);
  barClosure(1, 2);
}

@pragma('wasm:never-inline')
void foo(int a, [String? b]) {
  print('Foo $a $b');
}

@pragma('wasm:never-inline')
void bar(int a, [int? b]) {
  print('Bar $a $b');
}
