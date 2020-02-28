// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "incremental_dart2js_tester.dart";

main(List<String> args) async {
  bool fast = true;
  bool useExperimentalInvalidation = true;
  bool addDebugBreaks = false;
  int limit = -1;

  Dart2jsTester dart2jsTester = new Dart2jsTester(
      useExperimentalInvalidation, fast, addDebugBreaks, limit);
  await dart2jsTester.test();
}
