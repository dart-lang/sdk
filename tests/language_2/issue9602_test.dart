// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test case for http://dartbug.com/9602
library issue9602;

import 'issue9602_other.dart';

class C extends Object with M {}

main() {
  new C();
}
