// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Either2<T1, T2> {
  final int _which;
  final T1? _t1;
  final T2? _t2;

  const Either2.t1(T1 this._t1)
      : _t2 = null,
        _which = 1;

  const Either2.t2(T2 this._t2)
      : _t1 = null,
        _which = 2;
}

typedef ProgressToken = Either2<int, String>;

final analyzingProgressToken = ProgressToken.t2('ANALYZING');
