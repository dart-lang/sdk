// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

@patch
@pragma("vm:entry-point")
class bool {
  @patch
  @pragma("vm:external-name", "Bool_fromEnvironment")
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue = false});

  @patch
  @pragma("vm:external-name", "Bool_hasEnvironment")
  external const factory bool.hasEnvironment(String name);

  @patch
  int get hashCode => this ? 1231 : 1237;

  int get _identityHashCode => this ? 1231 : 1237;
}
