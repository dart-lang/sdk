// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var st1;
  try {
    try {
      throw 'bad';
    } catch (e, st) {
      st1 = st;
      rethrow;
    }
    Expect.fail('Exception expected');
  } catch (e, st2) {
    Expect.equals(st1, st2);
    Expect.identical(st1, st2);
    return;
  }
  Expect.fail('Exception expected');
}
