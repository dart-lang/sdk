// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  int get integer;
}

abstract class Util<E> {
  factory Util(int value) = _UtilImpl;
}

class _UtilImpl<E> implements Util<E>, Interface {
  final integer;

  _UtilImpl(this.integer);
}
