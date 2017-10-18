// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

import "package:expect/expect.dart";

main() {
  Expect.throwsArgumentError(() => new RegExp(null));
  Expect.throwsArgumentError(() => new RegExp(r"^\w+$").hasMatch(null));
  Expect.throwsArgumentError(() => new RegExp(r"^\w+$").firstMatch(null));
  Expect.throwsArgumentError(() => new RegExp(r"^\w+$").allMatches(null));
  Expect.throwsArgumentError(() => new RegExp(r"^\w+$").stringMatch(null));
}
