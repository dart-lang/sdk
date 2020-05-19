// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Const<T> {
  final T field;

  const Const(this.field);
}

const Const<int> a = const Const<int>(0);
const Const<int?> b = const Const<int?>(0);
const Const<int?> c = const Const<int?>(null);
const Const<int>? d = const Const<int>(0);
const Const<int>? e = null;
