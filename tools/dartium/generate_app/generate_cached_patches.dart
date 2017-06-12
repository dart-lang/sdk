// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  try {
    print("Generated Patches");
  } catch (e) {
    var workedElem = document.querySelector("#worked");
    var failedElem = document.querySelector("#failed");
    workedElem.style.dispay = 'none';
    failedElem.style.visibility = 'inline';
  }
}
