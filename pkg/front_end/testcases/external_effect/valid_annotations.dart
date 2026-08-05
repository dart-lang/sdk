// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('external-effect')
external void foo(Object? o);

class A {
  @pragma('external-effect')
  external static void foo(Object? o);
}

void main() {}
