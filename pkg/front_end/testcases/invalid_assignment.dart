// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=warning*/

test(int i, String s) {
  /*@warning=InvalidAssignment*/ i = s;
  /*@warning=InvalidAssignment*/ i ??= s;
}

main() {}
