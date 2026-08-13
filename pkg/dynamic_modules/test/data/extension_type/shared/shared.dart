// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type MyExtensionType.foo(int _info) {
  int get info => _info;
}

extension MyExtension on String {
  String addSuffix(String suffix) => this + suffix;
}
