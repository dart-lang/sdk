// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

library mixin_prefix_lib;

import "dart:convert";

mixin MixinClass {
  String bar() => json.encode({'a': 1});
}
