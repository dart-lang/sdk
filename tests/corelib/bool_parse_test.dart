// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=true -Db=false -Dc=NOTBOOL -Dd=True

import "package:expect/expect.dart";

main() {
  Expect.isTrue(const bool.parse('true'));
  Expect.isFalse(const bool.parse('false'));
  Expect.isTrue(const bool.parse('TRUE', caseSensitive: true));
  Expect.isFalse(const bool.parse('FALSE', caseSensitive: true));
  Expect.throws(()=> bool.parse('True'));
  Expect.throws(()=> bool.parse('False'));
  Expect.throws(()=> bool.parse('y'));
  Expect.throws(()=> bool.parse('n'));
  Expect.throws(()=> bool.parse('0'));
  Expect.throws(()=> bool.parse('1'));
}