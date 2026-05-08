// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

@RecordUse()
final class C {
  final Symbol s;
  const C(this.s);
}

@RecordUse()
void staticMethod(Symbol s) {}

void main() {
  const c1 = C(#publicSymbol);
  print(c1);

  staticMethod(#anotherSymbol);

  // Private symbols have a library URI associated with them in Kernel.
  const c2 = C(#_privateSymbol);
  print(c2);
}
