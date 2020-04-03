// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to crash in the presence of a
// super constructor declared external.

import "package:expect/expect.dart";
import 'dart:collection';

class Crash extends Expando<String> {
  Crash() : super();
}

void main() {
  Crash expando = new Crash();
  Expect.isTrue(expando is Expando);
}
