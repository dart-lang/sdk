// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=true -Db=false -Dc=NOTBOOL -Dd=True

import "package:expect/expect.dart";

main() {
  Expect.isTrue(const bool.tryParse('true'));
  Expect.isFalse(const bool.tryParse('false'));
  Expect.isTrue(const bool.tryParse('TRUE', caseSensitive: true));
  Expect.isFalse(const bool.tryParse('FALSE', caseSensitive: true));

  Expect.isNull(const bool.tryParse('TRUE'));
  Expect.isNull(const bool.tryParse('FALSE'));
  Expect.isNull(const bool.tryParse('y'));
  Expect.isNull(const bool.tryParse('n'));
  Expect.isNull(const bool.tryParse(' true ', caseSensitive: true));
  Expect.isNull(const bool.tryParse(' false ', caseSensitive: true));
  Expect.isNull(const bool.tryParse('0', caseSensitive: true));
  Expect.isNull(const bool.tryParse('1', caseSensitive: true));
}
