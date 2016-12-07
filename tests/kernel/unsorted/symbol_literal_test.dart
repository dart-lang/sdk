// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.isTrue('${#abc}' == 'Symbol("abc")');
  Expect.isTrue('${#abc.xzy}' == 'Symbol("abc.xzy")');
}
