// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_prefix_lib;

import "dart:convert";

class MixinClass {
  String bar() => json.encode({'a': 1});
}
