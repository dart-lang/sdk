// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Da= -Db=b -Dc=Something

import 'package:expect/expect.dart';

main() {
  Expect.isTrue(const bool.hasEnvironment('dart.library.core'));
  Expect.isTrue(const bool.hasEnvironment('a'));
  Expect.isTrue(const bool.hasEnvironment('b'));
  Expect.isTrue(const bool.hasEnvironment('c'));
  Expect.isFalse(const bool.hasEnvironment('d'));
}
