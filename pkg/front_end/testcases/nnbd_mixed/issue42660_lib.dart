// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E on int {
  String m() => 'm';
}

int? f() => 4;

int? get p => 4;

class Class<T> {
  int? f() => 4;
  int? get p => 4;

  int? operator [](int index) => 4;

  int? operator -() => 4;

  int? operator +(Object? other) => 4;
}
