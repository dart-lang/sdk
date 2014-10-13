// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unless overridden by a Zone, [print] in dart:core will call this function
/// if defined.
function dartPrint(message) {
  console.log(message);
  window.parent.postMessage(message, '*');
}
