// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=true -Db=false -Dc=NOTBOOL -Dd=True

import "package:expect/expect.dart";

main() {
  Expect.isTrue(bool.tryParse('true'));
  Expect.isFalse(bool.tryParse('false'));
  Expect.isTrue(bool.tryParse('TRUE', caseSensitive: false));
  Expect.isFalse(bool.tryParse('FALSE', caseSensitive: false));
  Expect.isNull(bool.tryParse('TRUE'));
  Expect.isNull(bool.tryParse('FALSE'));
  Expect.isNull(bool.tryParse('y'));
  Expect.isNull(bool.tryParse('n'));
  Expect.isNull(bool.tryParse(' true ', caseSensitive: false));
  Expect.isNull(bool.tryParse(' false ', caseSensitive: false));
  Expect.isNull(bool.tryParse('0', caseSensitive: true));
  Expect.isNull(bool.tryParse('1', caseSensitive: true));
}
