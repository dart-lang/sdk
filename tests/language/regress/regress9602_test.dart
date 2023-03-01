// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Regression test case for http://dartbug.com/9602
library issue9602;

import 'regress9602_other.dart';

class C extends Object with M {}

main() {
  new C();
}
