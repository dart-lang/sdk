// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  final int? _field;

  Super(this._field);

  void set _field(_) {}
}

class Sub extends Super {
  Sub(super._field);

  void method() {
    if (super._field != null) {
      super._field++;
    }
  }
}
