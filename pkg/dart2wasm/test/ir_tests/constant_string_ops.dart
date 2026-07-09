// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=constantStringOps
// typeFilter=NoMatch
// globalFilter=NoMatch

void main() {
  constantStringOps();
}

@pragma('wasm:never-inline')
void constantStringOps() {
  print('foo'.length);
  print('foo'.codeUnitAt(0));
  final a = 'hello';
  final b = 'world';
  print(a + ' ' + b);
}
