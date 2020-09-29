// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'a.dart';

const crossModule = B();
main() {
  Expect.equals(2.71, sameModule.d);
  Expect.equals('default', sameModule.s);

  Expect.equals(2.71, crossModule.d);
  Expect.equals('default', crossModule.s);
}
