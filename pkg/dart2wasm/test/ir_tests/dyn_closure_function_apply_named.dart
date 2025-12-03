// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// typeFilter=Closure-0-2|Vtable-0-2
// functionFilter=XXX
// globalFilter=foo|bar

void main() {
  Function.apply(() {}, []);
  Function.apply(foo, [1]);
  Function.apply(foo, [1, 'b']);
  Function.apply(bar, [1]);
  Function.apply((int a, {int? n}) {}, [1], {#n: 1});
}

@pragma('wasm:never-inline')
void foo(int a, [String? b]) {
  print('Foo $a $b');
}

@pragma('wasm:never-inline')
void bar(int a, [int? b]) {
  print('Bar $a $b');
}
