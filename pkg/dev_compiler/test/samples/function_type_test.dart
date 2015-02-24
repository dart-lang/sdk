// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Function f = (int x) => x + 1;
dynamic a = f;
Function g = a;

typedef int Foo(int x);
Foo foo = g;

void main() {
  print(g(41));
}
