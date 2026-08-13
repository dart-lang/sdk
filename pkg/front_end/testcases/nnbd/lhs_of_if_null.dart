// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/39694.

Object f() => g(null) ?? 0;
T g<T>(T t) => t;
main() {
  print(f());
}
