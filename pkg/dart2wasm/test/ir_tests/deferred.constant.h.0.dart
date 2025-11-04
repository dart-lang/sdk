// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class H0 {
  final void Function(int) fun;
  const H0(this.fun);
}

void globalH0Foo(int a) => print('globalH0Foo');

const constH0 = H0(globalH0Foo);
