// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for http://dartbug.com/19193
main() {
  RegExp re = new RegExp(r'.*(a+)+\d');
  Expect.isTrue("a0aaaaaaaaaaaaa".contains(re));
  Expect.isTrue("a0aaaaaaaaaaaaaa".contains(re)); // false when using JSCRE.
}
