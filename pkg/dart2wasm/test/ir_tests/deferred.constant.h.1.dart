// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class H1 {
  final void Function(int) fun;
  const H1(this.fun);
}

void globalH1Foo<T>(T a) => print('globalH1Bar<$T>($a)');

const constH1 = H1(globalH1Foo);

@pragma('wasm:never-inline')
void modH1UseH1() {
  print(constH1);
  constH1.fun(1);
}
