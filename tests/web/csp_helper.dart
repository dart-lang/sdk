// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:js" as js;

final isCspEnabled = (() {
  try {
    js.context.callMethod('eval', ['5;']);
    return false;
  } catch (e) {
    return true;
  }
})();
