// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TwoScriptsTestFirst;

import 'dart:html';

aGlobalFunction() {
  window.postMessage('first_global', '*');
}

main() {
  window.postMessage('first_local', '*');
  aGlobalFunction();
}
