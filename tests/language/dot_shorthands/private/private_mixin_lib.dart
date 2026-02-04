// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin _M {
  static _M get getter => _Impl();
  static _M method() => _Impl();
}

class _Impl with _M {}

typedef Public_M = _M;
final Public_M v = _Impl();

void context(_M m) {}
void contextAlias(Public_M m) {}
