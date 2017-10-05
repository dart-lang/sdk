// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class bool {
  @patch
  const factory bool.fromEnvironment(String name, {bool defaultValue: false})
      native "Bool_fromEnvironment";

  @patch
  int get hashCode => this ? 1231 : 1237;

  int get _identityHashCode => this ? 1231 : 1237;
}
