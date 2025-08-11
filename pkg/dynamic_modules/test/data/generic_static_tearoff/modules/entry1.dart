// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T tearImpl<T>(T value) {
  return value;
}

int Function(int) tear = tearImpl<int>;

@pragma('dyn-module:entry-point')
dynamic dynamicModuleEntrypoint() {
  return tear;
}
