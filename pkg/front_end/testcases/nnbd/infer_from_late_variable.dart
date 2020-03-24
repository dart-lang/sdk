// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T f<T>(T t) => t;

main() {
  late int local;
  local = f(0);
}
