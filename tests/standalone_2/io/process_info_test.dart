// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

main() {
  int currentRss = ProcessInfo.currentRss;
  print('currentRss = $currentRss');
  Expect.isTrue(currentRss > 0);

  int maxRss = ProcessInfo.maxRss;
  print('maxRss = $maxRss');
  Expect.isTrue(maxRss > 0);

  Expect.isTrue(currentRss <= maxRss);
}
