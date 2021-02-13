// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A container that is either [T1] or [T2].
class Either2<T1 extends Object, T2 extends Object> {
  final T1? _t1;
  final T2? _t2;

  Either2.t1(T1 t1)
      : _t1 = t1,
        _t2 = null;

  Either2.t2(T2 t2)
      : _t1 = null,
        _t2 = t2;

  T map<T>(T Function(T1) f1, T Function(T2) f2) {
    if (_t1 != null) {
      return f1(_t1!);
    } else {
      return f2(_t2!);
    }
  }

  @override
  String toString() => map((t) => t.toString(), (t) => t.toString());
}
