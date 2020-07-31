// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool Function(T) predicate<T>(bool Function(T) fn) => (T val) => fn(val);

void test() {
  print(predicate((v) => v % 2 == 1)(3));
}

void main() {}
