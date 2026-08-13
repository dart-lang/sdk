// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Child {}

Object getChild(int x) {
  return x < 3 ? Child() : 4;
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => getChild(1) as Child;
