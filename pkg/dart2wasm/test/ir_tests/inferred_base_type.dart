// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// typeFilter=Holder
// functionFilter=readX

class Base {
  final int x;
  final int y;
  Base(this.x, this.y);
}

class Sub1 extends Base {
  Sub1(super.x, super.y);
}

class Sub2 extends Base {
  Sub2(super.x, super.y);
}

class Holder {
  final Object field;
  Holder(this.field);
}

@pragma('wasm:never-inline')
Holder? makeHolder(Object o) {
  if (o is Base) {
    return Holder(o);
  }
  return null;
}

@pragma('wasm:never-inline')
int readX(Holder holder) {
  final b = holder.field as Base;
  return b.x + b.y;
}

void main() {
  final list = <Object>[Sub1(10, 1), Sub2(20, 2), 'not a Base'];
  for (final o in list) {
    final h = makeHolder(o);
    if (h != null) {
      print(readX(h));
    }
  }
}
