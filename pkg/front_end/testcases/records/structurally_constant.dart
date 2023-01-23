// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void method1([a = (0, 1), b = (const <String>[], c: 'foo')]) {
  (0, 1); // Const
  (const <String>[], c: 'foo'); // Const
}

void method2({a = (0, 1), b = (const <String>[], c: 'foo')}) {
  (<String>[], c: 'foo'); // Non-const
}