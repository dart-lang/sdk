// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int constructed = 0;

class Leaf {
  Leaf() {
    constructed++;
  }
}

class Spec<T> {
  const Spec(this._build);
  final T Function() _build;

  T create() {
    final created = _build();
    return created;
  }
}

const spec = Spec<Leaf>(Leaf.new);

void main() {
  spec.create();
  Expect.equals(1, constructed);
}
