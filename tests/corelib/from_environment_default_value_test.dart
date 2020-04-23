// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Verify that the default value is as expected.
  Expect.equals(false, const bool.fromEnvironment('UNDEFINED_NAME'));
  Expect.equals(0, const int.fromEnvironment('UNDEFINED_NAME'));
  Expect.equals('', const String.fromEnvironment('UNDEFINED_NAME'));

  // Verify that `defaultValue` is used when passed, not the default values.
  Expect.equals(
      true, const bool.fromEnvironment('UNDEFINED_NAME', defaultValue: true));
  Expect.equals(
      1, const int.fromEnvironment('UNDEFINED_NAME', defaultValue: 1));
  Expect.equals('qux',
      const String.fromEnvironment('UNDEFINED_NAME', defaultValue: 'qux'));
}
