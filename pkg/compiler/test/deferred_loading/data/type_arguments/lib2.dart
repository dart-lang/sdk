// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: C:OutputUnit(main, {})*/
class C<T> {
  const C();
}

/*class: D:OutputUnit(main, {})*/
class D {}

const dynamic field = const C<D>();
