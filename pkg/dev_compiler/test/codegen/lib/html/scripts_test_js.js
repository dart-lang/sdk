// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

window.postMessage('fish', '*');

function delayed() {
  window.postMessage('cow', '*');  // Unexpected message OK.
  parent.postMessage('weasel', '*');  // Message to parent OK.
  window.postMessage('crab', '*');
}
setTimeout(delayed, 500);
