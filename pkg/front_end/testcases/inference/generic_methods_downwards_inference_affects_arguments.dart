// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

T f<T>(List<T> s) => throw '';

test() {
  String x = f(['hi']);
  String y = f([/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 42]);
}
