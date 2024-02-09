// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E<T>(({T t}) it) {
  T get t => it.t;
}

T run<T>(E<T> e) => switch (e) { E(:var t) => t };

void main() {}
