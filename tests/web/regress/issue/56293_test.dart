// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class B {
  final void Function(Object?) call;
  final void Function(Object?) call2;
  B(this.call, this.call2);
}

bool f1Value = false;
bool f2Value = false;

f1(Object? o) => f1Value = o == null;
f2(Object? o) => f2Value = o == null;

void main() {
  B(f1, f2).call(null);
  B(f1, f2).call2(null);
  Expect.isTrue(f1Value);
  Expect.isTrue(f2Value);
}
